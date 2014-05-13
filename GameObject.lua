-- Import
local Class = require "Class"

local GameObject = Class{
    x = 0,
    y = 0,
    width = 0,
    height = 0,
    handle = 0,
    bucket = 0
}
setfenv(1, GameObject)

function GameObject:init(x, y)
    self.x = x
    self.y = y
end

function GameObject:preUpdate(dt)

end

function GameObject:update(dt)

end

function GameObject:postUpdate(dt)

end

function GameObject:draw()

end

return GameObject
