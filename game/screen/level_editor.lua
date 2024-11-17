local LevelEditor = Screen:extend()

local TILE_SIZE = 8

local SWATCH_NUM_COLS = 8
local SWATCH_PADDING = 2

local LAYER_DISPLAY_CURRENT_HIGHLIGHTED = 0
local LAYER_DISPLAY_CURRENT = 1
local LAYER_DISPLAY_ALL = 2

local LAYER_FADE_AMOUNT = 0.2

local PALETTE_HIDE_TIMER = 20

local SAVE_READABLE = false

function LevelEditor:new(x, y, width, height)
	self.prevmpos = Vec2(0, 0)
	self.mpos = Vec2(0, 0)
	self.screen_mpos = Vec2(0, 0)
	self.mdxy = Vec2(0, 0)
	self.mcell = Vec3(0, 0, 0)
	self.lmb = 0
	self.mmb = 0
	self.rmb = 0

	self.offset = Vec2(0, 0)
	self.offset_stepped = Vec2(0, 0)

	self.layer = 0

	self.layer_display_type = LAYER_DISPLAY_CURRENT_HIGHLIGHTED

	-- paint, fill, rectangle_start, rectangle_end
	self.paint_mode = "draw"

	self.painting = false
	self.erasing = false
	self.blocks_input = true

	self.tilesets = {}
	self.tiles = {}
	self.swatch_tiles = {}

	self.edit_history = {}
	self.edit_future = {}

	self.painting_tile_changes = {}

	self.active_key = "1_1"
	self.hovered_tile = nil

    self.state = "draw"
	
	self.map_name = "test"

	self.showing_palette = false
	self.palette_mouse_over_tile = nil
	self.palette_rect = Rect(0, 0, 0, 0)
	
	self.palette_scroll_offset = 0
	self.palette_rows = 0
	self.palette_hide_timer = 0

	self.rect_start = Vec3(0, 0, 0)
	self.rect_end = Vec3(0, 0, 0)

	self.layer_display_offset = 0

	self.notify_text = ""
	self.notify_text_alpha = 0
	

	self.grid_bgcolor = palette.navyblue * 0.5

	self.showing_ui = true
	self.showing_grid = true

	self:load_tilesets()

	self.palette_changed = true


	LevelEditor.super.new(self, x, y, width, height)

	input.signals.key_pressed:connect(
		function(key)
			-- global
			if self.input == input.dummy then
				return
			end


			local active_area = self:get_active_section()
			if active_area == "draw" or active_area == "palette" then
				self:on_key_pressed_drawing_area(key)
			end
			-- if active_area == "palette" then
			-- 	self:on_key_pressed_palette_area(key)
			-- end
		end)

	input.signals.mouse_wheel_moved:connect(
		function(x, y)
			local active_area = self:get_active_section()

			-- self.zoom_level = self.zoom_level + y

			if active_area == "draw" then
				-- self.layer = self.layer + y
			elseif active_area == "palette" then
				self.palette_scroll_offset = self.palette_scroll_offset + y
				self.palette_scroll_offset = clamp(self.palette_scroll_offset, -self.palette_rows, 0)
				-- print(self.palette_scroll_offset)
			end
		end)

	input.signals.mouse_pressed:connect(
		function(x, y, button)
			if self.input == input.dummy then
				return
			end

			local active_area = self:get_active_section()
			if active_area == "draw" then
				self:on_mouse_pressed_drawing_area(x, y, button)
			elseif active_area == "palette" then
				-- if self.palette_mouse_over_tile then
				--     self.active_key = self.palette_mouse_over_tile
				-- end
			end
        end)
		
	self:load("test")
	self:update_palette()
	
end

function LevelEditor:load_tilesets()
	self.tileset_tiles = {}
	self.tile_ids = {}
	self.tileset_ids = {}
	self.tileset_offsets = {}
    self.tileset_names = {}

	for _, v in ipairs(tilesets.get_all()) do
		self:load_tileset(v.name, v.tileset)
	end
end

function LevelEditor:load_tileset(tileset_name, ts)
	self.num_tiles = self.num_tiles or 0
	local c = 0
	self.tileset_offsets[self.num_tiles + 1] = ts
	self.num_tilesets = self.num_tilesets or 0
	self.num_tilesets = self.num_tilesets + 1
	for i, tile in ipairs(ts.tiles) do
		local id = tostring(self.num_tilesets) .. "_" .. tostring(i)
		self.tileset_tiles[id] = tile
		self.tile_ids[i + self.num_tiles] = id
		c = c + 1
	end
	self.tileset_names[self.num_tilesets] = tileset_name
	self.tileset_ids[ts] = self.num_tilesets
	self.tilesets[self.num_tilesets] = ts
	self.num_tiles = self.num_tiles + c
end

function LevelEditor:load(map_name)
	local map_string = filesystem.load_file_native("map/maps/" .. map_name .. "/map.lua")
    if not map_string then
        return
	end
	
	self.map_name = map_name
	
    local map_data = table.deserialize(map_string)

	self:build_from_level_data(map_data)
end

