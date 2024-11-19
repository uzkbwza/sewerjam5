local TileMap = require "tile.tilemap"

local GameMap = Object:extend()

function GameMap.load(map_name)
	unrequire("map.maps." .. map_name .. ".map")
    local map_data = require("map.maps." .. map_name .. ".map")

    local _, map_custom_data = pcall(function() return require("map.maps." .. map_name .. ".custom") end)

    return GameMap {
        map = map_data,
        custom = map_custom_data or nil
    }
end

function GameMap:new(level_data)
    self.tile_map = TileMap(level_data.map)
    self.batches = {}
	self.objects = {}
end

---@return boolean tile_will_be_drawn
function GameMap.default_tile_process(x, y, z, tile)
	return true -- will be drawn
end

function GameMap:build(tile_process_func)
    tile_process_func = tile_process_func or GameMap.default_tile_process
    local layer_tile_batches = {}
	self.objects = {}
	local TS = tilesets.TILE_SIZE

    for x, y, z, tile_string in self.tile_map:iter() do
        if tilesets.object_tiles[tile_string] then
            self.objects[#self.objects + 1] = { x, y, z, tile_string }
            goto continue
        end
		
        local tile = self.tile_map:tile_from_string(tile_string)

		if type(tile) == "string" then goto continue end

		local data = tile.data

		local sprite_batch_table = table.populate_recursive(layer_tile_batches, z, tile.texture)

        -- filter sprites
        if tile_process_func(x, y, z, tile) then
            table.insert(sprite_batch_table, { x = x, y = y, tile = tile })
        end

        -- collisions
        if data and data.collision_rect and self.bump_world then
			local collision_rect = Rect(x * TS + data.collision_rect.x, y * TS + data.collision_rect.y, data.collision_rect.width, data.collision_rect.height)

            local collision_data = {
                x = x,
				y = y,
                layer = z,
                tile = tile,
				collision_rect = collision_rect,
            }
			
			self.bump_world:add(collision_data, collision_rect.x, collision_rect.y, collision_rect.width, collision_rect.height)
		end
        ::continue::
    end

    table.clear(self.batches)

    for layer, texture_table in pairs(layer_tile_batches) do
        self.batches[layer] = self.batches[layer] or {}
        for texture, batch_table in pairs(texture_table) do
            local sprite_batch = graphics.new_sprite_batch(texture, 1000, "static")
            for i, tile_info in ipairs(batch_table) do
                sprite_batch:add(tile_info.tile.quad, tile_info.x * TS, tile_info.y * TS)
            end
            table.insert(self.batches[layer], sprite_batch)
        end
    end
end

function GameMap:bump_init(bump_world)
	self.bump_world = bump_world
end

function GameMap:draw()
    -- todo: sort
	for layer, _ in pairs(self.batches) do 
		self:draw_layer(layer)
	end
end

function GameMap:draw_layer(layer)
    if self.batches[layer] then
        local batches = self.batches[layer]
		for _, batch in ipairs(batches) do 
			love.graphics.draw(batch)
		end
	end
end


return GameMap
