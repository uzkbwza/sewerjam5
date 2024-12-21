local Camera = require "obj.camera"
local bump = require "lib.bump"
local shash = require "lib.shash"
local GameMap = require "map.GameMap"

local DEFAULT_CELL_SIZE = tilesets.TILE_SIZE * 2

-- represents an area of the game where objects can exist in space and interact with each other
local World = GameObject:extend("World")

-- Helper functions
local function add_to_table(array, obj)
	array:push(obj)
end

local function remove_from_array(array, obj)
	array:remove(obj)

end

function World:new(x, y, param_table)
    World.super.new(self, x, y)

    param_table = param_table or {}

    self.world = self

    self.objects = bonglewunch()

    self.update_objects = bonglewunch()

    self.bump_world = nil

    self.draw_sort = nil

    self.world_sfx = bonglewunch()
    self.sfx_polyphony = {}
    self.sfx_sources_playing = {}


    self.follow_camera = true
    self.input = input.dummy

    self:add_sequencer()
    self:add_elapsed_ticks()
end

function World:create_draw_grid()
    self.draw_grid = self:add_spatial_grid("draw_grid", self.draw_cell_size or 64)
    self.automatic_draw_culling = true
end

function World:create_camera()
	self.camera = self:add_object(Camera())
	return self.camera
end

function World.z_sort(a, b)
	return (a.z_index or 0) < (b.z_index or 0)
end

function World.y_sort(a, b)
	local az = a.z_index or 0
	local bz = b.z_index or 0

	if az < bz then
        return true
	elseif az > bz then
		return false
	end

	local avalue = a.pos.y + az
	local bvalue = b.pos.y + bz
	if avalue == bvalue then
		return a.pos.x < b.pos.x
	end
	return avalue < bvalue
end

function World:create_bump_world(cell_size)
	cell_size = cell_size or DEFAULT_CELL_SIZE
	self.bump_world = bump.newWorld(cell_size)
end

function World:get_update_objects()
	return self.update_objects
end

function World:update_shared(dt)	
	audio.set_position(self.camera.pos.x, self.camera.pos.y, self.camera.z_pos)

	local update_objects = self:get_update_objects()

	if self.update_sort then
		table.sort(update_objects, self.update_sort)
		if update_objects == self.update_objects then
			for i, obj in (update_objects:ipairs()) do
				self.update_indices[obj] = i
			end
		end
	end

	for _, obj in (update_objects:ipairs()) do
		obj:update_shared(dt)
	end

	for _, src in (self.world_sfx:ipairs()) do
        if (not src) or (not src.isPlaying) or (not src:isPlaying()) then
            self.world_sfx:remove(src)
			if src.release then
				src:release()
			end
		end
	end

    if self.deferred_functions then
        for _, t in ipairs(self.deferred_functions) do
            local func, args = unpack(t)
            func(unpack(args))
        end
        table.clear(self.deferred_functions)
    end
	
	World.super.update_shared(self, dt)
end

function World:update(dt)
end

function World:add_tag(object, tag)
    self.tags = self.tags or {}
    self.tags[tag] = self.tags[tag] or bonglewunch()
    self.tags[tag]:push(object)
	signal.connect(object, "destroyed", self, "remove_tag_" .. tag, function()
		self:remove_tag(object, tag)
	end)
end

function World:remove_tag(object, tag)
    if self.tags and self.tags[tag] then
        self.tags[tag]:remove(object)
    end
    signal.disconnect(object, "destroyed", self, "remove_tag_" .. tag)
end

---@return bonglewunch
function World:get_objects_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]
    end
    return nil
end

function World:get_first_object_with_tag(tag)
    if self.tags and self.tags[tag] then
        return self.tags[tag]:peek(1)
    end
    return nil
end

function World:add_spatial_grid(name, cell_size)
	self[name] = shash.new(cell_size or DEFAULT_CELL_SIZE)
	return self[name]
end