function LevelEditor:build_from_level_data(level_data)
	if type(level_data) ~= "table" then
		return
	end

    self.tiles = {}

    for z, layer in pairs(level_data.layers) do
        local tiles = layer.tiles
        for id, tile in pairs(tiles) do
			local split = string.split(tile, "_")
            local tileset_id = tonumber(split[1])
            local tileset_tile_id = tonumber(split[2])
			
            local tileset = tilesets[tileset_id]
			
            tileset_id = self.tileset_ids[tileset]

			local tile_string = tostring(tileset_id) .. "_" .. tostring(tileset_tile_id)

			assert(tileset ~= nil)

			local x, y = id_to_xy(id, layer.width)
            x = x + layer.offset.x - 1
            y = y + layer.offset.y - 1

			self:set_tile(x, y, z, tile_string)
		end
	end

end


function LevelEditor:save(map_name)
    map_name = map_name or self.map_name
    self.map_name = map_name

    local data = table.serialize(self:get_level_data())
    filesystem.save_file_native(data, "map/maps/" .. map_name .. "/map.lua")
end

function LevelEditor.convert_to_map_format(tiles, width, height, indent)
    if not SAVE_READABLE then
        local t = {}
        for i, id in pairs(tiles) do
			if type(id) ~= "function" then
            	t[i] = id
			end
        end

        return t
    end
	
	local longest_id = 0
	for i, id in pairs(tiles) do
		if type(id) == "string" then
			if string.len(id) > longest_id then
				longest_id = string.len(id)
			end
		end
	end
	longest_id = longest_id + 2
	
	local s = "{ \n" .. indent .. "  "
	for i = 1, width * height do
		local id = tiles[i]

		if id == nil then
			s = s .. string.format("%" .. longest_id .. "s", "nil") .. ","
		else
			s = s .. string.format("%" .. longest_id .. "s", "\"" .. id .. "\"") .. ","
		end
		if i % width == 0 then
			s = s .. "\n" .. indent .. "  "
		end
	end
	s = s .. " }"
	return s

end

function LevelEditor:get_level_data()
	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
    local level_data = {
        layers = {},
		tilesets = {}
    }

	for id, name in pairs(self.tileset_names) do 
		level_data.tilesets[id] = name
	end
		

    for z = min_z, max_z do
		if not self.tiles[z] then
			goto continue
		end

        local layer_min_x, layer_min_y, layer_max_x, layer_max_y = self:get_layer_bounds(z)
        local layer_width = layer_max_x - layer_min_x + 1
		local layer_height = layer_max_y - layer_min_y + 1
		local layer = {
            offset = { x = layer_min_x, y = layer_min_y },
            width = layer_width,
			height = layer_height,
            tiles = {}
        }
        
		layer.tiles.__table_format = function(tiles, next_indent) return self.convert_to_map_format(tiles, layer_width, layer_height, next_indent) end
		
        for y = 1, layer_height do
            for x = 1, layer_width do
                local tile = self:get_tile(layer_min_x + x - 1, layer_min_y + y - 1, z)
                if tile then
                	layer.tiles[xy_to_id(x, y, layer_width)] = tile
                else
                	layer.tiles[xy_to_id(x, y, layer_width)] = nil
                end
            end
        end

		level_data.layers[z] = layer
		
		::continue::
	end

	return level_data
end


function LevelEditor:notify(text)
	self.notify_text = text
	local s = self.sequencer
	s:start(function()
		s:tween_property(self, "notify_text_alpha", 1, 0, 60, "inQuad")
	end)
end

function LevelEditor:on_key_pressed_drawing_area(key)
	if input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"] then
		if key == "s" then
			-- local string = self:get_level_string()
			-- if string == "invalidcharacters" then
			--     self:notify("can't copy, contains non-string tiles")
			-- else
            -- love.system.setClipboardText(string)
			self:save()
			self:notify("Saved")
			-- end
		elseif key == "delete" then
			self:update_history()
			self.tiles = {}
			self:notify("Cleared")
		elseif key == "z" then
			if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
				self:redo()
			else
				self:undo()
			end
		end
		return
	end

	if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
		if not self.painting then
			if key == "r" then
				self.paint_mode = "rectf"
				self:notify("Mode: Rectangle Filled")
			elseif key == "e" then
				self.paint_mode = "replg"
				self:notify("Mode: Replace Global")
			elseif key == "d" then
				self.paint_mode = "line"
				self:notify("Mode: Line")
				return
			end
		end
	else
		if not self.painting then
			if key == "d" then
				self.paint_mode = "draw"
				self:notify("Mode: Draw")
				return
			elseif key == "f" then
				self.paint_mode = "fill"
				self:notify("Mode: Fill")
				return
			elseif key == "r" then
				self.paint_mode = "rect"
				self:notify("Mode: Rectangle")
				return
			elseif key == "e" then
				self.paint_mode = "repl"
				self:notify("Mode: Replace In Layer")
				return
			end
		end
		if key == "t" then
			self:toggle_palette()
		elseif key == "kp+" or key == "s" then
			self.layer = self.layer - 1
		elseif key == "kp-" or key == "w" then
			self.layer = self.layer + 1
		elseif key == "l" then
			self.layer_display_type = (self.layer_display_type + 1) % 3
		elseif key == "g" then
			self.showing_grid = not self.showing_grid
		elseif key == "tab" then
			self.showing_ui = not self.showing_ui
			-- if self.showing_palette then
			self.showing_palette = false
			-- end
		else
			-- local num = tonumber(key)
			-- if num then
			-- 	self.active_key = num
			-- end
		end
	end
