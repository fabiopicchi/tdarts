-- Import
local Class = require "Class"
local GameContext = require "GameContext"
local Tilemap = require "Tilemap"
local Player = require "Player"
local Enemy = require "Enemy"
local Bullet = require "Bullet"
local AABBPhysics = require "AABBPhysics"
local table = table
local math = math
local pairs = pairs
local require = require

local StageContext = Class({}, GameContext)
setfenv(1, StageContext)

local MAP_LAYER = "map"
local PATH_LAYER = "path"

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
    end

    self:addObject(tilemap)
    AABBPhysics.loadTilemap(tilemap, {false, true, true, true})
    self:addObject(Player(self.gamepads[1], AABBPhysics.createBody(32, 32, "player")))
    self:addObject(Enemy(paths[1], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[2], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[3], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[4], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[5], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[6], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[7], AABBPhysics.createBody(32, 32, "enemy")))
    self:addObject(Enemy(paths[8], AABBPhysics.createBody(32, 32, "enemy")))
end

function StageContext:addBullet(x, y, angle)
    self:addObject(Bullet(x, y, angle, AABBPhysics.createBody(10, 10, "bullet")))
end

function StageContext:updateBucket(bucket, dt)
    GameContext.updateBucket(self, bucket, dt)
    AABBPhysics.update(dt)
    AABBPhysics.collide("player", "tilemap")
    AABBPhysics.collide("bullet", "tilemap")
end

function StageContext:draw()
    GameContext.draw(self)
    AABBPhysics.draw()
end

return StageContext
