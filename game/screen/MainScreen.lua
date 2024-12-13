local MainScreen = CanvasLayer:extend("MainScreen")

local GameLayer = CanvasLayer:extend("GameScreen")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local PauseLayer = CanvasLayer:extend("PauseLayer")

local ScrollingGameWorld = World:extend("ScrollingGameWorld")

local O = require("obj")

local SCROLL_SPEED = 1/2.5
local MAP_WIDTH = 10
local SCREEN_WIDTH = 176


OBJECT_MAP = {
	enemy = O.Enemy.Enemy,
	skullbird = O.Enemy.SkullBird,
	devil = O.Enemy.Devil,
	kebab = O.Misc.ScorePickup,
	screen_clear = O.Misc.ScreenClear,
	bear = O.Enemy.Bear,
	tower = O.Enemy.Tower,
}

function GameLayer:new()
    GameLayer.super.new(self)
	self:add_signal("level_complete")
    self.clear_color = palette.black
    signal.connect(input, "key_pressed", self, "on_key_pressed", function(key)
		if key == "tab" then
			signal.emit(self, "level_complete", true)
		end
	end)
end

function GameLayer:start(level)
	local level_name = level.map
    local direction = level.direction
	local map_color = level.map_color
	local cutscene = level.cutscene
    self:ref("world", self:add_world(ScrollingGameWorld(level_name, direction, map_color, cutscene)))
    signal.connect(self.world, "player_died", self, "on_player_died")
	signal.chain_connect("level_complete", self.world, self)
end

function GameLayer:on_player_died()
	local s = self.sequencer
    s:start(function()
        local prev_clear_color = self.clear_color
		local flash_color = Color.from_hex("ff0000")
        for i = 1, 3 do
            self.clear_color = palette.black
            s:wait(2)
            self.clear_color = flash_color
            s:wait(2)
        end
		self.clear_color = prev_clear_color
	end)
end


local GlobalState = Object:extend("GlobalState")

function GlobalState:new()
    GlobalState.super.new(self)
	signal.register(self, "extra_life_threshold_reached")
    self.score = 0
	self.high_score = 0
	self.lives = 3
    self.level = 1
	self.base_extra_life_threshold = 20000
	self.extra_life_threshold_increment = 10000
	self.extra_life_threshold_increment_counter = 1
	self.extra_life_threshold = self.base_extra_life_threshold
    self.levels = {
		{
            type = "game",
			map = "cutscene1",
			map_color = "00ff00",
			cutscene = "cutscene1",
        },
		{
            type = "game",
            map = "map1",
			map_color = "00ff00",
			direction = "up",
        },
		-- {
        --     type = "game",
        --     map = "bonus1",
		-- 	map_color = "8000ff",
        --     direction = "up",
		-- 	bonus = true,
        -- },
		-- {
        --     type = "game",
        --     map = "map2",
		-- 	map_color = "ff0000",
		-- 	direction = "up",
        -- },
		{
			type = "game",
			map = "cutscene2",
			map_color = "ff8000",
			cutscene = "cutscene2",
		},
		-- {
        --     type = "game",
        --     map = "map2",
		-- 	map_color = "00ff80",
		-- 	direction = "down",
        -- },
		-- {
		-- 	type = "game",
		-- 	map = "bonus2",
		-- 	map_color = "ff00ff",

		-- 	direction = "down",
		-- 	bonus = true,
		-- },
		{
			type = "game",
			map = "map2",
			map_color = "0000ff",
			direction = "down",
        },

        {
			type = "game",
			map = "cutscene3",
			map_color = "0000ff",
			cutscene = "cutscene3",
        },
        {
			type = "end",
		}
	}
end

function GlobalState:add_score(score)
    self.score = self.score + score
    if self.score > self.high_score then
        self.high_score = self.score
    end
	if self.score >= self.extra_life_threshold then
		self.extra_life_threshold = self.extra_life_threshold + self.base_extra_life_threshold + self.extra_life_threshold_increment * self.extra_life_threshold_increment_counter
		self.extra_life_threshold_increment_counter = self.extra_life_threshold_increment_counter + 1
		signal.emit(self, "extra_life_threshold_reached")
		self.lives = self.lives + 1
	end
end

local INFO_PANEL_RECT = Rect(SCREEN_WIDTH, 0, conf.viewport_size.x - SCREEN_WIDTH, conf.viewport_size.y)
local INFO_PANEL_COLOR = Color.from_hex("000000")

