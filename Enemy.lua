-- Import
local love = love
local math = math
local Class = require "Class"
local GameObject = require "GameObject"

local Enemy = Class({}, GameObject)
setfenv(1, Enemy)

local ENEMY_SPEED = 100

function Enemy:init(path, body)
    self.body = body
    self.height = self.body.height
    self.width = self.body.width
    self.path = path

    self.body.x = self.path[1].x
    self.body.y = self.path[1].y

    self.currentIndex = 1
    self.nextPosition = self.path[1]
end

function Enemy:update(dt)

end

function Enemy:postUpdate(dt)
    if (self.nextPosition.x - self.body.position.x) * self.body.speed.x <= 0 and
        (self.nextPosition.y - self.body.position.y) * self.body.speed.y <= 0 then
        
        self.body.position.x = self.nextPosition.x
        self.body.position.y = self.nextPosition.y

        if self.currentIndex < #self.path then
            self.currentIndex = self.currentIndex + 1
            self.nextPosition = self.path[self.currentIndex]
        end

        local dx = (self.nextPosition.x - self.body.position.x)
        local dy = (self.nextPosition.y - self.body.position.y)
        
        if dx == 0 then
            self.body.speed.x = 0
        elseif dx > 0 then
            self.body.speed.x = ENEMY_SPEED
        else
            self.body.speed.x = -ENEMY_SPEED
        end
        
        if dy == 0 then
            self.body.speed.y = 0
        elseif dy > 0 then
            self.body.speed.y = ENEMY_SPEED
        else
            self.body.speed.y = -ENEMY_SPEED
        end
    end
end

function Enemy:draw()
    love.graphics.reset()
    love.graphics.setColor(255, 0, 255, 255)
    love.graphics.rectangle("fill", self.body.position.x, self.body.position.y, self.width, self.height)
end

return Enemy
