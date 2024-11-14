local Camera = require("obj.camera")
local bump = require("lib.bump")
local shash = require("lib.shash")
local sti = require("lib.sti")

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
	
	if self.map then
		self.map:update(dt)
	end

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
    
	if obj.moved then
        obj.moved:connect_named(self, function()
            local x, y, w, h = obj:get_draw_rect()
            self.draw_grid:update(obj, x, y, w, h)
        end, "update_draw_grid")
    end
	
    if obj.removed then
        obj.removed:connect_named(self, function()
            self:remove_from_draw_grid(obj)
        end, "remove_draw_grid", true)
    end
	
end

function World:remove_from_draw_grid(obj)
	self.draw_grid:remove(obj)
	obj.moved:disconnect("update_draw_grid")
end

function World:get_objects_in_draw_rect(x, y, w, h)

    return self.draw_grid:query(x, y, w, h)
end

function World:get_visible_objects()
	return self:get_objects_in_draw_rect(-self.camera_offset.x, -self.camera_offset.y, self.viewport_size.x, self.viewport_size.y)
end

function World:draw()

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
    local offset = Vec2(0, 0)
    local zoom = 1.0

    if self.follow_camera then
        zoom = self.camera.zoom
        self.camera.viewport_size = self.viewport_size
        offset = self:get_object_draw_position(self.camera)

        if self.camera.following then
            offset = self:get_object_draw_position(self.camera.following)
        end

        offset = self.camera:clamp_to_limits(offset)

        offset.y = -offset.y + (self.viewport_size.y / 2) / zoom
        offset.x = -offset.x + (self.viewport_size.x / 2) / zoom
    end

	-- return Vec2(0, 0), 1
    return offset, zoom
end

function World:draw_shared()

    if self.clear_color then
        graphics.push()
        graphics.origin()
        graphics.clear(self.clear_color.r, self.clear_color.g, self.clear_color.b)
        graphics.pop()
    end

	
	local offset, zoom = self:get_camera_offset()

    self.camera_offset = Vec2(floor(offset.x), floor(offset.y))
    -- self.camera_offset.x = floor(self.camera_offset.x)
    -- self.camera_offset.y = floor(self.camera_offset.y)

    graphics.push()
    graphics.origin()
    graphics.set_color(1, 1, 1, 1)
    graphics.scale(zoom, zoom)
    -- graphics.translate((offset.x), (offset.y))
	
    graphics.translate(offset.x, offset.y)
	
    if self.map then
        self.map:draw(offset.x, offset.y, zoom, zoom)
		if debug.can_draw() then
			self.map:bump_draw(0, 0)
		end
        -- print(self.map.layers)
    end
	

	self:draw()

	

    -- graphics.draw(self.canvas, self.pos.x, self.pos.y, 0, self.viewport_size.x, self.viewport_size.y)
    graphics.pop()

end

function World:load_tile_map(map_name)
    local path = "map/maps/" .. map_name .. ".lua"
    local do_bump = self.bump_world ~= nil
    local do_box = self.box_world ~= nil
	
    local t = {}
    if do_bump then
		table.insert(t, "bump")
    end

    if do_box then
		table.insert(t, "box2d")
	end
	
    local map = sti(path, t)

	self.map = map
	
    if do_bump then
        map:bump_init(self.bump_world)
    end

	if do_box then
		map:box2d_init(self.box_world)
	end
	
end

function World:get_object_draw_position(obj)
    return obj.pos:clone()
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

    if obj.visibility_changed then
        obj.visibility_changed:connect(nil, function()
            if obj.visible then
                self:add_to_draw_grid(obj)
            else
				self:remove_from_draw_grid(obj)
            end
        end)
    end

    if obj.update_changed then
        obj.update_changed:connect(nil, function()
            if not obj.static then
                add_to_array(self.update_objects, self.update_indices, obj)
            else
                remove_from_array(self.update_objects, self.update_indices, obj)
            end
        end)
    end

    obj.destroyed:connect(nil, function() self:remove_object(obj) end, true)

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
	obj.removed:emit()
	obj:prune_signals()
end

return World
