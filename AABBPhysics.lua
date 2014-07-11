--Imports
local love = love
local math = math
local type = type
local table = table
local pairs = pairs
local print = print
local Class = require "Class"
local Vector2D = require "Vector2D"
local FloatCompare = require "FloatCompare"

local AABBPhysics = {}
setfenv(1, AABBPhysics)

local AABBBody = Class{}

function AABBBody:init(world, width, height)
    self.world = world
    self.width = width
    self.height = height

    self.position = Vector2D(0, 0)
    self.lastPosition = Vector2D(0, 0)

    self.speed = Vector2D(0, 0)
    self.maxSpeed = Vector2D(-1, -1)
    self.acceleration = Vector2D(0, 0)

    self.immovable = false

    self.overlapCallbackList = {}
    self.collisionCallbackList = {}
end

function AABBBody:addOverlapCallback(collisionGroup, callback)
    self.overlapCallbackList[collisionGroup] = callback
end

function AABBBody:addCollisionCallback(collisionGroup, callback)
    self.collisionCallbackList[collisionGroup] = callback
end

local function limitValue (val, limit)
    if limit >= 0 then
        if val < 0 then
            val = math.max(val, -limit)
        else
            val = math.min(val, limit)
        end
    end

    return val
end

function AABBBody:update(dt)
    self.lastPosition.x, self.lastPosition.y = self.position.x, self.position.y

    self.position.x, self.position.y = self.position.x + self.speed.x * dt + self.acceleration.x * 0.5 * dt * dt,
    self.position.y + self.speed.y * dt + self.acceleration.y * 0.5 * dt * dt

    self.speed.x, self.speed.y = limitValue(self.speed.x + self.acceleration.x * dt, self.maxSpeed.x), 
    limitValue(self.speed.y + self.acceleration.y * dt, self.maxSpeed.y)
end

function AABBBody:destroy()
    self.world:removeBody(self)
end

local AABBWorld = Class{}

local function getNewHandle(world)
    if #world.freeHandles > 0 then
        return table.remove(world.freeHandles)
    else
        local handle = world.nextHandle
        world.nextHandle = world.nextHandle + 1
        return handle
    end
end

function AABBWorld:init()
    self.nextHandle = 1
    self.freeHandles = {}
    self.bodyList = {}
    self.collisionGroups = {}
end

function AABBWorld:createBody(width, height, collisionGroup)
    local newBody = AABBBody(self, width, height)
    newBody.handle = getNewHandle(self)

    self.bodyList[newBody.handle] = newBody

    if collisionGroup then
        if not self.collisionGroups[collisionGroup] then
            self.collisionGroups[collisionGroup] = {}
        end

        self.collisionGroups[collisionGroup][newBody.handle] = newBody
        newBody.collisionGroup = collisionGroup
    end

    return newBody
end

function AABBWorld:queryBody(group, origin, radius)
    local minDistance = math.huge
    local target = nil

    if self.collisionGroups[group] then
        for _, body in pairs(self.collisionGroups[group]) do
            if minDistance > (body.position.x - origin.x) ^ 2 + (body.position.y - origin.y) ^ 2 then
                minDistance = (body.position.x - origin.x) ^ 2 + (body.position.y - origin.y) ^ 2
                if minDistance < radius ^ 2 then
                    target = body
                end
            end
        end
    end
    return target
end

function AABBWorld:raycast(origin, destiny, collisionGroup)
    -- Makes destiny relative to origin
    destiny:sub(origin)

    local len = destiny:len()

    local tMaxX = 0
    local tMaxY = 0

    if destiny.x > 0 then
        tMaxX = (32 - origin.x % 32) / math.abs(destiny.x)
    else
        tMaxX = origin.x % 32 / math.abs(destiny.x)
    end

    if destiny.y > 0 then
        tMaxY = (32 - origin.y % 32) / math.abs(destiny.y)
    else
        tMaxY = origin.y % 32 / math.abs(destiny.y)
    end

    local tDeltaX = 32 / math.abs(destiny.x)
    local tDeltaY = 32 / math.abs(destiny.y)

    local x = math.floor(origin.x / 32)
    local y = math.floor(origin.y / 32)

    local stepX = destiny.x / math.abs(destiny.x)
    local stepY = destiny.y / math.abs(destiny.y)

    while tMaxY < 1 or tMaxX < 1 do
        if tMaxX < tMaxY then
            tMaxX = tMaxX + tDeltaX
            x = x + stepX
            if self.tilemap.tiles[x + y * self.tilemap.widthInTiles + 1] > 1 then
                return (tMaxX - tDeltaX) * len
            end
        else
            tMaxY = tMaxY + tDeltaY
            y = y + stepY
            if self.tilemap.tiles[x + y * self.tilemap.widthInTiles + 1] > 1 then
                return (tMaxY - tDeltaY) * len
            end
        end
    end

    return len
end

function AABBWorld:removeBody(body)
    self.bodyList[body.handle] = nil
    self.collisionGroups[body.collisionGroup][body.handle] = nil
end

