#!/bin/bash

IPMITOOL=ipmitool
bmc_version=0.00
bmc_bk_version=0.00
bmc_update_version=1.22
bios_version=3.41.0.9-10
bios_update_version=3.41.0.9-10
cpld_version=0x9
cpld_update_version=0xB
remote_station=0

wifi_left_cpld_version=0
wifi_right_cpld_version=0
wifi_left_cpld_present=0
wifi_right_cpld_present=0
wifi_cpld_update_verision=0x0
rndc_left_cpld_version=0
rndc_right_cpld_version=0
rndc_left_cpld_present=0
rndc_right_cpld_present=0
rndc_cpld_update_verision=0x0
rndc_firmware_update_version=18.8.9
rndc_left_board_type=NA
rndc_right_board_type=NA
rndc_left_firmware_info=0.0
rndc_right_board_type=NA
rndc_right_firmware_info=0.0

minimum_bios_version=3.41.0.9-10
minimum_cpld_verison=0xC
minimum_bmc_version=1.22
update_bios_image=./VEP4600-BIOS-3.41.0.9-13.BIN
update_bmc_image=./VEP4600-BMC-v1.23.ima
update_cpld_image=./AZUL_CPLD_V0C.vme
wifi_update_cpld_image=./mstr_01_2011226.vme
rndc_update_cpld_image=./
bmc_ip=10.11.225.90
admin=admin
passwd=admin
pkg_version=1.0
ipmi_option=" "
yafu_option=" "

spin_wait () {
	counter=0	
	spinar[0]=45;spinar[1]=47;spinar[2]=124;spinar[3]=92;
	printf "\n"
	while [ $counter != $1 ]
	do
		spin=${spinar[$(($counter % 4))]}
		printf "\r\x$(printf %x $spin) "
		sleep 0.25
		counter=$(( $counter + 1 ))
	done
}

