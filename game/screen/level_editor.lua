local LevelEditor = Screen:extend()

local Tile = require "tile.tile"

local TILE_SIZE = 8

local shift_chars = {
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	[";"] = ":",
	["'"] = "\"",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
}

local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()_+-=[]{}|;':\",.<>/?\\"

function LevelEditor:new(x, y, width, height)
	self.prevmpos = Vec2(0, 0)
	self.mpos = Vec2(0, 0)
	self.mdxy = Vec2(0, 0)
	self.mcell = Vec2(0, 0)
	self.lmb = 0
	self.mmb = 0
	self.rmb = 0

	self.offset = Vec2(0, 0)

	-- paint, fill, rectangle_start, rectangle_end
	self.mode = "paint"

	self.painting = false
	self.erasing = false
	self.blocks_input = true

	self.tiles = {}

	self.edit_history = {}
	self.edit_future = {}

    self.active_key = 1
	
	self.state = "draw"

	self.notify_text = ""
	self.notify_text_alpha = 0

	self.clear_color = palette.darkgreyblue

    self.character_sprites = {}
	
    for k, v in pairs(tilesets.get_all()) do
		self:load_tileset(k, v)
	end

	LevelEditor.super.new(self, x, y, width, height)

	input.signals.key_pressed:connect(
        function(key)
			local active_area = self:get_active_section()
			if active_area == "draw" then
				self:on_key_pressed_drawing_area(key)
			end
        end)
		
	input.signals.mouse_pressed:connect(
        function(x, y, button)
            local active_area = self:get_active_section()
			if active_area == "draw" then
				self:on_mouse_pressed_drawing_area(x, y, button)
			end
		end)
end

function LevelEditor:load_tileset(tileset_name, ts)
    self.num_tiles = self.num_tiles or 0
	local c = 0
    for i, tile in ipairs(ts.tiles) do
        self.character_sprites[i + self.num_tiles] = tile
        c = c + 1
    end
	self.num_tiles = self.num_tiles + c
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
			self:notify("todo: save")
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
	
	if #key == 1 then
		if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
			self.active_key = shift_chars[key]
		else
			if key == "d" then
				self.mode = "paint"
				self:notify("Mode: Paint")
			elseif key == "f" then
				self.mode = "fill"
				self:notify("Mode: Fill")
			else
				local num = tonumber(key)
				if num then
					self.active_key = num
				end
			end
		end
	end
end

function LevelEditor:on_mouse_pressed_drawing_area(x, y, button)
    if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
        return
    end
    if self.mode == "fill" then
        if button == 1 or button == 2 then
            self:update_history()
            self:flood_fill(self.mcell.x, self.mcell.y, button == 1 and self.active_key or nil)
        end
    end
end

function LevelEditor:update_mouse_drawing_area(dt)
    if self.mmb ~= nil then
        self.offset.x = self.offset.x + self.mdxy.x
        self.offset.y = self.offset.y + self.mdxy.y
    end

    if self.lmb ~= nil then
        local cx, cy = floor(self.mpos.x / TILE_SIZE), floor(self.mpos.y / TILE_SIZE)
        if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
            self.active_key = self:get_tile(cx, cy) or self.active_key
        else
            if self.mode == "paint" then
                if not self.painting then self:update_history() end
                for _, point in ipairs(bresenham_line(self.prevmpos.x, self.prevmpos.y, self.mpos.x, self.mpos.y)) do
                    local cx, cy = floor(point.x / TILE_SIZE), floor(point.y / TILE_SIZE)
                    self:set_tile(cx, cy, self.active_key)
                end
                self.painting = true
            end
        end
    else
        self.painting = false
    end

    if self.rmb ~= nil then
        local cx, cy = floor(self.mpos.x / TILE_SIZE), floor(self.mpos.y / TILE_SIZE)
        if self.mode == "paint" then
            if not self.erasing then self:update_history() end
            self:set_tile(cx, cy, nil)
            self.erasing = true
        end
    else
        self.erasing = false
    end
end