end

function LevelEditor:toggle_palette()
	self.showing_palette = not self.showing_palette
	if not self.showing_ui then
		self.showing_ui = true
		self.showing_palette = false
	end
end

function LevelEditor:set_painting_tile_change(x, y, z, tile)
	if tile == nil then tile = " " end
	self.painting_tile_changes = self.painting_tile_changes or {}
	self.painting_tile_changes[z] = self.painting_tile_changes[z] or {}
	self.painting_tile_changes[z][y] = self.painting_tile_changes[z][y] or {}
	self.painting_tile_changes[z][y][x] = tile
end

function LevelEditor:get_painting_tile_change(x, y, z)
	if self.painting_tile_changes == nil then
		return nil
	end

	if self.painting_tile_changes[z] == nil then
		return nil
	end
	if self.painting_tile_changes[z][y] == nil then
		return nil
	end
	return self.painting_tile_changes[z][y][x]
end

function LevelEditor:on_mouse_pressed_drawing_area(x, y, button)
	if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
		return
	end
	if button == 1 or button == 2 then
		if self.paint_mode == "fill" then
			self:update_history()
			self:flood_fill(self.mcell.x, self.mcell.y, self.layer, button == 1 and self.active_key or nil)
		elseif self.paint_mode == "repl" then
			self:update_history()
			if self.tiles[self.layer] ~= nil then
				local min_x, min_y, max_x, max_y = self:get_layer_bounds(self.layer)
				for x = min_x, max_x do
					for y = min_y, max_y do
						local tile = self:get_tile(x, y, self.layer)
						if tile == self.hovered_tile then
							self:set_tile(x, y, self.layer, button == 1 and self.active_key or nil)
						end
					end
				end
			end
		elseif self.paint_mode == "replg" then
			self:update_history()
			local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
			for z = min_z, max_z do
				for y = min_y, max_y do
					for x = min_x, max_x do
						local tile = self:get_tile(x, y, z)
						if tile == self.hovered_tile then
							self:set_tile(x, y, z, button == 1 and self.active_key or nil)
						end
					end
				end
			end
		end
	end
end

local paint_start_functions = {
	draw = (function(self, key)
		self:update_history()
		self:set_tile(self.mcell.x, self.mcell.y, self.layer, key)
	end),

	line = (function(self, key)
		self:update_history()
		self.rect_start.x = self.mcell.x
		self.rect_start.y = self.mcell.y
		self:set_tile(self.mcell.x, self.mcell.y, self.layer, key)
	end),

	rect = (function(self, key)
		self:update_history()
		self.rect_start.x = self.mcell.x
		self.rect_start.y = self.mcell.y
		self.rect_start.z = self.layer
	end),
	rectf = (function(self, key)
		self:update_history()
		self.rect_start.x = self.mcell.x
		self.rect_start.y = self.mcell.y
		self.rect_start.z = self.layer
	end),

}
local paint_functions = {
	draw = (function(self, key)
		for _, point in ipairs(bresenham_line(self.prevmpos.x, self.prevmpos.y, self.mpos.x, self.mpos.y)) do
			local cx, cy = floor(point.x / TILE_SIZE), floor(point.y / TILE_SIZE)
			self:set_tile(cx, cy, self.layer, key)
		end
	end),
	rect = (function(self, key)
		self.painting_tile_changes = {}
		self.rect_end.x = self.mcell.x
		self.rect_end.y = self.mcell.y
		self.rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.rect_start.x, self.rect_end.x), min(self.rect_start.y, self.rect_end.y),
			min(self.rect_start.z, self.rect_end.z)
		local max_x, max_y, max_z = max(self.rect_start.x, self.rect_end.x), max(self.rect_start.y, self.rect_end.y),
			max(self.rect_start.z, self.rect_end.z)
		for z = min_z, max_z do
			for y = min_y, max_y do
				self:set_painting_tile_change(min_x, y, z, key)
				self:set_painting_tile_change(max_x, y, z, key)
			end
			for x = min_x, max_x do
				self:set_painting_tile_change(x, min_y, z, key)
				self:set_painting_tile_change(x, max_y, z, key)
			end
		end
	end),
	rectf = (function(self, key)
		self.painting_tile_changes = {}
		self.rect_end.x = self.mcell.x
		self.rect_end.y = self.mcell.y
		self.rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.rect_start.x, self.rect_end.x), min(self.rect_start.y, self.rect_end.y),
			min(self.rect_start.z, self.rect_end.z)
		local max_x, max_y, max_z = max(self.rect_start.x, self.rect_end.x), max(self.rect_start.y, self.rect_end.y),
			max(self.rect_start.z, self.rect_end.z)
		for z = min_z, max_z do
			for y = min_y, max_y do
				for x = min_x, max_x do
					self:set_painting_tile_change(x, y, z, key)
				end
			end
		end
	end),

	line = (function(self, key)
		self.rect_end.x = self.mcell.x
		self.rect_end.y = self.mcell.y
		if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
			local dx, dy = vec2_snap_angle(self.rect_end.x - self.rect_start.x, self.rect_end.y - self.rect_start.y,
				tau / 8)
			self.rect_end.x = self.rect_start.x + round(dx)
			self.rect_end.y = self.rect_start.y + round(dy)
		end
		for _, point in ipairs(bresenham_line(self.rect_start.x, self.rect_start.y, self.rect_end.x, self.rect_end.y)) do
			self:set_painting_tile_change(point.x, point.y, self.layer, key)
		end
	end),
}