function AABBWorld:loadTilemap(tilemap, collidableTiles, wrap)
    self.tilemap = tilemap
    for i = 1, #tilemap.tiles do
        if collidableTiles[tilemap.tiles[i]] then
            local row = math.floor((i - 1) / tilemap.widthInTiles)
            local col = (i - 1) % tilemap.widthInTiles

            local body = self:createBody(tilemap.tileWidth, tilemap.tileHeight, "tilemap")
            body.position.x = col * tilemap.tileWidth
            body.position.y = row * tilemap.tileHeight
            body.immovable = true
        end
    end

    if wrap then
        for i = 0, tilemap.widthInTiles - 1 do
            local body = self:createBody(tilemap.tileWidth, tilemap.tileHeight, "tilemap")
            body.position.x = i * tilemap.tileWidth
            body.position.y = -tilemap.tileHeight

            body = self:createBody(tilemap.tileWidth, tilemap.tileHeight, "tilemap")
            body.position.x = i * tilemap.tileWidth
            body.position.y = 1080
        end

        for i = 0, tilemap.heightInTiles - 1 do
            local body = self:createBody(tilemap.tileWidth, tilemap.tileHeight, "tilemap")
            body.position.x = -tilemap.tileWidth
            body.position.y = i * tilemap.tileHeight

            body = self:createBody(tilemap.tileWidth, tilemap.tileHeight, "tilemap")
            body.position.x = tilemap.widthInTiles * tilemap.tileWidth
            body.position.y = i * tilemap.tileHeight
        end

    end
end

function AABBWorld:update(dt)
    for handle, body in pairs(self.bodyList) do
        body:update(dt)
    end
end

function AABBWorld:draw()
    for handle, body in pairs(self.bodyList) do
        love.graphics.reset()
        if not body.debug then
            love.graphics.setColor(0, 255, 0, 255)
        else
            love.graphics.setColor(255, 0, 0, 255)
            body.debug = false
        end
        love.graphics.rectangle("line", body.position.x, body.position.y, body.width, body.height)
    end
end

local fc = FloatCompare()

local function overlapHitboxes (h1, h2)
    if fc.lt(h1.position.x, h2.position.x + h2.width) and fc.gt(h1.position.x + h1.width, h2.position.x) and
        fc.lt(h1.position.y, h2.position.y + h2.height) and fc.gt(h1.position.y + h1.height, h2.position.y) then

        if h1.overlapCallbackList[h2.collisionGroup] then h1.overlapCallbackList[h2.collisionGroup](h1, h2) end

        if h2.overlapCallbackList[h1.collisionGroup] then h2.overlapCallbackList[h1.collisionGroup](h2, h1) end

        return true
    else
        return false
    end
end

function AABBWorld:overlap (h1, h2)
    if type(h1) == "string" then
        if self.collisionGroups[h1] then
            for _, hitbox in pairs(self.collisionGroups[h1]) do
                self:overlap(hitbox, h2)
            end
        end
    elseif type(h2) == "string" then
        if self.collisionGroups[h2] then
            for _, hitbox in pairs(self.collisionGroups[h2]) do
                overlapHitboxes(h1, hitbox)
            end
        end
    else
        overlapHitboxes(h1, h2)
    end
end

local delta = Vector2D(0, 0)
local entry = Vector2D(0, 0)
local entryDistance = Vector2D(0, 0)

local function collideHitboxes (h1, h2)
    if overlapHitboxes(h1, h2) then
        delta.x = (h1.position.x - h1.lastPosition.x) - (h2.position.x - h2.lastPosition.x)
        delta.y = (h1.position.y - h1.lastPosition.y) - (h2.position.y - h2.lastPosition.y)

        if not fc.eq(delta.x, 0) then
            if fc.gt(delta.x, 0) then
                entryDistance.x = h2.lastPosition.x - h1.lastPosition.x - h1.width
            elseif fc.lt(delta.x, 0) then
                entryDistance.x = h2.lastPosition.x + h2.width - h1.lastPosition.x
            end

            entry.x = entryDistance.x / delta.x
        else
            entry.x = -math.huge
        end

        if not fc.eq(delta.y, 0) then
            if fc.gt(delta.y, 0) then
                entryDistance.y = h2.lastPosition.y - h1.lastPosition.y - h1.height
            elseif fc.lt(delta.y, 0) then
                entryDistance.y = h2.lastPosition.y + h2.height - h1.lastPosition.y
            end

            entry.y = entryDistance.y / delta.y
        else
            entry.y = -math.huge
        end

        local entryTime = math.max(entry.x, entry.y)

        if fc.ge(entryTime, 0) and fc.le(entryTime, 1) then 
            h1.position.x = h1.lastPosition.x + (h1.position.x - h1.lastPosition.x) * entryTime
            h1.position.y = h1.lastPosition.y + (h1.position.y - h1.lastPosition.y) * entryTime

            h2.position.x = h2.lastPosition.x + (h2.position.x - h2.lastPosition.x) * entryTime
            h2.position.y = h2.lastPosition.y + (h2.position.y - h2.lastPosition.y) * entryTime

            if fc.eq(entryTime, entry.x) then
                h1.speed.x = 0
                h2.speed.x = 0
            else
                h1.speed.y = 0
                h2.speed.y = 0
            end

            if h1.collisionCallbackList[h2.collisionGroup] then h1.collisionCallbackList[h2.collisionGroup](h1, h2) end
            if h2.collisionCallbackList[h1.collisionGroup] then h2.collisionCallbackList[h1.collisionGroup](h2, h1) end
        end
    end
end

function AABBWorld:collide (h1, h2)
    if type(h1) == "string" then
        if self.collisionGroups[h1] then
            for _, hitbox in pairs(self.collisionGroups[h1]) do
                self:collide(hitbox, h2)
            end
        end
    elseif type(h2) == "string" then
        if self.collisionGroups[h2] then
            for _, hitbox in pairs(self.collisionGroups[h2]) do
                collideHitboxes(h1, hitbox)
            end
        end
    else
        collideHitboxes(h1, h2)
    end
end

function createWorld ()
    return AABBWorld()
end

return AABBPhysics
