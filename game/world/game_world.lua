local Camera = require("obj.camera")
local bump = require("lib.bump")
local shash = require("lib.shash")
local sti = require("lib.sti")
local GameMap = require "map.gamemap"

-- represents an area of the game where objects can exist in space and interact with each other
local World = GameObject:extend()

-- Helper functions
local function add_to_array(array, indices, obj)
    if indices[obj] then
        return -- Object already in array
    end
    table.insert(array, obj)
    indices[obj] = #array
end

local function remove_from_array(array, indices, obj)
    local index = indices[obj]
    if not index then
        return -- Object not in array
    end
    local last = array[#array]
    array[index] = last
    indices[last] = index
    array[#array] = nil
    indices[obj] = nil
end

function World:new(x, y, param_table)

    World.super.new(self, x, y)
	param_table = param_table or {}
	
	self.world = self

    self.objects = {}
    self.objects_indices = {}

    self.update_objects = {}
    self.update_indices = {}

	self.bump_world = nil

    -- function to sort draw objects
    self.draw_sort = nil
        --[[	example: y-sorting function for draw objects

		self.draw_sort = function(a, b)
			return a.pos.y < b.pos.y
		end

    ]] --
	
	self.draw_grid = shash.new(param_table.draw_cell_size or 64)

    self.blocks_logic = true
    self.blocks_render = true
    self.blocks_input = true

	self.follow_camera = true
	self.input = input.dummy

    self:add_sequencer()
    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self.camera = self:add_object(Camera())

end

function World:create_bump_world(cell_size)
	cell_size = cell_size or 64
	self.bump_world = bump.newWorld(cell_size)

end

function World:get_update_objects()
	return self.update_objects
end

function World:update_shared(dt)
    World.super.update_shared(self, dt)
	self:update(dt)

    local update_objects = self:get_update_objects()

	if self.update_sort then
        table.sort(update_objects, self.update_sort)
		if update_objects == self.update_objects then
			for i, obj in ipairs(update_objects) do
				self.update_indices[obj] = i
			end
		end
	end

    for _, obj in ipairs(update_objects) do
        obj:update_shared(dt)
    end

end

function World:update(dt)
end

function World:add_to_draw_grid(obj)
	local x, y, w, h = obj:get_draw_rect()
    self.draw_grid:add(obj, x, y, w, h)

	if signal.get(obj, "moved") then
        signal.connect(obj, "moved", self, "update_draw_grid", function()
            local x, y, w, h = obj:get_draw_rect()
            self.draw_grid:update(obj, x, y, w, h)
        end)
    end
	
	if signal.get(obj, "removed") then
        signal.connect(obj, "removed", self, "remove_from_draw_grid", nil, true)
    end
	
end

function World:remove_from_draw_grid(obj)
	self.draw_grid:remove(obj)
	signal.disconnect(obj, "moved", self, "update_draw_grid")
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

function World:get_draw_rect()
	return -self.camera_offset.x, -self.camera_offset.y, self.viewport_size.x, self.viewport_size.y
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
        self.camera.viewport_size = self.viewport_size
        offset_x, offset_y = self:get_object_draw_position(self.camera)

        if self.camera.following then
            offset_x, offset_y = self:get_object_draw_position(self.camera.following)
        end

        offset_x, offset_y = self.camera:clamp_to_limits(offset_x, offset_y)

        offset_y = -offset_y + (self.viewport_size.y / 2) / zoom
        offset_x = -offset_x + (self.viewport_size.x / 2) / zoom
    end

	-- return Vec2(0, 0), 1
    return offset_x, offset_y, zoom
end

function World:draw_shared()

    if self.clear_color then
        graphics.push()
        graphics.origin()
        graphics.clear(self.clear_color.r, self.clear_color.g, self.clear_color.b)
        graphics.pop()
    end

	
	local offset_x, offset_y, zoom = self:get_camera_offset()

    self.camera_offset = self.camera_offset or Vec2()
    self.camera_offset.x = floor(offset_x)
	self.camera_offset.y = floor(offset_y)
    -- self.camera_offset.x = floor(self.camera_offset.x)
    -- self.camera_offset.y = floor(self.camera_offset.y)

    graphics.push()
    graphics.origin()
    graphics.set_color(1, 1, 1, 1)
    graphics.scale(zoom, zoom)
    -- graphics.translate((offset.x), (offset.y))
	
    graphics.translate(offset_x, offset_y)
	
    if self.map then
        self.map:draw()

        -- print(self.map.layers)
    end

	if self.bump_world and debug.can_draw() then
		self:bump_draw()
	end

	self:draw()

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
		graphics.draw_collision_box(object.collision_rect, palette.blue)
	end
	-- end
end

function World:enter_shared()
    World.super.enter_shared(self)
	self.camera:move_to(self.viewport_size.x / 2, self.viewport_size.y / 2)
end

function World:load_game_map(map_name, tile_process_func)
	self.map = GameMap.load(map_name)
    if self.bump_world then self.map:bump_init(self.bump_world) end
    self.map:build(tile_process_func or self.tile_process_func)
	self:process_map_objects(self.map.objects)
end

function World:process_map_objects(objects)
	for _, object_data in ipairs(objects) do
        local x, y, z, object_name = unpack(object_data)
		self:process_map_object(x, y, z, object_name)
	end
end

function World:process_map_object(x, y, z, object_name)
	print("unprocessed object!", x, y, z, object_name)
end

function World:get_object_draw_position(obj)
    return obj.pos.x, obj.pos.y
end

function World:spawn_object(obj)
	return self:add_object(obj)
end

function World:get_input_table()
	return self:get_base_world().input
end

function World:get_camera_bounds()
	return -self.camera_offset.x, -self.camera_offset.y, self.camera_offset.x + self.viewport_size.x, self.camera_offset.x + self.viewport_size.y
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
        obj.world:remove_object(obj)
    end

    obj.world = self
    obj.base_world = self:get_base_world()
    add_to_array(self.objects, self.objects_indices, obj)

    self:add_to_update_tables(obj)

    if signal.get(obj, "visibility_changed") then
        signal.connect( obj, "visibility_changed", self, "on_object_visibility_changed", (function()
            if obj.visible then
                self:add_to_draw_grid(obj)
            else
				self:remove_from_draw_grid(obj)
            end
        end))
    end

    if signal.get(obj, "update_changed") then
        signal.connect( obj, "update_changed", self, "on_object_update_changed", (function()
            if not obj.static then
                add_to_array(self.update_objects, self.update_indices, obj)
            else
                remove_from_array(self.update_objects, self.update_indices, obj)
            end
        end))
    end

    signal.connect(obj, "destroyed", self, "remove_object", nil, true)
	self:destroy_when_i_am_destroyed(obj)

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
        add_to_array(self.update_objects, self.update_indices, obj)
    end

    if obj.draw and obj.visible then
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
    remove_from_array(self.objects, self.objects_indices, obj)
    remove_from_array(self.update_objects, self.update_indices, obj)
    self:remove_from_draw_grid(obj)
	if obj.is_bump_object then
		self.bump_world:remove(obj)
		obj:set_bump_world(nil)
	end
	obj:emit_signal("removed")
	obj:prune_signals()
end

return World