function World:add_to_spatial_grid(obj, grid_name, get_rect_function)
    if not self[grid_name] then
        error("No spatial grid with name " .. grid_name)
    end

	if self[grid_name]:has_object(obj) then
		return
	end
	
    if get_rect_function == nil then
		get_rect_function = function()
			local dist = tilesets.TILE_SIZE
			local posx, posy = obj.pos.x, obj.pos.y
			return posx - dist / 2, posy - dist / 2, dist, dist
		end
	end

	local grid = self[grid_name]

	local x, y, w, h = get_rect_function()
	grid:add(obj, x, y, w, h)

	if signal.get(obj, "moved") then
		signal.connect(obj, "moved", self, "update_spatial_grid_" .. grid_name, function()
			local x, y, w, h = get_rect_function()
			grid:update(obj, x, y, w, h)
		end)
	end

	if signal.get(obj, "destroyed") then
		signal.connect(obj, "destroyed", self, "remove_from_spatial_grid_" .. grid_name, function()
			self:remove_from_spatial_grid(obj, grid_name)
		end, true)
	end
end

function World:remove_from_spatial_grid(obj, grid_name)
	if not self[grid_name] then
		return
	end

	self[grid_name]:remove(obj)
    signal.disconnect(obj, "moved", self, "update_spatial_grid_" .. grid_name)
	signal.disconnect(obj, "destroyed", self, "remove_from_spatial_grid_" .. grid_name)
end

function World:add_to_draw_grid(obj)
	self:add_to_spatial_grid(obj, "draw_grid", function()
		return obj:get_draw_rect(function() return self:get_object_draw_position(obj) end)
	end)
end

function World:remove_from_draw_grid(obj)
    self:remove_from_spatial_grid(obj, "draw_grid")
end

function World:query_spatial_grid(grid_name, x, y, w, h, t)
	return self[grid_name]:query(x, y, w, h, t)
end

function World:defer(func, ...)
	self.deferred_functions = self.deferred_functions or {}
	table.insert(self.deferred_functions, {func, ...})
end

function World:get_objects_in_draw_rect(x, y, w, h)
	self.draw_object_table = self.draw_object_table or {}
	table.clear(self.draw_object_table)
	self.add_to_draw_cache = self.add_to_draw_cache or function(obj)
		table.insert(self.draw_object_table, obj)
	end
	self.draw_grid:each(x, y, w, h, self.add_to_draw_cache)
	return self.draw_object_table
end

function World:get_visible_objects()
	return self:get_objects_in_draw_rect(-self.camera_offset.x, -self.camera_offset.y, self.viewport_size.x,
		self.viewport_size.y)
end

function World:get_mouse_position()
	return input.mouse.pos.x - self.camera_offset.x, input.mouse.pos.y - self.camera_offset.y
end

function World:get_draw_rect()
	return -self.camera_offset.x, -self.camera_offset.y, self.viewport_size.x, self.viewport_size.y,
		-self.camera_offset.x + self.viewport_size.x, -self.camera_offset.y + self.viewport_size.y,
		-self.camera_offset.y + self.viewport_size.y
end

function World:draw()
	-- TODO: this is generating lots of garbage. fix it
	local culled_objects = self:get_visible_objects()

	if self.draw_sort then
		table.sort(culled_objects, self.draw_sort)
	end

	for _, obj in ipairs(culled_objects) do
		if obj.draw_shared then
			obj:draw_shared()
		elseif obj.draw then
			obj:draw()
		end
	end

	if debug.can_draw() then
		if self.bump_world or self.box_world then
			for _, obj in ipairs(culled_objects) do
				if obj.debug_draw_bounds_shared then obj:debug_draw_bounds_shared() end
			end
		end

		for _, obj in ipairs(culled_objects) do
			if obj.debug_draw_shared then obj:debug_draw_shared() end
		end
	end
end

function World:get_camera_offset()
	local offset_x, offset_y = 0, 0
	local zoom = 1.0

	if self.follow_camera then
		zoom = self.camera.zoom

		if self.camera.following then
			offset_x, offset_y = self:get_object_draw_position(self.camera.following)
		else
			offset_x, offset_y = self:get_object_draw_position(self.camera)
		end

		offset_x, offset_y = self.camera:clamp_to_limits(offset_x, offset_y)

		local local_offset_x, local_offset_y = self.camera:get_draw_offset()

		offset_x = offset_x + local_offset_x
		offset_y = offset_y + local_offset_y

		offset_y = -offset_y + (self.viewport_size.y / 2) / zoom
		offset_x = -offset_x + (self.viewport_size.x / 2) / zoom
	end

	-- return Vec2(0, 0), 1
	return offset_x, offset_y, zoom
end

