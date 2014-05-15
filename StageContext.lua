-- Import
local Class = require "Class"
local GameContext = require "GameContext"
local Tilemap = require "Tilemap"
local Player = require "Player"
local Enemy = require "Enemy"
local Bullet = require "Bullet"
local Sentry = require "Sentry"
local AABBPhysics = require "AABBPhysics"
local table = table
local math = math
local pairs = pairs
local print = print
local os = os
local require = require
local Timer = require "Timer"

local StageContext = Class({}, GameContext)
setfenv(1, StageContext)

local MAP_LAYER = "map"
local PATH_LAYER = "path"
local RESOURCES_LAYER = "resources"

local SPAWN_INTERVAL = 5
local HORDE_INTERVAL = 25

local function loadPaths(paths, tileWidth, tileHeight)
    local tiledPaths = {}
    for _, path in pairs(paths) do
        local tiledPath = {}

        for _, point in pairs(path.polyline) do
            table.insert(tiledPath, {
                x = math.floor((path.x + point.x) / tileWidth) * tileWidth, 
                y = math.floor((path.y + point.y) / tileHeight) * tileHeight
            })
        end
        table.insert(tiledPaths, tiledPath)
    end

    return tiledPaths
end

local function loadResources(resources)
    for _, resource in pairs(resources) do
        local body = AABBPhysics.createBody(resource.width, resource.height, "junk")
        body.position.x = resource.x
        body.position.y = resource.y
    end
end

function StageContext:init(gamepads, stageFile)
    GameContext.init(self)

    self.tiledMapFile = require (stageFile)
    self.gamepads = gamepads
    
    local tilemap = nil
    local paths = nil
    for _, layer in pairs(self.tiledMapFile.layers) do
        if layer.name == MAP_LAYER then
            tilemap = Tilemap(self.tiledMapFile.tilesets[1].image, layer,
                self.tiledMapFile.tilewidth, self.tiledMapFile.tileheight)
        end

        if layer.name == PATH_LAYER then
            paths = loadPaths(layer.objects, self.tiledMapFile.tilewidth, self.tiledMapFile.tileheight)
        end

        if layer.name == RESOURCES_LAYER then
            loadResources(layer.objects)
        end
    end

    self:addObject(tilemap)
    AABBPhysics.loadTilemap(tilemap, {false, true, true, true}, true)
    self:addObject(Player(self.gamepads[1], 
        AABBPhysics.createBody(32, 32, "player"), 
        AABBPhysics.createBody(48, 48, "playerInfluence")
    ))

    self.timer = Timer ()
    self.groupsSpawned = 0

    math.randomseed(os.time())
    local function spawn ()
        print("HUE")
        local arPaths = {}
        table.insert(arPaths, math.random(8))
        self:addObject(Enemy(paths[arPaths[1]], AABBPhysics.createBody(32, 32, "enemy")))
        while #arPaths < 3 do
            local n = math.random(8)
            local hasN = false
            for _, r in pairs(arPaths) do
                if r == n then
                    hasN = true
                    break
                end
            end

            if not hasN then
                table.insert(arPaths, n)
                self:addObject(Enemy(paths[n], AABBPhysics.createBody(32, 32, "enemy")))
            end
        end
        self.groupsSpawned = self.groupsSpawned + 1

        if self.groupsSpawned > 10 then
            self.groupsSpawned = 0
            self.timer:start(HORDE_INTERVAL, spawn)
        else
            self.timer:start(SPAWN_INTERVAL, spawn)
        end
    end
    spawn()
end

function StageContext:addBullet(x, y, angle)
    self:addObject(Bullet(x, y, angle, AABBPhysics.createBody(10, 10, "bullet")))
end

function StageContext:addSentry(x, y)
    self:addObject(Sentry(x, y, AABBPhysics.createBody(32, 32, "sentry")))
end

function StageContext:queryAABBRadius(group, origin, radius)
    return AABBPhysics.queryBody(group, origin, radius)
end

function StageContext:updateBucket(bucket, dt)
    self.timer:update(dt)
    
    GameContext.updateBucket(self, bucket, dt)

    AABBPhysics.update(dt)

    AABBPhysics.collide("player", "tilemap")
    AABBPhysics.collide("bullet", "tilemap")
    AABBPhysics.collide("player", "sentry")

    AABBPhysics.overlap("bullet", "enemy")
    AABBPhysics.overlap("sentry", "playerInfluence")
    AABBPhysics.overlap("junk", "playerInfluence")
end

function StageContext:draw()
    GameContext.draw(self)
end

return StageContext
