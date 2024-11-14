game = require "game"
input = require "input"
conf = require "conf"
graphics = require "graphics"
rng = require "lib.rng"
gametime = require "time"
global_state = require "global_state"
tilesets = require "tile.tilesets"


GameObject = require "obj.game_object"
GameObjectSignal = require "obj.game_object_signal"
Screen = require "screen.game_screen"
World = require "world.game_world"
Effect = require "fx.effect"

local function step(dt)
	if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

	if love.graphics and love.graphics.isActive() then
		love.graphics.origin()
		love.graphics.clear(love.graphics.getBackgroundColor())

		if love.draw then love.draw() end

		love.graphics.present()
	end
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

    local debug_printed_yet = false
	
	-- Main loop time.
	return function()
		-- Process events.
        local frame_start = love.timer.getTime()
		
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
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
		
        if gametime.ticks % 120 == 0 then
            if debug.enabled and not debug_printed_yet then
                local fps = love.timer.getFPS()
				if conf.use_fixed_delta and fps > conf.fixed_tickrate then
					fps = conf.fixed_tickrate
				end
                print("fps: " .. fps)
                debug_printed_yet = true
            end
        else 
			debug_printed_yet = false
		end
		
        gametime.frames = gametime.frames + 1
        -- collectgarbage()
        local frame_end = love.timer.getTime()
        local frame_length = frame_end - frame_start
		if frame_length < conf.min_delta_seconds then
            love.timer.sleep(conf.min_delta_seconds - frame_length)
			-- print(conf.min_delta_seconds)
		end
	end
	
end

function love.load()
	input.load()
    game.load()

end

function love.update(dt)
	if gametime.ticks % 2 == 0 then 
		-- dbg("ticks", gametime.ticks)
		local fps = love.timer.getFPS()
        if conf.use_fixed_delta and fps > conf.fixed_tickrate then
            fps = conf.fixed_tickrate
        end
		if debug.enabled then
			dbg("fps", fps)
			dbg("memory use (kB)", floor(collectgarbage("count")))
		end
	end
	
	if debug.enabled and input.debug_count_memory_pressed then 
		table.pretty_print(debug.type_count())
	end
	input.update(dt)
	game.update(dt)
	
    debug.update(dt)
	if debug.enabled then
		dbg("move", input.move)
		dbg("primary", input.primary)
		dbg("secondary", input.secondary)
	end
	-- dbg("time", gametime.time)
	-- dbg("ticks", gametime.ticks)
	-- dbg("frames", gametime.frames)

end

function love.draw()
	-- graphics.interp_fraction = conf.interpolate_timestep and clamp(accumulated_time / frame_time, 0, 1) or 1
	-- graphics.interp_fraction = stepify(graphics.interp_fraction, 0.1)

	game.draw()
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
	input.keypressed(key)
end

function love.keyreleased(key)
	input.keyreleased(key)
end

function love.gamepadpressed(gamepad, button)
	input.joystick_pressed(gamepad, button)
end

function love.gamepadreleased(gamepad, button)
	input.joystick_released(gamepad, button)
end

function love.joystickpressed(joystick, button)
	input.joystick_pressed(joystick, button)
end

function love.joystickreleased(joystick, button)
	input.joystick_released(joystick, button)
end

function love.mousepressed(x, y, button)
	input.mouse_pressed(x, y, button)
end

function love.mousereleased(x, y, button)
	input.mouse_released(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
	input.mouse_moved(x, y, dx, dy, istouch)
end
