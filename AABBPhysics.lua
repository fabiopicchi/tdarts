--Imports
local love = love
local math = math
local type = type
local table = table
local pairs = pairs
local Class = require "Class"
local FloatCompare = require "FloatCompare"

local AABBPhysics = {}
setfenv(1, AABBPhysics)

local AABBBody = Class{}

TOP = "top"
LEFT = "left"
RIGHT = "right"
BOTTOM = "bottom"
NONE = "none"

function AABBBody:init(world, width, height)
    self.world = world
    self.width = width
    self.height = height

    self.position = {x = 0, y = 0}
    self.lastPosition = {x = 0, y = 0}

    self.speed = {x = 0, y = 0}
    self.maxSpeed = {x = -1, y = -1}
    self.acceleration = {x = 0, y = 0}

    self.immovable = false

    self.touching = NONE
    self.lastTouching = NONE

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
    self.touching, self.lastTouching = NONE, self.touching
    self.lastPosition.x, self.lastPosition.y = self.position.x, self.position.y

    self.position.x, self.position.y = self.position.x + self.speed.x * dt + self.acceleration.x * 0.5 * dt * dt,
                                        self.position.y + self.speed.y * dt + self.acceleration.y * 0.5 * dt * dt

    self.speed.x, self.speed.y = limitValue(self.speed.x + self.acceleration.x * dt, self.maxSpeed.x), 
                                    limitValue(self.speed.y + self.acceleration.y * dt, self.maxSpeed.y)
end

function AABBBody:isTouching(dir)
    if dir == NONE and self.touching == NONE or string.find(self.touching, dir) then return true
    else return false
    end
end

function AABBBody:wasTouching(dir)
    if dir == NONE and self.lastTouching == NONE or string.find(self.lastTouching, dir) then return true
    else return false
    end
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

    for _, body in pairs(self.collisionGroups[group]) do
        if minDistance > (body.position.x - origin.x) ^ 2 + (body.position.y - origin.y) ^ 2 then
            minDistance = (body.position.x - origin.x) ^ 2 + (body.position.y - origin.y) ^ 2
            if minDistance < radius ^ 2 then
                target = body
            end
        end
    end

    return target
end

function AABBWorld:removeBody(body)
    self.bodyList[body.handle] = nil
    self.collisionGroups[body.collisionGroup][body.handle] = nil
end

function AABBWorld:loadTilemap(tilemap, collidableTiles, wrap)
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
        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.rectangle("line", body.position.x, body.position.y, body.width, body.height)
    end
end

local fc = FloatCompare()

local function createHull (h)
    local delta = {x = h.position.x - h.lastPosition.x, y = h.position.y - h.lastPosition.y}
    local hull = {}
    hull.position = {}

    if fc.lt(delta.x, 0) then
        hull.position.x = h.position.x
        hull.width = -delta.x + h.width
    else
        hull.position.x = h.lastPosition.x
        hull.width = delta.x + h.width
    end

    if fc.lt(delta.y, 0) then
        hull.position.y = h.position.y
        hull.height = -delta.y + h.height
    else
        hull.position.y = h.lastPosition.y
        hull.height = delta.y + h.height
    end

    return hull
end

local function overlapHitboxes (h1, h2)
    local hull1 = createHull (h1)
    local hull2 = createHull (h2)

    if fc.le(hull1.position.x, hull2.position.x + hull2.width) and
    fc.ge(hull1.position.x + hull1.width, hull2.position.x) and
    fc.le(hull1.position.y, hull2.position.y + hull2.height) and
    fc.ge(hull1.position.y + hull1.height, hull2.position.y) then
        if h1.overlapCallbackList[h2.collisionGroup] then h1.overlapCallbackList[h2.collisionGroup](h1, h2) end
        if h2.overlapCallbackList[h1.collisionGroup] then h2.overlapCallbackList[h1.collisionGroup](h2, h1) end
        return true
    else
        return false
    end
end

function AABBWorld:overlap (h1, h2)
    if type(h1) == "string" then
        if not self.collisionGroups[h1] then return end
        for id, hitbox in pairs(self.collisionGroups[h1]) do
            self:overlap(hitbox, h2)
        end
    elseif type(h2) == "string" then
        if not self.collisionGroups[h2] then return end
        for id, hitbox in pairs(self.collisionGroups[h2]) do
            overlapHitboxes(h1, hitbox)
        end
    else
        overlapHitboxes(h1, h2)
    end

end

local h1Delta = {x = 0, y = 0}
local h2Delta = {x = 0, y = 0}
local delta = {x = 0, y = 0}
local toi = {x = 0, y = 0}
local xDistanceLeft = 0
local xDistanceRight = 0
local xDistanceTop = 0
local xDistanceBottom = 0
local xDistance = 0
local yDistance = 0

