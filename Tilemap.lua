-- Import
local love = love
local math = math
local require = require
local Class = require "Class"
local GameObject = require "GameObject"

local Tilemap = Class({

}, GameObject)
setfenv(1, Tilemap)

function Tilemap:init(tilesetFile, tilemapData, tileWidth, tileHeight)
    self.tileWidth = tileWidth
    self.tileHeight = tileHeight
    self.x = tilemapData.x
    self.y = tilemapData.y
    self.width = tilemapData.width * self.tileWidth
    self.height = tilemapData.height * self.tileHeight
    self.widthInTiles = tilemapData.width
    self.heightInTiles = tilemapData.height
    self.tileset = love.graphics.newImage(tilesetFile)
    self.tiles = tilemapData.data

    self.tileQuads = {}
    local tilesetWidthInTiles = self.tileset:getWidth() / self.tileWidth
    local tilesetHeightInTiles = self.tileset:getHeight() / self.tileHeight
    for j = 1, tilesetHeightInTiles do
        for i = 1, tilesetWidthInTiles do
            self.tileQuads[i + (j - 1) * tilesetWidthInTiles] = 
                love.graphics.newQuad((i - 1) * self.tileWidth, (j - 1) * self.tileHeight, 
                    self.tileWidth, self.tileHeight,
                    self.tileset:getWidth(), self.tileset:getHeight())
        end
    end
end

function Tilemap:draw()
    love.graphics.reset()
    for i = 1, #self.tiles do
        love.graphics.draw(self.tileset, self.tileQuads[self.tiles[i]],
            self.x + (i - 1) % self.widthInTiles * self.tileWidth,
            self.y + math.floor((i - 1) / self.widthInTiles) * self.tileHeight,
            0, 1, 1) 
    end
end

return Tilemap