function HUDLayer:new()
    HUDLayer.super.new(self)
	signal.connect(global_state, "extra_life_threshold_reached", self, "on_extra_life_threshold_reached", function() 
		local s = self.sequencer
		s:start(function() 
			self.score_flash = true
			s:wait(60)
			self.score_flash = false
		end)
	end)
end

function HUDLayer:cool_text_1(x, y, text, color1, color2)
	graphics.set_color(color2)
    -- graphics.print_outline(color2, text, x+2, y+2)
    graphics.print_outline(color2, text, x+1, y+1)
    graphics.print_outline(color2, text, x+1, y)
    graphics.print_outline(color2, text, x, y)
	graphics.set_color(0, 0, 0, 0)
    graphics.print_outline(color2, text, x, y)
	graphics.set_color(palette.black)
    graphics.print(text, x, y - 1)
    graphics.set_color(color1)
    graphics.print(text, x, y)
	graphics.set_color(palette.white)
end

function HUDLayer:draw()
	graphics.set_font(graphics.font["PressStart2P-8"])
    graphics.set_color(INFO_PANEL_COLOR)
	graphics.rect("fill", INFO_PANEL_RECT)
	graphics.set_color(graphics.color_flash(0, 10))
	-- graphics.set_color(palette.black)
	graphics.rectangle("line", 1, 1, SCREEN_WIDTH-2, conf.viewport_size.y - 1)
    graphics.rectangle("line", 2, 2, SCREEN_WIDTH-2, conf.viewport_size.y - 3)
	-- graphics.set_color(graphics.color_flash(10, 10))
	graphics.rectangle("line", SCREEN_WIDTH, 2, conf.viewport_size.x - SCREEN_WIDTH - 1, conf.viewport_size.y - 2)
	graphics.rectangle("line", SCREEN_WIDTH, 1, conf.viewport_size.x - SCREEN_WIDTH - 0, conf.viewport_size.y - 2)


    local text_x = SCREEN_WIDTH + 4	
	local text_y = 4
	

	graphics.push()
    graphics.translate(text_x, text_y + 8)
	self:cool_text_1(16, 0, "Hi", "ffffff", "0000ff")

    -- graphics.set_color(graphics.color_flash(0, 5))
    -- graphics.rectangle("line", -2, -2, conf.viewport_size.x - SCREEN_WIDTH - 3, 16 + 4)
	if (not self.score_flash) or global_state.high_score > global_state.score or floor(self.tick / 2)% 2 == 0 then
		graphics.print_outline_no_diagonals(palette.black, global_state.high_score, 0, 12)
	end
    graphics.pop()
	
    graphics.push()
	
    graphics.translate(text_x, text_y + 40)
    self:cool_text_1(16, 0, "Score", "ffffff", "0000ff")
	if (not self.score_flash) or floor(self.tick / 2) % 2 == 0 then
		graphics.print_outline_no_diagonals(palette.black, global_state.score, 0, 12)
	end
    graphics.pop()
	
	graphics.push()
    graphics.translate(text_x, text_y + 72)
	self:cool_text_1(16, 0, "Mans", "ffffff", "0000ff")

	graphics.set_color(palette.white)
	-- graphics.set_color(graphics.color_flash(0, 5))
	-- graphics.rectangle("line", -2, -2, conf.viewport_size.x - SCREEN_WIDTH - 3, 16 + 4)
	-- graphics.set_color(palette.white)
	for i = 1, global_state.lives - 1 do
		graphics.draw(textures.player_stock, 10 * (i-1), 12, 0, 1, 1, 0, 1)
	end


	graphics.pop()

	graphics.translate(text_x, text_y + 104)
   graphics.push()
   graphics.set_color(palette.white)

    self:cool_text_1(16, 0, "Next", "ffffff", "0000ff")
	if (not self.score_flash) or floor(self.tick / 2) % 2 == 0 then
		graphics.print_outline_no_diagonals(palette.black, global_state.extra_life_threshold, 0, 12)
	end
    graphics.pop()

end

