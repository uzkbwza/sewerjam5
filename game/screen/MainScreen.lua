local MainScreen = CanvasLayer:extend("MainScreen")

local GameLayer = CanvasLayer:extend("GameScreen")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local PauseLayer = CanvasLayer:extend("PauseLayer")
local ContinueLayer = CanvasLayer:extend("ContinueLayer")
local TitleScreen = CanvasLayer:extend("TitleScreen")
local ScrollingGameWorld = World:extend("ScrollingGameWorld")
local GuideScreen = CanvasLayer:extend("GuideScreen")
local HighScoreEntryScreen = CanvasLayer:extend("HighScoreEntryScreen")
local HighScoreScreen = CanvasLayer:extend("HighScoreScreen")

local DeathFx = require"fx.death_effect"

local O = require("obj")

local SCROLL_SPEED = 1/2.5
local MAP_WIDTH = 10
local SCREEN_WIDTH = 176
local LIVES = 3

local START_SCREEN = 1

local SKIP_CUTSCENE = true

local FONT = graphics.font["PressStart2P-8"]

local HIGH_SCORES = {}
local NUM_SHOWN_HIGH_SCORES = 10

local function is_valid_high_score(score)
    if #HIGH_SCORES >= NUM_SHOWN_HIGH_SCORES then
        return score > HIGH_SCORES[NUM_SHOWN_HIGH_SCORES][2]
    end
    return true
end

local OBJECT_MAP = {
	enemy = O.Enemy.Enemy,
	skullbird = O.Enemy.SkullBird,
	devil = O.Enemy.Devil,
	kebab = O.Misc.ScorePickup,
	screen_clear = O.Misc.ScreenClear,
	bear = O.Enemy.Bear,
	tower = O.Enemy.Tower,
	warning = O.Enemy.Warning,
    level_complete_tile = O.Misc.LevelCompleteTile,
	robot = O.Enemy.Robot,
	wall = O.Enemy.Wall,
}

local GlobalState = Object:extend("GlobalState")

