--Imports
local math = math
local Class = require "Class"

local Vector2D = Class{
    x = 0,
    y = 0
}
setfenv(1, Vector2D)

function Vector2D:init(x, y)
    self.x = x
    self.y = y
end

function Vector2D:add(v)
    self.x = self.x + v.x
    self.y = self.y + v.y
end

function Vector2D:sub(v)
    self.x = self.x - v.x
    self.y = self.y - v.y
end

function Vector2D:scale(factor)
    self.x = self.x * factor
    self.y = self.y * factor
end

function Vector2D:dot(v)
    return (self.x * v.x + self.y * v.y)
end

function Vector2D:cross(v)
    return self.x * v.y - self.y * v.x
end

function Vector2D:len()
    return math.sqrt(self:dot(self))
end

function Vector2D:angle()
    return math.atan2(self.y, self.x)
end

return Vector2D
