-- Import
local math = math
local ipairs = ipairs
local Class = require "Class"
local RingBuffer = require "RingBuffer"

local Gamepad = Class{
    id = -1,
    bufferSize = 0,
    inputBuffer = nil
}
setfenv(1, Gamepad)

local gamepadButtons = {
    "a",
    "b",
    "x",
    "y",
    "rightshoulder",
    "leftshoulder",
    "rightstick",
    "leftstick",
    "back",
    "guide",
    "start",
    "dpup",
    "dpdown",
    "dpright",
    "dpleft"
}

local gamepadAxes = {
    "leftx",
    "lefty",
    "rightx",
    "righty",
    "triggerleft",
    "triggerright"
}

-- Button state data structure
local ButtonState = Class{pressed = false}

-- Axis state data structure
local AxisState = Class{value = 0}

-- Gamepad state data structure
local GamepadState = Class{}

function GamepadState:init()
    for i, value in ipairs(gamepadButtons) do
        self[value] = ButtonState()
    end

    for i, value in ipairs(gamepadAxes) do
        self[value] = AxisState()
    end
end

function Gamepad:init(bufferSize, id)
    self.id = id
    self.inputBuffer = RingBuffer(bufferSize)
    self.inputBuffer:insertElement(GamepadState())
    self.inputBuffer:insertElement(GamepadState())
end

function Gamepad:update()
    self.inputBuffer:insertElement(self.inputBuffer:headElement():clone())
end

function Gamepad:updateButton(button, buttonState)
    self.inputBuffer:headElement()[button].pressed = buttonState
end

function Gamepad:updateAxis(axis, axisValue)
    self.inputBuffer:headElement()[axis].value = axisValue
end

local function axisGT(a, b)
    if math.abs(a) >= math.abs(b) and a * b >= 0 then
        return true
    end
    return false
end

function Gamepad:axis(axis)
    return self.inputBuffer:headElement()[axis].value
end

function Gamepad:axisMoved(axis, axisValue, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 1 then frameTolerance = self.inputBuffer:size() - 1 end    

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if axisGT (state[axis].value, axisValue) then
            return true
        end
    end
    return false
end

function Gamepad:axisJustMoved(axis, axisValue, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if axisGT(state[axis].value, axisValue) and not axisGT(self.inputBuffer:getElement(i - 1)[axis].value, axisValue) then
            return true
        end
    end
    return false
end

function Gamepad:axisJustReleased(axis, axisValue, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if not axisGT(state[axis].value, axisValue) and axisGT(self.inputBuffer:getElement(i - 1)[axis].value, axisValue) then
            return true
        end
    end
    return false
end

function Gamepad:buttonPressed(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 1 then frameTolerance = self.inputBuffer:size() - 1 end    

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if state[button].pressed then
            return true
        end
    end
    return false
end

function Gamepad:buttonJustPressed(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end    

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if state[button].pressed and not self.inputBuffer:getElement(i - 1)[button].pressed then
            return true
        end
    end
    return false
end

function Gamepad:buttonJustReleased(button, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if not state[button].pressed and self.inputBuffer:getElement(i - 1)[button].pressed then
            return true
        end
    end
    return false
end

return Gamepad
