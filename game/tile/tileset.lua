local Tile = require "tile.tile"

local Tileset = Object:extend()

function Tileset:new(texture, tile_width, tile_height)
    self.texture = texture
    self.tile_width = tile_width
    self.tile_height = tile_height

	self.tiles = {}

    local tex_width, tex_height = texture:getPixelDimensions()

    for y = 1, floor(tex_height / tile_height) do
        for x = 1, floor(tex_width / tile_width) do
            local quad = graphics.new_quad((x - 1) * tile_width, (y - 1) * tile_height, tile_width, tile_height, tex_width, tex_height)
            self.tiles[self:xy_to_id(x, y)] = Tile(quad, texture)
        end
    end
end

function Tileset:xy_to_id(x, y)
    return (y - 1) * self.tile_width + x
end

function Tileset:id_to_xy(id)
	local x = id % self.tile_width
	local y = floor(id / self.tile_width)
	return x, y
end

function Tileset:set_tile_data(x, y, data)
	local id = self:xy_to_id(x, y)
	local tile = self.tiles[id]
    assert(self.tiles[id] ~= nil, "tile doesn't exist")
	tile.data = data
end

function Tileset:get_tile(x, y)
	return self.tiles[self:xy_to_id(x,y)]
end

return Tileset