get_pacakge_version () {
	pkg_version=$(sed -n '/^PACKAGE::/,/^PACKAGEEND/p;/^PACKAGEEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
}

get_bmc_update_version () {
	bmc_update_version=1.22
	bmc_update_version=$(sed -n '/^BMC::/,/^BMCEND/p;/^BMCEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
	update_bmc_image=$(sed -n '/^BMC::/,/^BMCEND/p;/^BMCEND/q' firmware.files | sed -n 's/^[ \t]*image:[ \t]*\(.\+\)/\1/p')
}

get_bios_update_version () {
	bios_update_version=3.41.0.9-10
	bios_update_version=$(sed -n '/^BIOS::/,/^BIOSEND/p;/^BIOSEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
	update_bios_image=$(sed -n '/^BIOS::/,/^BIOSEND/p;/^BIOSEND/q' firmware.files | sed -n 's/^[ \t]*image:[ \t]*\(.\+\)/\1/p')
}

get_cpld_update_version () {
	cpld_update_version=0xC
	cpld_update_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
	update_cpld_image_no_reset=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*image:[ \t]*\(.\+\)/\1/p')
	update_cpld_image_reset=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*reset_image:[ \t]*\(.\+\)/\1/p')
}

get_wifi_cpld_update_version () {
	wifi_cpld_update_version=0x0
	wifi_cpld_update_version=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
	update_wifi_cpld_image=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*image:[ \t]*\(.\+\)/\1/p')
}

get_rndc_cpld_update_version () {
	rndc_cpld_update_version=0x0
	rndc_cpld_update_version=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
	update_rndc_cpld_image=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*image:[ \t]*\(.\+\)/\1/p')
}

get_rndc_firmware_version () {
	rndc_firmware_update_version=18.8.9
	rndc_firmware_update_version=$(sed -n '/^RNDCFIRMWARE::/,/^RNDCFIRMWAREEND/p;/^RNDCFIRMWAREEND/q' firmware.files | sed -n 's/^[ \t]*version:[ \t]*\(.\+\)/\1/p')
}

check_rndc_firmware_version () {
    #3 tupple
    ver_tup1=$(echo $1 | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\1/p')
    ver_tup2=$(echo $1 | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\2/p')
    ver_tup3=$(echo $1 | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\3/p')
    ver_update_tup1=$(echo $rndc_firmware_update_version | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\1/p')
    ver_update_tup2=$(echo $rndc_firmware_update_version | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\2/p')
    ver_update_tup3=$(echo $rndc_firmware_update_version | sed -n 's/\(\w\+\).\(\w\+\).\(\w\+\)/\3/p')

    if [[ "$ver_tup1" -lt "$ver_update_tup1" ]]; then 
        return 1
    fi
    if [[ "$ver_tup2" -lt "$ver_update_tup2" ]]; then 
        return 1
    fi
    if [[ "$ver_tup3" -lt "$ver_update_tup3" ]]; then 
        return 1
    fi
    return 0
}

check_cpld_minimum_firmwares () {
	minimum_bmc_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	minimum_bios_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ]; then
		minor=$(echo $minimum_bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		if (( $(echo "$minor > $(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')" | bc -l) )) 
		then
			echo "Need to first update BMC before updating BIOS"
			bmc_update $bmc_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BMC Failed & Exiting"
				exit 1
			fi
		fi
	fi
	if [ ! -z "$minimum_bios_version" ]; then
		minor=$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update BIOS before updating BMC"
			bios_update $bios_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BIOS Failed & Exiting"
				exit 1
			fi
		fi
	fi
}

check_wifi_cpld_minimum_firmwares () {
	minimum_bmc_version=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	minimum_bios_version=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ]; then
		minor=$(echo $minimum_bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		if (( $(echo "$minor > $(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')" | bc -l) )) 
		then
			echo "Need to first update BMC before updating BIOS"
			bmc_update $bmc_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BMC Failed & Exiting"
				exit 1
			fi
		fi
	fi
	if [ ! -z "$minimum_bios_version" ]; then
		minor=$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update BIOS before updating BMC"
			bios_update $bios_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BIOS Failed & Exiting"
				exit 1
			fi
		fi
	fi
}


check_rndc_cpld_minimum_firmwares () {
	minimum_bmc_version=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	minimum_bios_version=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ]; then
		minor=$(echo $minimum_bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		if (( $(echo "$minor > $(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')" | bc -l) )) 
		then
			echo "Need to first update BMC before updating BIOS"
			bmc_update $bmc_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BMC Failed & Exiting"
				exit 1
			fi
		fi
	fi
	if [ ! -z "$minimum_bios_version" ]; then
		minor=$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update BIOS before updating BMC"
			bios_update $bios_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BIOS Failed & Exiting"
				exit 1
			fi
		fi
	fi
}


check_left_cpld_minimum_firmwares () {
	if [ "$wifi_left_cpld_present" -eq "1" ]; then
		check_wifi_cpld_minimum_firmwares
		if [[ $? != 0 ]]; then
			return 1
		fi
	fi
	if [ "$rndc_left_cpld_present" -eq "1" ]; then
		check_rndc_cpld_minimum_firmwares
		if [[ $? != 0 ]]; then
			return 1
		fi
	fi
}


check_right_cpld_minimum_firmwares () {
	if [ "$wifi_right_cpld_present" -eq "1" ]; then
		check_wifi_cpld_minimum_firmwares
		if [[ $? != 0 ]]; then
			return 1
		fi
	fi
	if [ "$rndc_right_cpld_present" -eq "1" ]; then
		check_rndc_cpld_minimum_firmwares
		if [[ $? != 0 ]]; then
			return 1
		fi
	fi
}


check_bios_minimum_firmwares () {
	minimum_bmc_version=$(sed -n '/^BIOS::/,/^BIOSEND/p;/^BIOSEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	minimum_cpld_version=$(sed -n '/^BIOS::/,/^BIOSEND/p;/^BIOSEND/q' firmware.files | sed -n 's/^[ \t]*minimum_cpld_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ]; then
		minor=$(echo $minimum_bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		if (( $(echo "$minor > $(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')" | bc -l) )) 
		then
			echo "Need to first update BMC before updating BIOS"
			bmc_update $bmc_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BMC Failed & Exiting"
				exit 1
			fi
		fi
	fi
	if [ ! -z "$minimum_cpld_version" ]; then
		minor=$(echo $minimum_cpld_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $cpld_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update CPLD before updating BMC"
			cpld_update $cpld_update_image
			if [[ $? != 0 ]]; 
			then
				echo "Upgrade CPLD Failed & Exiting"
				exit 1
			fi
			echo "Please power cycle unit, when done please press y and <enter>"
			choice=n		
			while [ "$choice" != "y" ]
			do
				read choice
				if [ "$choice" = "y" ]
				then
					spin_wait 320
				else 
					echo "please press y and <enter>"
				fi			
			done
		fi
	fi
}


check_bmc_minimum_firmwares () {
	minimum_bios_version=$(sed -n '/^BMC::/,/^BMCEND/p;/^BMCEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	minimum_cpld_version=$(sed -n '/^BMC::/,/^BMCEND/p;/^BMCEND/q' firmware.files | sed -n 's/^[ \t]*minimum_cpld_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bios_version" ]; then
		minor=$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update BIOS before updating BMC"
			bios_update $bios_update_image
			if [ $? != 0 ]; 
			then
				echo "Upgrade BIOS Failed & Exiting"
				exit 1
			fi
		fi
	fi
	if [ ! -z "$minimum_cpld_version" ]; then
		minor=$(echo $minimum_cpld_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		if (( $(echo "$minor > $(echo $cpld_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			echo "Need to first update CPLD before updating BMC"
			cpld_update $cpld_update_image
			if [[ $? != 0 ]]; 
			then
				echo "Upgrade CPLD Failed & Exiting"
				exit 1
			fi
			echo "Please power cycle unit, when done please press y and <enter>"
			choice=n		
			while [ "$choice" = "y" ]
			do
				read choice
				if [ "$choice" = "y" ]
				then
					spin_wait 240
				else 
					echo "please press y and <enter>"
				fi			
			done
		fi
	fi
}



bmc_reset () {
	#check BMC is up	
	echo "BMC might have gone to uknown state. Waiting a minute.."
	spin_wait 240
	version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x01)
	completion_code=$(echo $version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		return 2
	fi	

	#send BMC reset command
	echo "Sending reset to BMC to recover"
	$IPMITOOL $ipmi_option raw 0x06 0x02
	spin_wait 240

	#check BMC is up
	version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x01)
	completion_code=$(echo $version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		return 2
	fi	
}

get_ipmitool () {
	choice=n
	IPMITOOL="ipmitool"
	local ssllib
	redhat_flavor=0
	command -v dpkg >/dev/null 2>&1 || {
		redhat_flavor=1
	}
	diag_os=$(uname -a | sed  -n 's/\(.\+\)\(dellemc-diag-os\)\(.\+\)/\2/p')
    if [[ "$diag_os" = "dellemc-diag-os" ]]; then
        # DiagOS. Install all libraries first
        library=$( dpkg -l | sed  -n 's/\(.\+\)\(zlib1g-dev:amd64\)\(.\+\)/\2/p')
        if [[ -z "$library" ]]; then
            dpkg -i diag/zlib1g-dev_1%3a1.2.8.dfsg-2+b1_amd64.deb
        fi                
        library=$( dpkg -l | sed  -n 's/\(.\+\)\(libssl-dev:amd64\)\(.\+\)/\2/p')
        if [[ -z "$library" ]]; then
            dpkg -i diag/libssl-dev_1.0.1t-1+deb8u6_amd64.deb
        fi
        library=$( dpkg -l | sed  -n 's/\(.\+\)\(libssl-doc\)\(.\+\)/\2/p')
        if [[ -z "$library" ]]; then
            dpkg -i diag/libssl-doc_1.0.1t-1+deb8u6_all.deb
        fi
    fi
	command -v bc >/dev/null 2>&1 || {
		if [[ "$redhat_flavor" -eq "0" ]]; then
            if [[ "$diag_os" -eq "dellemc-diag-os" ]]; then
                dpkg -i diag/bc_1.06.95-9_amd64.deb
            else 
                apt install bc
            fi
		else
			yum install bc
		fi
	}
	command -v ipmitool >/dev/null 2>&1 || {
		if [[ "$redhat_flavor" -eq "1" ]]; then
            centos_version=$(cat /etc/redhat-release | sed  -n 's/\(CentOS Linux release 7\)\(.\+\)/\1/p')
            if [[ "$centos_version" = "CentOS Linux release 7" ]]; then
                rpm -i ./centos7/OpenIPMI-modalias-2.0.23-2.el7.x86_64.rpm
                rpm -i ./centos7/ipmitool-1.8.18-7.el7.x86_64.rpm
            else
                yum install ipmitool
                if [ $? != 0 ]; then 
                    IPMITOOL=./ipmitool
                fi
            fi
		else
			apt install ipmitool
			if [ $? != 0 ]; then
				IPMITOOL=./ipmitool
			fi
		fi 
		#if [ ! -f ./ipmitool ]; then 
		#	printf >&2 "Require ipmitool but it's not installed.  \nInstall?(y/n):"; 
		#	read choice
		#else 
		#	choice=n
		#	IPMITOOL=./ipmitool
		#	return 0
		#fi 

		#choice=$(echo "$choice" | sed 's/\(.*\)/\L\1/')
		#if [ "$choice"  = "y" ]; then
		#	#installing
		#	echo installing ipmitool
		#	if [[ "$redhat_flavor" -eq "0" ]]; then
		#		apt install ipmitool
		#	fi
		#else
		#	return 2
		#fi
	}
	
	if [[ "$redhat_flavor" -eq "0" ]]; then
		ssllib=$(dpkg -l | grep libssl-dev)
		if [ -z "$ssllib" ]; then
			echo installing libssl-dev
			if [[ "$redhat_flavor" -eq "0" ]]; then
				apt install libssl-dev
			fi
			#else rpm -qa libssl-dev
		fi

	fi
}



get_bmc_versions() {
	#check the BMC version
	get_bmc_update_version 
	bmc_version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x01)
	if [ $? != 0 ]; then
		echo "BMC not responding.."
		exit 1
	fi
	completion_code=$(echo $bmc_version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error, completion code: $completion_code"
		exit 1
	fi
	major=$(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\1/')
	minor=$(echo $bmc_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
	bmc_version=$((16#$major)).$((16#$minor))

	#chYeck the back up BMC version
	bmc_bk_version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x02)
	completion_code=$(echo $bmc_version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error, completion code: $completion_code"
		exit 1
	fi
	
	if [ -z  $completion_code ] 
	then
		major=$(echo $bmc_bk_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\1/')
		minor=$(echo $bmc_bk_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		bmc_bk_version=$((16#$major)).$((16#$minor))
	fi
}

get_bios_version() {
	#check the BIOS version
	bios_version=$($IPMITOOL $ipmi_option mc getsysinfo system_fw_version)
	completion_code=$(echo $bios_version | sed  -n 's/Error:\(.\+\)/\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error: $completion_code"
		exit 1
	fi

	if [[ "$bios_version" = "Version1.0" ]]; then
		if [ -z "$ipmi_option" ]; then
			echo "Update BMC first before updating BIOS"
			echo "If BMC is updated already, then this tool will continue to update BIOS"
			return 0
		fi
		echo "CPU needs to be reset. Please wait.."
		$IPMITOOL $ipmi_option chassis power cycle
		#wait for CPU to come up
		spin_wait 660
	fi

	bios_version=$($IPMITOOL $ipmi_option mc getsysinfo system_fw_version)
	completion_code=$(echo $bios_version | sed  -n 's/Error:\(.\+\)/\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error: $completion_code"
		exit 1
	fi	
}

get_cpld_version () {
	if (( $(echo "$bmc_version < 1.23" | bc -l) )) 
	then
		cpld_version=0x0
		return 0
	fi		
	cpld_version=$($IPMITOOL $ipmi_option raw 0x3a 0xc 0x00 0x01 0x00)
	cpld_version=$(echo $cpld_version | sed  's/\([^   ]\+\)\([ ]\+\)/\1/')
	cpld_version=$((16#$cpld_version))
}

update_all () {
	echo "updating ALL images"
	local bmc_version_needed=
	local bios_version_needed=

	minimum_bmc_version=$(sed -n '/^BIOS::/,/^BIOSEND/p;/^BIOSEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ];  then
		if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
		then
			bmc_version_needed=$minimum_bmc_version
		fi
	fi
	#there is no minimum bmc needed for CPLD upates. Adding it here for showing logic for future firmware components.
	minimum_bmc_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ];  then
		if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
		then
			if (( $(echo "$minimum_bmc_version > $bmc_version_needed" | bc -l) )) 
			then 
				bmc_version_needed=$minimum_bmc_version
			fi
		fi
	fi
	
	minimum_bios_version=$(sed -n '/^BMC::/,/^BMCEND/p;/^BMCEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bios_version" ];  then
		if (( $(echo "$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/') > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			bios_version_needed=$minimum_bios_version
		fi
	fi
	minimum_bios_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bios_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bios_version" ];  then
		if (( $(echo "$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/') > $(echo $bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
		then
			if (( $(echo "$(echo $minimum_bios_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/') > $(echo $bios_version_needed | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
			then
				bios_version_needed=$minimum_bios_version
			fi
		fi
	fi

	#if [ ! -z "$bios_version_needed" ]; then
	#	if (( $(echo "$(echo $bios_version_needed | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/') > $(echo $bios_update_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
	#	then
	#		echo "BIOS version needed is not packaged in this package. Quiting"
	#		echo "Try with a later version of firmware package"
	#		exit 1
	#	fi
	#fi
	
	if [ ! -z "$bmc_version_needed" ] && [ ! -z "$bios_version_needed" ];  then
		# To avoid circular logic and keeping it simple, ask customer to go back and do 
		# incremental upgrade
		echo "Unable to resolve firmware dependencies"
		echo "Please use older update package to get minimum firmware"
		#exit 1
	fi
	#there is not minimum CPLD requirements. All CPLDs should support updating all components

	if [  -z "$bios_version_needed" ];  then
		#Always try to update BMC first
		update_bmc $update_bmc_image
		if [[ $? != 0 ]]; then 
			echo "Upgrade Failed & Exiting"
			exit 1
		fi
		get_bmc_versions
		update_bios $update_bios_image $bios_version no_check
	else
		update_bios $update_bios_image $bios_version
		update_bmc $update_bmc_image
	fi
	get_cpld_version
	rndc_left_cpld_present
	rndc_right_cpld_present
	wifi_left_cpld_present
	wifi_right_cpld_present

	#if [ ! -z "$bios_version_needed" ];  then
	#update_bios $update_bios_image $bios_version no_check
	#if [[ $? != 0 ]]; 
	#then
	#	exit 1
	#fi
	#fi

    if [ -z "$ipmi_option" ]; then
        update_cpld $update_cpld_image_no_reset no_reset
    else
        update_cpld $update_cpld_image_reset 
    fi
	if [[ "$wifi_left_cpld_present" -eq "1" ]]; then	
		update_left_cpld $update_wifi_cpld_image no_reset
	elif [[ "$rndc_left_cpld_present" -eq "1" ]]; then	
		update_left_cpld $update_rndc_cpld_image no_reset
	fi
	if [[ "$wifi_right_cpld_present" -eq "1" ]]; then
		update_right_cpld $update_wifi_cpld_image no_reset
	elif [[ "$rndc_right_cpld_present" -eq "1" ]]; then
		update_right_cpld $update_rndc_cpld_image no_reset
	fi

	if [[ "$remote_station" -eq "0" ]]; then
        update_rndc_firmware
    fi
	
	echo "Power cycle chassis for updates to take effect"
	return 0
}

update_bmc () {
	local ignore_backup=0
	#check dependency list

	echo "updating BMC image"
	get_bmc_update_version
	#check the BMC version
	version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x01)
	if [ $? != 0 ]; then
		echo "BMC not responding.."
		return 1
	fi
	completion_code=$(echo $version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error, completion code: $completion_code"
		echo "attempting to reset BMC"
		#try resetting BMC is we cannot get version info
		bmc_reset
		if [[ $? != 0 ]];
		then 
			echo "BMC reset attempted and failed"
			return 1
		fi		
	fi
	version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x01)
	if [ $? != 0 ]; then
		echo "BMC not responding.."
		return 1
	fi
	completion_code=$(echo $version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "Error: Unable to get BMC information. Reset Chassis and try again"
		return 1
	fi
	#check the back up BMC version
	bk_version=$($IPMITOOL $ipmi_option raw 0x32 0x8F 0x08 0x02)
	completion_code=$(echo $version | sed  -n 's/rsp=\(.\+\)/\U\1/p')
	if [ ! -z $completion_code ] 
	then
		echo "BMC reports error, completion code: $completion_code"
		#We may not have valid backup image, ignore and proceed
		echo "BMC may not have a valid backup image. Ignoring backup image"
		ignore_backup=1
	fi
	

	major=$(echo $version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\1/')
	minor=$(echo $version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
	version=$((16#$major)).$((16#$minor))
	if [ "$ignore_backup" -ne "1" ]; then
		major=$(echo $bk_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\1/')
		minor=$(echo $bk_version | sed  's/\([^   ]\+\)\([ ]\+\)\([^   ]\+\)/\3/')
		bk_version=$((16#$major)).$((16#$minor))
	else
		bk_version=0.0
	fi

	echo 
	echo "****************************"
	echo "* BMC version = $version       *"
	echo "* Back-up Version = $bk_version   *"
	echo "****************************"
	if (( $(echo "$version == $bmc_update_version" | bc -l) )) 
	then 
		echo "Already have $version programmed"
		echo
		sleep 5
		return 0
	fi 
	if (( $(echo "$version > $bmc_update_version" | bc -l) )) 
	then
		clear
		echo "upgrade version is older than the current BMC image"
		echo "upgrade version = $bmc_update_version, primary image version = $version"
		printf "do you want to update(y\\\n):"
		read choice
		if [ "$choice" == "n" ]
		then
			return 0
		fi
	fi	
	echo "updating primary image only.."
	./Yafuflash -non-interactive $yafu_option -d 1 -mse 1 $1
	if [[ $? != 0 ]]; 
	then
		echo "Image update failed"
		return 2
	else
		echo "Done with updating image"
		echo "Waiting while BMC reboots.."
		spin_wait 320
		get_bmc_versions
		if [ $? != 0 ]; then
			echo "BMC not responding. Unsually taking long time to boot. Exiting.."
			return 1
		fi
		return 0
	fi
}

update_bios () {
	#check dependency list

	echo "updating BIOS image"
	#check the BIOS version
	if [ "$bios_version" == "$bios_update_version" ]; then
		echo "Already have latest version of BIOS($bios_version)"
		sleep 5
		if [[ -z "${UPDATE_BACKUP_BIOS}" ]]; then
            echo " "
        else
            echo "Force updating back up BIOS"
            $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x01 
            ./Yafuflash -non-interactive $yafu_option -d 2 -mse 1 $1
            if [[ $? != 0 ]]; then
                echo "Backup BIOS image update failed"
                echo "Try flashing BIOS again"
            fi
            echo "Backup BIOS update done"
            $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x00
            if [ -z "$ipmi_option" ]; then
                echo "Will continue to update rest of components"
				echo "Power cycle cpu to boot new BIOS after update is complete"
				sleep 5
			else
                echo "Reseting CPU"
                $IPMITOOL $ipmi_option chassis power cycle
                #wait for CPU to come up
                spin_wait 1000
            fi
        fi
        return 0
	fi
	if [ -z $2 ]; then 
		version=$($IPMITOOL $ipmi_option mc getsysinfo system_fw_version)
		if [ $? != 0 ]; then
			echo "BMC not responding.."
			return 1
		fi
		completion_code=$(echo $version | sed  -n 's/Error:\(.\+\)/\1/p')
		if [ ! -z $completion_code ] 
		then
			echo "BMC reports error: $completion_code"
			echo "Possibly using wrong remote IP. Exiting.."
			return 1
		fi
	else
		completion_code=
		version=$2
	fi

	if [ -z  $completion_code ] 
	then
		major=$(echo $version | sed  's/\([^-]\+\)-\([0-9]\+\)/\1/')
		minor=$(echo $version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')
		echo 
		echo "******************************"
		echo "* BIOS version = $version *"
		echo "******************************"
		#check if the platform match the BIOS image
		if [ "$3" != "no_check" ]; then
			if  [ "$major" != $(echo $bios_update_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\1/') ];  
			then
				echo "BIOS image does not match target platform"
				return 1
			fi
			if (( $(echo "$minor > $(echo $bios_update_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
			then
	 			clear
				echo "upgrade version is older than the current BIOS image"
				echo "upgrade version = $bios_update_version, primary image version = $version"
				printf "do you want to update(y\\\n):"
				read choice
				if [ "$choice" = "n" ]
				then
					return 0
				fi
			fi
			if (( $(echo "$minor == $(echo $bios_update_version | sed  's/\([^-]\+\)-\([0-9]\+\)/\2/')" | bc -l) )) 
			then 
				echo "Already have $version programmed"
				echo
				sleep 5
				return 0
			fi
		fi
		echo "updating primary image only.."
		echo "BIOS image is $1"
		$IPMITOOL $ipmi_option raw 0x3A 0x11 0x00 
		./Yafuflash -non-interactive $yafu_option -d 2 -mse 1 $1
		if [[ $? != 0 ]]; 
		then
			echo "Image update failed"
			echo "Trying after resetting bmc. Please wait.."
			bmc_reset
			spin_wait 320
			echo "Updating primary image only.."
			./Yafuflash -non-interactive $yafu_option -d 2 -mse 1 $1
			if [[ $? != 0 ]]; then
				echo "Update failed again. Aborting"
				exit 1
			fi
		else
			echo "Done with updating primary image"
            if [ -z "$ipmi_option" ]; then
                if [[ -z "${UPDATE_BACKUP_BIOS}" ]]; then
                    echo " "
                else
                    echo "Updating backup BIOS"
                    $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x01 
                    ./Yafuflash -non-interactive $yafu_option -d 2 -mse 1 $1
                    if [[ $? != 0 ]]; then
                        echo "Backup BIOS image update failed"
                        echo "Try flashing BIOS again"
                    fi
                    $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x00
                fi
				echo "Will continue to update rest of components"
				echo "Power cycle cpu to boot new BIOS after update is complete"
				sleep 5
				return 0
			fi
			if [[ -z "${UPDATE_BACKUP_BIOS}" ]]; then
                echo " "
            else
                $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x01 
                ./Yafuflash -non-interactive $yafu_option -d 2 -mse 1 $1
                if [[ $? != 0 ]]; then
                    echo "Backup BIOS image update failed"
                    echo "Try flashing BIOS again"
                fi
                $IPMITOOL $ipmi_option raw 0x3a 0x06 0x01 0x00
            fi

			echo "Reseting CPU"
			$IPMITOOL $ipmi_option chassis power cycle
			#wait for CPU to come up
			spin_wait 1000
			get_bios_version 
			if [[ $? != 0 ]]; then
				echo "Unable to reset CPU or unsually taking longer for CPU to boot up"
				sleep 5
			fi
			return 0
		fi
	fi	
}

update_cpld () {
	echo "updating CPLD image"

	get_cpld_version
	minimum_bmc_version=$(sed -n '/^CPLD::/,/^CPLDEND/p;/^CPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
	if [ ! -z "$minimum_bmc_version" ];  then
		if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
		then
			echo "Please update BMC to version later than $minimum_bmc_version before updating MC card CPLD"
			return 1
		fi
	fi
	
	if (( $(printf "%d > %d\n" $cpld_version $cpld_update_version| bc -l) )) 
	then
		echo "upgrade version is older than the current CPLD image"
		printf "upgrade version = $cpld_update_version, programmed image version = 0x%X\n" $cpld_version
		printf "do you want to update(y\\\n):"
		read choice
		if [ $choice == "n" ]
		then
			return 0
		fi
	fi	

	if (( $(printf "%d == %d\n" "$cpld_version" "$cpld_update_version" | bc -l) )) 
	then
		printf "Already have 0x%x programmed\n" "$cpld_version"
		sleep 5
		return 0
	fi

	$IPMITOOL $ipmi_option raw 0x3A 0x07 0x01 0x0
	if [ $? != 0 ]; then
		echo "BMC not responding.."
		return 1
	fi

	./Yafuflash -non-interactive $yafu_option  -d 4 $1
	echo
	if [[ $? != 0 ]];  then
		echo "Image update failed"
		return 1
	else 
		if [ "$2" == "no_reset" ]; then
			return 0
		fi
		echo "Resetting main board CPLD image and CPU. Please wait.."
		spin_wait 320
		get_cpld_version
	fi
}

update_left_cpld () {
	echo "updating MC1_CARD CPLD image"
	local minimum_bmc_version
	
	if [[ "$wifi_left_cpld_present" -eq "1" ]]; then
		minimum_bmc_version=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
		if [ ! -z "$minimum_bmc_version" ];  then
			if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
			then
				echo "Please update BMC to version later than $minimum_bmc_version before updating MC card CPLD"
				return 1
			fi
		fi
		if (( $(printf "%d > %d\n" $wifi_left_cpld_version $wifi_cpld_update_version| bc -l) )) 
		then
			echo "upgrade version is older than the current CPLD image"
			printf "upgrade version = $wifi_cpld_update_version, programmed image version = 0x%X\n" $wifi_left_cpld_version
			printf "do you want to update(y\\\n):"
			read choice
			if [ $choice == "n" ]
			then
				return 0
			fi
		fi

		if (( $(printf "%d == %d\n" "$wifi_left_cpld_version" "$wifi_cpld_update_version" | bc -l) )) 
		then
			printf "Already have 0x%x programmed\n" "$wifi_left_cpld_version"
			sleep 5
			return 0
		fi

		$IPMITOOL $ipmi_option raw 0x3A 0x07 0x01 0x1
		if [ $? != 0 ]; then
			echo "BMC not responding.."
			return 1
		fi

		./Yafuflash -non-interactive $yafu_option  -d 4 $1
		echo
		if [[ $? != 0 ]];  then
			echo "Image update failed"
			return 1
		else 
			if [ "$2" == "no_reset" ]; then
				return 0
			fi
			echo "Reseting CPU"
			$IPMITOOL $ipmi_option chassis power cycle
			spin_wait 320
		fi
	elif [[ "$rndc_left_cpld_present" -eq "1" ]]; then
		minimum_bmc_version=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
		if [ ! -z "$minimum_bmc_version" ];  then
			if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
			then
				echo "Please update BMC to version later than $minimum_bmc_version before updating MC card CPLD"
				return 1
			fi
		fi
		if (( $(printf "%d > %d\n" $rndc_left_cpld_version $rndc_cpld_update_version| bc -l) )) 
		then
			echo "upgrade version is older than the current CPLD image"
			printf "upgrade version = $rndc_cpld_update_version, programmed image version = 0x%X\n" $rndc_left_cpld_version
			printf "do you want to update(y\\\n):"
			read choice
			if [ $choice == "n" ]
			then
				return 0
			fi
		fi

		if (( $(printf "%d == %d\n" "$rndc_left_cpld_version" "$rndc_cpld_update_version" | bc -l) )) 
		then
			printf "Already have 0x%x programmed\n" "$rndc_left_cpld_version"
			sleep 5
			return 0
		fi

		$IPMITOOL $ipmi_option raw 0x3A 0x07 0x01 0x1
		if [ $? != 0 ]; then
			echo "BMC not responding.."
			return 1
		fi

		./Yafuflash -non-interactive $yafu_option  -d 4 $1
		echo
		if [[ $? != 0 ]];  then
			echo "Image update failed"
			return 1
		else 
			if [ "$2" == "no_reset" ]; then
				return 0
			fi
			echo "Reseting CPU"
			$IPMITOOL $ipmi_option chassis power cycle
			spin_wait 320		
		fi
	else
		echo "No card present on left MC slot" 
		return 0
	fi
}

update_right_cpld () {
	echo "updating MC2_CARD CPLD image"

	
	if [[ "$wifi_right_cpld_present" -eq "1" ]]; then
		minimum_bmc_version=$(sed -n '/^WIFICPLD::/,/^WIFICPLDEND/p;/^WIFICPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
		if [ ! -z "$minimum_bmc_version" ];  then
			if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
			then
				echo "Please update BMC to version later than $minimum_bmc_version before updating MC card CPLD"
				return 1
			fi
		fi
		if (( $(printf "%d > %d\n" $wifi_right_cpld_version $wifi_cpld_update_version| bc -l) )) 
		then
			echo "upgrade version is older than the current CPLD image"
			printf "upgrade version = $wifi_cpld_update_version, programmed image version = 0x%X\n" $wifi_right_cpld_version
			printf "do you want to update(y\\\n):"
			read choice
			if [ $choice == "n" ]
			then
				return 0
			fi
		fi

		if (( $(printf "%d == %d\n" "$wifi_right_cpld_version" "$wifi_cpld_update_version" | bc -l) )) 
		then
			printf "Already have 0x%x programmed\n" "$wifi_right_cpld_version"
			sleep 5
			return 0
		fi

		$IPMITOOL $ipmi_option raw 0x3A 0x07 0x01 0x2
		if [ $? != 0 ]; then
			echo "BMC not responding.."
			return 1
		fi

		./Yafuflash -non-interactive $yafu_option  -d 4 $1
		echo
		if [[ $? != 0 ]];  then
			echo "Image update failed"
			return 1
		else 
			if [ "$2" == "no_reset" ]; then
				return 0
			fi
			echo "Reseting CPU"
			$IPMITOOL $ipmi_option chassis power cycle
			spin_wait 320
		fi
	elif [[ "$rndc_right_cpld_present" -eq "1" ]]; then
		minimum_bmc_version=$(sed -n '/^RNDCCPLD::/,/^RNDCCPLDEND/p;/^RNDCCPLDEND/q' firmware.files | sed -n 's/^[ \t]*minimum_bmc_version:[ \t]*\(.\+\)/\1/p')
		if [ ! -z "$minimum_bmc_version" ];  then
			if (( $(echo "$minimum_bmc_version > $bmc_version" | bc -l) )) 
			then
				echo "Please update BMC to version later than $minimum_bmc_version before updating MC card CPLD"
				return 1
			fi
		fi
		if (( $(printf "%d > %d\n" $rndc_right_cpld_version $rndc_cpld_update_version| bc -l) )) 
		then
			echo "upgrade version is older than the current CPLD image"
			printf "upgrade version = $rndc_cpld_update_version, programmed image version = 0x%X\n" $rndc_right_cpld_version
			printf "do you want to update(y\\\n):"
			read choice
			if [ $choice == "n" ]
			then
				return 0
			fi
		fi

		if (( $(printf "%d == %d\n" "$rndc_right_cpld_version" "$rndc_cpld_update_version" | bc -l) )) 
		then
			printf "Already have 0x%x programmed\n" "$rndc_right_cpld_version"
			sleep 5
			return 0
		fi

		$IPMITOOL $ipmi_option raw 0x3A 0x07 0x01 0x2
		if [ $? != 0 ]; then
			echo "BMC not responding.."
			return 1
		fi

		./Yafuflash -non-interactive $yafu_option  -d 4 $1
		echo
		if [[ $? != 0 ]];  then
			echo "Image update failed"
			return 1
		else 
			if [ "$2" == "no_reset" ]; then
				return 0
			fi
			echo "Reseting CPU"
			$IPMITOOL $ipmi_option chassis power cycle
			spin_wait 320		
        fi
	else
		echo "No card present on right MC slot"
		return 0
	fi
}

update_rndc_firmware ()
{
    if [[ "$rndc_right_cpld_present" -eq "1"  ||  "$rndc_left_cpld_present" -eq "1" ]]; then
        if [[ "$rndc_left_board_type" == "X710"  || "$rndc_right_board_type" == "X710" ]]; then
            #nvmx520=$(lspci -nn | grep Network | sed -n 's/\(.\+\)\[8086:\(1521\)\]\(.\+\)/\2/p')
            #if [[ -z "$nvmx520" ]]; then
            if [[ "$rndc_left_board_type" == "X710" ]]; then
                check_rndc_firmware_version $rndc_left_firmware_info
                retval1=$?
            fi
            if [[ "$rndc_right_board_type" == "X710" ]]; then
                check_rndc_firmware_version $rndc_right_firmware_info
                retval2=$?
            fi
            if [[ "$retval1" -eq "1"  || "$retval2" -eq "1" ]]; then
                echo "WARNING: To avoid damage to your device, do not stop the update or reboot or power off the system during this update."
                cd x710
                ./nvmupdate64e -u
                cd ..
            else
                echo "X710 already has the latest firmware image. Skipping update"
                sleep 2
            fi
        fi
        if [[ "$rndc_left_board_type" == "X520"  || "$rndc_right_board_type" == "X520" ]]; then
            if [[ "$rndc_left_board_type" == "X520" ]]; then
                check_rndc_firmware_version $rndc_left_firmware_info
                retval1=$?
            fi
            if [[ "$rndc_right_board_type" == "X520" ]]; then
                check_rndc_firmware_version $rndc_right_firmware_info
                retval2=$?
            fi
            if [[ "$retval1" -eq "1"  || "$retval2" -eq "1" ]]; then
                echo "WARNING: To avoid damage to your device, do not stop the update or reboot or power off the system during this update."
                cd x520
                ./nvmupdate64e -u
                cd ..
                echo "done updating"
            else
                echo "X520 already has the latest firmware image. Skipping update"
                sleep 2
            fi
        fi
        if [[ "$rndc_left_board_type" == "I350"  || "$rndc_right_board_type" == "I350" ]]; then
            if [[ "$rndc_left_board_type" == "I350" ]]; then
                check_rndc_firmware_version $rndc_left_firmware_info
                retval1=$?
            fi
            if [[ "$rndc_right_board_type" == "I350" ]]; then
                check_rndc_firmware_version $rndc_right_firmware_info
                retval2=$?
            fi
            if [[ "$retval1" -eq "1"  || "$retval2" -eq "1" ]]; then
                echo "WARNING: To avoid damage to your device, do not stop the update or reboot or power off the system during this update."
                cd x520
                ./nvmupdate64e -u
                cd ..
                echo "done updating"
            else
                echo "X520 already has the latest firmware image. Skipping update"
                sleep 2
            fi
        fi
    fi

}

rndc_left_cpld_present () {
	local rndc_board
	if (( $(echo "$bmc_version < 1.23" | bc -l) )) 
	then
		cpld_version=0x0
		return 0
	fi
	rndc_board=$($IPMITOOL $ipmi_option fru print 10 2> /dev/null | sed -n 's/^[ \t]*Board Product[ ]*:[ \t]*\(.\+\)\([ ]*$\)/\1/p')
	rndc_board=$(echo $rndc_board | sed 's/[ \t]*$//')
	if [[ "$rndc_board" == *"Intel"* ]]; then
		rndc_left_cpld_present=1
		rndc_left_cpld_version=$($IPMITOOL $ipmi_option raw 0x3a 0xc 0x01 0x01 0x9)
		rndc_left_cpld_version=$(echo $rndc_left_cpld_version | sed  's/\([^   ]\+\)\([ ]\+\)/\1/')
		rndc_left_cpld_version=$((16#$rndc_left_cpld_version))
        if [[ "$remote_station" -eq "0" ]]; then
            if [[ "$rndc_board" == *"X710"* ]]; then 
                rndc_left_board_type="X710"
                # get the firmware information
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(65\)\(66\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)X710\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; x; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_left_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)\s*\(.\+\)/\3/p')
            elif [[ "$rndc_board" == *"X520"* ]]; then
                rndc_left_board_type="X520"
                # get the firmware information
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(65\)\(66\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)82599ES\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; x; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_left_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)/\2/p')
            else
                rndc_right_board_type="I350"
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(17\)\(18\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)I350\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; x; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_right_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)\s*\(\S\+\)/\3/p')
            fi
        fi
		return 1
	fi
	rndc_left_cpld_present=0
	return 0
}

rndc_right_cpld_present () {
	local rndc_board
	if (( $(echo "$bmc_version < 1.23" | bc -l) )) 
	then
		cpld_version=0x0
		return 0
	fi
	rndc_board=$($IPMITOOL $ipmi_option fru print 11 2> /dev/null | sed -n 's/^[ \t]*Board Product[ ]*:[ \t]*\(.\+\)\([ ]*$\)/\1/p')
	rndc_board=$(echo $rndc_board | sed 's/[ \t]*$//')
	if [[ "$rndc_board" == *"Intel"* ]]; then
		rndc_right_cpld_present=1
		rndc_right_cpld_version=$($IPMITOOL $ipmi_option raw 0x3a 0xc 0x02 0x01 0x9)
		rndc_right_cpld_version=$(echo $rndc_right_cpld_version | sed  's/\([^   ]\+\)\([ ]\+\)/\1/')
		rndc_right_cpld_version=$((16#$rndc_right_cpld_version))
		if [[ "$remote_station" -eq "0" ]]; then
            if [[ "$rndc_board" == *"X710"* ]]; then 
                rndc_right_board_type="X710"
                # get the firmware information
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(65\)\(66\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)X710\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_right_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)\s*\(.\+\)/\3/p')
            elif [[ "$rndc_board" == *"X520"* ]]; then
                rndc_right_board_type="X520"
                # get the firmware information
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(65\)\(66\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)82599ES\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; x; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_right_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)/\2/p')
            else
                rndc_right_board_type="I350"
                ethdev=$(lshw -C network -businfo | sed -n 's/^pci@0000:\([\(17\)\(18\)]*\):\([0-9]*\.[0-9]*[ ]*\)\(.\+[0-9]\+ \)\( .\+\)I350\(.\+\)/\3/p')
                ethdev=$(echo $ethdev | sed -n '/./{H;$!d}; x; s/\s*\(\S\+\)\s*\(.\+\)/\1/p')
                if [[ -z "$ethdev" ]]; then
                    return 1
                fi
                rndc_right_firmware_info=$(ethtool -i $ethdev | sed -n 's/^firmware-version:\(\s*\)\(.\+\)/\2/p' | sed -n 's/\(\S\+\)\s*\(\S\+\)\s*\(\S\+\)/\3/p')
            fi
        fi
		return 1
	fi
	rndc_right_cpld_present=0
	return 0
}

wifi_left_cpld_present () {
	local wifi_board
	if (( $(echo "$bmc_version < 1.23" | bc -l) )) 
	then
		cpld_version=0x0
		return 0
	fi
	wifi_board=$($IPMITOOL $ipmi_option fru print 10 2> /dev/null | sed -n 's/^[ \t]*Board Product[ ]*:[ \t]*\(.\+\)\([ ]*$\)/\1/p')
	wifi_board=$(echo $wifi_board | sed 's/[ \t]*$//')
	if [ "$wifi_board" = "VEP-4600 WIFI CARD" ]; then
		wifi_left_cpld_present=1
		wifi_left_cpld_version=$($IPMITOOL $ipmi_option raw 0x3a 0xc 0x01 0x01 0x9)
		wifi_left_cpld_version=$(echo $wifi_left_cpld_version | sed  's/\([^   ]\+\)\([ ]\+\)/\1/')
		wifi_left_cpld_version=$((16#$wifi_left_cpld_version))
		return 1
	fi
	wifi_left_cpld_present=0
	return 0
}

wifi_right_cpld_present () {
	local wifi_board
	if (( $(echo "$bmc_version < 1.23" | bc -l) )) 
	then
		cpld_version=0x0
		return 0
	fi
	wifi_board=$($IPMITOOL $ipmi_option fru print 11 2> /dev/null | sed -n 's/^[ \t]*Board Product[ ]*:[ \t]*\(.\+\)/\1/p')
	wifi_board=$(echo $wifi_board | sed 's/[ \t]*$//')
	if [ "$wifi_board" = "VEP-4600 WIFI CARD" ]; then
		wifi_right_cpld_present=1
		wifi_right_cpld_version=$($IPMITOOL $ipmi_option raw 0x3a 0xc 0x02 0x01 0x9)
		wifi_right_cpld_version=$(echo $wifi_right_cpld_version | sed  's/\([^   ]\+\)\([ ]\+\)/\1/')
		wifi_right_cpld_version=$((16#$wifi_right_cpld_version))
		return 1
	fi
	wifi_right_cpld_present=0
	return 0
}

validate_ip () {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}



clear

if [[ -z "${BMC_ADMIN}" ]]; then
    admin=admin
else
    echo "Setting admin passwd from env variables"
    sleep 5
    admin="${BMC_ADMIN}"
fi

if [[ -z "${BMC_PASSWD}" ]]; then
    passwd=admin
else
    passwd="${BMC_PASSWD}"
fi

get_ipmitool
if [[ $? != 0 ]]; 
then
	echo "ipmitool is missing. Please install and then update firmware"
	exit 1
fi
if [ ! -z "$1" ] && [ "$1" != "interactive" ]; then
    validate_ip $1
	if [[ $? != 0 ]]; then
		echo "Invalid IP address. Please re-enter"
		exit 2
	fi
	ipmi_option="-H $1 -I lanplus -U $admin -P $passwd"
	yafu_option="-nw -ip $1 -u $admin -p $passwd -pnet -fb"
	remote_station=1
else
	ipmi_option=
	yafu_option="-cd "
fi

get_bmc_update_version
get_bios_update_version
get_cpld_update_version
get_wifi_cpld_update_version
get_rndc_cpld_update_version
get_pacakge_version
get_bmc_versions
get_bios_version
get_cpld_version
get_rndc_firmware_version

choice="1"
while [ "$choice" != "q" ]
do  
	get_cpld_version
	if [ "$2" != "interactive" ] && [ "$1" != "interactive" ]; then
		update_all
		exit 0
	fi
	
	
	printf "\n\n    Package version: $pkg_version"
	printf "\n    Packaged images:\n"
	echo "        BMC image:  $bmc_update_version"
	echo "        BIOS image: $bios_update_version"
	echo "        CPLD image: $cpld_update_version"
	echo "        Wifi CPLD image: $wifi_cpld_update_version"

	echo "    Note:If BMC version is less than 1.23 CPLD versions will not be shown correctly"
	printf "\n\n\n    1. Automatically update all firmware components\n"
	printf "    2. BMC image[Primary version:$bmc_version, backup version:$bmc_bk_version]\n"
	echo "    3. BIOS image[Booted version: $bios_version]"
	printf "    4. CPLD image[CPLD version: 0x%X]\n" $cpld_version
	wifi_left_cpld_present
	if [[ $? == 1 ]]; then
		printf "    5. Wifi left CPLD image[CPLD version: 0x%X]\n" $wifi_left_cpld_version
	else
		rndc_left_cpld_present
		if [[ $? = 1 ]]; then
			printf "    5. rNDC left CPLD image[CPLD version: 0x%X]\n" $rndc_left_cpld_version
		fi
	fi
	wifi_right_cpld_present
	if [[ $? == 1 ]]; then
		printf "    6. Wifi right CPLD image[CPLD version: 0x%X]\n" $wifi_right_cpld_version
	else
		rndc_right_cpld_present
		if [[ $? = 1 ]]; then
			printf "    6. rNDC right CPLD image[CPLD version: 0x%X]\n" $rndc_right_cpld_version
		fi
	fi
	if [[ "$remote_station" -eq "0" ]]; then
        if [[ "$rndc_right_cpld_present" -eq "1"  ||  "$rndc_left_cpld_present" -eq "1" ]]; then
            printf "    7. intel rNDC firmware update[ left Type: %s, ($rndc_left_firmware_info)]\n" $rndc_left_board_type
            printf "                                 [ right Type: %s, ($rndc_right_firmware_info)]\n" $rndc_right_board_type
        fi
    fi

	echo "    q. Exit"
	printf "\n\n\n"
	printf "    Enter your choice:"
	read choice


	case $choice in
		1 )		
		update_all
		;;
		2 )
		check_bmc_minimum_firmwares 
		update_bmc  $update_bmc_image
		if [[ $? != 0 ]]; 
		then
			echo "Upgrade Failed & Exiting"
			exit 1
		fi
		;;
		3 )
		check_bios_minimum_firmwares 
		update_bios $update_bios_image
		if [[ $? != 0 ]]; then
			echo "Upgrade Failed & Exiting"
			exit 1
		fi
		;;
		4 )
		check_cpld_minimum_firmwares 
		if [[ $? != 0 ]]; 
		then
			echo "Upgrade Failed & Exiting"
			exit 1
		fi
		if [ -z "$ipmi_option" ]; then
            update_cpld $update_cpld_image_no_reset no_reset
        else
            update_cpld $update_cpld_image_reset
        fi
		;;
		5 )
		check_left_cpld_minimum_firmwares 
		if [[ $? != 0 ]]; 
		then
			echo "Upgrade Failed & Exiting"
			exit 1
		fi
		if [[ "$wifi_left_cpld_present" -eq "1" ]]; then
			update_left_cpld $update_wifi_cpld_image
		elif [[ "$rndc_left_cpld_present" -eq "1" ]]; then
			update_left_cpld $update_rndc_cpld_image
		fi
		;;
		6 )
		check_right_cpld_minimum_firmwares 
		if [[ $? != 0 ]]; then
			echo "Upgrade Failed & Exiting"
			exit 1
		fi		
		if [[ "$wifi_right_cpld_present" -eq "1" ]]; then
			update_right_cpld $update_wifi_cpld_image
		elif [[ "$rndc_right_cpld_present" -eq "1" ]]; then
			update_right_cpld $update_rndc_cpld_image
		fi
		;;
		7 ) 
		if [[ "$remote_station" -eq "0" ]]; then
            update_rndc_firmware
        fi
        echo "Please reboot the system for the new firmware to take effect."
        ;;
		q )
		#rm -f -r *
		#rmdir ../images
		break;
		;;
	esac
	clear
done

printf "\n"

