--Import
local pairs = pairs
local math = math
local table = table
local Class = require "Class"

local Timer = {}
setfenv (1, Timer)

local Event = Class{
    elapsed = 0,
    duration = 0,
    callback = nil
}

Timer = Class{
    nextHandle = 1
}

function Timer:getNewHandle()
    if #self.freeHandles > 0 then
        return table.remove(self.freeHandles)
    else
        local handle = self.nextHandle
        self.nextHandle = self.nextHandle + 1
        return handle
    end
end

function Timer:init()
    self.eventList = {}
    self.TimerId = 1
    self.freeHandles = {}
end

function Timer:start(frameDuration, callback)
    local e = Event()
    e.frameDuration = frameDuration
    e.callback = callback
    e.handle = self:getNewHandle()

    self.eventList[e.handle] = e

    return e.handle
end

function Timer:clear(handle)
    if self.eventList[handle] then
        table.insert(self.freeHandles, handle)
        self.eventList[handle] = nil
    end
end

function Timer:update(dt)
    for handle, event in pairs(self.eventList) do
        if event.elapsed >= event.frameDuration then
            event.callback()
            self:clear(handle)
        end

        event.elapsed = event.elapsed + dt
    end
end

return Timer