local paint_end_functions = {

	line = (function(self, key)
		for _, point in ipairs(bresenham_line(self.rect_start.x, self.rect_start.y, self.rect_end.x, self.rect_end.y)) do
			local cx, cy = (point.x), (point.y)
			self:set_tile(cx, cy, self.layer, key)
		end
	end),

	rect = (function(self, key)
		self.rect_end.x = self.mcell.x
		self.rect_end.y = self.mcell.y
		self.rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.rect_start.x, self.rect_end.x), min(self.rect_start.y, self.rect_end.y),
			min(self.rect_start.z, self.rect_end.z)
		local max_x, max_y, max_z = max(self.rect_start.x, self.rect_end.x), max(self.rect_start.y, self.rect_end.y),
			max(self.rect_start.z, self.rect_end.z)
		for z = min_z, max_z do
			for y = min_y, max_y do
				self:set_tile(min_x, y, z, key)
				self:set_tile(max_x, y, z, key)
			end
			for x = min_x, max_x do
				self:set_tile(x, min_y, z, key)
				self:set_tile(x, max_y, z, key)
			end
		end
	end),

	rectf = (function(self, key)
		self.rect_end.x = self.mcell.x
		self.rect_end.y = self.mcell.y
		self.rect_end.z = self.layer
		local min_x, min_y, min_z = min(self.rect_start.x, self.rect_end.x), min(self.rect_start.y, self.rect_end.y),
			min(self.rect_start.z, self.rect_end.z)
		local max_x, max_y, max_z = max(self.rect_start.x, self.rect_end.x), max(self.rect_start.y, self.rect_end.y),
			max(self.rect_start.z, self.rect_end.z)
		for z = min_z, max_z do
			for y = min_y, max_y do
				for x = min_x, max_x do
					self:set_tile(x, y, z, key)
				end
			end
		end
	end),
}

local paint_hover_functions = {

}

function LevelEditor:update_mouse_drawing_area(dt)
	if self.mmb ~= nil then
		self.offset.x = self.offset.x + self.mdxy.x
		self.offset.y = self.offset.y + self.mdxy.y
	end

	if self.lmb ~= nil or self.rmb ~= nil then
		local cx, cy = floor(self.mpos.x / TILE_SIZE), floor(self.mpos.y / TILE_SIZE)
		if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
			self.active_key = self:get_tile(cx, cy) or self.active_key
		else
			self.erasing = self.rmb
			if not self.painting then
				self.painting = true
				if paint_start_functions[self.paint_mode] ~= nil then
					paint_start_functions[self.paint_mode](self, self.active_key or nil)
				end
			end

			if paint_functions[self.paint_mode] ~= nil then
				paint_functions[self.paint_mode](self, self.lmb and self.active_key or nil)
			end
		end
	else
		if self.painting then
			if paint_end_functions[self.paint_mode] ~= nil then
				paint_end_functions[self.paint_mode](self, (not self.erasing) and self.active_key or nil)
			end
		end
		self.painting = false
		self.erasing = false
	end

	if not self.painting then
		if paint_hover_functions[self.paint_mode] ~= nil then
			paint_hover_functions[self.paint_mode](self, self.active_key or nil)
		end
	end

	if self.screen_mpos.x < self.palette_rect.x then
		self.palette_hide_timer = self.palette_hide_timer - dt
	elseif self.showing_palette and self.screen_mpos.x >= self.palette_rect.x then
		self.palette_hide_timer = PALETTE_HIDE_TIMER
	elseif self.screen_mpos.x >= self.viewport_size.x - 16 and not self.painting then
		self.showing_palette = true
		self.palette_hide_timer = PALETTE_HIDE_TIMER
	end
	
	if self.palette_hide_timer <= 0 then
		self.showing_palette = false
	end
end

function LevelEditor:on_palette_changed()
	self.palette_changed = true
end

