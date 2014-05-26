--Import
local love = love
local math = math
local Class = require "Class"
local Timer = require "Timer"
local Vector2D = require "Vector2D"
local GameObject = require "GameObject"
local FlagManager = require "FlagManager"

local Sentry = Class({}, GameObject)
setfenv(1, Sentry)

local SHOT_COOLDOWN = 0.1
local PERCENTAGE_BUILT_PER_SECOND = 0.5
local LASER_SIGHT_SPEED = math.pi / 6
local SHOT_RADIUS = 200

function Sentry:init(x, y, body)
    GameObject.init(self, x, y)

    self.laserSightAngle = 0
    self.laserSightRadius = SHOT_RADIUS

    self.body = body
    self.body.position.x = x
    self.body.position.y = y

    self.body:addOverlapCallback("playerInfluence", function (a, b)
        if b.active then
            self.updateBuild = true
        end
    end)

    self.width = self.body.width
    self.height = self.body.height
    self.percentageBuilt = 0

    self.timer = Timer()
    self.flagManager = FlagManager()
    self.flagManager:addFlag("SHOT_COOLDOWN")
    self.flagManager:addFlag("BUILDING")

    self.flagManager:setFlag("BUILDING")
end

function Sentry:update(dt)
    self.timer:update(dt)
    self.flagManager:update(dt)

    if self.updateBuild then
        self.percentageBuilt = self.percentageBuilt + PERCENTAGE_BUILT_PER_SECOND * dt
        self.updateBuild = false
        if self.percentageBuilt >= 1 then
            self.flagManager:resetFlag("BUILDING")
        end
    end

    if not self.flagManager:isFlagSet("BUILDING") then
        if not self.target then
            self.laserSightAngle = self.laserSightAngle + LASER_SIGHT_SPEED * dt
        else
            self.laserSightAngle = math.atan2(self.target.position.y - self.body.position.y,
            self.target.position.x - self.body.position.x)
            
            if not self.flagManager:isFlagSet("SHOT_COOLDOWN") then
                self.parentContext:addBullet(self.body.position.x + self.body.width / 2, self.body.position.y + self.body.height / 2, self.laserSightAngle)
                self.flagManager:setFlag("SHOT_COOLDOWN")
                self.timer:start(SHOT_COOLDOWN, function ()
                    self.flagManager:resetFlag("SHOT_COOLDOWN")
                end)
            end
        end

        self.laserSightRadius = math.min(SHOT_RADIUS, self.parentContext:raycast(
            Vector2D(self.body.position.x + self.body.width / 2, self.body.position.y + self.body.height / 2),
            Vector2D(self.body.position.x + self.body.width / 2 + math.cos(self.laserSightAngle) * SHOT_RADIUS,
                self.body.position.y + self.body.height / 2 + math.sin(self.laserSightAngle) * SHOT_RADIUS),
            "tilemap"))
    end
end

function Sentry:postUpdate(dt)
    if not self.flagManager:isFlagSet("BUILDING") then
        self.target = self.parentContext:queryAABBRadius("enemy", self.body.position, SHOT_RADIUS)
    end
end

function Sentry:draw()
    love.graphics.reset()
    if self.flagManager:isFlagSet("BUILDING") then
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.rectangle("fill", self.body.position.x, self.body.position.y - 10, self.percentageBuilt * self.body.width, 10)

        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("line", self.body.position.x, self.body.position.y - 10, self.body.width, 10)

        love.graphics.setColor(0, 255, 0, 255)
    else
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.line(self.body.position.x + self.body.width / 2, self.body.position.y + self.body.height / 2, self.body.position.x + self.body.width / 2 + math.cos(self.laserSightAngle) * self.laserSightRadius, self.body.position.y + self.body.height / 2 + math.sin(self.laserSightAngle) * self.laserSightRadius)
        love.graphics.setColor(0, 0, 255, 255)
    end
    love.graphics.rectangle("fill", self.body.position.x, self.body.position.y, self.width, self.height)
end

return Sentry
