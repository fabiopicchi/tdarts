-- Import
local print = print
local pairs = pairs
local table = table
local Class = require "Class"

local GameContext = Class{
    nextHandle = 1,
    bucketCount = 1
}
setfenv(1, GameContext)

function GameContext:getNewHandle()
    if #self.freeHandles > 0 then
        return table.remove(self.freeHandles)
    else
        local handle = self.nextHandle
        self.nextHandle = self.nextHandle + 1
        return handle
    end
end

function GameContext:init()
    self.objectBuckets = {}
    self.objectBuckets[1] = {}
    self.objectList = {}
    self.freeHandles = {}
end

function GameContext:addObject(object, parent)
    local handle = self:getNewHandle()
    self.objectList[handle] = object
    object.handle = handle
    object.parentContext = self

    if parent then
       object.bucket = parent.bucket + 1
       self.bucketCount = self.bucketCount + 1
    else
       object.bucket = 1
    end

    if not self.objectBuckets[object.bucket] then
        self.objectBuckets[object.bucket] = {}
    end
    self.objectBuckets[object.bucket][object.handle] = object
end

function GameContext:removeObject(object)
    if object.handle > 0 then
        self.objectList[object.handle] = nil
        self.objectBuckets[object.bucket][object.handle] = nil

        table.insert(self.freeHandles, object.handle)
        object.handle = 0
        object.bucket = 0
    end
end

function GameContext:update(dt)
    for i = 1, self.bucketCount do
        self:preUpdateBucket(i, dt)
        self:updateBucket(i, dt)
        self:postUpdateBucket(i, dt)
    end
end

function GameContext:preUpdateBucket(bucket, dt)
    for _, object in pairs(self.objectBuckets[bucket]) do
        object:preUpdate(dt)
    end
end

function GameContext:updateBucket(bucket, dt)
    for _, object in pairs(self.objectBuckets[bucket]) do
        object:update(dt)
    end
end

function GameContext:postUpdateBucket(bucket, dt)
    for _, object in pairs(self.objectBuckets[bucket]) do
        object:postUpdate(dt)
    end
end

function GameContext:draw()
    for _, object in pairs(self.objectList) do
        object:draw()
    end
end

return GameContext
