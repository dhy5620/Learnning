print("***************字典******************")
print("***************字典声明******************")
a = {["name"] = "123", ["age"] = 14, ["1"] = 1}
print(a.name)
-- 可以通过类似成员变量获取值，但不能是数字
print(a["1"])
-- 修改
a.name = "456"
print(a.name)
print(a["name"])
-- 新增
a.sex = false
print(a.sex)
-- 删除
a.sex = nil
print(a.sex)
print("***************字典遍历******************")
for i, k in pairs(a) do print(i, k) end
for i in pairs(a) do
    print(i)
    print(a[i])
end
print("***************类和结构体******************")
-- lua 中没有面向对象 需要自己是想
-- 用表来实现成员函数 成员变量
student = {
    -- 年龄
    age = 1,
    -- 函数
    up = function()
        -- 与表中的age无关 它是一个全局变量
        print(age)
        print(student.age + 1)
        print(student.age + 1)
    end,
    learn = function(t)
        -- body 将自己传入
        print("学习")
    end

}
-- c# new 实例化对象 静态直接点
-- lua 一个类中有很多静态变量和函数
print(student.age)
student.up()
print(student.up)
-- 在表外声明变量和方法
student.name = "dd"
print(student.name)
-- 
student.learn(student)
student:learn()
student.speak = function(...)
    -- body
    print("说话")
end
function student:speak2(...)
    -- lua中默认第一个传入的参数是self
    -- body
    print(self.name .. "说话2")
end
-- lua中. 和:的区别
-- .正常调用
-- : 将自己作为第一个参数传入
student.speak()
student.speak2(student)
student:speak2()
print("***************表公共操作******************")
t1 = {{age = 1}, {age = 2}}
print(#t1)
t2 = {name = "dd"}
table.insert(t1, 1, t2)
print(#t1)
print(t1[1].name)
table.remove(t1)
print(#t1)

t3 = {1, 4, 2, 6, 3, 1, 7}
table.sort(t3, function(a, b) if a > b then return true end end)
for i, k in pairs(t3) do print(k) end

s = table.concat(t3, ", ", 1, 3)
print(s)