function LevelEditor:update_palette()
	local horizontal_space = SWATCH_NUM_COLS * TILE_SIZE + (SWATCH_PADDING * 2)
	self.palette_rect.x = self.viewport_size.x - horizontal_space
	self.palette_rect.y = 0
	self.palette_rect.width = horizontal_space
	self.palette_rect.height = self.viewport_size.y

	self.palette_mouse_over_tile = nil

	local x = self.palette_rect.x + SWATCH_PADDING
    local y = self.palette_rect.y + SWATCH_PADDING + self.palette_scroll_offset * TILE_SIZE


	if self.palette_changed then
		self.swatch_tiles = {}
		self.palette_rows = 0
	end

	local current_tileset = self.tileset_offsets[1]

	local row = 0

	local active_area = self:get_active_section()

	for i, id in pairs(self.tile_ids) do
		local tile = self.tileset_tiles[id]

		if self.screen_mpos.x >= x and self.screen_mpos.x <= x + TILE_SIZE and self.screen_mpos.y >= y and self.screen_mpos.y <= y + TILE_SIZE then
			self.palette_mouse_over_tile = id
			if active_area == "palette" and self.lmb then
				self.active_key = id
			end
		end


		if self.palette_changed then
			self.swatch_tiles[x] = self.swatch_tiles[x] or {}
			self.swatch_tiles[x][y] = tile
		end

		local new_tileset = self.tileset_offsets[i + 1] ~= nil and self.tileset_offsets[i + 1] ~= current_tileset
		x = x + TILE_SIZE
		row = row + 1
		if row % SWATCH_NUM_COLS == 0 or new_tileset then
			row = 0
			x = self.palette_rect.x + SWATCH_PADDING
			y = y + TILE_SIZE
			if self.palette_changed then
				self.palette_rows = self.palette_rows + 1
			end
		end
	end

	self.palette_changed = false
end

function LevelEditor:get_active_section()
	if self.state == "draw" then
		if self.painting then
			return "draw"
		elseif self.screen_mpos.x >= self.viewport_size.x or self.screen_mpos.y >= self.viewport_size.y or self.viewport_size.x < 0 or self.viewport_size.y < 0 then
			return "none"
		elseif not self.showing_ui then
			return "draw"
		elseif self.showing_palette then
			if self.palette_rect:contains_point(self.screen_mpos) then
				return "palette"
			end
		end
		return "draw"
	end
end

function LevelEditor:update_history()
	self.edit_future = {}
	table.push_back(self.edit_history, table.deepcopy(self.tiles))
end

function LevelEditor:redo()
	if table.is_empty(self.edit_future) then return end
	table.push_back(self.edit_history, table.deepcopy(self.tiles))
	self.tiles = table.pop_back(self.edit_future)
	self:notify("Redo")
end

function LevelEditor:undo()
	if table.is_empty(self.edit_history) then return end
	table.push_back(self.edit_future, table.deepcopy(self.tiles))
	self.tiles = table.pop_back(self.edit_history)
	self:notify("Undo")
end

function LevelEditor:update(dt)
	self.prevmpos.x = self.mpos.x
	self.prevmpos.y = self.mpos.y
	local step_size = TILE_SIZE
	self.offset_stepped.x = floor(self.offset.x / step_size) * step_size
	self.offset_stepped.y = floor(self.offset.y / step_size) * step_size
	self.mpos.x = round(input.mouse.pos.x - self.offset_stepped.x + 0.5)
	self.mpos.y = round(input.mouse.pos.y - self.offset_stepped.y + 0.5)
	self.screen_mpos.x = input.mouse.pos.x
	self.screen_mpos.y = input.mouse.pos.y
	self.mdxy.x = input.mouse.dxy.x
	self.mdxy.y = input.mouse.dxy.y
	if not self.mmb then
		self.mcell.x = floor(self.mpos.x / TILE_SIZE)
		self.mcell.y = floor(self.mpos.y / TILE_SIZE)
	end
	self.mcell.z = self.layer

	self.lmb = input.mouse.lmb
	self.mmb = input.mouse.mmb
	self.rmb = input.mouse.rmb

	self.hovered_tile = self:get_tile(self.mcell.x, self.mcell.y, self.layer)

	self.layer_display_offset = splerp(self.layer_display_offset, self.layer, dt, 90)

    local active_area = self:get_active_section()
	
	if self.showing_palette then
		self:update_palette()
	end

	self.painting_tile_changes = nil

	if active_area == "draw" then
		self:update_mouse_drawing_area(dt)
	end

	if self.input.debug_editor_toggle_pressed then
		self:pop()
	end

	if debug.enabled then
		dbg("self.offset", floor(self.offset.x) .. ", " .. floor(self.offset.y))
	end
end

function LevelEditor:flood_fill(cx, cy, cz, tile)
	cz = cz or self.layer

	if self.tiles[cz] == nil then
		return
	end

	local tile_to_change = self:get_tile(cx, cy, cz)

	tile = tile or nil


	if tile == tile_to_change then return end

	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()

	local check_solid = function(c2x, c2y)
		if c2x < min_x or c2x > max_x or c2y < min_y or c2y > max_y then
			return true
		end
		local check_tile = self:get_tile(c2x, c2y, cz)
		if check_tile == tile_to_change then
			return false
		end
		return true
	end
	local fill = function(c2x, c2y)
		self:set_tile(c2x, c2y, cz, tile)
	end
	flood_fill(cx, cy, fill, check_solid, true)
end

function LevelEditor:get_tile(x, y, z)
	z = z or self.layer

	if self.tiles[z] == nil then
		return nil
	end

	if self.tiles[z][y] == nil then
		return nil
	end

	return self.tiles[z][y][x] or nil
end

function LevelEditor:world_to_tile(x, y)
	return floor(x / TILE_SIZE), floor(y / TILE_SIZE)
end

function LevelEditor:tile_to_world(x, y)
	return x * TILE_SIZE, y * TILE_SIZE
end