function MainScreen:new()
    MainScreen.super.new(self)
    global_state = GlobalState()
    self:ref("hud_layer", self:push(HUDLayer))


    local s = self.sequencer
    s:start(function()
        for _, level in ipairs(global_state.levels) do
            if self.game_layer then
                self.game_layer:destroy()
            end
            self:ref("game_layer", self:insert_layer(GameLayer, 2))
            if level.type == "cutscene" or level.type == "game" then
                if level.type == "cutscene" then
                    self:start_cutscene(level)
                else
                    self.game_layer:start(level)
                end
                s:wait_for_signal(self.game_layer, "level_complete")
                local success = unpack(s.signal_output)
                if not success then
                    -- TODO: transition to end screen
                    self:transition_to(MainScreen)
                    return
                end
            elseif level.type == "end" then
                -- TODO: transition to end screen
                self:transition_to(MainScreen)
                return
            end
        end
    end)
end

function MainScreen:start_cutscene(level)

end

function MainScreen:update(dt)
	MainScreen.super.update(self, dt)
    if self.input.debug_editor_toggle_pressed then
        self:transition_to("LevelEditor")
    end
    if self.input.menu_pressed then
        self:push_to_parent(PauseLayer)
    end
end

ScrollingGameWorld.scroll_events = {
	"map1"
}

local ObjectScore = require("fx.object_score")

function ScrollingGameWorld:new(level_name, direction, map_color, cutscene)
	ScrollingGameWorld.super.new(self)
	self:add_spatial_grid("object_grid")

    self:add_signal("level_complete")
	self:add_signal("player_died")

	self:implement(Mixins.Behavior.GridTerrainQuery)

    signal.connect(global_state, "extra_life_threshold_reached", self, "on_extra_life_threshold_reached", function()
		local s = self.sequencer
		s:start(function()
            s:wait_for(function() return self.player ~= nil end)
			self:play_sfx("player_1up")
			self:add_object(ObjectScore(self.player.pos.x, self.player.pos.y - 24, 0, "1UP"))
		end)
	end)
	
	self:create_draw_grid()
    self:create_camera()
	self:create_bump_world()
    self.map = GameMap.load(level_name)
	self.map_color = map_color
	self.level_name = level_name
	self.map:build()
	self.map:bump_init(self.bump_world)

	self.scroll = 0
	self.scroll_direction = direction == "up" and -1 or 1
	self.cutscene = cutscene
    self.scroll_size = conf.viewport_size.y
	
	self.scrolling = true

    self.map_width = MAP_WIDTH

	for _, sfx in ipairs({
		"enemy_die",
		"enemy_hit_by_bullet",
		"player_pickup",
		"player_bomb",
		"enemy_spawn",
		"enemy_bonerattle",
		"enemy_birdspawn",
		"enemy_birdswoop",
        "pickup_spawn",
		"enemy_bear_die",
		"enemy_bear_spawn",
        "enemy_demon_spawn",
        "enemy_demon_attack",
        "player_death",
		"player_respawn",
		"player_1up",
	}) do
		self:add_sfx(sfx)
	end


	if not cutscene then
		audio.play_music(audio.music.loop)
	end


	local spawn_y_offset = self.scroll_direction == -1 and 0 or -11

    self.spawn_function_map = {
        flyer1 = function(x, y, z)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
            y = y + 1 + spawn_y_offset
            local wx, wy = self.map.cell_to_world(x, y, z)
            self:add_object(O.Enemy.Flyer(wx, wy)).curve_amount = 1
        end,
        flyer2 = function(x, y, z)
            print(y)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
            local s = self.sequencer
            y = y + 1 + spawn_y_offset
            s:start(function()
                for i = 1, 3 do
                    local wx, wy = self.map.cell_to_world(x, y, z)
                    self:add_object(O.Enemy.Flyer(wx, wy)).curve_amount = 0.1
                    s:wait(20)
                    y = y + 3
                end
            end)
        end,
        flyer3 = function(x, y, z)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
            local wx, wy = self.map.cell_to_world(x, y + 10 + spawn_y_offset, z)
            local s = self.sequencer
            s:start(function()
                s:wait(12)
				local obj = O.Enemy.Flyer(wx, wy)
				obj.curve_amount = -1.6
                self:add_object(obj)
            end)
        end,
        skull_up = function(x, y, z)
            if self.scroll_direction == 1 then return end
            local despawn_y = self:get_scroll_despawn_ycell() - self.scroll_direction
            local wx, wy = self.map.cell_to_world(x, despawn_y, z)
            local obj = O.Enemy.SkullBird(wx, wy)
            obj.reversed = true
            self:add_object(obj)
        end,
		skull_down = function(x, y, z)
			if self.scroll_direction == -1 then return end
            local despawn_y = self:get_scroll_despawn_ycell() - self.scroll_direction
            local wx, wy = self.map.cell_to_world(x, despawn_y, z)
            local obj = O.Enemy.SkullBird(wx, wy)
            obj.reversed = true
            self:add_object(obj)
		end
	}

    self:process_map_data(self.map)
	-- self.map:erase_tiles()
    self.draw_sort = self.y_sort
	self.scroll_speed = SCROLL_SPEED
	
    self.room_size = conf.room_size

