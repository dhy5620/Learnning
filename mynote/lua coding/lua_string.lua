print("*********字符串*********")
str = "abcDefG"
print(#str)
-- 英文1 中文3
str2 = "电话"
print(#str2)
-- 多行打印
s = "123\n123"
print(s)
s = [[我
123
123
]]
print(s)
-- 字符串拼接 ..
s = "1" .. "4"
--print(s)
-- %d 数字 %s 字符 &a 任意字符
print(string.format("我是%s","aaa"))
-- 转字符串
-- tostring(s)
-- 常用函数
str = "abcDefG"
print(string.upper(str));
print(string.lower(str));
print(string.reverse(str));
print(string.find(str,"cD"));
print(string.sub(str, 3));
print(string.rep(str, 2));
print(string.gsub(str, "c","1"));

-- 字符转ASCII码
a = string.byte("Lua",1)
print(a)
-- ASCII码转字符
print(string.char(a))