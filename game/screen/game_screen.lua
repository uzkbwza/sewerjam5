local Screen = GameObject:extend()

function Screen:new(x, y, viewport_size_x, viewport_size_y)

    Screen.super.new(self, x, y)
	
	self.screen = self

    self.blocks_render = true
    self.blocks_input = true

	self.worlds = {}

    self:add_sequencer()
    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self.screen_pushed = Signal()
    self.screen_popped = Signal()

    self.interp_fraction = 0

    self.viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
	self.canvas = love.graphics.newCanvas(viewport_size_x or conf.viewport_size.x, viewport_size_y or conf.viewport_size.y)
    self.offset = Vec2(0, 0)
	self.zoom = 1
end

function Screen.get_world(world)
	if type(world) == "string" then
		return require("world." .. world)()
	end
	return world
end

function Screen:update_shared(dt)
    self:update_worlds(dt)
    Screen.super.update_shared(self, dt)
end

function Screen:add_world(world)
    table.insert(self.worlds, world)
    return world
end

function Screen:update_worlds(dt)
	for _, world in ipairs(self.worlds) do
		self:update_world(world, dt)
	end
end

function Screen:update_world(world, dt)
	world.viewport_size = self.viewport_size
	world:update_shared(dt)
end

function Screen:update(dt)
end

function Screen:draw()
end

function Screen:draw_shared()

    graphics.push("all")
    graphics.origin()
    graphics.set_canvas(self.canvas)
	if self.clear_color then
		graphics.clear(self.clear_color.r, self.clear_color.g, self.clear_color.b, self.clear_color.a or 1)
	end

	graphics.set_color(1, 1, 1, 1)
    graphics.scale(self.zoom, self.zoom)
    -- graphics.translate((offset.x), (offset.y))
    graphics.translate(self.offset.x, self.offset.y)
	for _, world in ipairs(self.worlds) do
		world:draw_shared()
	end

    self:draw()
	
	graphics.set_color(1, 1, 1, 1)

    graphics.pop()
    graphics.draw(self.canvas, self.pos.x, self.pos.y, 0, 1, 1)
end

function Screen:enter_shared()
    self.input = input.dummy
    self:enter()
end

function Screen:exit_shared()
    self:exit()
end

function Screen:enter()

end

function Screen:exit()
end

function Screen:push(screen_name)
    self.screen_pushed:emit(screen_name)
end

function Screen:pop()
    self.screen_popped:emit(self)
end

function Screen:get_input_table()
	return self:get_base_screen().input
end

function Screen:get_base_screen()
	local s = self.screen
	while s ~= s.screen do
		s = s.screen
	end
	return s
end


return Screen