function LevelEditor:set_tile(x, y, z, tile_id)
	-- local in_charset = false
	-- for i = 1, #charset do
	-- 	if charset:sub(i, i) == tile_id then
	-- 		in_charset = true
	-- 		break
	-- 	end
	-- end
	-- if not in_charset and type(tile_id) == "string" then
	-- 	tile_id = nil
	-- end
	-- if tile_id == " " or tile_id == "\n" or tile_id == "_" then
	-- 	tile_id = nil
	-- end

	if self.tiles[z] == nil then
		if tile_id == nil then
			return
		end
		self.tiles[z] = {}
	end

	if self.tiles[z][y] == nil then
		if tile_id == nil then
			return
		end
		self.tiles[z][y] = {}
	end

	self.tiles[z][y][x] = tile_id

	if tile_id == nil then
		if table.is_empty(self.tiles[z][y]) then
			self.tiles[z][y] = nil
		end
		if table.is_empty(self.tiles[z]) then
			self.tiles[z] = nil
		end
	end
end

function LevelEditor:get_painting_bounds()
	if self.painting_tile_changes == nil then
		return 0, 0, 0, 0, 0, 0
	end
	local min_x = math.huge
	local min_y = math.huge
	local min_z = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	local max_z = -math.huge

	for z, layer in pairs(self.painting_tile_changes) do
		for y, row in pairs(layer) do
			for x, _ in pairs(row) do
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				min_z = min(min_z, z)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
				max_z = max(max_z, z)
			end
		end
	end

	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:get_layer_bounds(layer)
	local min_x = math.huge
	local min_y = math.huge
	local max_x = -math.huge
	local max_y = -math.huge

	if self.tiles[layer] == nil then
		return 0, 0, 0, 0
	end

	for y, row in pairs(self.tiles[layer]) do
		for x, _ in pairs(row) do
			if self:get_tile(x, y, layer) == nil then
				self:set_tile(x, y, layer, nil)
			else
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
			end
		end
	end
	return min_x, min_y, max_x, max_y
end

function LevelEditor:get_bounds(tiles)
	local min_x = math.huge
	local min_y = math.huge
	local min_z = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	local max_z = -math.huge

	for z, layer in pairs(tiles or self.tiles) do
		for y, row in pairs(layer) do
            for x, _ in pairs(row) do
				if tiles == self.tiles and self:get_tile(x, y, z) == nil then
					self:set_tile(x, y, z, nil)
				else
					min_x = min(min_x, x)
					min_y = min(min_y, y)
					min_z = min(min_z, z)
					max_x = max(max_x, x)
					max_y = max(max_y, y)
					max_z = max(max_z, z)
				end
			end
		end
	end

	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:get_draw_bounds() -- includes painting bounds
	if self.painting_tile_changes == nil then
		return self:get_bounds()
	end
	local min_x, min_y, min_z, max_x, max_y, max_z = self:get_bounds()
	local pmin_x, pmin_y, pmin_z, pmax_x, pmax_y, pmax_z = self:get_painting_bounds()
	min_x = min(min_x, pmin_x)
	min_y = min(min_y, pmin_y)
	min_z = min(min_z, pmin_z)
	max_x = max(max_x, pmax_x)
	max_y = max(max_y, pmax_y)
	max_z = max(max_z, pmax_z)
	return min_x, min_y, min_z, max_x, max_y, max_z
end

function LevelEditor:enter()
	self:update_history()
	-- love.mouse.setVisible(false)
end

function LevelEditor:exit()
	-- love.mouse.setVisible(true)
end

function LevelEditor:draw()
	self.clear_color = (self.showing_grid and self.showing_ui) and self.grid_bgcolor or palette.black
	LevelEditor.super.draw(self)
	graphics.push()
	graphics.origin()
	graphics.set_color(palette.white)
	graphics.translate(floor(self.offset_stepped.x), floor(self.offset_stepped.y))
	graphics.set_font(graphics.font["PixelOperatorMono8-Bold"])

	-- if debug.can_draw() then
	-- end
	local active_section = self:get_active_section()

	self:draw_tiles()

	if (self.showing_grid and self.showing_ui) then
		self:draw_level_grid()
	end


	if active_section == "draw" then
		graphics.set_color(palette.black)
		-- graphics.print(key_string, self.mpos.x + 2, self.mpos.y + 2)
		-- graphics.points(self.mpos.x + 1, self.mpos.y + 1)


		graphics.set_color(1, 1, 1, 0.25)
		graphics.rectangle("line", self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE, TILE_SIZE + 1, TILE_SIZE + 1)

		graphics.set_color(palette.white)
		if self.tileset_tiles[self.active_key] then
			graphics.set_color(palette.white, 0.75)
			self.tileset_tiles[self.active_key]:draw(self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE)
			graphics.set_color(palette.white, 0.35)
			-- else
		end
	end

	graphics.set_color(palette.white)

	-- graphics.points(self.mpos.x, self.mpos.y)

	graphics.origin()

	if debug.enabled then
		dbg("mcell", self.mcell)
	end
	graphics.set_font(graphics.font["PixelOperator8"])
	if self.showing_ui then
		graphics.set_color(palette.black, 0.5)
		graphics.rectangle("fill", 0, 0, self.viewport_size.x, 8)

		graphics.set_color(palette.white)
		graphics.print(self.paint_mode, 0, 0)
		graphics.set_color(palette.greyblue)
		graphics.push("all")
		graphics.set_font(graphics.font["PixelOperatorMono8"])
		graphics.print(string.format("%+4i,%+4i", self.mcell.x, self.mcell.y), 48, 0)
		graphics.pop()

		graphics.set_color(palette.black, 0.5)
		graphics.rectangle("fill", 0, self.viewport_size.y - 8, self.viewport_size.x, 8)

		self:draw_layer_offset()

		if self.showing_palette then
			self:draw_palette()
		end
	end

	if self.notify_text ~= "" then
		graphics.set_color(palette.white, self.notify_text_alpha)
		graphics.print(self.notify_text, 0, self.viewport_size.y - 8)
		
	end


	graphics.pop()