end

function ScrollingGameWorld:exit()
	audio.stop_music(audio.music.loop)
end


function ScrollingGameWorld:get_enemies_at_cell(x, y)
    local wx, wy = self.map.cell_to_world(x, y, 0)
    local objects = {}
    for _, obj in ipairs(self.object_grid:query(wx, wy, 1, 1)) do
        if not obj.is_enemy then
            goto continue
        end
        local cell_x, cell_y = self.map.world_to_cell(obj.pos.x, obj.pos.y, 0)
        if cell_x == x and cell_y == y then
            table.insert(objects, obj)
        end
        ::continue::
    end
    return objects
end

function ScrollingGameWorld:on_player_death()
    local s = self.sequencer
    s:start(function()
		self.scrolling = false
		s:wait(60)
        global_state.lives = global_state.lives - 1
		if global_state.lives <= 0 then
			s:wait(30)
			self:emit_signal("level_complete", false)
		else
            -- local cy = self:get_scroll_despawn_ycell() + self.scroll_direction * 2
            -- local middle = MAP_WIDTH / 2
			-- local cx = middle
			-- local c = 1
			-- while not self:is_cell_solid(cx, cy, 0) do
            --     local sign_ = c % 2 == 0 and 1 or -1
            --     cx = cx + sign_ * floor(c / 2)
            --     c = c + 1
			-- 	if c > MAP_WIDTH then
			-- 		break
			-- 	end
			-- end
            -- local px, py = self.map.cell_to_world(cx, cy, 0)
            self:spawn_player(self.player_x, self.player_y, true)
			self:clamp_player(false)
			self.scrolling = true
			self:play_sfx("player_respawn")
		end
    end)
	self:emit_signal("player_died")
end

function ScrollingGameWorld:spawn_player(x, y, invuln)
	if invuln == nil then invuln = true end
    self:ref("player", self:add_object(O.Player.DeliveryGuy(x, y, invuln)))
	signal.connect(self.player, "moved", self, "on_player_moved", function() self.player_x, self.player_y = self.player.pos.x, self.player.pos.y end)
	signal.connect(self.player, "died", self, "on_player_death")
	self.player.cutscene = self.cutscene
end

function ScrollingGameWorld:process_map_data(map)
	local min_x, min_y, max_x, max_y, min_z, max_z = map:get_bounds()
	
	local min_x_world, min_y_world = map.cell_to_world(min_x, min_y, min_z)
	local max_x_world, max_y_world = map.cell_to_world(max_x, max_y, max_z)
	local middle_y = min_y_world + (max_y_world - min_y_world) / 2


	local player

    for x, y, z, object in map:query_objects_world_space() do
        if object == "player" then
			if player == nil then 
				player = {x = x, y = y}
            elseif self.scroll_direction == -1 then
				if y > player.y then
					player = {x = x, y = y}
				end
			else
				if y < player.y then
					player = {x = x, y = y}
				end
			end
		end
	end

	self:spawn_player(player.x, player.y, false)


	self.world_bounds = Rect(min_x_world, min_y_world - tilesets.TILE_SIZE, max_x_world - min_x_world, max_y_world - min_y_world + tilesets.TILE_SIZE)
	self.cell_bounds = Rect(min_x, min_y, max_x - min_x, max_y - min_y)
	print("world bounds", self.world_bounds)
	print("cell bounds", self.cell_bounds)

	self.middle = Vec2(self.world_bounds.x + self.world_bounds.width / 2, self.world_bounds.y + self.world_bounds.height / 2)

end

function ScrollingGameWorld:enter()
	if not self.player then return end
	ScrollingGameWorld.super.enter(self)
    self:set_scroll(self.player.pos.y - self.viewport_size.y / 2)
	self:initial_spawn()
end

