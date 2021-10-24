print("***************面向对象******************")
print("***************封装******************")
Object = {
	id = 1
}
function Object:Test( ... )
	-- body
	print(self)
	print("123")
end
function Object:new()
	local obj = {}
	self.__index = self
	setmetatable(obj,self)
	return obj;
end

local myobj = Object:new()
myobj.Test()
myobj.Test(myobj)
myobj:Test()
print("=======")
myobj.id = 2
print(myobj.id)

print("***************继承******************")
function Object:subClass( className )
	-- body
	_G[className] = {};
	local obj = _G[className] ;
	self.__index = self
	obj.base = self;
	setmetatable(obj,self)
end
print("person")
Object:subClass("Person")
print(Person.id)
local p1 = Person:new()
print(p1.id)

print("Monster")
Object:subClass("Monster")
local m1 = Monster:new()
m1.id = 200;
print(m1.id)
print(p1.id)

print("***************多态******************")

Object:subClass("Gameobject")
Gameobject.x = 0;
Gameobject.y = 0;
Gameobject:subClass("Player")
function Gameobject:Move()
	self.x = self.x + 1
	self.y = self.y + 1
	print(self.x,self.y)
end
function Player:Move( ... )
	-- body
	-- self.base:Move()
	-- 执行父类逻辑不要使用冒号，使用点自己传入参数
	self.base.Move(self)
end

local  p1 = Player:new()
p1:Move()
p1:Move()
local p2 = Player:new()
p2:Move()



