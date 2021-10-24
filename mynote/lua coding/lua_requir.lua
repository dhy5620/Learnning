print("***************多脚本执行******************")
print("***************全局变量和本地变量******************")
--本地变量关键字 local
print("***************多脚本执行******************")
print(T1)
require("TestA")
print(T1)
print(T2)
print("***************脚本卸载******************")
--require加载之后不会重复加载
--package.loaded["TestA"] 返回是否被加载
print(package.loaded["TestA"]);
package.loaded["TestA"] = nil
print(package.loaded["TestA"]);
print("***************大G表******************")
-- _G 总表
for k,v in pairs(_G) do
	print(k,v)
end

local t = require("TestA")
print(t)
	