end

function LevelEditor:draw_palette()
	graphics.push()
	graphics.origin()
	graphics.set_color(palette.black, 0.75)
	graphics.rectangle("fill", self.palette_rect.x, self.palette_rect.y, self.palette_rect.width,
		self.palette_rect.height)
	graphics.set_color(palette.white)
	local hover_x, hover_y = nil, nil
	local active_x, active_y = nil, nil
	local print_x, print_y = nil, nil
	local print_text = nil
	for x, row in pairs(self.swatch_tiles) do
		for y, tile in pairs(row) do
			y = y + self.palette_scroll_offset * TILE_SIZE
			tile:draw(x, y)
			if tile == self.tileset_tiles[self.palette_mouse_over_tile] then
				-- graphics.push()
				-- graphics.set_color(palette.white, 0.5)
				hover_x, hover_y = x, y
				print_x, print_y = x, y
				print_text = tostring(self.palette_mouse_over_tile):sub(3)
				-- graphics.set_color(palette.black, 1.0)
				-- graphics.print(tostring(self.palette_mouse_over_tile), x, y + 1)
				-- graphics.set_color(palette.white, 1.0)
				-- graphics.print(tostring(self.palette_mouse_over_tile), x, y)
				-- graphics.pop()
				-- graphics.set_color(palette.white)
			end
			if tile == self.tileset_tiles[self.active_key] then
				graphics.push()
				graphics.set_color(palette.white, 0.5)
				active_x, active_y = x, y
				graphics.pop()
				graphics.set_color(palette.white)
			end
		end
	end

	if hover_x and hover_y then
		graphics.set_color(palette.white, 0.5)
		graphics.rectangle("line", hover_x, hover_y, TILE_SIZE + 1, TILE_SIZE + 1)
	end

	if active_x and active_y then
		graphics.set_color(palette.white, 0.5)
		graphics.rectangle("line", active_x, active_y, TILE_SIZE + 1, TILE_SIZE + 1)
	end

	if print_x and print_y and print_text then
		graphics.set_color(palette.black)
		graphics.print(print_text, print_x, print_y + 1)
		graphics.set_color(palette.white)
		graphics.print(print_text, print_x, print_y)
	end

	graphics.pop()
end

function LevelEditor:draw_layer_offset()
	graphics.push("all")
	graphics.origin()
	local font = graphics.font["PixelOperator8"]
	graphics.set_font(font)

	local height = 80
	local bar_separation = 6
	local bar_thickness = 2
	local bar_width = 3
	local total_bar_height = bar_thickness + bar_separation
	local num_bars = floor(height / total_bar_height)

	local top = self.viewport_size.y / 2 - (height / 2)
	local bottom = self.viewport_size.y / 2 + (height / 2)
	local horiz = TILE_SIZE / 2

	graphics.set_color(palette.black, 0.5)
	graphics.rectangle("fill", horiz - 4, top - 4, 8, height + 8)

	graphics.push()
	for i = ceil(-num_bars / 2), floor(num_bars / 2) do
		local bar_layer = (-i + self.layer)
		local yoffs = ((i + num_bars / 2 + (self.layer_display_offset - self.layer)) * total_bar_height) -
			total_bar_height / (num_bars * 2) - bar_thickness / 2

		if abs(yoffs - height) < 0.01 then yoffs = 0 end
		if yoffs < -2 or yoffs > height then
			goto continue
		end

		local y = top + yoffs


		local color = palette.greyblue

		if bar_layer == self.layer then
			color = palette.white
		end

		if bar_layer % 10 == 0 or bar_layer == self.layer then
			local string = tostring(bar_layer)
			graphics.set_color(palette.black, 0.5)
			graphics.rectangle("fill", horiz + 4, y - 4, font:getWidth(string) + 1, 8)
			graphics.set_color(palette.white, 0.5)
			graphics.print(string, horiz + 4, y - 4)
		end
		graphics.push("all")
		if self.tiles[bar_layer] == nil or table.is_empty(self.tiles[bar_layer]) then
			graphics.set_color(color, 0.05)
			graphics.rectangle("fill", horiz - bar_width / 2, y, bar_width, bar_thickness)
		else
			graphics.set_color(color, 1)
			graphics.rectangle("fill", horiz - bar_width / 2, y, bar_width, bar_thickness)
		end
		graphics.pop()

		::continue::
	end
	graphics.pop()

	graphics.set_color(palette.white, 0.25)


	graphics.line(horiz, top, horiz, bottom)


	graphics.points(horiz, top - 2)

	graphics.push("all")
	graphics.set_color(palette.white, 1)

	graphics.points(horiz - 3, (top + bottom) / 2)
	graphics.points(horiz - 3, (top + bottom) / 2 + 1)

	graphics.pop()

	graphics.points(horiz, bottom + 3)

	graphics.pop()