function GlobalState:new()
    GlobalState.super.new(self)
	signal.register(self, "extra_life_threshold_reached")
    self.score = 0
	self.high_score = HIGH_SCORES[1] and HIGH_SCORES[1][2] or 0
	self.lives = LIVES
	self.continues_used = 0
    self.level = 1
	self.kebabs = 0
	self.base_extra_life_threshold = 20000
	self.cutscene = false
	self.extra_life_threshold_increment = 10000
	self.extra_life_threshold_increment_counter = 1
    self.extra_life_threshold = self.base_extra_life_threshold
    self.hudless_level = false
	
    self.levels = {
		{
            type = "game",
			map = "cutscene1",
			cutscene = "cutscene1",
			map_color = {
                { 0, "00ff00" },
				-- { 0.5, "0000ff" },
                -- { , "ff0000" },
			},
        },

        {
			type = "guide_screen",
		},

		{
            type = "game",
            map = "map1",
            map_color = {
                { 0, "00ff00" },
                -- { 0.75, "80ff00" },
                -- { 1.5,  "ffff00" },
                -- { 2.25, "ff8000" },
			},
            song = "loop",
			direction = "up",
			number = 1,
		},
		
		{
			type = "game",
			map = "cutscene2",
            cutscene = "cutscene2",
			cutscene_offset = false,
			map_color = {
				{ 0, "ff8000" },
			},
			direction = "up",
			
        },
		
		
		{
			type = "game",
			map = "map2",
			music_volume = 0.75,
			direction = "down",
            number = 2,
			song="level2",
			map_color = {
				{ 0, "0000ff" },
			},
        },

        {
			type = "game",
			map = "cutscene3",
			cutscene = "cutscene3",
			map_color = { 
				{ 0, "8000ff" },
			},
        },

        {
			type = "end",
        },
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
	-- self.blocks_render = true
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
    graphics.print(text, x, y + 1)
    graphics.set_color(color1)
    graphics.print(text, x, y)
	graphics.set_color(palette.white)
end

function HUDLayer:draw_cutscene() 
	graphics.set_color(palette.black)
	graphics.rectangle("line", 1, 1, self.viewport_size.x - 1, self.viewport_size.y - 1)
	graphics.rectangle("line", 2, 2, self.viewport_size.x - 3, self.viewport_size.y - 3)
end

function HUDLayer:draw()

	graphics.set_font(FONT)
    if global_state.cutscene then
        self:draw_cutscene()
        return
    end

    if global_state.hudless_level then
        self:draw_cutscene()
		self:cool_text_1(2, 2, "Hi", "ffffff", (graphics.color_flash(0, 3)))
		if (not self.score_flash) or global_state.high_score > global_state.score or floor(self.tick / 2)% 2 == 0 then
			graphics.set_color(palette.black)
            graphics.printf(global_state.high_score, 9, 3, 8 * 9, "right")
			graphics.set_color(palette.white)
			graphics.printf(global_state.high_score, 8, 2, 8 * 9, "right")
		end
		self:cool_text_1(self.viewport_size.x - 96, 2, "Score", "ffffff", (graphics.color_flash(1, 3)))
        if (not self.score_flash) or global_state.high_score > global_state.score or floor(self.tick / 2) % 2 == 0 then
            graphics.set_color(palette.black)
            graphics.printf(global_state.score, self.viewport_size.x - 80 + 9, 3, 8 * 9, "right")
            graphics.set_color(palette.white)
            graphics.printf(global_state.score, self.viewport_size.x - 80 + 8, 2, 8 * 9, "right")
        end
        self:cool_text_1(2, self.viewport_size.y - 9, "Mans", "ffffff", (graphics.color_flash(2, 3)))
        for i = 1, global_state.lives - 1 do
			graphics.set_color(palette.black)
            graphics.draw(textures.player_stock, 30 + 10 * (i) + 1, self.viewport_size.y - 8 + 1, 0, 1, 1, 0, 1)
			graphics.set_color(palette.white)
			graphics.draw(textures.player_stock, 30 + 10 * (i), self.viewport_size.y - 8, 0, 1, 1, 0, 1)
		end

		self:cool_text_1(self.viewport_size.x - 96, self.viewport_size.y - 9, "Next", "ffffff",	(graphics.color_flash(3, 3)))
		graphics.set_color(palette.black)
		graphics.printf(global_state.extra_life_threshold, self.viewport_size.x - 80 + 9, self.viewport_size.y - 7, 8 * 9, "right")
		graphics.set_color(palette.white)
		graphics.printf(global_state.extra_life_threshold, self.viewport_size.x - 80 + 8, self.viewport_size.y - 8, 8 * 9, "right")
		return
	end

	graphics.set_color(INFO_PANEL_COLOR)
	graphics.rect("fill", INFO_PANEL_RECT)
	graphics.set_color(graphics.color_flash(0, 30))

	graphics.rectangle("line", SCREEN_WIDTH+1, 2, self.viewport_size.x - SCREEN_WIDTH - 2, self.viewport_size.y - 3)

    local text_x = SCREEN_WIDTH + 4	
	local text_y = 4

	graphics.push()
    graphics.translate(text_x, text_y + 8)
	self:cool_text_1(0, 0, "Hi", "ffffff", "0000ff")

    -- graphics.set_color(graphics.color_flash(0, 5))
    -- graphics.rectangle("line", -2, -2, conf.viewport_size.x - SCREEN_WIDTH - 3, 16 + 4)
	if (not self.score_flash) or global_state.high_score > global_state.score or floor(self.tick / 2)% 2 == 0 then
		graphics.printf(global_state.high_score, 0, 12, 8 * 9, "right")
	end
    graphics.pop()
	
    graphics.push()
	
    graphics.translate(text_x, text_y + 40)
    self:cool_text_1(0, 0, "Score", "ffffff", "0000ff")
	if (not self.score_flash) or floor(self.tick / 2) % 2 == 0 then
		graphics.printf(global_state.score, 0, 12, 8 * 9, "right")
	end
    graphics.pop()
	
	graphics.push()
    graphics.translate(text_x, text_y + 72)
	self:cool_text_1(0, 0, "Mans", "ffffff", "0000ff")

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

    self:cool_text_1(0, 0, "Next", "ffffff", "0000ff")
	if (not self.score_flash) or floor(self.tick / 2) % 2 == 0 then
		graphics.printf(global_state.extra_life_threshold, 0, 12, 8 * 9, "right")
	end
    graphics.pop()

end

function TitleScreen:new()
    TitleScreen.super.new(self)
    self:add_signal("selected")
end

function TitleScreen:update(dt)
    if input.confirm_pressed then
        signal.emit(self, "selected")
		audio.play_sfx(audio.sfx.cutscene_boop)
    end
end


function HighScoreEntryScreen:new()
	HighScoreEntryScreen.super.new(self)
    self.alphabet = string.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    self.slot_selected = 1
    self.slot_1 = "A"
    self.slot_2 = "A"
    self.slot_3 = "A"
    self:add_signal("selected")
    self.selecting = true
    self.blocks_input = true
    self.blocks_logic = true
	self.blocks_render = true
end

function HighScoreEntryScreen:update(dt)
    local input = self.input
    if self.selecting then
        if input.move_left_pressed or input.move_right_pressed then
            self.slot_selected = self.slot_selected + input.move_digital.x
            if self.slot_selected > 3 then
                self.slot_selected = 1
            end
            if self.slot_selected < 1 then
                self.slot_selected = 3
            end
			audio.play_sfx(audio.sfx.cutscene_boop)
        end
        if input.aim_left_pressed or input.aim_right_pressed then
            self.slot_selected = self.slot_selected + input.aim_digital.x
            if self.slot_selected > 3 then
                self.slot_selected = 1
            end
            if self.slot_selected < 1 then
                self.slot_selected = 3
            end
			audio.play_sfx(audio.sfx.cutscene_boop)
        end
        if input.move_up_pressed or input.move_down_pressed then
            local index = table.find(self.alphabet, self["slot_" .. self.slot_selected])
            -- local letter = self.alphabet[index]
            local next_index = index - input.move_digital.y
            if next_index > #self.alphabet then
                next_index = 1
            end
            if next_index < 1 then
                next_index = #self.alphabet
            end
            local next_letter = self.alphabet[next_index]
            if next_letter then
                self["slot_" .. self.slot_selected] = next_letter
            end
			audio.play_sfx(audio.sfx.cutscene_boop)
        end
        if input.aim_up_pressed or input.aim_down_pressed then
            local index = table.find(self.alphabet, self["slot_" .. self.slot_selected])
            -- local letter = self.alphabet[index]
            local next_index = index - input.aim_digital.y
            if next_index > #self.alphabet then
                next_index = 1
            end
            if next_index < 1 then
                next_index = #self.alphabet
            end
            local next_letter = self.alphabet[next_index]
            if next_letter then
                self["slot_" .. self.slot_selected] = next_letter
            end
			audio.play_sfx(audio.sfx.cutscene_boop)
        end


        if input.confirm_pressed then
            self.selecting = false
            self:add_high_score()
            self:start_timer(60, function() self:emit_signal("selected") end)
			audio.play_sfx(audio.sfx.cutscene_boop)
        end
    end
end

function HighScoreEntryScreen:draw()
    graphics.set_color(palette.white)
	
	graphics.set_font(FONT)

	graphics.print("PRESS ENTER/START TO CONTINUE", self.viewport_size.x / 2 - FONT:getWidth("PRESS ENTER/START TO CONTINUE") / 2, self.viewport_size.y - 16)
	graphics.translate(0, 16)
    graphics.print("YOU HAVE REACHED", self.viewport_size.x / 2 - FONT:getWidth("YOU HAVE REACHED") / 2, 8)
    graphics.print("THE ECHELON OF LEGENDS", self.viewport_size.x / 2 - FONT:getWidth("THE ECHELON OF LEGENDS") / 2, 18)
    graphics.print("YOUR SCORE:", 16, 64)
	graphics.printf(global_state.score, 16, 64, self.viewport_size.x - 32, "right")
	graphics.print("ENTER YOUR INITIALS", self.viewport_size.x / 2 - FONT:getWidth("ENTER YOUR INITIALS") / 2, 112)




	if not (not self.selecting and floor(self.tick / 2) % 2 == 0) then
		if self.slot_selected == 1 then
			graphics.set_color(graphics.color_flash(0, 10))
		end
		graphics.print(self.slot_1, self.viewport_size.x / 2 -12,self.viewport_size.y / 2 -4) 
		graphics.set_color(palette.white)
		if self.slot_selected == 2 then
			graphics.set_color(graphics.color_flash(0, 10))
		end
		graphics.print(self.slot_2, self.viewport_size.x / 2 -4,self.viewport_size.y / 2 -4)
		graphics.set_color(palette.white)
		if self.slot_selected == 3 then
			graphics.set_color(graphics.color_flash(0, 10))
		end
		graphics.print(self.slot_3, self.viewport_size.x / 2 +4,self.viewport_size.y / 2 -4)
		graphics.set_color(palette.white)
	end


end

function HighScoreEntryScreen:add_high_score()
	table.insert(HIGH_SCORES, { self.slot_1 .. self.slot_2 .. self.slot_3, global_state.score })
	table.sort(HIGH_SCORES, function(a, b) return a[2] > b[2] end)
	while #HIGH_SCORES > NUM_SHOWN_HIGH_SCORES do
		table.remove(HIGH_SCORES, #HIGH_SCORES)
	end
    filesystem.write("high_scores.lua", table.serialize(HIGH_SCORES))
end	

function HighScoreScreen:new()
    HighScoreScreen.super.new(self)
    table.sort(HIGH_SCORES, function(a, b) return a[2] > b[2] end)
	self:add_signal("selected")
end

function HighScoreScreen:draw()
	graphics.set_color(palette.white)
    graphics.set_font(FONT)
	graphics.translate(0, -4)
	-- graphics.set_color(graphics.color_flash(0, 10))
    graphics.print("HIGH SCORES", self.viewport_size.x / 2 - FONT:getWidth("HIGH SCORES") / 2, 12)
	graphics.set_color(graphics.color_flash(1, 10))
    graphics.rectangle("line", 8, 24, self.viewport_size.x - 16, self.viewport_size.y - 40)
	-- graphics.translate(1, 1)
    for i = 1, NUM_SHOWN_HIGH_SCORES do
        if i > #HIGH_SCORES then
            break
        end
        local score = HIGH_SCORES[i]
        graphics.set_color(graphics.color_flash(i, 4))
        graphics.print(score[1], 64, 3 + 14 + 16 + (i - 1) * 14)
        graphics.printf(score[2], 64 + 32, 3 + 14 + 16 + (i - 1) * 14, self.viewport_size.x - 64 - 32 - 16 - 48, "right")
    end
    graphics.set_color(palette.white)
	graphics.print("PRESS ENTER/START TO CONTINUE", self.viewport_size.x / 2 - FONT:getWidth("PRESS ENTER/START TO CONTINUE") / 2, self.viewport_size.y - 12)
end

function HighScoreScreen:update(dt)
	if input.confirm_pressed then
		self:emit_signal("selected")
	end
end

function GuideScreen:new()
    GuideScreen.super.new(self)
	audio.play_sfx(audio.sfx.cutscene_boop)
    self:add_signal("selected")
	self:add_elapsed_ticks()
end

function GuideScreen:update(dt)
    if input.confirm_pressed or debug.enabled and input.keyboard_held["tab"] then
        signal.emit(self, "selected")
    end
end
function GuideScreen:draw()
	graphics.set_color(palette.white)
	graphics.set_font(FONT)
	local text1 = "HOW TO PLAY"
    local text2 = "PRESS ENTER/START TO CONTINUE"
	local text3 = "MOVE WITH WASD/LEFT STICK"
    local text4 = "SHOOT BY HOLDING \nARROW KEYS/RIGHT STICK"
	local text5 = "JUMP OVER LOGS\n\n\n\n\nTO SHOOT OVER WALLS"

	local text1_width = FONT:getWidth(text1)
    local text2_width = FONT:getWidth(text2)

    local player_sprite = floor(self.tick / 10) % 2 == 0 and textures.player_placeholder1 or textures.player_placeholder2
	local t = (self.tick % 60) / 60
	
	graphics.print(text1, self.viewport_size.x / 2 - text1_width / 2, self.viewport_size.y / 2 - 88)
    graphics.print(text2, 8, self.viewport_size.y / 2 + 80)
	
    graphics.translate(0, 0)
	
	local t2 = clamp(t, 0, 0.5) * 2
    graphics.draw(player_sprite, lerp(64 - 16, 64 + 16, t2), 120 - math.bump(t2) * 15 + 24, 0, 1, 1, 0, 1)

	graphics.draw(player_sprite, 64 + math.tri(t*tau) * 16, 48, 0, 1, 1, 0, 1)
    graphics.draw(player_sprite, 64, 92
	, 0, 1, 1, 0, 1)
	
    local angle = stepify(t * tau, tau / 8)
    local vec = Vec2(cos(angle), sin(angle))
	graphics.set_color(graphics.color_flash(0, 2))
	graphics.line(64 + 8 + vec.x * 8, 92 + 8 + vec.y * 8, 64 + vec.x * 16 + 8, 92 + vec.y * 16 + 8)
	graphics.set_color(palette.white)


	graphics.draw(textures.log, 64, 120 + 24, 0, 1, 1, 0, 1)
	graphics.print(text3, 8, 32)
	graphics.print(text4, 8, 64)
	graphics.print(text5, 8, 96 + 24)
end

function TitleScreen:draw()
	graphics.set_color(palette.white)
	graphics.set_font(FONT)
	local text = "THE TITLE OF GAME"
    local text2 = "PRESS ENTER/START"
	local text3 = "MADE BY IVY SLY"
    local text_width = FONT:getWidth(text)
	local text2_width = FONT:getWidth(text2)
	local text3_width = FONT:getWidth(text3)
    graphics.print(text, self.viewport_size.x / 2 - text_width / 2, self.viewport_size.y / 2 - 88)
    graphics.print(text2, self.viewport_size.x / 2 - text2_width / 2, self.viewport_size.y / 2 + 0)
	graphics.print(text3, self.viewport_size.x / 2 - text3_width / 2, self.viewport_size.y / 2 + 80)
end

function ContinueLayer:new()
    ContinueLayer.super.new(self)
    self.selected = 2
	self.timer = 10
    self.blocks_input = true
    self.blocks_logic = true
	self:add_signal("selected")
end

function ContinueLayer:update(dt)
	local input = self.input
    if input.move_right_pressed or input.move_left_pressed or input.aim_left_pressed or input.aim_right_pressed then
        if self.selected == 1 then self.selected = 2 else self.selected = 1 end
    end
	self.timer = self.timer - frames_to_seconds(dt)
    if self.timer <= 0 then
        self:choose()
    end
	
	if input.confirm_pressed then
		self:choose()
	end
end

function ContinueLayer:choose()
    if self.selected == 1 then
        global_state.continues_used = global_state.continues_used + 1
        global_state.lives = LIVES
		global_state.score = 0
		global_state.extra_life_threshold = global_state.base_extra_life_threshold
        global_state.extra_life_threshold_increment_counter = 1
		signal.emit(self, "selected", 1)
        
	else
		signal.emit(self, "selected", 0)
	end
end

function ContinueLayer:draw()
    graphics.set_font(FONT)
	
	local text = "CONTINUE?"
    local text_width = FONT:getWidth(text)
    graphics.set_color(palette.black)
    local width = SCREEN_WIDTH
	if global_state.hudless_level then
		width = self.viewport_size.x
	end
	graphics.rectangle("fill", width / 2 - 48, self.viewport_size.y / 2 - 32, 96, 64)
	
    graphics.set_color(palette.white)
	graphics.print_outline("000000", text, width / 2 - text_width / 2, self.viewport_size.y / 2 - 16, 0, 1, 1, 0, 0)

	graphics.print(tostring(floor(self.timer)), width / 2 - 4, self.viewport_size.y / 2)
    graphics.set_color(self.selected == 2 and palette.white or graphics.color_flash(0, 10))
	graphics.print("YES", width / 2 - text_width / 2, self.viewport_size.y / 2 + 16)
    graphics.set_color(self.selected == 1 and palette.white or graphics.color_flash(0, 10))
    graphics.print("NO", width / 2 - text_width / 2 + 48, self.viewport_size.y / 2 + 16)
end


function GameLayer:new()
    GameLayer.super.new(self)
	self:add_signal("level_complete")
    self.clear_color = palette.black
    signal.connect(input, "key_pressed", self, "on_key_pressed", function(key)
		if key == "tab" and debug.enabled then
			signal.emit(self, "level_complete", true)
		end
	end)
end

function GameLayer:update(dt)
	if self.world and self.world.level_data.cutscene == "cutscene1" and self.input.confirm_pressed then
		signal.emit(self, "level_complete", true)
	end
end

function GameLayer:start(level)
	local level_name = level.map
    local direction = level.direction
	local cutscene = level.cutscene
    self:ref("world", self:add_world(ScrollingGameWorld(level_name, direction, cutscene, level.number)))
    self.world.level_data = level
	signal.connect(self.world, "player_died", self, "player_death_effect")
	signal.chain_connect("level_complete", self.world, self)
end

function GameLayer:player_death_effect()
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

function MainScreen:score_stuff()
    local s = self.sequencer
    if self.game_layer then
        self.game_layer:destroy()
    end
	if self.hud_layer then	
		self.hud_layer:destroy()
	end
	if is_valid_high_score(global_state.score) then
		self:ref("high_score_entry_screen", self:push(HighScoreEntryScreen))
		s:wait_for_signal(self.high_score_entry_screen, "selected")
		self.high_score_entry_screen:destroy()

	end
	self:ref("high_score_screen", self:push(HighScoreScreen))
	s:wait_for_signal(self.high_score_screen, "selected")
	self.high_score_screen:destroy()		
	self:transition_to("MainScreen")
end

function MainScreen:new()
    MainScreen.super.new(self)
    local s = self.sequencer

	local scores = filesystem.read("high_scores.lua")

    if scores == nil then
        HIGH_SCORES = {
            -- { "SLY", 0 },
        }
    else
        HIGH_SCORES = table.deserialize(scores)
        table.sort(HIGH_SCORES, function(a, b) return a[2] > b[2] end)
    end

    s:start(function()
        self:ref("title_screen", self:push(TitleScreen))
        s:wait_for_signal(self.title_screen, "selected")
        self.title_screen:destroy()
		s:wait(10)
		global_state = GlobalState()
		self:ref("hud_layer", self:push(HUDLayer))
	
        for i=START_SCREEN, #global_state.levels do
			local level = global_state.levels[i]
			global_state.hudless_level = false
            if self.game_layer then
                self.game_layer:destroy()
            end
            if level.type == "game" then
				self:ref("game_layer", self:insert_layer(GameLayer, 1))
				self.game_layer:start(level)
				global_state.cutscene = level.cutscene
                while true do
                    s:wait_for_signal(self.game_layer, "level_complete")
                    global_state.cutscene = false
                    local success = unpack(s.signal_output)
                    if not success then
                        self:ref("continue_layer", self:push(ContinueLayer))
                        s:wait_for_signal(self.continue_layer, "selected")
                        self.continue_layer:destroy()
                        local selected = unpack(s.signal_output)
                        if selected == 0 then
							self:score_stuff()
							return
                        end
                    else
                        break
                    end
                end
            elseif level.type == "guide_screen" then
				global_state.cutscene = true
				self:ref("guide_screen", self:push(GuideScreen))
				s:wait_for_signal(self.guide_screen, "selected")
				self.guide_screen:destroy()
            elseif level.type == "end" then
				self:score_stuff()
                return
            end
        end
    end)
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

function ScrollingGameWorld:new(level_name, direction, cutscene, level_number)
	self.level_number = level_number
	ScrollingGameWorld.super.new(self)
	self:add_spatial_grid("object_grid")

    self.scroll_time = 0

    self:add_signal("level_complete")
	self:add_signal("player_died")

	self:implement(Mixins.Behavior.GridTerrainQuery)

    signal.connect(global_state, "extra_life_threshold_reached", self, "on_extra_life_threshold_reached", function()
        if global_state.game_complete then return end
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
	self.level_name = level_name
	self.map:build()
	self.map:bump_init(self.bump_world)

	self.scroll = 0
	self.scroll_direction = direction == "up" and -1 or 1
	self.cutscene = cutscene
    self.scroll_size = conf.viewport_size.y
	
	self.scrolling = true
	if cutscene then
		self.scrolling = false
	end

    self.map_width = MAP_WIDTH

    for sfx, _ in pairs(audio.sfx) do
        self:add_sfx(sfx)
    end
	
	local spawn_y_offset = self.scroll_direction == -1 and 0 or -11

    self.spawn_function_map = {
        flyer1 = function(x, y, z)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
            if self.scroll_direction == 1 then
				y = y + self.scroll_size / tilesets.TILE_SIZE
			end
            y = y + 1 * -self.scroll_direction + spawn_y_offset
            local wx, wy = self.map.cell_to_world(x, y, z)
            local flyer = self:add_object(O.Enemy.Flyer(wx, wy))
			-- if self.scroll_direction == 1 then 
                -- flyer.curve_amount = -1.6
			-- else
				flyer.curve_amount = 1.6
			-- end
        end,
        flyer2 = function(x, y, z)
            -- print(y)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
			if self.scroll_direction == 1 then
				y = y + self.scroll_size / tilesets.TILE_SIZE + 2
			end
			local s = self.sequencer
            y = y + 1 * -self.scroll_direction + spawn_y_offset
            s:start(function()
                for i = 1, 3 do
                    local wx, wy = self.map.cell_to_world(x, y, z)
                    local flyer = self:add_object(O.Enemy.Flyer(wx, wy))
					-- if self.scroll_direction == 1 then 
						-- flyer.curve_amount = -0.5
					-- else
						flyer.curve_amount = 0.1
					-- end
                    s:wait(20)
                    y = y + 3 * -self.scroll_direction
                end
            end)
        end,
        flyer3 = function(x, y, z)
            if x < MAP_WIDTH / 2 then x = 0 else x = MAP_WIDTH end
			-- if self.scroll_direction == 1 then
			-- 	y = y - self.scroll_size / tilesets.TILE_SIZE
			-- end
			if self.scroll_direction == -1 then 
                y = y + 10
			else
				y = y + 2
			end
            local wx, wy = self.map.cell_to_world(x, y + spawn_y_offset, z)
            local s = self.sequencer
            s:start(function()
                s:wait(12)
				local flyer = O.Enemy.Flyer(wx, wy)
                -- flyer.curve_amount = -1.6 * -self.scroll_direction
				-- if self.scroll_direction == 1 then 
					-- flyer.curve_amount = 1.6
				-- else
					flyer.curve_amount = -1.6
				-- end
                self:add_object(flyer)
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
        end,
        ghost1 = function(x, y, z)
            local middle = self.scroll_center
            local num_ghosts = 7
            for i = 1, num_ghosts do
                local angle = (i / num_ghosts) * tau
                local ghost = self:add_object(O.Enemy.Ghost(middle.x, middle.y))
                ghost.delay = (i - 1) * 20
                ghost.start_angle = angle
            end
        end,
		ghost2 = function(x, y, z)
            local middle = self.scroll_center
            local num_ghosts = 7
            for i = 1, num_ghosts do
                local angle = (i / num_ghosts) * tau
                local ghost = self:add_object(O.Enemy.Ghost(middle.x, middle.y))
                ghost.delay = (i - 1) * 20
                ghost.start_angle = angle
				ghost.direction = -1
            end
        end,
	}

    self:process_map_data(self.map)
	-- self.map:erase_tiles()
    self.draw_sort = self.y_sort
	self.scroll_speed = SCROLL_SPEED
	
    self.room_size = conf.room_size

end


function ScrollingGameWorld:exit()
	audio.stop_music()
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
		local was_scrolling = self.scrolling
		self.scrolling = false
		s:wait(60)
        global_state.lives = global_state.lives - 1
		if global_state.lives <= 0 then
			s:wait(30)
			self:emit_signal("level_complete", false)
			s:wait(1)
		
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
		end
		self:spawn_player(self.player_x, self.player_y, true)
		self:clamp_player(false)
		self.scrolling = was_scrolling
		self:play_sfx("player_respawn")
    end)
	self:emit_signal("player_died")
end

function ScrollingGameWorld:spawn_player(x, y, invuln)
	if invuln == nil then invuln = true end
    self:ref("player", self:add_object(O.Player.DeliveryGuy(x, y, invuln)))
	signal.connect(self.player, "moved", self, "on_player_moved", function() self.player_x, self.player_y = self.player.pos.x, self.player.pos.y end)
	signal.connect(self.player, "died", self, "on_player_death")
	signal.connect(self.player, "level_complete", self, "on_player_completed_level")
	self.player.cutscene = self.cutscene
end

function ScrollingGameWorld:clear_all_enemies()
	for _, obj in (self.objects:ipairs()) do
		if obj.is_enemy then
			obj:die()
		end
	end
end

function ScrollingGameWorld:on_player_completed_level()
	local s = self.sequencer
	s:start(function()
		self.player.cutscene = true
		self.scrolling = false
		audio.stop_music()
		self:clear_all_enemies()
		s:wait(90)
		self:play_sfx("levelcomplete")
        s:wait(400)
        -- if blackout then
		self.blackout = true
		global_state.cutscene = true
		s:wait(30)
		global_state.cutscene = false
		-- end
		self:emit_signal("level_complete", true)
	end)
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
    self.player_min_x = (tilesets.TILE_SIZE / 2 + tilesets.TILE_SIZE)
	self.player_max_x = (MAP_WIDTH * tilesets.TILE_SIZE + tilesets.TILE_SIZE / 2 - tilesets.TILE_SIZE)
	print("world bounds", self.world_bounds)
    print("cell bounds", self.cell_bounds)


	self.middle = Vec2(self.world_bounds.x + self.world_bounds.width / 2, self.world_bounds.y + self.world_bounds.height / 2)

end

function ScrollingGameWorld:enter()
	if not self.player then return end
	ScrollingGameWorld.super.enter(self)
    self:set_scroll(self.player.pos.y - self.viewport_size.y / 2)
	self:initial_spawn()
	if self.cutscene then
		self.blackout = true
		self.scrolling = false

		local s = self.sequencer
		s:start(function() 
			self.blackout = false
			self[self.cutscene](self)
		end)
	else
		self.player.cutscene = true
		self.scrolling = false
		local s = self.sequencer
		s:start(function()
			-- s:wait(120)
			self:play_sfx("levelstart")
			self:cutscene_text("LEVEL " .. self.level_number .. " START", 0, 0, 90, nil, "flash")
			self.scrolling = true
			self.player.cutscene = false	
			if not self.cutscene then
				audio.play_music(audio.music[self.level_data.song], self.level_data.music_volume or 1.0)
			end
		end)
	end
end

function ScrollingGameWorld:cutscene1()
	local s = self.sequencer
	local player = self.player
	self.blackout = true
    s:wait(30)
	audio.play_music(audio.music.loop2)
    self.blackout = false
    s:wait(120)
	self.blackout = true
	s:wait(30)

	self:cutscene_text("THE MAD WIZARD TIRELESSLY\nPERFORMS HIS MYSTIC RITUAL\nIN THE ANCIENT FOREST", 0, 0, 230, "cutscene_boop")
	s:wait(30)
	self.blackout = false
	s:wait(120)

	self:play_sfx("cutscene_servitor_spawn")
	local servitor = self:add_object(O.Misc.Servitor(self.player.pos.x, self.player.pos.y - 32))

	s:wait(150)
	self:cutscene_text("FINALLY AFTER ALL\nTHESE YEARS", 0, 50, 120)
	s:wait(60)
	self:cutscene_text("I HAVE CREATED \nA PERFECT SERVITOR", 0, 50, 120)
	s:wait(90)
	self:cutscene_text("NOW GO FORTH\nAND FETCH ME KEBAB", 0, 50, 120)
	s:wait(30)
	self:cutscene_text("YES MASTER", 0, -36, 120, "cutscene_yes_master", "flash")
	s:wait(30)
	s:start(function()
		s:tween(function(y) servitor.pos.y = y end, servitor.pos.y, servitor.pos.y - 132, 120)
	end)
	s:wait(200)
	self.blackout = true
	s:wait(60)
	-- self:play_sfx("cutscene_boop")
	self:cutscene_text("ONE WEEK LATER", 0, 0, 120)
	s:wait(60)
	self.blackout = false
	s:wait(120)
	self:cutscene_text("WHERE IS MY KEBAB?", 0, 50, 120)
	s:wait(90)
	s:tween(function(y) player.pos.y = y end, player.pos.y, player.pos.y - 132, 120)
	s:wait(30)
	self.blackout = true
	audio.stop_music()
	s:wait(30)
	self:emit_signal("level_complete", true)

end

function ScrollingGameWorld:cutscene2()
    local s = self.sequencer
	local player = self.player
	local vendor = self:add_object(O.Enemy.Boss1(self.player.pos.x, self.player.pos.y - 64 - 48))
	self.blackout = true
    s:wait(30)


	audio.play_music(audio.music.loop2)

	self.blackout = false

	

	s:tween(function(y) player:tp_to(player.pos.x, y) end, player.pos.y, player.pos.y - 64, SKIP_CUTSCENE and 10 or 90)
	
	if not SKIP_CUTSCENE then
		s:wait(120)

		self:cutscene_text("HAVE YOU SEEN\nMY FAMULUS?", 0, 50, 120)
		s:wait(90)
		self:cutscene_text("YOU AGAIN?", 0, -56, 120)
		s:wait(110)
		self:cutscene_text("DO I KNOW YOU?", 0, 50, 120)
		s:wait(90)
		self:cutscene_text("YOU MUST BE HERE\nTO STEAL MORE OF MY\nKEBAB", 0, -64, 150, "cutscene_boop")
	end
    audio.stop_music()
	s:wait(30)
	vendor:explode_cart()
	s:wait(75)
    audio.play_music(audio.music.boss1)
	
	s:wait(60)
    self.player.cutscene = false
	self.force_color_flash = true
    self.cutscene = false
	global_state.cutscene = false
	
    s:wait_for_signal(vendor, "died")
    audio.stop_music()
    self.player.cutscene = true
	
	s:wait(120)

	self:on_player_completed_level()
end

function ScrollingGameWorld:cutscene3()
    local s = self.sequencer
	local player = self.player
	local creator = self:add_object(O.Enemy.Boss2(self.player.pos.x, self.player.pos.y + 64 + 48))
    self.blackout = true
	global_state.hudless_level = true
    s:wait(30)

	
	audio.play_music(audio.music.loop2)
	
    self.blackout = false
	

	s:tween(function(y) player:tp_to(player.pos.x, y) end, player.pos.y, player.pos.y + 64, SKIP_CUTSCENE and 10 or 90)
    if not SKIP_CUTSCENE then
        s:wait(90)
        self:cutscene_text("WHERE WERE YOU?", 0, -56, 120)
        s:wait(120)

        self:cutscene_text("SHOULDN'T I BE\nASKING THAT OF YOU?", 0, 50, 150)
        s:wait(60)

        self:cutscene_text("I WAITED HERE SO LONG\nFOR YOU", 0, 50, 150)
        s:wait(60)

        self:cutscene_text("TO RETURN WITH THE KEBAB", 0, 50, 150)
        s:wait(60)

		self:cutscene_text("YOUR PURPOSE WAS TO RETRIEVE", 0, 50, 150)
		s:wait(60)

        self:cutscene_text("NOW GIVE IT TO ME!", 0, 50, 150)
    end
	
	self:ending1(creator)

    -- if global_state.kebabs == 0 then
    --     self:ending3(creator)
    -- else
	-- 	if global_state.continues_used == 0 then
	-- 		self:ending1(creator)
	-- 	else
	-- 		self:ending2(creator)
	-- 	end
	-- end


end

function ScrollingGameWorld:ending1(creator)
    local s = self.sequencer
    local player = self.player

	if not SKIP_CUTSCENE then
		self:cutscene_text("THIS CAN'T BE!", 0, -56, 120)
		s:wait(60)
		self:cutscene_text("YOU ARE NO MASTER OF MINE!", 0, -56, 120)
		audio.stop_music()
		s:wait(30)
	end
    audio.play_music(audio.music.boss1)
	s:wait(60)
    self.player.cutscene = false
	self.force_color_flash = true
    self.cutscene = false
	creator:change_state(creator:get_next_state())
    global_state.cutscene = false
	global_state.hudless_level = true

	s:wait_for_signal(creator, "died")

    global_state.game_complete = true
    global_state.cutscene = true
	self.force_color_flash = false

	self.player.cutscene = true
    self.scrolling = false

    local _1cc = global_state.continues_used == 0
	-- _1cc = false

	audio.stop_music()
    self:clear_all_enemies()

	s:wait(1)
    local score = creator.score
	if _1cc then score = score * 1.5 end	


	if not _1cc then
    	player.invuln = true
	end
	creator.invuln = true
    s:wait(120)
    player.invuln = false
	creator.invuln = false
	while not creator.player do
		creator:ref_player()
		s:wait(1)
	end
    creator.world.canvas_layer:player_death_effect()
	self:play_sfx("player_death")
    if _1cc then
		creator:spawn_object(ObjectScore(creator.pos.x, creator.pos.y, score))
		-- self:ending1(creator)
	else
		creator.player:fake_die()
		creator:spawn_object(ObjectScore(self.scroll_center.x - 8, self.scroll_center.y, score))
		-- self:ending2(creator)
	end
	creator:queue_destroy()
	-- creator.world:play_sfx(creator.death_fx or "enemy_die")
    local tex = creator:get_texture()
	
	local fx = creator:spawn_object(DeathFx(creator.pos.x, creator.pos.y, tex, creator.flip))
    fx.duration = fx.duration * 2
	
	-- self:play_sfx("levelcomplete")
    s:wait(200)
	
    if _1cc then
		-- s:wait(120)
		self:play_sfx("levelcomplete")
        s:wait(400)
		-- s:wait(200)
        self:cutscene_text("YOU WIN", 0, 0, 180, "cutscene_youwin", "flash")
        self.blackout = true
		s:wait(60)
		self:emit_signal("level_complete", true)
    else
		self.blackout = true
        s:wait(30)
		self:cutscene_text("HISTORY WILL MOURN\nNO SHADES ERRANT", 0, 0, 180, "cutscene_boop")
        s:wait(10)
        self:cutscene_text("SPURN DEATH\nTO ACHIEVE LIFE", 0, 0, 180, "cutscene_boop")
        s:wait(10)
        self:cutscene_text("COMPLETE THE GAME\nWITH NO CONTINUES", 0, 0, 180, "cutscene_boop")
        s:wait(10)
		self:cutscene_text("OR YOU ARE FATED\nTO RELIVE THIS TALE", 0, 0, 180, "cutscene_boop")
		-- s:wait(120)

		-- global_state.cutscene = true
		s:wait(30)
		-- global_state.cutscene = false
		-- end
		self:emit_signal("level_complete", true)
	end

	-- if blackout then


	-- self:on_player_completed_level()
end

function ScrollingGameWorld:ending2(creator)
	local s = self.sequencer
	local player = self.player
   
    s:wait(140)
    audio.stop_music()
	s:wait(60)
	self:cutscene_text("YES MASTER", 0, -56, 120, "cutscene_yes_master", "flash")
    s:wait(60)
	
    -- if global_state.kebabs == 0 then global_state.kebabs = 1 end
    for i = 1, clamp(global_state.kebabs, 1, 8) do
        local kebab = self:add_object(O.Misc.ScorePickup(self.player.pos.x, self.player.pos.y))
        s:tween(function(y) kebab.pos.y = y end, kebab.pos.y, creator.pos.y, 30)
        self:play_sfx("player_pickup")
        kebab:destroy()
    end
	
    s:wait(120)
	
	self:play_sfx("player_shoot")
    local laser = self:add_object(O.Enemy.EnemyLaser(creator.pos.x, creator.pos.y, 0, -1))
	laser.speed = 10

    s:wait(10)
	player.invuln = true
    s:wait(70)
	-- self:play_sfx("player_death")
	self.canvas_layer:player_death_effect()
    player:die_fx()
    player:hide()
	
    s:wait(180)
	
    self:cutscene_text("STAND UP TO YOUR CREATOR", 0, 0, 180, "cutscene_boop")
    self:cutscene_text("CLEAR THE GAME\nWITH NO CONTINUES", 0, 0, 240, "cutscene_boop")
	self.blackout = true

    s:wait(60)
	self:emit_signal("level_complete", true)

end

function ScrollingGameWorld:ending3(creator)
    local s = self.sequencer
	local player = self.player
   
    -- s:wait(140)
	s:wait(180)
    self:cutscene_text("NO KEBAB?", 0, 50, 150)
    s:wait(60)
	self:cutscene_text("YOU HAVE FAILED ME", 0, 50, 150)
    
    s:wait(60)
	
	audio.stop_music()
	
	
    s:wait(60)
	
	self:play_sfx("player_shoot")
    local laser = self:add_object(O.Enemy.EnemyLaser(creator.pos.x, creator.pos.y, 0, -1))
	laser.speed = 10

    s:wait(10)
	player.invuln = true
    s:wait(70)
	-- self:play_sfx("player_death")
	self.canvas_layer:player_death_effect()
    player:die_fx()
    player:hide()
	
    s:wait(180)
	
    self:cutscene_text("STAND UP TO YOUR CREATOR", 0, 0, 180, "cutscene_boop")
    self:cutscene_text("CLEAR THE GAME\nWITH NO CONTINUES", 0, 0, 180, "cutscene_boop")
    self:cutscene_text("AND DON'T FORGET THE KEBAB", 0, 0, 240, "cutscene_boop")
	self.blackout = true

    s:wait(60)
	self:emit_signal("level_complete", true)
end

function ScrollingGameWorld:cutscene_text(text, x_offset, y_offset, time, sound_file, color)
	time = time or 200
	x_offset = x_offset or 0
	y_offset = y_offset or 0
	local text_object = {
		text = text,
		x_offset = x_offset,
		y_offset = y_offset,
		time = time,
		color = color or palette.white
	}
	self.cutscene_text_object = text_object
	if sound_file then 
		if not self:get_sfx(sound_file) then
			self:add_sfx(sound_file)
		end
		self:play_sfx(sound_file)
	end
	self.sequencer:wait(time)
	self.cutscene_text_object = nil
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
	if self.cutscene then return end
	if self.player and self.player.level_complete then 
		return
	end
	if allow_death == nil then allow_death = true end
    if self.player then
		self.player:tp_to(clamp(self.player.pos.x, tilesets.TILE_SIZE / 2 + tilesets.TILE_SIZE, MAP_WIDTH * tilesets.TILE_SIZE + tilesets.TILE_SIZE / 2 - tilesets.TILE_SIZE), self.player.pos.y)
		local y = self.player.pos.y
		if y < self.scroll + 8 then 
			if y < self.scroll and allow_death and self.player.state ~= "PitJump" then 
				self.player:die()
			else
				self.player:move(0, self.scroll + 8 - y) 
			end
		end
		if y > self.scroll + self.scroll_size - 8 then 
			if y > self.scroll + self.scroll_size and allow_death and self.player.state ~= "PitJump" then
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
		self.scroll_time = self.scroll_time + dt
	end

    self.scroll_center = self.scroll_center or Vec2()
	self.scroll_center.x = global_state.hudless_level and self.viewport_size.x / 2 or SCREEN_WIDTH / 2
	self.scroll_center.y = self.viewport_size.y / 2 + self.scroll

	local new_scroll_spawn_ycell = self:get_scroll_spawn_ycell()
	if new_scroll_spawn_ycell ~= self.scroll_spawn_ycell then
		self.scroll_spawn_ycell = new_scroll_spawn_ycell
		self:process_objects_at_ycell(new_scroll_spawn_ycell)
	end

	local despawn_ycell = self:get_scroll_despawn_ycell()
	self.scroll_despawn_ycell = despawn_ycell
	
	if global_state.continuing then 
        self:spawn_player(self.player_x, self.player_y, true)
		global_state.continuing = false
	end
	
	if not global_state.hudless_level then
		self:clamp_player()
	end

    for _, obj in self.objects:ipairs() do
        local _, y = self.map.world_to_cell(obj.pos.x, obj.pos.y, 0)

        -- print(self.scroll_direction, y, self.scroll_despawn_ycell)
        local should_despawn = (self.scroll_direction < 0 and y > self.scroll_despawn_ycell) or
            (self.scroll_direction > 0 and y < self.scroll_despawn_ycell)
		if obj.ignore_despawn then
			should_despawn = false
		end
        -- print(should_despawn)
        if should_despawn and obj ~= self.camera and obj.tick and obj.tick > 60 then
			obj:destroy()
		end
	end

	local len = self.objects:length()

	dbg("num objects", len)

	-- if len > 25 then 
	-- 	gametime.scale = clamp(1 - (len - 25) * 0.05, 0.5, 1)
	-- else
	-- 	gametime.scale = 1
	-- end
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
	
	graphics.push()

	local spawn_y = self:get_scroll_spawn_ycell()
	local despawn_y = self:get_scroll_despawn_ycell()

	local min_y = min(spawn_y, despawn_y)
	local max_y = max(spawn_y, despawn_y)

	if (global_state.hudless_level or global_state.cutscene) and self.level_data.cutscene_offset ~= false then
		graphics.translate(tilesets.TILE_SIZE / 2, 0)
	end

	if not self.blackout then
		graphics.set_color(palette.white)
		local x1, y1, w, h, x2, y2 = self:get_draw_rect()
		self.map:draw_world_space("dynamic", x1, y1, x2, y2, nil, 0)

		local bg_color = palette.white
        if self.level_data and self.level_data.map_color then
            local colors = self.level_data.map_color
			for i = #colors, 1, -1 do
				if frames_to_minutes(self.scroll_time) >= colors[i][1] then
					bg_color = colors[i][2]
					break
				end
			end
		end
		
		for y=min_y, max_y do
			for x=-1, self.viewport_size.x / tilesets.TILE_SIZE do			
				local wx, wy = self.map.cell_to_world(x, y, 0)
				local color = bg_color
				local tile = self:get_tile(x, y, 0)
				if tile and tile.data and tile.data.auto_color and self:is_cell_solid(x, y, 0) then
					if (self.scrolling or self.force_color_flash) and (floor(self.tick / 1) % 2 == 0 and abs((y % 38) - (floor(self.scroll_direction * -self.tick * self.scroll_speed) % 38)) < 4) then
						color = graphics.color_flash(y * 2, 4)
					end
					graphics.set_color(color)
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
	end

	graphics.pop()

	if self.cutscene_text_object then
		graphics.push()
		graphics.origin()
		
		if global_state.cutscene and self.level_data.cutscene_offset ~= false then
			graphics.translate(INFO_PANEL_RECT.width / 2, 0)
		end

		graphics.set_font(FONT)
		local lines = string.split(self.cutscene_text_object.text, ("\n"))
		for i, line in ipairs(lines) do	
			line = string.strip_whitespace(line)
			local width = FONT:getWidth(line)	
			graphics.set_color(palette.black)
			local y = stepify(self.viewport_size.y / 2 + self.cutscene_text_object.y_offset + (i - 1) * FONT:getHeight() - #lines * 0.5 * FONT:getHeight(), 8)
			graphics.rectangle("fill", SCREEN_WIDTH / 2 + self.cutscene_text_object.x_offset - stepify(width / 2, 8), y, width, FONT:getHeight())
			graphics.set_color(self.cutscene_text_object.color == "flash" and graphics.color_flash(1, 5) or self.cutscene_text_object.color)
			graphics.print(line, SCREEN_WIDTH / 2 + self.cutscene_text_object.x_offset - stepify(width / 2, 8), y)
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
