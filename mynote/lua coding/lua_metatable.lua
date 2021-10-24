print("***************元表******************")
print("***************元表概念******************")
--任何表变量都可以设置元表
--任何表变量都可以是元表
--字表中一些特定操作会执行元表的中内容
print("***************设置元表******************")
t1 = {}
t2 = {}
-- 设置元表函数 
-- 参数字表 元表
setmetatable(t1,t2)
print("***************特定操作******************")
print("***************特定操作 __tostring******************")
-- 当子表要被当字符串处理时，会调用元表的__tostring方法
t4 = {
	__tostring = function ( ... )
		-- body
		return "456"
	end,
	__call = function ( a,b )
		-- body
		print(a)
		print(b)
		print("=====")
	end
}
t3 = {}
setmetatable(t3,t4)
print(t3)
print("***************特定操作 __call******************")
-- 当子表要被当函数处理时，会调用元表的__call方法
-- 且字表会默认将自己作为第一个参数传入__call
t3(1)
print("***************特定操作 运算符重载******************")
m = {
	--字表执行+ 会调用元表的__add
	__add = function ( ... )
		-- body
		return 1
	end,
	-- -
	__sub = function ( ... )
		-- body
		return 2
	end,
	-- *
	__mul = function ( ... )
		-- body
		return 3
	end,
	-- -- /
	__div = function ( ... )
		-- body
		return 4
	end,
	-- -- %
	__mod = function ( ... )
		-- body
		return 5
	end,
	-- -- ^
	__pow = function ( ... )
		-- body
		return 6
	end,
	-- -- ==
	__eq = function ( ... )
		-- body
		return true
	end,
	-- <
	__lt = function ( ... )
		-- body
		return true
	end,
	-- <=
	__le = function ( ... )
		-- body
		return false
	end,
	-- ..
	__concat = function ( ... )
		-- body
		return "123"
	end
}
m1 = {}
m2 = {}
setmetatable(m1,m)
print(m1 + m2)
print(m1 - m2)
print(m1 * m2)
print(m1 / m2)
print(m1 % m2)
print(m1 ^ m2)
--条件运算符要求两个表的元表要一致
setmetatable(m2,m)
print(m1 == m2)
print(m1 < m2)
print(m1 <= m2)
print(m1 .. m2)
print("***************特定操作 __index 和 __newindex******************")
-- 当字表中找不到一个元素时，会到元表中的__index指向的表去找索引
-- 且会一致想上查找
father6 = {
	name = "123"
}
father6.__index = father6
m6 = {}
m6.__index = m6

my6 = {}
setmetatable(m6,father6)
setmetatable(my6,m6)
print(m6.name)
print(my6.name)
--rawget 找自己的变量 绕过__index
print("rawget")
print(rawget(m6,"name"))

--赋值时，如果赋值一个不存在的索引，那么会这个值付给元表中__newindex指向的表，不会修改自己
meta7 = {a = 2}
meta7.__index = meta7
-- meta7.__newindex = {}
mytable7 = {}
setmetatable(mytable7,meta7)
print("=======")
mytable7.a = 1
print(mytable7.a)
-- print(meta7.__newindex.a)

-- print(getmetatable(mytable7))

--rawset 设置自己的变量 绕过__newindex
-- rawset(mytable7,"a",100)
-- print(mytable7.a)