function ScrollingGameWorld:initial_spawn()
	-- if self.scroll_direction < 0 then
	-- 	for ycell = self:get_scroll_spawn_ycell(), self.cell_bounds.y + self.cell_bounds.height, 1 do
	-- 		self:process_objects_at_ycell(ycell)
	-- 	end
	-- else
	-- 	for ycell = self:get_scroll_spawn_ycell(), self.cell_bounds.y, -1 do
	-- 		self:process_objects_at_ycell(ycell)
	-- 	end
	-- end
end

function ScrollingGameWorld:get_scroll_spawn_ycell()
	local scroll = self.scroll
	local scroll_direction = self.scroll_direction
	local scroll_size = self.scroll_size


	if scroll_direction < 0 then
		local _, y, _ =  self.map.world_to_cell(0, scroll, 0)
		return y
	else
		local _, y, _ =  self.map.world_to_cell(0, scroll + scroll_size, 0)
		return y
	end
end

function ScrollingGameWorld:get_scroll_despawn_ycell()
	local scroll = self.scroll
	local scroll_direction = self.scroll_direction
	local scroll_size = self.scroll_size


	if scroll_direction > 0 then
		local _, y, _ =  self.map.world_to_cell(0, scroll, 0)
		return y
	else
		local _, y, _ =  self.map.world_to_cell(0, scroll + scroll_size, 0)
		return y
	end
end

function ScrollingGameWorld:clamp_player(allow_death)
	if allow_death == nil then allow_death = true end
    if self.player then
		self.player:tp_to(clamp(self.player.pos.x, tilesets.TILE_SIZE / 2 + tilesets.TILE_SIZE, MAP_WIDTH * tilesets.TILE_SIZE + tilesets.TILE_SIZE / 2 - tilesets.TILE_SIZE), self.player.pos.y)
		local y = self.player.pos.y
		if y < self.scroll + 8 then 
			if y < self.scroll and allow_death then 
				self.player:die()
			else
				self.player:move(0, self.scroll + 8 - y) 
			end
		end
		if y > self.scroll + self.scroll_size - 8 then 
			if y > self.scroll + self.scroll_size and allow_death then
				self.player:die()
			else
				self.player:move(0, (self.scroll + self.scroll_size - 8) - y) 
			end
		end

	end
end

function ScrollingGameWorld:set_scroll(scroll)
    local scroll = clamp(scroll, self.world_bounds.y + tilesets.TILE_SIZE / 2, self.world_bounds.y + self.world_bounds.height - self.viewport_size.y + tilesets.TILE_SIZE / 2)
	self.scroll = scroll
end

function ScrollingGameWorld:update(dt)

	ScrollingGameWorld.super.update(self, dt)
	self:update_camera(dt)

	if self.scrolling and not self.cutscene then
		self:set_scroll(self.scroll + dt * self.scroll_speed * self.scroll_direction)
	end


	local new_scroll_spawn_ycell = self:get_scroll_spawn_ycell()
	if new_scroll_spawn_ycell ~= self.scroll_spawn_ycell then
		self.scroll_spawn_ycell = new_scroll_spawn_ycell
		self:process_objects_at_ycell(new_scroll_spawn_ycell)
	end

	local despawn_ycell = self:get_scroll_despawn_ycell()
	self.scroll_despawn_ycell = despawn_ycell
	
	
	self:clamp_player()

    for _, obj in self.objects:ipairs() do
        local _, y = self.map.world_to_cell(obj.pos.x, obj.pos.y, 0)

        -- print(self.scroll_direction, y, self.scroll_despawn_ycell)
        local should_despawn = (self.scroll_direction < 0 and y > self.scroll_despawn_ycell) or
        (self.scroll_direction > 0 and y < self.scroll_despawn_ycell)
        -- print(should_despawn)
        if should_despawn and obj ~= self.camera and obj.tick and obj.tick > 60 then
			obj:destroy()
		end
	end
end

function ScrollingGameWorld:process_objects_at_ycell(ycell)
	local min_x, min_y, max_x, max_y, min_z, max_z = self.map:get_bounds()
	for x, y, z, object in self.map:query_objects(min_x, ycell, max_x, ycell, min_z, max_z) do
        if OBJECT_MAP[object] then
            local x_, y_, z_ = self.map.cell_to_world(x, y, z)
            self:add_object(OBJECT_MAP[object](x_, y_, z_))
		elseif self.spawn_function_map[object] then
			self.spawn_function_map[object](x, y, z)
		end
	end