end

function LevelEditor:tile_draw(tile_id, x, y)
	local sprite = self.tileset_tiles[tile_id]
	if sprite then
		if sprite.draw then
			sprite:draw(x, y)
		else
			graphics.draw(self.tileset_tiles[tile_id], x, y)
		end
	elseif type(tile_id) == string then
		graphics.print(tile_id, x, y)
	else
		graphics.print(tostring(tile_id):sub(1, 1), x, y)
	end
end

function LevelEditor:tile_color(tile_id)
	if self.tileset_tiles[tile_id] then
		return palette.white
	end
	if type(tile_id) == "number" then
		return palette.red
	end
	if tile_id == nil then
		return palette.black
	end
	if tile_id == "#" or tile_id == "." then
		return palette.darkgreyblue
	end
	if string.match("0123456789", tile_id) then
		return palette.green
	end
	return palette.white
end

function LevelEditor:draw_tiles()
	graphics.push()
	local camera_min_x, camera_min_y, camera_max_x, camera_max_y = -self.offset.x, -self.offset.y,
		self.viewport_size.x - self.offset.x, self.viewport_size.y - self.offset.y
	local min_x = floor(camera_min_x / TILE_SIZE)
	local min_y = floor(camera_min_y / TILE_SIZE)
	local max_x = floor(camera_max_x / TILE_SIZE)
	local max_y = floor(camera_max_y / TILE_SIZE)


	local bounds_min_x, bounds_min_y, bounds_min_z, bounds_max_x, bounds_max_y, bounds_max_z = self:get_draw_bounds()

	-- if x >= bounds_min_x and x <= bounds_max_x and y >= bounds_min_y and y <= bounds_max_y then
	graphics.set_color(palette.black, 1)
	graphics.rectangle("fill", bounds_min_x * TILE_SIZE, bounds_min_y * TILE_SIZE,
		(bounds_max_x - bounds_min_x + 1) * TILE_SIZE, (bounds_max_y - bounds_min_y + 1) * TILE_SIZE)


	local show_all_layers = (self.layer_display_type == LAYER_DISPLAY_CURRENT_HIGHLIGHTED or self.layer_display_type == LAYER_DISPLAY_ALL)
	local min_z = show_all_layers and bounds_min_z or self.layer
	local max_z = show_all_layers and bounds_max_z or self.layer
	local fade_layers = self.layer_display_type == LAYER_DISPLAY_CURRENT_HIGHLIGHTED

	dbg("bounds",
		tostring(min_x) ..
		", " ..
		tostring(min_y) ..
		", " .. tostring(min_z) .. ", " .. tostring(max_x) .. ", " .. tostring(max_y) .. ", " .. tostring(max_z))

	for y = min_y, max_y do
		for x = min_x, max_x do
			for z = min_z, max_z do
				local tile = self:get_tile(x, y, z)
				local painting_tile = self:get_painting_tile_change(x, y, z)

				if painting_tile then
					tile = painting_tile
				end

				if tile then
					local color = self:tile_color(tile)

					graphics.set_color(color)

					if fade_layers then
						local dist = abs(z - self.layer)
						local fade = pow(LAYER_FADE_AMOUNT, dist)
						graphics.set_color(color, fade)
					end

					self:tile_draw(tile, x * TILE_SIZE, y * TILE_SIZE)
				end
			end
		end
	end
	graphics.pop()
end

function LevelEditor:draw_level_grid()
	graphics.push()
	graphics.set_color(1, 1, 1, 0.05)

	local start_x = (floor(-self.offset.x / TILE_SIZE - 2) * TILE_SIZE)
	local end_x = start_x + floor(graphics.main_viewport_size.x / TILE_SIZE + 4) * TILE_SIZE
	local start_y = (floor(-self.offset.y / TILE_SIZE - 2) * TILE_SIZE)
	local end_y = start_y + floor(graphics.main_viewport_size.y / TILE_SIZE + 4) * TILE_SIZE
	for i = 1, graphics.main_viewport_size.x / TILE_SIZE + 3 do
		graphics.set_color(1, 1, 1, 0.02)
		if ((start_x + (i) * TILE_SIZE)) % self.viewport_size.x == 0 then
			graphics.set_color(1, 1, 1, 0.15)
		end
		graphics.line(start_x + i * TILE_SIZE, start_y, start_x + i * TILE_SIZE, end_y)
	end
	for i = 1, graphics.main_viewport_size.y / TILE_SIZE + 3 do
		graphics.set_color(1, 1, 1, 0.02)
		if ((start_y + (i) * TILE_SIZE)) % self.viewport_size.y == 0 then
			graphics.set_color(1, 1, 1, 0.15)
		end

		graphics.line(start_x, start_y + i * TILE_SIZE, end_x, start_y + i * TILE_SIZE)
	end



	graphics.pop()
end

return LevelEditor
