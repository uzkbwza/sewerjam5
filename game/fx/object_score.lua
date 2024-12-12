local ObjectScore = Effect:extend("ObjectScore")

function ObjectScore:new(x, y, score)
    ObjectScore.super.new(self, x, y)
    self.score = score
	self.duration = 30 + score / 10
    self.font = graphics.font["PressStart2P-8"]
	self.z_index = -1
	global_state:add_score(self.score)
end

function ObjectScore:update(dt)
end

function ObjectScore:draw(elapsed, ticks, t)
    graphics.set_font(self.font)
	if ticks > self.duration - 10 and floor(ticks / 2) % 2 == 0 then return end
    local text = self.score
    local text_width = self.font:getWidth(text)

	local yoffs = ticks / 2

	
	if self.score >= 500 then
		local layers = min(floor(yoffs), self.score / 200)
        for i = 1, layers do
            graphics.set_color(palette.white)
            graphics.print_outline_no_diagonals(graphics.color_flash(i, 2), self.score, -text_width / 2,
                -floor(yoffs) + (layers - i))
        end
		-- graphics.set_color(graphics.color_flash(2, 1))
	else
		-- graphics.set_color(palette.white)
	end
	graphics.set_color(palette.white)

	
    graphics.print_outline_no_diagonals(self.score >= 500 and graphics.color_flash(0, 2) or palette.black, self.score, -text_width / 2, -floor(yoffs))
end

return ObjectScore

