-- Import
local Gamepad = require "Gamepad"
local Keyboard = require "Keyboard"
local Constants = require "Constants"
local StageContext = require "StageContext"

local gamepads = {}
setmetatable (gamepads, {
    __index = {
        update = function (self, dt)
            for _, gamepad in pairs(self) do
                gamepad:update(dt)
            end
        end
    }
})

local currentContext = nil
local keyboard = nil

function love.load()
    -- Screen size
    love.window.setMode(Constants.screenWidth, Constants.screenHeight)
    
    -- Keyboard initialization
    love.keyboard.setKeyRepeat(false)
    keyboard = Keyboard(20)

    for i, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then
            table.insert(gamepads, Gamepad(20, joystick:getID()))
        end
    end

    currentContext = StageContext(gamepads, keyboard, "map")
end

function love.update(dt)
    currentContext:update(dt)
    gamepads:update(dt) 
    keyboard:update(dt)
end

function love.draw()
    currentContext:draw()
end

function love.keypressed(key)
    keyboard:updateKey(key, true)
end

function love.keyreleased(key)
    keyboard:updateKey(key, false)
end

function love.joystickadded(joystick)
    if joystick:isGamepad() then
        table.insert(gamepads, Gamepad(20, joystick:getID()))
    end
end

function love.joystickremoved(joystick)
    if joystick:isGamepad() then
        for i, gamepad in ipairs(gamepads) do
            if joystick:getID() == gamepad.id then
                table.remove(gamepads, i)
            end
        end
    end
end

function love.gamepadpressed(joystick, button)
    for _, gamepad in pairs(gamepads) do
        if joystick:getID() == gamepad.id then
            gamepad:updateButton(button, true)
        end
    end
end

function love.gamepadreleased(joystick, button)
    for _, gamepad in pairs(gamepads) do
        if joystick:getID() == gamepad.id then
            gamepad:updateButton(button, false)
        end
    end
end

function love.gamepadaxis(joystick, axis)
    for _, gamepad in pairs(gamepads) do
        if joystick:getID() == gamepad.id then
            gamepad:updateAxis(axis, joystick:getGamepadAxis(axis))
        end
    end
end