function LevelEditor:get_active_section()
	if self.state == "draw" then
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
	self.mpos.x = floor(input.mouse.pos.x - self.offset.x)
	self.mpos.y = floor(input.mouse.pos.y - self.offset.y)
	self.mdxy.x = input.mouse.dxy.x
	self.mdxy.y = input.mouse.dxy.y
	self.mcell.x = floor(self.mpos.x / TILE_SIZE)
	self.mcell.y = floor(self.mpos.y / TILE_SIZE)

	self.lmb = input.mouse.lmb
	self.mmb = input.mouse.mmb
	self.rmb = input.mouse.rmb

	local active_area = self:get_active_section()
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

function LevelEditor:flood_fill(cx, cy, tile)
	local tile_to_change = self:get_tile(cx, cy)

	tile = tile or " "

	if tile == tile_to_change then return end

	local min_x, min_y, max_x, max_y = self:get_bounds()
	local check_solid = function(c2x, c2y)
		if c2x < min_x or c2x > max_x or c2y < min_y or c2y > max_y then
			return true
		end
		local check_tile = self:get_tile(c2x, c2y)
		if check_tile == tile_to_change then
			return false
		end
		return true
	end
	local fill = function(c2x, c2y)
		self:set_tile(c2x, c2y, tile)
	end
	flood_fill(cx, cy, fill, check_solid)
end

function LevelEditor:draw()
	LevelEditor.super.draw(self)
	graphics.push()
	graphics.origin()
	graphics.set_color(palette.white)
	graphics.translate(floor(self.offset.x), floor(self.offset.y))
	graphics.set_font(graphics.font["PixelOperatorMono8-Bold"])

	-- if debug.can_draw() then
	-- end
	self:draw_tiles()
	self:draw_level_grid()

	local key_string = tostring(self.active_key)

	graphics.set_color(palette.black)
	-- graphics.print(key_string, self.mpos.x + 2, self.mpos.y + 2)
	-- graphics.points(self.mpos.x + 1, self.mpos.y + 1)


	graphics.set_color(1, 1, 1, 0.25)
    graphics.rectangle("line", self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE, TILE_SIZE + 1, TILE_SIZE + 1)
	
	graphics.set_color(palette.white)
    if self.character_sprites[self.active_key] then
        graphics.set_color(palette.white, 0.75)
        self.character_sprites[self.active_key]:draw(self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE)
		graphics.set_color(palette.white, 0.35)
    end
	
	graphics.print(key_string, self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE)

	graphics.set_color(palette.white)

	-- graphics.points(self.mpos.x, self.mpos.y)
	
	graphics.origin()

	graphics.set_font(graphics.font["PixelOperator8"])
	graphics.set_color(palette.white)
	graphics.print(self.mode, 0, 0)

	if debug.enabled then 
		dbg("mcell", self.mcell)
	end
	if self.notify_text ~= "" then
		graphics.set_color(palette.white, self.notify_text_alpha)
		graphics.print(self.notify_text, 0, self.viewport_size.y - 8)
	end

	graphics.pop()
end

function LevelEditor:tile_draw(char, x, y)
	local sprite = self.character_sprites[char]
	if sprite then
		if sprite.draw then
			sprite:draw(x, y)
		else
			graphics.draw(self.character_sprites[char], x, y)
		end
	elseif type(char) == string then
		graphics.print(char, x, y)
	else
		graphics.print(tostring(char):sub(1, 1), x, y)
	end
end

function LevelEditor:tile_color(char)
	if self.character_sprites[char] then
		return palette.white
	end
	if type(char) == "number" then
		return palette.red
	end
	if char == nil then
		return palette.black
	end
	if char == "#" or char == "." then
		return palette.darkgreyblue
	end
	if string.match("0123456789", char) then
		return palette.green
	end
	return palette.white
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
		if ((start_x + (i - 1) * TILE_SIZE)) % self.viewport_size.x == 0 then
			graphics.set_color(1, 1, 1, 0.15)
		end
		graphics.line(start_x + i * TILE_SIZE, start_y, start_x + i * TILE_SIZE, end_y)
	end
	for i = 1, graphics.main_viewport_size.y / TILE_SIZE + 3 do
		graphics.set_color(1, 1, 1, 0.02)
		if ((start_y + (i - 1) * TILE_SIZE)) % self.viewport_size.y == 0 then
			graphics.set_color(1, 1, 1, 0.15)
		end

		graphics.line(start_x, start_y + i * TILE_SIZE, end_x, start_y + i * TILE_SIZE)
	end



	graphics.pop()
end

