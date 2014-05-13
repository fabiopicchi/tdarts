-- Import
local Class = require "Class"
local pairs = pairs

local FlagManager = Class{}
setfenv (1, FlagManager)

local Flag = Class{
    set = false
}

function FlagManager:init()
    self.flagList = {}
end

function FlagManager:addFlag(id, update, onEnter, onLeave)
    if id then
        flag = Flag()
        flag.update = update
        flag.onEnter = onEnter
        flag.onLeave = onLeave
        self.flagList[id] = flag
    end
end

function FlagManager:setFlag(id, ...)
    if not self.flagList[id].set then
        self.flagList[id].set = true

        if self.flagList[id].onEnter then
            self.flagList[id].onEnter(...)
        end
    end
end

function FlagManager:resetFlag(id, ...)
    if self.flagList[id].set then
        self.flagList[id].set = false

        if self.flagList[id].onLeave then
            self.flagList[id].onLeave(...)
        end
    end
end

function FlagManager:isFlagSet(id)
    return self.flagList[id].set
end

function FlagManager:areFlagsSet(table)
    for i = 1, #table do
        if not self:isFlagSet(table[i]) then
            return false
        end
    end
    return true
end

function FlagManager:isOneFlagSet(table)
    for i = 1, #table do
        if self:isFlagSet(table[i]) then
            return true
        end
    end
    return false
end

function FlagManager:update(dt)
    for id, flag in pairs(self.flagList) do
        if flag.update and flag.set then 
            flag.update(dt) 
        end
    end
end

return FlagManager
