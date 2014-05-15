-- Import
local love = love
local math = math
local Class = require "Class"
local Timer = require "Timer"
local GameObject = require "GameObject"
local FlagManager = require "FlagManager"

local Enemy = Class({}, GameObject)
setfenv(1, Enemy)

local ENEMY_SPEED = 20
local ENEMY_HEALTH = 20
local DAMAGE_COOLDOWN = 0.1

local function getDirection(position, nextPosition)
    local dx = (nextPosition.x - position.x)
    local dy = (nextPosition.y - position.y)
    local ret = {}

    if dx == 0 then
        ret.x = 0
    elseif dx > 0 then
        ret.x = ENEMY_SPEED
    else
        ret.x = -ENEMY_SPEED
    end

    if dy == 0 then
        ret.y = 0
    elseif dy > 0 then
        ret.y = ENEMY_SPEED
    else
        ret.y = -ENEMY_SPEED
    end

    return ret
end

function Enemy:init(path, body)
    self.body = body
    self.height = self.body.height
    self.width = self.body.width
    self.path = path

    self.body.x = self.path[1].x
    self.body.y = self.path[1].y

    self.currentIndex = 1
    self.nextPosition = self.path[1]

    self.health = ENEMY_HEALTH

    self.flagManager = FlagManager()
    self.flagManager:addFlag("TAKING_DAMAGE")

    self.timer = Timer()

    self.body:addOverlapCallback("bullet", function (a, b)
        self.health = self.health - 1

        if self.health <= 0 then
            a:destroy()
            self.parentContext:removeObject(self)
        else
            if self.flagManager:isFlagSet("TAKING_DAMAGE") then
                self.timer:clear(self.damageTimer)
            end

            self.flagManager:setFlag("TAKING_DAMAGE")
            self.damageTimer = self.timer:start(DAMAGE_COOLDOWN, function ()
                self.flagManager:resetFlag("TAKING_DAMAGE")
            end)
        end
    end)
end

function Enemy:update(dt)
    self.timer:update(dt)
    self.flagManager:update(dt)
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

        self.body.speed = getDirection(self.body.position, self.nextPosition)
    end
end

function Enemy:draw()
    love.graphics.reset()
    if self.flagManager:isFlagSet("TAKING_DAMAGE") then
        love.graphics.setColor(255, 255, 0, 255)
    else
        love.graphics.setColor(255, 0, 255, 255)
    end

    love.graphics.rectangle("fill", self.body.position.x, self.body.position.y, self.width, self.height)
end

return Enemy
