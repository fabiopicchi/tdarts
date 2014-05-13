-- Import
local Class = require "Class"
local error = error

local RingBuffer = Class{
    head = 0,
    bufferSize = 0,
    buffer = {}
}
setfenv(1, RingBuffer)

function RingBuffer:init(size)
    self.bufferSize = size
end

function RingBuffer:size()
    return self.bufferSize
end

function RingBuffer:elementCount()
    return #self.buffer
end

function RingBuffer:isFull()
    return self.bufferSize == #self.buffer
end

function RingBuffer:getElement(index)
    if index > self:elementCount() or index <= 0 then
        error("Index out of bounds")
    end

    local absoluteIndex = ((self.head - 1) + (index - 1) - (self:elementCount() - 1)) % self.bufferSize + 1
    return self.buffer[absoluteIndex]
end

function RingBuffer:insertElement(e)
    self.head = (self.head % self.bufferSize) + 1
    self.buffer[self.head] = e
end

function RingBuffer:headElement()
    return self.buffer[self.head]
end

function reverseIterator(cB, range)
    local i = cB:elementCount()
    if range == nil then
        range = i
    end

    return function()
        if i >= cB:elementCount() - range then
            i = i - 1
            return i + 1, cB:getElement(i + 1)
        end
    end
end

return RingBuffer
