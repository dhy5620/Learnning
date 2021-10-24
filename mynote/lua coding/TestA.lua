require("BaseClass")
local T = {}
function T:F1()
   print(self)
   return 2;
end
local T1 = T.F1();
print(T1);
-- for _k, _v in pairs(T1) do
--     print(_k, _v)
-- end

print("====")
local A = {}
local B = {}
B.__index = {a = 1}
B.__newindex = {b = 4}
setmetatable(A, B);
print(A.a)
A.a = 2;
print(A.a)
print(B.__index.a)
print(B.__newindex.a)
print("====")
print(A.b)
A.b = 3;
print(A.b)
print(B.__index.b)
print(B.__newindex.b)
