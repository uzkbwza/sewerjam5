local GameObject = Object:extend()
local Sensor = require("obj.sensor")

GameObject.DEFAULT_DRAW_CULL_DIST = 64

function GameObject:new(x, y)

	self:add_signal("destroyed")
	self:add_signal("removed")
    self:add_signal("moved")
	
	if x then
		if type(x) == "table" then
			self.pos = Vec2(x.x, x.y)
		else
			self.pos = Vec2(x, y)
		end
	else
		self.pos = Vec2(0, 0)
	end

	
	self.rot = 0
	self.scale = Vec2(1, 1)
	
	self._update_functions = {}
	self._draw_functions = {}
	
	self.screen = nil
	
	self.visible = true
	
	-- signals
	self.visibility_changed = nil
	self.update_changed = nil
	self.static = false
	
	self.is_bump_object = nil
	
	self.z_pos = 0
    self.z_index = 0

end

function GameObject:get_draw_rect()
	local cull_dist = self.draw_cull_dist or GameObject.DEFAULT_DRAW_CULL_DIST
	return self.pos.x - cull_dist / 2, self.pos.y - cull_dist / 2, cull_dist, cull_dist
end

function GameObject:on_moved()
	-- self.moved:emit()
    if self._move_functions then
        for _, v in ipairs(self._move_functions) do
            v(self)
        end
    end
	self.moved:emit()
end

function GameObject.dummy() end

function GameObject:add_sensor(rect, monitoring, monitorable, filter, entered_function, update_function, exit_function)
	local sensor = Sensor(rect, monitoring, monitorable, filter, entered_function, update_function, exit_function, self)
	if self.sensors == nil then
		self.sensors = {}
		self:add_update_function(GameObject.update_sensors)
		self:add_move_function(GameObject.move_sensors)
	end

	table.insert(self.sensors, sensor)
	return sensor
end

function GameObject:update_sensors(dt)
	for _, sensor in ipairs(self.sensors) do
		sensor:update(dt)
	end
end

function GameObject:move_sensors(name)
	for _, sensor in ipairs(self.sensors) do
		if sensor.name == name then
			sensor:move_to(self.pos.x, self.pos.y)
			return
		end
	end
end


function GameObject:add_sequencer()
	assert(self.sequencer == nil, "GameObject:add_sequencer() called but sequencer already exists")
	self.sequencer = Sequencer()
	self:add_update_function(function(obj, dt) obj.sequencer:update(dt) end)
end

function GameObject:add_elapsed_time()
	self.elapsed = 1
	self:add_update_function(function(obj, dt) obj.elapsed = obj.elapsed + dt end)
end

function GameObject:add_elapsed_ticks()
	assert(self.elapsed ~= nil, "GameObject:add_elapsed_ticks() called but no elapsed time implemented")
	self.tick = 1
	self:add_update_function(function(obj, dt) obj.tick = floor(obj.elapsed) end)
end

function GameObject:add_update_function(func)
	if self._update_functions == nil then
		self._update_functions = {}
	end
	table.insert(self._update_functions, func)
end

function GameObject:add_draw_function(func)
	if self._draw_functions == nil then
		self._draw_functions = {}
	end
	table.insert(self._draw_functions, func)
end

function GameObject:add_move_function(func)
	if self._move_functions == nil then
		self._move_functions = {}
	end
	table.insert(self._move_functions, func)
end

-- does not affect transform, only world traversal
function GameObject:add_child(child)
	if self.children == nil then
		self.children = {}
		self:add_update_function(GameObject.update_children)
		child.destroyed:connect(nil, function() self:remove_child(child) end)
	end
	table.insert(self.children, child)
	child.parent = self
end

function GameObject:remove_child(child)
	table.fast_remove(self.children, function (v) return v == child end)
end

function GameObject:update_shared(dt, ...)
	-- assert(self.update ~= nil, "GameObject:update_shared() called but no update function implemented")
	for _, func in ipairs(self._update_functions) do
		func(self, dt, ...)
	end
	self:update(dt, ...)