end

function ScrollingGameWorld:add_object(obj)
    local obj = ScrollingGameWorld.super.add_object(self, obj)
	self:add_to_spatial_grid(obj, "object_grid")
	return obj
end

-- if not self.player then return end
function ScrollingGameWorld:update_camera(dt)

	-- local target_x, target_y =
	-- 	stepify_floor(self.player.pos.x + self.room_size.x, self.room_size.x) - self.room_size.x / 2,
	-- 	stepify_floor(self.player.pos.y + self.room_size.y, self.room_size.y) - self.room_size.y / 2
	-- self.camera.pos.x, self.camera.pos.y = splerp_vec_unpacked(self.camera.pos.x, self.camera.pos.y, target_x, target_y, dt, seconds_to_frames(4))
    -- self.camera.pos.x, self.camera.pos.y = target_x, target_y

    self.camera.pos.x = self.viewport_size.x / 2
	self.camera.pos.y = self.viewport_size.y / 2 + self.scroll

	-- self.camera.pos.y = stepify_floor(self.camera.pos.y, 1) 

	
end

function ScrollingGameWorld:get_cells_on_screen()
	local spawn_y = self:get_scroll_spawn_ycell()
	local despawn_y = self:get_scroll_despawn_ycell()
	local scroll_height = self.scroll_size

	local min_y = min(spawn_y, despawn_y)
	local max_y = max(spawn_y, despawn_y)


	local cells = {}
	for y=min_y, max_y do
		for x=1, MAP_WIDTH do
			table.insert(cells, Vec2(x, y))
		end	
	end
	return cells
end

function ScrollingGameWorld:draw()
	
	local spawn_y = self:get_scroll_spawn_ycell()
	local despawn_y = self:get_scroll_despawn_ycell()

	local min_y = min(spawn_y, despawn_y)
	local max_y = max(spawn_y, despawn_y)


	graphics.set_color(palette.white)
	local x1, y1, w, h, x2, y2 = self:get_draw_rect()
    self.map:draw_world_space("dynamic", x1, y1, x2, y2, nil, 0)


	for y=min_y, max_y do
		for x=0, MAP_WIDTH do			
            local wx, wy = self.map.cell_to_world(x, y, 0)
			local color = self.map_color
            if self:is_cell_solid(x, y, 0) then
				if self.tick % 2 == 0 and abs((y % 38) - (floor(self.scroll_direction * -self.tick * self.scroll_speed) % 38)) < 4 then
					color = graphics.color_flash(y * 5, 4)
				end
					-- color.a = remap(stepify(pow(sin(((y) / 1) + (self.scroll / 3)), 2), 0.25), 0, 1, 0.25, 1)
				graphics.set_color(color)
				local tile = self:get_tile(x, y, 0)
				graphics.draw(tile, wx - tilesets.TILE_SIZE / 2, wy - tilesets.TILE_SIZE / 2, 0, 1, 1, tile.rotation)
			end
		end
	end

	-- self.map:draw("static", nil, nil, nil, nil, nil, 0)
    ScrollingGameWorld.super.draw(self)

	graphics.set_color(palette.white)
    if debug.can_draw() then
        graphics.push("all")
        graphics.set_color(palette.yellow)
        graphics.line(0, self.scroll - self.scroll_direction, SCREEN_WIDTH, self.scroll - self.scroll_direction)
        local _, y = self.map.cell_to_world(0, self.scroll_spawn_ycell, 0)
        if y then
            graphics.set_color(palette.green)
            graphics.line(0, y, SCREEN_WIDTH, y)
            local _, y = self.map.cell_to_world(0, self.scroll_despawn_ycell, 0)
            graphics.set_color(palette.blue)
            graphics.line(0, y, SCREEN_WIDTH, y)
        end
        graphics.pop()
    end





    self.map:draw_world_space("dynamic", x1, y1, x2, y2, 1, nil)
	-- self.map:draw("static", nil, nil, nil, nil, 1, nil)
	
	-- graphics.draw_centered(spritesheet[2], self.player.pos.x, self.player.pos.y)
end


-- function ScrollingGameWorld:get_object_draw_position(obj)
-- 	return stepify_floor(obj.pos.x, 1), stepify_floor(obj.pos.y, 1)
-- end

return MainScreen
