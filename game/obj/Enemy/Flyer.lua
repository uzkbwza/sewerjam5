local FlyerEnemy = require("obj.Enemy.Enemy"):extend("FlyerEnemy")

function FlyerEnemy:new(x, y)
    FlyerEnemy.super.new(self, x, y)
    self.curve_amount = 1
	self.score = 250
end

function FlyerEnemy:enter()
	local s = self.sequencer
    s:start(function()
        for i = 1, 5 do
            self:set_visibility(true)
            s:wait(3)
            self:set_visibility(false)
            s:wait(3)
        end
        self:set_visibility(true)
        local cx, cy = self:get_cell()
		local endx = self.world.map.cell_to_world(self.world.map_width, cy, 0) + 16
        local startx = 0
        if cx == self.world.map_width then
			startx = endx
            endx = -16
        end
		local starty = self.pos.y
		local endy = self.pos.y + 80 * self.curve_amount
        s:tween(function(t)
            self:tp_to(lerp(startx, endx, t), lerp(starty, endy, t) + math.tent(t) * 16 * self.curve_amount)
        end, 0, 1, 50, "linear")
		self:queue_destroy()
    end)
end

return FlyerEnemy