end

function GameObject:add_update_signals()
	self:add_signal("update_changed")
	self:add_signal("visibility_changed")
end

function GameObject:spawn_object(obj, x, y)
	obj.pos = self.pos:clone() + Vec2(x or 0, y or 0)
	self.screen:add_object(obj)
	return obj
end

function GameObject:get_input_table()
	return self.base_screen:get_input_table()
end

function GameObject:movev(dv)
	self:move(dv.x, dv.y)
end

function GameObject:move(dx, dy)
	self:move_to(self.pos.x + dx, self.pos.y + dy)
end

function GameObject.default_bump_filter(item, other)
	if other and other.solid then
		return "slide"
	else 
		return "cross"
	end
end

function GameObject:hide()
	if not self.visible then
		return
	end
	self.visible = false
	self.visibility_changed:emit()
end

function GameObject:show()
	if self.visible then
		return
	end
	self.visible = true
	self.visibility_changed:emit()
end


function GameObject:bump_track_overlaps()
	local cr = self.collision_rect

	local overlaps = {}

	local query = self.bump_world:queryRect(self.pos.x + cr.x, self.pos.y + cr.y, cr.width, cr.height, self.bump_filter)
	
	for _, other in ipairs(query) do
		if other == self then
			goto continue
		end
		if other and not (other.solid) then
			if self.overlaps[other] == nil then
				self:object_entered_rect_shared(other)
			end
			overlaps[other] = true
		end
		::continue::
	end

	for k, _ in pairs(self.overlaps) do 
		if not overlaps[k] then 
			self:object_exited_rect_shared(k)
		end
	end

	self.overlaps = overlaps

end

function GameObject:add_object_entered_rect_function(func)
	if self._object_entered_rect_functions == nil then
		self._object_entered_rect_functions = {}
	end
	table.insert(self._object_entered_rect_functions, func)
end

function GameObject:add_object_exited_rect_function(func)
	if self._object_exited_rect_functions == nil then
		self._object_exited_rect_functions = {}
	end
	table.insert(self._object_exited_rect_functions, func)
end

function GameObject:object_entered_rect_shared(other)
	if self._object_entered_rect_functions then
		for _, v in ipairs(self._object_entered_rect_functions) do
			v(self, other)
		end
	end
	
	self:object_entered_rect(other)
end

function GameObject:object_entered_rect(other)

end

function GameObject:object_exited_rect_shared(other)
	if self._object_exited_rect_functions then
		for _, v in ipairs(self._object_exited_rect_functions) do
			v(self, other)
		end
	end

	self:object_exited_rect(other)
end

function GameObject:object_exited_rect(other)
end

function GameObject:get_overlapping_objects_in_rect(rect, object_filter)
	local objects = {}
	rect = rect + self.pos
	local query = self.bump_world:queryRect(rect.x, rect.y, rect.width, rect.height, object_filter)
	for _, v in pairs(query) do
		if not v.collision_rect and not v.pos then goto continue end
			if rect:intersects(v.collision_rect + v.pos) then
				table.insert(objects, v)
			end
		::continue::
	end
	return objects
end

function GameObject:get_closest_overlapping_object(rect, object_filter)
	local closest = nil
	local closest_dist = math.huge

	if rect ~= nil then
		rect = rect + self.pos
		local query = self.bump_world:queryRect(rect.x, rect.y, rect.width, rect.height, object_filter)
		for _, v in pairs(query) do
			if not v.collision_rect and not v.pos then goto continue end
				if rect:intersects(v.collision_rect + v.pos) then
					if v ~= self and self.pos:distance_squared(v.pos) < closest_dist then
						closest = v
						closest_dist = self.pos:distance_squared(v.pos)
					end
				end
			::continue::
		end
		return closest
	end

	for k, _ in pairs(self.overlaps) do
		if self.pos:distance_squared(k.pos) < closest_dist then
			closest = k
			closest_dist = self.pos:distance_squared(k.pos)
		end
	end
	return closest
end

