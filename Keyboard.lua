-- Import
local math = math
local pairs = pairs
local string = string
local Class = require "Class"
local RingBuffer = require "RingBuffer"

local Keyboard = Class{
    bufferSize = 0,
    inputBuffer = nil
}
setfenv(1, Keyboard)

local keys = {
    up = "up",
    down = "down",
    left = "left",
    right = "right",
    z = "z",
    x = "x"
}

-- Key state data structure
local KeyState = Class{pressed = false}

-- Keyboard state data structure -- keeps track of every key in the keyboard
local KeyboardState = Class{}

function KeyboardState:init()
    for key, value in pairs(keys) do
        self[value] = KeyState()
    end
end

function Keyboard:init(bufferSize)
    self.inputBuffer = RingBuffer(bufferSize)
    self.inputBuffer:insertElement(KeyboardState())
    self.inputBuffer:insertElement(KeyboardState())
end

function Keyboard:update()
    self.inputBuffer:insertElement(self.inputBuffer:headElement():clone())
end

function Keyboard:updateKey(key, keyState)
    if keys[key] then 
        self.inputBuffer:headElement()[key].pressed = keyState
    end
end

function Keyboard:keyPressed(key, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 1 then frameTolerance = self.inputBuffer:size() - 1 end    

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if state[key].pressed then
            return true
        end
    end
    return false
end

function Keyboard:keyJustPressed(key, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end    

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if state[key].pressed and not self.inputBuffer:getElement(i - 1)[key].pressed then
            return true
        end
    end
    return false
end

function Keyboard:keyJustReleased(key, frameTolerance)
    if not frameTolerance then frameTolerance = 0
    elseif frameTolerance > self.inputBuffer:size() - 2 then frameTolerance = self.inputBuffer:size() - 2 end

    for i, state in RingBuffer.reverseIterator(self.inputBuffer, frameTolerance) do
        if not state[key].pressed and self.inputBuffer:getElement(i - 1)[key].pressed then
            return true
        end
    end
    return false
end

return Keyboard
