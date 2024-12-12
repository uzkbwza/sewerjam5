input = require "input"
conf = require "conf"
graphics = require "graphics"
rng = require "lib.rng"
gametime = require "time"
global_state = {}
tilesets = require "tile.tilesets"
nativefs = require "lib.nativefs"
binser = require "lib.binser"
signal = require "signal"
audio = require "audio"

require "lib.color"

GameObject = require "obj.game_object"
GameMap = require "map.GameMap"
-- Screen = require "screen.game_screen"
World = require "world.game_world"
Effect = require "fx.effect"
Mixins = require "mixins"
SpriteSheet = require "lib.spritesheet"
-- ScreenStack = require "screen_stack"
CanvasLayer = require "screen.CanvasLayer"

bonglewunch = require "datastructure.bonglewunch"
makelist = require "datastructure.smart_array"

local fsm = require "lib.fsm"
StateMachine = fsm.StateMachine
State = fsm.State

local frame_length = 0

Game = require "game"

game = Game()


local function manual_gc(time_budget, memory_ceiling, disable_otherwise)
	time_budget = time_budget or 1e-3
	memory_ceiling = memory_ceiling or math.huge
	local max_steps = 1000
	local steps = 0
	local start_time = love.timer.getTime()
	while
		love.timer.getTime() - start_time < time_budget and
		steps < max_steps
	do
		if collectgarbage("step", 1) then
			break
		end
		steps = steps + 1
	end
	--safety net
	if collectgarbage("count") / 1024 > memory_ceiling then
		collectgarbage("collect")
	end
	--don't collect gc outside this margin
	if disable_otherwise then
		collectgarbage("stop")
	end
end

local function step(dt)
	local frame_start = love.timer.getTime()

    if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

    if love.graphics and love.graphics.isActive() then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())

        if love.draw then love.draw() end

        love.graphics.present()
    end

	local frame_end = love.timer.getTime()
	frame_length = frame_end - frame_start
	
end
function love.run()

	if love.math then
		love.math.setRandomSeed(os.time())
	end

	local accumulated_time = 0
	local frame_time = 1 / conf.fixed_tickrate
	
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

    local dt = 0
	local min_delta = 1 / conf.max_fps

    local debug_printed_yet = false
	
	-- Main loop time.
	return function()
		-- Process events.
		
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

		
		
		-- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end
		

		-- Call update and draw
		accumulated_time = accumulated_time + dt

		local delta_frame = min(dt * 60, conf.max_delta_seconds * 60)
	
		if not conf.use_fixed_delta then
			step(delta_frame)
		else
			for i = 1, conf.max_fixed_ticks_per_frame do
				if accumulated_time < frame_time then
					break
				end
				
				step(frame_time * 60)
	
				accumulated_time = accumulated_time - frame_time
			end
		end


		gametime.time = gametime.time + delta_frame
        gametime.ticks = floor(gametime.time)

		
        gametime.frames = gametime.frames + 1
        -- collectgarbage()


		
        if gametime.ticks % 300 == 0 then
            if debug.enabled and not debug_printed_yet then
                local fps = love.timer.getFPS()
                -- if conf.use_fixed_delta and fps > conf.fixed_tickrate then
                --     fps = conf.fixed_tickrate
                -- end
                print("fps: " .. fps)
				debug_printed_yet = true
            end
        else
            debug_printed_yet = false
        end
		
		if frame_length < min_delta and not usersettings.vsync then
            love.timer.sleep(min_delta - frame_length)
			-- print(min_delta - frame_length)
		end

		manual_gc(0.001, math.huge, false)

	end
	
	
end

function love.load()
	graphics.load()
	audio.load()
	tilesets.load()
    input.load()
	Screens = filesystem.get_modules("screen")
    game:load()
end

function love.update(dt)
	if gametime.ticks % 1 == 0 then 
		-- dbg("ticks", gametime.ticks)
		local fps = love.timer.getFPS()
        if conf.use_fixed_delta and fps > conf.fixed_tickrate then
            fps = conf.fixed_tickrate
        end
		
		if debug.enabled then
			dbg("fps", fps)
			dbg("memory use (kB)", floor(collectgarbage("count")))
			dbg("frame length (ms)", string.format("%0.3f",  (1000 * frame_length)))
		end
	end
	
	if debug.enabled and input.debug_count_memory_pressed then 
        filesystem.save_file(table.pretty_format(_G), "game_memory.txt")
		-- table.pretty_print(_G)
        table.pretty_print(debug.type_count())
	end
	
	input.update(dt)

    -- global input shortcuts
	if input.fullscreen_toggle_pressed then
		love.window.setFullscreen(not love.window.getFullscreen())
	end

	game:update(dt)
    
	
    debug.update(dt)
	if debug.enabled then
        -- dbg("move", input.move)
        -- dbg("move_left", input.move_left)
        -- dbg("move_right", input.move_right)
        -- dbg("move_up", input.move_up)
		-- dbg("move_down", input.move_down)
		-- dbg("primary", input.primary)
		-- dbg("z pressed", input.keyboard_pressed["z"])
		-- dbg("z held", input.keyboard_held["z"])
		-- dbg("secondary", input.secondary)
	end
	-- collectgarbage()

end

function love.draw()
	-- graphics.interp_fraction = conf.interpolate_timestep and clamp(accumulated_time / frame_time, 0, 1) or 1
	-- graphics.interp_fraction = stepify(graphics.interp_fraction, 0.1)

    graphics.layer_tree = game.layer_tree
    graphics.draw_loop()
	
	if debug.can_draw() then
		debug.printlines(0, 0)
    end
	if gametime.ticks % 10 == 0 then
		if debug.enabled then
			dbg("draw calls", love.graphics.getStats().drawcalls)
		end
		-- dbg("interp_fraction", graphics.interp_fraction)
	end
end

function love.joystickadded(joystick)
	input.joystick_added(joystick)
end

function love.joystickremoved(joystick)
	input.joystick_removed(joystick)
end

function love.keypressed(key)
	input.on_key_pressed(key)
end

function love.gamepadpressed(gamepad, button)
	input.on_joystick_pressed(gamepad, button)
end

function love.joystickpressed(joystick, button)
	input.on_joystick_pressed(joystick, button)
end

function love.mousepressed(x, y, button)
	input.on_mouse_pressed(x, y, button)
end

function love.mousereleased(x, y, button)
	input.on_mouse_released(x, y, button)
end

function love.textinput(text)
	input.on_text_input(text)
end

function love.wheelmoved(x, y)
	input.on_mouse_wheel_moved(x, y)
end