local default_bump_info = {
	rect = Rect.centered(0, 0, 1, 1),
	solid = true,
	filter = GameObject.default_bump_filter,
	track_overlaps = false,
}

function GameObject:bump_init(info_table)

	-- initializes bump.lua physics with AABB collisions and spatial hashing. useful even for non-physics objects for collision detection for e.g. coins
	info_table = info_table or default_bump_info

	-- TODO: position centered on feet?
	if not (info_table.rect.x == -info_table.rect.width / 2 and info_table.rect.y == -info_table.rect.height / 2) then 
		print("warning: collision rect will be centered")
	end

	local filter = info_table.filter or default_bump_info.filter

	if info_table.track_overlaps == nil then 
		info_table.track_overlaps = default_bump_info.track_overlaps
	end

	local track_overlaps = info_table.track_overlaps

	if track_overlaps then
		self.tracks_overlaps = true
		self.overlaps = {}
		self:add_update_function(self.bump_track_overlaps)
	end

	if info_table.solid == nil then 
		info_table.solid = default_bump_info.solid
	end

	self.solid = info_table.solid
	self.collision_rect = (info_table.rect) or default_bump_info.rect
	self.is_bump_object = true
	self.move_to = GameObject.move_to_bump
	self.bump_filter = filter
	self.bump_filter_checks = {}
	self.bump_world = nil
	self.colliding_objects = {}

end

