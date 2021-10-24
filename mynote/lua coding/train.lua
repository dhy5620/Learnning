Object = {}

function Object:new()
    local obj = {};
    self.__index = self;
    setmetatable(obj, self);
    return obj;
end


function Object:subClass(className)
    _G[className] = {};
    local obj = _G[className];
    self.__index = self;
    obj.base = self;
    setmetatable(obj, self);
end

Object:subClass("Gameobject");

Gameobject.x = 0;

Gameobject.y = 0;

function Gameobject:Move()
    
    self.x = self.x + 1;
    
    self.y = self.y + 1;
    
    print(self.x, self.y)
    
end

Gameobject:subClass("Person");

function Person:Move(...) self.base.Move(self); end

local p = Person:new();

local p2 = Person:new();

p:Move();

p2:Move();

p:Move();

