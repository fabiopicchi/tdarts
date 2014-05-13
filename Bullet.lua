-- Import
local math = math
local love = love
local Class = require "Class"
local GameObject = require "GameObject"

local Bullet = Class({}, GameObject)
setfenv(1, Bullet)

local SPEED = 500

function Bullet:init(x, y, angle, body)
    GameObject.init(self, x, y)
    
    self.body = body
    self.body.position.x = x
    self.body.position.y = y
    self.body.speed.x = SPEED * math.cos(angle)
    self.body.speed.y = SPEED * math.sin(angle)

    self.width = 10
    self.height = 10

    self.body:addCollisionCallback("tilemap", function (a, b)
        a:destroy()
        self.parentContext:removeObject(self)
    end)
end

function Bullet:draw()
    love.graphics.reset()
    love.graphics.setColor(255, 255, 0, 255)
    love.graphics.circle("fill", self.body.position.x + self.width / 2, self.body.position.y + self.height / 2, self.width / 2, self.width)
end

return Bullet