local function collideHitboxes (h1, h2)
    if overlapHitboxes (h1, h2) then
        if h1.touching == NONE then h1.touching = "" end
        if h2.touching == NONE then h2.touching = "" end

        h1Delta.x = h1.position.x - h1.lastPosition.x
        h1Delta.y = h1.position.y - h1.lastPosition.y

        h2Delta.x = h2.position.x - h2.lastPosition.x
        h2Delta.y = h2.position.y - h2.lastPosition.y

        delta.x = h1Delta.x - h2Delta.x
        delta.y = h1Delta.y - h2Delta.y

        toi.x = -1
        toi.y = -1
        
        -- distance to stay at the left side of the object
        xDistanceLeft = h2.lastPosition.x - h1.lastPosition.x - h1.width
        -- distance to stay at the right side of the object
        xDistanceRight = h2.lastPosition.x + h2.width - h1.lastPosition.x
        -- distance to stay on top of the object
        yDistanceTop = h2.lastPosition.y - h1.lastPosition.y - h1.height
        -- distance to stay at the bottom of the object
        yDistanceBottom = h2.lastPosition.y + h2.height - h1.lastPosition.y

        xDistance = nil
        yDistance = nil

        if not fc.eq(delta.x, 0) then
            if fc.gt(delta.x, 0) then
                xDistance = xDistanceLeft
            elseif fc.lt(delta.x, 0) then
                xDistance = xDistanceRight
            end

            if fc.le(math.abs(xDistance), math.abs(delta.x)) then toi.x = xDistance / delta.x end
        end

        if not fc.eq(delta.y, 0) then
            if fc.gt(delta.y, 0) then
                yDistance = yDistanceTop
            elseif fc.lt(delta.y, 0) then
                yDistance = yDistanceBottom
            end

            if fc.le(math.abs(yDistance), math.abs(delta.y)) then toi.y = yDistance / delta.y end
        end

        if fc.gt(toi.x, toi.y) and fc.lt(h1.position.y, h2.position.y + h2.height) and fc.gt(h1.position.y + h1.height, h2.position.y) then
            h1.position.x = h1.lastPosition.x + xDistance
            h1.speed.x = 0
            h2.speed.x = 0
        elseif fc.lt(toi.x, toi.y) and fc.lt(h1.position.x, h2.position.x + h2.width) and fc.gt(h1.position.x + h1.width, h2.position.x) then
            h1.position.y = h1.lastPosition.y + yDistance
            h1.speed.y = 0
            h2.speed.y = 0
        elseif fc.eq(toi.x, toi.y) and not fc.eq(toi.x, -1) then
            h1.position.y = h1.lastPosition.y + yDistance
            h1.speed.y = 0
            h2.speed.y = 0
        end

        if fc.eq(h1.position.x + h1.width, h2.position.x) and fc.ge(delta.x, 0) then
            h1.touching = h1.touching .. "_" .. RIGHT
            h2.touching = h2.touching .. "_" .. LEFT
        elseif fc.eq(h1.position.x, h2.position.x + h2.width) and fc.le(delta.x, 0) then
            h2.touching = h2.touching .. "_" .. RIGHT
            h1.touching = h1.touching .. "_" .. LEFT
        end

        if fc.eq(h1.position.y + h1.height, h2.position.y) and fc.ge(delta.y, 0) then 
            h1.touching = h1.touching .. "_" .. BOTTOM
            h2.touching = h2.touching .. "_" .. TOP
        elseif fc.eq(h1.position.y, h2.position.y + h2.height) and fc.le(delta.y, 0) then
            h2.touching = h2.touching .. "_" .. BOTTOM
            h1.touching = h1.touching .. "_" .. TOP
        end

        if h1.collisionCallbackList[h2.collisionGroup] then h1.collisionCallbackList[h2.collisionGroup](h1, h2) end
        if h2.collisionCallbackList[h1.collisionGroup] then h2.collisionCallbackList[h1.collisionGroup](h2, h1) end
    end
end

function AABBWorld:collide (h1, h2)
    if type(h1) == "string" then
        if not self.collisionGroups[h1] then return end
        for id, hitbox in pairs(self.collisionGroups[h1]) do
            self:collide(hitbox, h2)
        end
    elseif type(h2) == "string" then
        if not self.collisionGroups[h2] then return end
        for id, hitbox in pairs(self.collisionGroups[h2]) do
            collideHitboxes(h1, hitbox)
        end
    else
        collideHitboxes(h1, h2)
    end
end

function createWorld ()
    return AABBWorld()
end

return AABBPhysics
