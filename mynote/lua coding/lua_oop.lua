Object = {}
function Object:new()
	local obj = {}
	self.__index = self;
	setmetatable(obj,self)
	return obj
end
function Object:subClass(className)
	-- body
	_G[className] = {}
	local obj = _G[className]
	self.__index = self;
	obj.base = self;
	setmetatable(obj,self)
end

Object:subClass("Gameobject")
Gameobject.x = 0;
Gameobject.y = 0;
function Gameobject:Move()
	-- body
	self.x = self.x +1;
	self.y = self.y+1;
	print(self.x,self.y)
end

Gameobject:subClass("Person")
function Person:Move( ... )
	-- body
	self.base.Move(self)
end

local g1 = Gameobject:new()
local g2 = Gameobject:new()
g1:Move()
g2:Move()
g1:Move()


local p1 = Person:new()
local p2 = Person:new()
p1:Move()
p2:Move()

print(collectgarbage("count"))
collectgarbage("collect")
print(collectgarbage("count"))




