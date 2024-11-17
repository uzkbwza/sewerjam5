local input = {}

input.mapping = nil
input.vectors = nil

input.dummy = {}

input.joysticks = {}

input.generated_action_names = {}

input.mouse = {
	prev_wheel = Vec2(0, 0),
	prev_pos = Vec2(0, 0),
	pos = Vec2(0, 0),
	dxy = Vec2(0, 0),
	lmb = nil,
	mmb = nil,
    rmb = nil,
    wheel = Vec2(0, 0),
	dxy_wheel = Vec2(0, 0),
	is_touch = false,
}

input.signals = {
	joystick_pressed = Signal(),
	joystick_released = Signal(),
	key_pressed = Signal(),
	key_released = Signal(),
	mouse_pressed = Signal(),
	mouse_released = Signal(),
    mouse_moved = Signal(),
	mouse_wheel_moved = Signal(),
}

function input.load()
	local g = input.generated_action_names

	input.mapping = conf.input_actions
	input.vectors = conf.input_vectors

	input.keyboard_held = {}

	input.joystick_held = {}


	input.dummy.mapping = conf.input_actions
	input.dummy.vectors = conf.input_vectors
	

	for action, _ in pairs(input.mapping) do
		g[action] = {
			pressed = action .. "_pressed",
			released = action .. "_released",
			amount = action .. "_amount"
		}

		input[action] = false
		input[action .. "_pressed"] = false
		input[action .. "_released"] = false
		
		input.dummy[action] = false
		input.dummy[action .. "_pressed"] = false
		input.dummy[action .. "_released"] = false


		if input.mapping[action].joystick_axis then 
			input[action .. "_amount"] = 0
			input.dummy[action .. "_amount"] = 0
		end

	end

	for vector, _ in pairs(input.vectors) do
		g[vector] = {
			normalized = vector .. "_normalized",
			clamped = vector .. "_clamped"
		}
		input[vector] = Vec2(0, 0)
		input.dummy[vector] = Vec2(0, 0)
		input[vector .. "_normalized"] = Vec2(0, 0)
		input.dummy[vector .. "_normalized"] = Vec2(0, 0)
		input[vector .. "_clamped"] = Vec2(0, 0)
		input.dummy[vector .. "_clamped"] = Vec2(0, 0)

	end
	
end

