-- Import
local love = love
local math = math
local print = print
local Class = require "Class"
local Timer = require "Timer"
local GameObject = require "GameObject"
local FlagManager = require "FlagManager"

local Player = Class({}, GameObject)
setfenv(1, Player)

local SHOT_COOLDOWN = 0.1
local LEFT = {x = -1, y = 0}
local RIGHT = {x = 1, y = 0}
local DOWN = {x = 0, y = 1}
local UP = {x = 0, y = -1}
local SENTRY_COST = 100
local JUNK_EXTRACTION_PER_SECOND = 40

function Player:init(gamepad, body, influenceArea)
    body.position.x = 944
    body.position.y = 524
    GameObject.init(self, body.position.x, body.position.y)

    self.body = body

    self.influenceArea = influenceArea
    self.influenceArea.active = false
    self.influenceArea.position.x = self.body.position.x - (self.influenceArea.width - self.body.width) / 2
    self.influenceArea.position.y = self.body.position.y - (self.influenceArea.height - self.body.height) / 2

    self.width = self.body.width
    self.height = self.body.height
    self.gamepad = gamepad
    self.facing = LEFT
    self.junk = 100

    self.timer = Timer()
    self.flagManager = FlagManager()

    self.flagManager:addFlag("SHOT_COOLDOWN")

    self.junkSource = nil
    self.influenceArea:addOverlapCallback("junk", function (a, b)
        if self.influenceArea.active then
            self.junkSource = b
        end
    end)
end

function Player:update(dt)
    self.timer:update(dt)
    self.flagManager:update(dt)

    self.body.speed.x = 0
    self.body.speed.y = 0

    if self.gamepad:buttonPressed("dpright") or self.gamepad:axisMoved("leftx", 0.5) then
        self.body.speed.x = 200
        self.facing = RIGHT
    elseif self.gamepad:buttonPressed("dpleft") or self.gamepad:axisMoved("leftx", -0.5) then
        self.body.speed.x = -200
        self.facing = LEFT
    elseif self.gamepad:buttonPressed("dpdown") or self.gamepad:axisMoved("lefty", 0.5) then
        self.body.speed.y = 200
        self.facing = DOWN
    elseif self.gamepad:buttonPressed("dpup") or self.gamepad:axisMoved("lefty", -0.5) then
        self.body.speed.y = -200
        self.facing = UP
    end

    if self.gamepad:buttonJustPressed("rightshoulder") then
        if self.junk >= SENTRY_COST then
            self.junk = self.junk - SENTRY_COST
            self.parentContext:addSentry(self.body.position.x + self.facing.x * 32, 
            self.body.position.y + self.facing.y * 32)
        end
    end

    if self.gamepad:buttonPressed("leftshoulder") then
        self.influenceArea.active = true
    else
        self.influenceArea.active = false
    end
end

function Player:postUpdate(dt)
    self.influenceArea.position.x = self.body.position.x - (self.influenceArea.width - self.body.width) / 2
    self.influenceArea.position.y = self.body.position.y - (self.influenceArea.height - self.body.height) / 2

    local rightAnalogMovement = self.gamepad:axis("rightx") * self.gamepad:axis("rightx") +
    self.gamepad:axis("righty") * self.gamepad:axis("righty")

    if rightAnalogMovement >= 0.81 and not self.flagManager:isFlagSet("SHOT_COOLDOWN") then
        local rightAnalogDirection = math.atan2(self.gamepad:axis("righty"), self.gamepad:axis("rightx"))
        self.parentContext:addBullet(self.body.position.x + self.width / 2, self.body.position.y + self.height / 2, rightAnalogDirection)

        self.flagManager:setFlag("SHOT_COOLDOWN")
        self.timer:start(SHOT_COOLDOWN, function ()
            self.flagManager:resetFlag("SHOT_COOLDOWN")
        end)
    end

    if self.junkSource then
        self.junk = self.junk + JUNK_EXTRACTION_PER_SECOND * dt
    end
end

function Player:draw()
    love.graphics.reset()
    if self.junkSource then
        love.graphics.setColor(255, 255, 0, 255)
        love.graphics.rectangle("fill", self.body.position.x, self.body.position.y - 10, (self.junk % 100) / 100 * self.body.width, 10)

        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("line", self.body.position.x, self.body.position.y - 10, self.body.width, 10)
        self.junkSource = nil
    end

    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("fill", self.body.position.x, self.body.position.y, self.width, self.height)
end

return Player
