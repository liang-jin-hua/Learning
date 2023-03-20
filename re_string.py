# 给定一个字符串 s 和一个整数 k，从字符串开头算起，每计数至 2k 个字符，就反转这 2k 字符中的前 k 个字符。
#
# 如果剩余字符少于 k 个，则将剩余字符全部反转。
# 如果剩余字符小于 2k 但大于或等于 k 个，则反转前 k 个字符，其余字符保持原样。
class Solution:
    def reverseStr(self, s: str, k: int) -> str:
        nums=list(s)
        n=len(nums)
        print(n)
        for i in range(0, n, 2 * k):
            q= i+k if i + k < n else n
            nums[i:q]=nums[i:q][::-1]
        return "".join(nums)

re=Solution()
s="1234567890a"
k=4
result=re.reverseStr(s, k)
print(result)