function input.joystick_added(joystick)
	input.joysticks[#input.joysticks+1] = joystick
end

function input.joystick_removed(joystick)
	for i, joy in ipairs(input.joysticks) do
		if joy == joystick then
			table.remove(input.joysticks, i)
			break
		end
	end
end

function input.check_input_combo(table, joystick, input_table)
	-- if table == nil then
	-- 	return false
	-- end
	local pressed = false

	for _, keycombo in ipairs(table) do
		if type(keycombo) == "string" then
			if joystick == nil then 
				if input_table.keyboard_held[keycombo] ~= nil then
					pressed = true
				end
			else
				if input_table.joystick_held[keycombo] ~= nil then
					pressed = true
				end
			end

		else
			local all_pressed = true
			for _, key in ipairs(keycombo) do
				if joystick == nil then 
					if input_table.keyboard_held[key] == nil then
						all_pressed = false
						break
					end
				else
					if input_table.joystick_held[key] == nil then
						all_pressed = false
						break
					end
				end
			end
			pressed = all_pressed
		end

		if pressed then
			break
		end

	end
	return pressed 

end

function input.process(table)

	local g = input.generated_action_names

	for action, _ in pairs(table.mapping) do
		table[g[action].pressed] = false
		table[g[action].released] = false
	end

	for action, mapping in pairs(table.mapping) do
		local pressed = false

		if mapping.debug and not debug.enabled then
			goto skip
		end

		if input.check_input_combo(mapping.keyboard, nil, table) then
			pressed = true
		end

		for _, joystick in ipairs(input.joysticks) do
			if input.check_input_combo(mapping.joystick, joystick, table) then
				pressed = true
			end

			if pressed then break end

			if mapping.joystick_axis then
				local axis = mapping.joystick_axis.axis
				local dir = mapping.joystick_axis.dir
				local value = joystick:getGamepadAxis(axis)
				local deadzone = mapping.joystick_axis.deadzone or 0.5
				if dir == 1 then
					if value > deadzone then
						pressed = true
						table[g[action].amount] = abs(value)
					end
				else
					if value < -deadzone then
						pressed = true
						table[g[action].amount] = abs(value)
					end
				end
				if not pressed then
					table[g[action].amount] = 0
				end
			end
			if pressed then break end
		end
		
		if pressed then
			if not table[action] then
				table[g[action].pressed] = true
			end
			if table[g[action].amount] == 0 then
				table[g[action].amount] = 1
			end
		else
			if table[action] then
				table[g[action].released] = true
			end
			table[g[action].amount] = 0
		end

		
		table[action] = pressed
		::skip::
	end

	for k, dirs in pairs(table.vectors) do

		local v = table[k]
		v.x = 0
		v.y = 0

		if table[g[dirs.left].amount] then
			v.x = v.x - table[g[dirs.left].amount]
		elseif table[dirs.left] then
			v.x = v.x - 1
		end
		if table[g[dirs.right].amount] then
			v.x = v.x + table[g[dirs.right].amount]
		elseif table[dirs.right] then
			v.x = v.x + 1
		end
		if table[g[dirs.up].amount] then
			v.y = v.y - table[g[dirs.up].amount]
		elseif table[dirs.up] then
			v.y = v.y - 1
		end
		if table[g[dirs.down].amount] then
			v.y = v.y + table[g[dirs.down].amount]
		elseif table[dirs.down] then
			v.y = v.y + 1
		end

		table[k] = v

		local nv = table[g[k].normalized]
		local nx, ny = vec2_normalized(v.x, v.y)
		nv.x = nx
		nv.y = ny

		local cv = table[g[k].clamped]
		local cx, cy = v.x, v.y
		if vec2_magnitude(v.x, v.y) > 1 then
			cx, cy = vec2_normalized(v.x, v.y)
		end
		cv.x = cx
		cv.y = cy
		-- print(v)
	end

    for k, v in pairs(table.keyboard_held) do
        if v == -1 then
            table.keyboard_held[k] = nil
        end
    end
	
    for k, v in pairs(table.joystick_held) do
        if v == -1 then
            table.joystick_held[k] = nil
        end
    end
	
	for k, v in pairs(table.mouse) do
		if v == -1 then
			table.mouse[k] = nil
		end
	end

    -- if debug.enabled then
        -- dbg("mouse dxy", input.mouse.dxy)
    -- end
	
	input.mouse.dxy.x = input.mouse.pos.x - input.mouse.prev_pos.x
	input.mouse.dxy.y = input.mouse.pos.y - input.mouse.prev_pos.y
	
	input.mouse.prev_pos.x = input.mouse.pos.x
    input.mouse.prev_pos.y = input.mouse.pos.y

    input.mouse.prev_wheel.x = input.mouse.wheel.x
	input.mouse.prev_wheel.y = input.mouse.wheel.y

    -- if input.mouse.dxy.x ~= 0 or input.mouse.dxy.y ~= 0 then
	-- 	print(input.mouse.dxy)
	-- end

end	

function input.update(dt)
	input.process(input)
end


function input.keypressed(key)
	if input.keyboard_held[key] == nil then
		input.keyboard_held[key] = gametime.frames
		input.signals.key_pressed:emit(key)
	end

end

function input.keyreleased(key)
	if input.keyboard_held[key] == gametime.frames then
		input.keyboard_held[key] = -1
	else
		input.keyboard_held[key] = nil
	end
	input.signals.key_released:emit(key)
end

function input.joystick_pressed(joystick, button)
	if input.joystick_held[button] == nil then
		input.joystick_held[button] = gametime.frames
		input.signals.joystick_pressed:emit(joystick, button)
	end
end

function input.joystick_released(joystick, button)
	if input.joystick_held[button] == gametime.frames then
		input.joystick_held[button] = -1
	else
		input.joystick_held[button] = nil
	end
	input.signals.joystick_released:emit(joystick, button)

end

function input.mouse_pressed(x, y, button)
	if button == 1 then
		if input.mouse.lmb == nil then
			input.mouse.lmb = gametime.frames
			input.signals.mouse_pressed:emit(x, y, button)
		end
	end
	if button == 2 then
		if input.mouse.rmb == nil then
			input.mouse.rmb = gametime.frames
			input.signals.mouse_pressed:emit(x, y, button)
		end
	end
	if button == 3 then
		if input.mouse.mmb == nil then
			input.mouse.mmb = gametime.frames
			input.signals.mouse_pressed:emit(x, y, button)
		end
	end
	
end

function input.mouse_released(x, y, button)
	if button == 1 then
		if input.mouse.lmb == gametime.frames then
			input.mouse.lmb = -1
		else
			input.mouse.lmb = nil
		end
	end
	if button == 2 then
		if input.mouse.rmb == gametime.frames then
			input.mouse.rmb = -1
		else
			input.mouse.rmb = nil
		end
	end
	if button == 3 then
		if input.mouse.mmb == gametime.frames then
			input.mouse.mmb = -1
		else
			input.mouse.mmb = nil
		end
	end
	input.signals.mouse_released:emit(x, y, button)
end

function input.mouse_moved(x, y, dxy, dy, istouch)

	local mposx, mposy = graphics.screen_pos_to_canvas_pos(x, y)
	input.mouse.pos.x = (mposx)
    input.mouse.pos.y = (mposy)
	if debug.enabled then
		dbg("mouse_pos", "(" .. tostring(floor(input.mouse.pos.x)) .. ", " ..  tostring(floor(input.mouse.pos.y)) .. ")")
	end
	input.mouse.is_touch = istouch

end

function input.mouse_wheel_moved(dx, dy)
	input.mouse.wheel.x = dx
    input.mouse.wheel.y = dy
	input.signals.mouse_wheel_moved:emit(dx, dy)
end

return input
