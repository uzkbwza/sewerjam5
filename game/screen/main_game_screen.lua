local MainScreen = Screen:extend()

function MainScreen:new()
	MainScreen.super.new(self)
    self.clear_color = palette.black
	
    self.world = self:add_world(World())
    self.world:create_bump_world()
	self.world:load_game_map("test")

end

function MainScreen:update(dt)
	MainScreen.super.update(self, dt)
	if self.input.debug_editor_toggle_pressed then
		self.game.transition_to_screen("LevelEdit")
	end
end

function MainScreen:draw()
end

function MainScreen:enter()
end

return MainScreen
