local Pausescreen = Screen:extend()

function Pausescreen:new()
	Pausescreen.super.new(self)
	self.blocks_render = false
end

function Pausescreen:update(dt)
	if self.input.menu_pressed then
		self:pop()
	end
end

function Pausescreen:draw()
	Pausescreen.super.draw(self)

	graphics.print("PAUSED", 0, 0)
end

function Pausescreen:enter()
end

return Pausescreen
