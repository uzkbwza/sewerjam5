local MainScreen = Screen:extend()

function MainScreen:new()
	MainScreen.super.new(self)
    self.clear_color = palette.lilac
	
    self.world = self:add_world(World())
	self.world:create_bump_world()
    -- self.world:load_tile_map("map1")

end

function MainScreen:update(dt)
	MainScreen.super.update(self, dt)
	if self.input.debug_editor_toggle_pressed then
		self:push("LevelEdit")
	end
end

function MainScreen:enter()

end

return MainScreen
