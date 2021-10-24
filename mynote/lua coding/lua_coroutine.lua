print("***************协同程序******************")
print("***************创建******************")
fun = function ( )
print(123)
end

co = coroutine.create(fun)
co2 = coroutine.wrap(fun)
print(co)
print(type(co))
print(co2)
print(type(co2))
print("***************运行******************")
coroutine.resume(co)
co2()
print("***************挂起******************")
fun2 = function ( ... )
	while true do
		print("===")
		coroutine.yield(1)
	end
end

co3 = coroutine.create(fun2)
-- 第一个返回参数默认是携程是否创建成功
coroutine.resume(co3)
coroutine.resume(co3)
i,k = coroutine.resume(co3)
print(i,k)
co4 = coroutine.wrap(fun2)
print("return"..co4())

print("***************状态******************")
print(coroutine.status(co3))
print(coroutine.running())