function GameObject:set_bump_collision_rect(rect)
	self.collision_rect = rect
	self.world:update(self, self.pos.x - self.collision_rect.width / 2, self.pos.y - self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
end

function GameObject:set_bump_world(world)
	if self.bump_world then
		if self.bump_world:hasItem(self) then
			self.bump_world:remove(self)
		end
	end
	self.bump_world = world
	if world then
		world:add(self, self.pos.x - self.collision_rect.width / 2, self.pos.y - self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
	end

	if self.sensors then 
		for _, sensor in ipairs(self.sensors) do
			sensor:add_bump_world(world)
		end
	end
end

function GameObject:move_to_bump(x, y, filter, noclip)

	local old_x = self.pos.x
	local old_y = self.pos.y

	if noclip or self.noclip then
		self.pos.x = x
		self.pos.y = y
		if old_x ~= self.pos.x or old_y ~= self.pos.y then
			if self.bump_world then
				self.bump_world:update(self, x, y)
			end
			self:on_moved()
		end
		return
	end
	
	filter = filter or self.bump_filter

	local actual_x, actual_y, collisions, num_collisions = self.bump_world:move(self, x - self.collision_rect.width / 2, y - self.collision_rect.height / 2, filter)

	self.pos.x = actual_x + self.collision_rect.width / 2
	self.pos.y = actual_y + self.collision_rect.height / 2

	for i = 1, num_collisions do
		local col = collisions[i]
		self:process_collision(col)
		if col.slide then 
			if self.is_simple_physics_object then 
				self.vel:mul_in_place(col.normal.x ~= 0 and 0 or 1, col.normal.y ~= 0 and 0 or 1)
			end
		end
	end

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function GameObject:process_collision(col)
end

function GameObject:move_toward(x, y, speed)
	local dx, dy = x - self.pos.x, y - self.pos.y
	local dist = sqrt(dx * dx + dy * dy)
	if dist < speed then
		self:move_to(x, y)
	else
		self:move(dx / dist * speed, dy / dist * speed)
	end
end
	

---@diagnostic disable-next-line: duplicate-set-field
function GameObject:move_to(x, y)
	local old_x = self.pos.x
	local old_y = self.pos.y

	self.pos.x = x
	self.pos.y = y

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function GameObject:movev_to(v)
	self:move_to(v.x, v.y)
end

function GameObject:tp_to(x, y)
	-- old method from when interpolation was used
	self:move_to(x, y, nil, true)
end

function GameObject:tpv_to(v)
	self:tp_to(v.x, v.y)
end


function GameObject:set_update(on)
	self.static = not on
	self.update_changed:emit()
end

function GameObject:update(dt, ...)
end

function GameObject:apply_forcev(force)
	self.accel:add_in_place(force.x, force.y)
end

function GameObject:apply_force(forcex, forcey)
	self.accel:add_in_place(forcex, forcey)
end

function GameObject:init_basic_physics()
	if self.vel ~= nil then
		error("init_basic_physics() called but vel already exists")
	end
	self.vel = Vec2(0, 0)
	self.accel = Vec2(0, 0)
	self.impulses = Vec2(0, 0)
	self:add_update_function(GameObject.apply_simple_physics)
	self.drag = 0.5
	self.is_simple_physics_object = true
end

function GameObject:apply_simple_physics(dt)
	local ax, ay = vec2_mul_scalar(self.accel.x, self.accel.y, dt)
	self.vel:add_in_place(ax, ay)
	self:move_to(self.pos.x + self.vel.x * dt, self.pos.y + self.vel.y * dt)
	self.accel:mul_in_place(0)
	self.impulses:mul_in_place(0)
	if self.drag > 0 then 
		self.vel:mul_in_place(pow(1 - self.drag, dt))
	end
end

function GameObject:graphics_transform()
	-- using the api here directly because it's faster
	local pos = self.pos
	local scale = self.scale
	love.graphics.translate(pos.x, pos.y + self.z_pos)
	love.graphics.rotate(self.rot)
	love.graphics.scale(scale.x, scale.y)
	love.graphics.setColor(1, 1, 1, 1)
end

function GameObject:draw_shared(...)

	love.graphics.push()

	self:graphics_transform()

	for _, func in ipairs(self._draw_functions) do
		func(self, ...)
	end

	self:draw(...)

	love.graphics.pop()
end

function GameObject:debug_draw_shared(...)
	love.graphics.push()

	self:graphics_transform()

	if self.debug_draw then self:debug_draw(...) end

	love.graphics.pop()
end

function GameObject:debug_draw_bounds_shared()
	love.graphics.push()

	self:graphics_transform()
	
	if self.collision_rect then
		if self.solid then 
			love.graphics.setColor(0, 0.25, 1, 0.125)
		else 
			love.graphics.setColor(1, 0.5, 0, 0.125)
		end
		love.graphics.rectangle("fill", -self.collision_rect.width / 2, -self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
		if self.solid then 
			love.graphics.setColor(0, 0.25, 1, 1.0)
		else 
			love.graphics.setColor(1, 0.5, 0, 1.0)
		end
		love.graphics.rectangle("line", -self.collision_rect.width / 2, -self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
	end

	if self.sensors then
		for _, sensor in ipairs(self.sensors) do
            local color
			local alpha = 1.0
			if sensor.monitoring and sensor.monitorable then
				color = palette.purple
			elseif sensor.monitorable then
				color = palette.green
			elseif sensor.monitoring then
				color = palette.maroon
			else
                color = palette.darkgreyblue
				alpha = 0.25
			end 
			graphics.draw_collision_box(sensor.rect, color, alpha)
		end
	end

	self:debug_draw_bounds()

	love.graphics.pop()
end

function GameObject:debug_draw_bounds()
end

function GameObject:destroy()
	self.is_destroyed = true
	self:exit_shared()
	if self.sequencer then
		self.sequencer:destroy()
	end
	self.destroyed:emit()
end

function GameObject:prune_signals()
	for _, v in pairs(self.signals) do 
		v:prune()
	end
end

function GameObject:clear_signals()
	for _, v in pairs(self.signals) do
		v:clear()
	end
end

function GameObject:enter_shared()

	self:enter()
end

function GameObject:enter() end

function GameObject:exit_shared()
    self:exit()
end

function GameObject:to_local(pos)
	return pos - self.pos
end

function GameObject:to_world(pos)
	return pos + self.pos
end

function GameObject:add_signal(signal_name)
	self[signal_name] = GameObjectSignal(self)
	self.signals = self.signals or {}
	table.insert(self.signals, self[signal_name])
end

function GameObject:exit() end

return GameObject
