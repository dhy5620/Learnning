print("***************复杂数据类型 表******************")
print("***************数组******************")
a = {}
a = {1,2,3,4,"124",nil}
-- lua中索引从1开始
print(a[1])
-- #通用的获取长度的关键字
-- nil之后会被忽略
print(#a)
print("***************数组遍历******************")
for i = 1,#a do
	print(a[i])
end

print("***************二维数组******************")
print("***************二维数组遍历******************")
a = {{1,2,3},{4,5,6}}
for i = 1,#a do
	for j=1,#a[i] do
		print(a[i][j])
	end
end
print("***************自定义数组******************")
aa = {[1] = 1,[2] = 2,[5]=5}
print(#aa)
print(table.maxn(aa))
print(aa[1])
print(aa.a)
for i = 1,#aa do
	print(aa[i])
end

print("***************迭代器遍历******************")
-- 迭代器遍历 遍历表
-- #得到的长度不准确 不方便遍历表
a = {[0]=1,2,3,[-1]=4,5,[5]=5}
--ipairs
--只能找到连续索引的键值 如果断续无法遍历
for i,k in ipairs(a) do
	print("ipairs键值对"..i.."_"..k)
end
-- pairs
-- 能找到所有的键值对
for i,k in pairs(a) do
	print("pairs键值对"..i.."_"..k)
end
local aTb = {"One", "Two", "Three"} for i, v in ipairs(aTb) do     print(i, v) end






