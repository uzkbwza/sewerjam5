-- local Illuminator = Object:extend()
-- function Illuminator:_init(radius)
-- 	self.illumination_radius = radius or 32
-- 	self.illuminating = false

-- 	self:add_update_function(
-- 		Illuminator.illuminate
-- 	)

-- 	self:add_draw_function(
-- 		Illuminator._draw
-- 	)

-- 	self.illuminated_objects = {}
-- end

-- function Illuminator:_draw()
-- 	-- graphics.set_color(1, 1, 1, 1/4)
-- 	-- graphics.circle("line", 0, 0, self.illumination_radius)
-- 	if not self.illuminating then return end
-- 	-- graphics.set_color(palette.yellow, 1/64)
-- 	-- graphics.circle("line", 0, 0, self.illumination_radius)
-- 	-- graphics.circle("line", 0, 0, self.illumination_radius - 1)

-- 	graphics.set_color(self.illumination_color or palette.yellow, 1/64 + rng.randfn(0, 1/512))
-- 	graphics.circle("fill", 0, 0, rng.randfn(self.illumination_radius, 0.5))
-- 	graphics.set_color(1, 1, 1, 1)
-- end

-- function Illuminator:illuminate()
-- 	if self.illuminating then
-- 		local objs = self:get_overlapping_objects_in_rect(Rect.centered(0, 0, self.illumination_radius * 2, self.illumination_radius * 2))
-- 		for _, obj in ipairs(objs) do
-- 			if self.pos:distance_to(obj.pos) < self.illumination_radius then
-- 				if obj.on_illuminated then
-- 					obj:on_illuminated(self)
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- function Illuminator:activate_illumination()
-- 	self.illuminating = true
-- end

-- function Illuminator:deactivate_illumination()
-- 	self.illuminating = false
-- end



return {

}
