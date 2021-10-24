print("***************函数******************")
-- function function_name( ... )
-- 	-- body
-- end
-- a = function()
-- 	-- body
-- end
print("***************无参数无返回函数******************")
function F1( ... )
	print("F1")
end
F1()
F2 = function ( ... )
	print("F2")
end
F2()

print("***************有参数函数******************")
function F3(a)
	print(a)
end
F3(A)
F3(1,2,3)
-- 如果传入参数不匹配 不会报错 自动补空nil

print("***************有返回函数******************")
function F4(a)
	return a,"123",true
end
temp = F4("123")
temp,temp2,temp3 = F4("A")
print(temp)
print(temp2)
print(temp3)

print("***************函数类型******************")
F5 = function()
print("123")
end
print(type(F5))

print("***************函数重载******************")
-- 不支持重载
-- 调用最后一个同名函数 就是函数被覆盖了

print("***************变长参数******************")
function F7( ... )
	arg = {...}
	for i=1,#arg do
		print(arg[i])
	end
end
F7(1,"123",a)
print("***************函数嵌套******************")
function F8( ... )
	F9 = function( ... )
		print("===")
	end
	return F9
end
f9 = F8()
f9()

-- 闭包
function F9( a )
	-- 改变传入参数的生命周期
	return function ( b )
	 	return a+b
	end
end

f10 = F9(1)
print(f10(2))

function newCounter()     
	local i = 0     
	return function () -- 匿名函数          
		i = i + 1          
		return i    
 	end 
end 
c1 = newCounter() 
print(c1())  
print(c1())