function World:draw_shared()


	self.camera.viewport_size = self.viewport_size


	local offset_x, offset_y, zoom = self:get_camera_offset()

	self.camera_offset = self.camera_offset or Vec2()
	self.camera_offset.x = floor(offset_x)
	self.camera_offset.y = floor(offset_y)

	graphics.push()
	graphics.origin()
	graphics.set_color(1, 1, 1, 1)
	graphics.scale(zoom, zoom)

	graphics.translate(offset_x, offset_y)

	self:draw()

	if self.bump_world and debug.can_draw() then
		-- self:bump_draw()
	end

	graphics.pop()
end

function World.bump_draw_filter(obj)
	if Object.is(obj, GameObject) then return false end

	if type(obj) == "table" and obj.collision_rect then
		return true
	end

	return false
end

function World:bump_draw()
	-- for _, object in self.bump_world do
	local x, y, w, h = self:get_draw_rect()
	self.bump_draw_query_table = self.bump_draw_query_table or {}
	local objects = self.bump_world:queryRect(x, y, w, h, World.bump_draw_filter, self.bump_draw_query_table)
	for _, object in ipairs(objects) do
		graphics.draw_collision_box(object.collision_rect, object.solid and palette.blue or palette.orange)
	end
	-- end
end

function World:enter_shared()
	World.super.enter_shared(self)
	self.camera:move_to(self.viewport_size.x / 2, self.viewport_size.y / 2)
end

-- function World:load_game_map(map_name, tile_process_func)
-- 	self.map = GameMap.load(map_name)
--     if self.bump_world then self.map:bump_init(self.bump_world) end
--     self.map:build(tile_process_func or self.tile_process_func)
-- 	self:process_map_objects(self.map.objects)
-- end

-- function World:process_map_objects(objects)
-- 	for _, object_data in ipairs(objects) do
-- 		local x, y, z, object_name = unpack(object_data)
-- 		self:process_map_object(x, y, z, object_name)
-- 	end
-- end

-- function World:process_map_object(x, y, z, object_name)
-- 	print("unprocessed object!", x, y, z, object_name)
-- end

function World:get_object_draw_position(obj)
	return obj.pos.x, obj.pos.y
end

function World:manipulate_object_draw_position(obj)

end

function World:get_input_table()
	return self:get_base_world().input
end

function World:get_camera_bounds()
	return -self.camera_offset.x, -self.camera_offset.y, self.camera_offset.x + self.viewport_size.x,
		self.camera_offset.x + self.viewport_size.y
end

function World:get_base_world()
	local s = self.world
	while s ~= s.world do
		s = s.world
	end
	return s
end

function World:add_object(obj)
	if obj.world then
		error("cannot move objects between worlds")
	end

	obj.world = self

	add_to_table(self.objects, obj)

	self:add_to_update_tables(obj)

	if self.automatic_draw_culling then
		if signal.get(obj, "visibility_changed") then
			signal.connect(obj, "visibility_changed", self, "on_object_visibility_changed", (function()
				if obj.visible then
					self:add_to_draw_grid(obj)
				else
					self:remove_from_draw_grid(obj)
				end
			end))
		end
	end

	if signal.get(obj, "update_changed") then
		signal.connect(obj, "update_changed", self, "on_object_update_changed", (function()
			if not obj.static then
				add_to_table(self.update_objects, obj)
			else
				remove_from_array(self.update_objects, obj)
			end
		end))
	end

	signal.connect(obj, "destroyed", self, "remove_object", nil, true)
	self:bind_destruction(obj)

	if obj.is_bump_object then
		obj:set_bump_world(self.bump_world)
	end

	obj:enter_shared()

	if obj.children then
		for _, child in ipairs(obj.children) do
			child:tpv_to(obj.pos)
			self:add_object(child)
		end
	end

	return obj
end

function World:add_to_update_tables(obj)
	if not obj.static then
		add_to_table(self.update_objects, obj)
	end

	if self.draw_grid and obj.draw and obj.visible then
		self:add_to_draw_grid(obj)
	end
end

function World:remove_object(obj)
	if not obj then return end

	if not obj.world == self then
		return
	end

	obj.world = nil
	obj.base_world = nil
	remove_from_array(self.objects, obj)
	remove_from_array(self.update_objects, obj)
	self:remove_from_draw_grid(obj)
    if obj.is_bump_object then
        self.bump_world:remove(obj)
        obj:set_bump_world(nil)
    end
	obj:prune_signals()
end

return World