function LevelEditor:get_level_string()
	local min_x, min_y, max_x, max_y = self:get_bounds()
	local level_string = ""
	for y = min_y, max_y do
		local line = ""
		for x = min_x, max_x do
			local char = self:get_tile(x, y)
			if type(char) ~= "string" then
				return "invalidcharacters"
			end
			if char == "\n" or char == " " or char == nil then
				char = "_"
			end
			line = line .. char
		end
		local line1 = string.strip_whitespace(line, false, true)
		local line2 = string.strip_char(line1, "_", false, true)
		level_string = level_string .. line2 .. "\n"
	end
	print(level_string)
	return level_string
end

function LevelEditor:get_tile(x, y)
	if self.tiles[y] == nil then
		return nil
	end

	return self.tiles[y][x] or " "
end

function LevelEditor:build_from_level_string(level_string)
	if type(level_string) ~= "string" then
		return
	end
	local lines = string.split(level_string, "\n")
	self.tiles = {}

	for y = 1, #lines do
		local line = lines[y]
		if string.strip_whitespace(line) == "" then
			y = y - 1
			goto continue
		end

		local len = #line
		if line:sub(len, len) == "" then
			line = line:sub(1, len - 1)
		end
		for x = 1, len do
			self:set_tile(x, y, line:sub(x, x))
		end
		::continue::
	end
end

function LevelEditor:world_to_tile(x, y)
	return floor(x / TILE_SIZE), floor(y / TILE_SIZE)
end

function LevelEditor:tile_to_world(x, y)
	return x * TILE_SIZE, y * TILE_SIZE
end

function LevelEditor:set_tile(x, y, char)
	local in_charset = false
	for i = 1, #charset do
		if charset:sub(i, i) == char then
			in_charset = true
			break
		end
	end
	if not in_charset and type(char) == "string" then
		char = nil
	end
	if char == " " or char == "\n" or char == "_" then
		char = nil
	end
	if self.tiles[y] == nil then
		if char == nil then
			return
		end
		self.tiles[y] = {}
	end

	self.tiles[y][x] = char
end

function LevelEditor:get_bounds()
	local min_x = math.huge
	local min_y = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	for y, row in pairs(self.tiles) do
		for x, _ in pairs(row) do
			min_x = min(min_x, x)
			min_y = min(min_y, y)
			max_x = max(max_x, x)
			max_y = max(max_y, y)
		end
	end
	return min_x, min_y, max_x, max_y
end

function LevelEditor:draw_tiles()
	graphics.push()
	local camera_min_x, camera_min_y, camera_max_x, camera_max_y = -self.offset.x, -self.offset.y,
		self.viewport_size.x - self.offset.x, self.viewport_size.y - self.offset.y
	local min_x = floor(camera_min_x / TILE_SIZE)
	local min_y = floor(camera_min_y / TILE_SIZE)
	local max_x = floor(camera_max_x / TILE_SIZE)
	local max_y = floor(camera_max_y / TILE_SIZE)


	local bounds_min_x, bounds_min_y, bounds_max_x, bounds_max_y = self:get_bounds()

	-- if x >= bounds_min_x and x <= bounds_max_x and y >= bounds_min_y and y <= bounds_max_y then
	graphics.set_color(palette.black, 1)
	graphics.rectangle("fill", bounds_min_x * TILE_SIZE, bounds_min_y * TILE_SIZE,
		(bounds_max_x - bounds_min_x + 1) * TILE_SIZE, (bounds_max_y - bounds_min_y + 1) * TILE_SIZE)

	for y = min_y, max_y do
		for x = min_x, max_x do
			local tile = self:get_tile(x, y)
			if tile then
				graphics.set_color(self:tile_color(tile))
				self:tile_draw(tile, x * TILE_SIZE, y * TILE_SIZE)
				-- if self.character_sprites[tile] then
				-- 	graphics.draw(self.character_sprites[tile], x * TILE_SIZE, y * TILE_SIZE)
				-- else
				-- 	graphics.print(tile, x * TILE_SIZE, y * TILE_SIZE)
				-- end
				-- graphics.print(tile, x * TILE_SIZE, y * TILE_SIZE)
			end
		end
	end
	graphics.pop()
end

function LevelEditor:enter()
	self:update_history()
	-- love.mouse.setVisible(false)
end

function LevelEditor:exit()
	-- love.mouse.setVisible(true)
end

return LevelEditor
