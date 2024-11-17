local Tile = require "tile.tile"

local Tileset = Object:extend()

function Tileset:new(texture, tile_width, tile_height)
    self.texture = texture
    self.tile_width = tile_width
    self.tile_height = tile_height

    local tex_width, tex_height = texture:getPixelDimensions()

    self.tile_count_x = floor(tex_width / tile_width)
	self.tile_count_y = floor(tex_height / tile_height)

	self.tiles = {}


    for y = 1, self.tile_count_y do
        for x = 1, self.tile_count_x do
            local quad = graphics.new_quad((x - 1) * tile_width, (y - 1) * tile_height, tile_width, tile_height, tex_width, tex_height)
            self.tiles[self:xy_to_id(x, y)] = Tile(quad, texture)
        end
    end

	self.tile_count = #self.tiles
end

function Tileset:xy_to_id(x, y)
    return (y - 1) * self.tile_count_x + x
end

function Tileset:id_to_xy(id)
	local x = id % self.tile_count_x
	local y = floor(id / self.tile_count_x)
	return x, y
end

function Tileset:set_tile_data(x, y, data)
	local id = self:xy_to_id(x, y)
	local tile = self.tiles[id]
    assert(self.tiles[id] ~= nil, "tile doesn't exist")
	tile.data = data
end

function Tileset:get_tile(x, y)
	if y == nil then return self.tiles[x] end 
	return self.tiles[self:xy_to_id(x, y)]
end

return Tileset
