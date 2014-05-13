-- Import
local love = love
local math = math
local Class = require "Class"
local Timer = require "Timer"
local GameObject = require "GameObject"
local FlagManager = require "FlagManager"

local Player = Class({}, GameObject)
setfenv(1, Player)

local SHOT_COOLDOWN = 0.1

function Player:init(gamepad, body)
    GameObject.init(self, body.x, body.y)
    
    self.body = body
    self.height = self.body.width
    self.width = self.body.height
    self.gamepad = gamepad

    self.timer = Timer()
    self.flagManager = FlagManager()

    self.flagManager:addFlag("SHOT_COOLDOWN")
end

function Player:update(dt)
    self.timer:update(dt)
    self.flagManager:update(dt)

    self.body.speed.x = 0
    self.body.speed.y = 0

    if self.gamepad:buttonPressed("dpright") or self.gamepad:axisMoved("leftx", 0.5) then
        self.body.speed.x = 200
    elseif self.gamepad:buttonPressed("dpleft") or self.gamepad:axisMoved("leftx", -0.5) then
        self.body.speed.x = -200
    elseif self.gamepad:buttonPressed("dpdown") or self.gamepad:axisMoved("lefty", 0.5) then
        self.body.speed.y = 200
    elseif self.gamepad:buttonPressed("dpup") or self.gamepad:axisMoved("lefty", -0.5) then
        self.body.speed.y = -200
    end

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
end

function Player:draw()
    love.graphics.reset()
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("fill", self.body.position.x, self.body.position.y, self.width, self.height)
end

return Player
