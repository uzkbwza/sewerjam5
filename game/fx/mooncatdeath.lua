local Effect = require("fx.effect")

local DeathEffect = Effect:extend()

local NUM_STARS = 3
local NUM_STARS_2 = floor(NUM_STARS / 2)
local NUM_PUFFS = 3
local DURATION = 36

local STAR_DISTANCE = 60
local PUFF_DISTANCE = 30

local STAR_OFFSET = 30
local PUFF_OFFSET = 0

local easing = ease("outExpo")

function DeathEffect:new(x, y)
	DeathEffect.super.new(self, x, y)
	self.duration = DURATION
	self.starting_rot = math.random() * tau
	self.rot = self.starting_rot
	self.star_angle_offset = math.random() * tau
	self.dir = math.random() < 0.5 and -1 or 1
	
end

function DeathEffect:draw(_, ticks, t)
	local e = easing(t)

	for i = 1, NUM_PUFFS do

		graphics.set_color(palette.lilac)
		local angle = (tau / NUM_PUFFS * i) + rad(PUFF_OFFSET) + ((tau / NUM_PUFFS / 2) * (floor(ticks / 2)))
		local dist = PUFF_DISTANCE * e
		local x, y = vec2_from_polar(dist, angle)
		local fill = "fill"
		if t < 0.5 then fill = "fill" end
		if t > 0.5 and floor(ticks / 2) % 2 == 0 then
			fill = "line"
		end
		if t > 0.6 then fill = "line" end
		graphics.circle(fill, x, y, ticks < 1 and 60 or 12 + (1 - e) * 10 )
	end

	local star_size = 17 + (1 - e) * 10

	if t > 0.5 and floor(ticks / 2) % 2 == 0 then
		return
	end

	for i = 1, NUM_STARS do
		local angle = ((tau / NUM_STARS) * i) + rad(STAR_OFFSET) + self.star_angle_offset
		local dist = STAR_DISTANCE * e
		local x, y = vec2_from_polar(dist, angle)
		graphics.set_color(palette.yellow)
		if floor(ticks / 5) % 2 == 0 then
			graphics.set_color(palette.white)
		end
		graphics.push()
		graphics.translate(x, y)
		graphics.rotate(e * tau * 2 * -self.dir + (tau / NUM_STARS) * i)
		graphics.rectangle("fill", -star_size/2, -star_size/2, star_size, star_size)
		graphics.pop()
	end

end

return DeathEffect
