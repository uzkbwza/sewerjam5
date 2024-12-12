local ScorePickup = GameObject:extend("ScorePickup")
local ObjectScoreFx = require("fx.object_score")


local sheet = SpriteSheet(textures.object_kebab, 16, 16)

local SCORE = 500

function ScorePickup:new(x, y)
	ScorePickup.super.new(self, x, y)
    self.score = SCORE
    self.sprite = sheet:random()
    self.z_index = -1
    self:add_elapsed_ticks()
	self.collision_rect = Rect.centered(0, 0, 16, 16)
    self:implement(Mixins.Behavior.BumpCollision)
    self:enable_bump_layer(PHYSICS_OBJECT)
	self.is_pickup = true
end

function ScorePickup:update(dt)
    self:move(0, 0)
	if self.tick > 400 then
		self:queue_destroy()
	end
end

function ScorePickup:pickup()
    self:queue_destroy()
	self:spawn_object(ObjectScoreFx(self.pos.x, self.pos.y, self.score))
end

function ScorePickup:draw()
	if floor(self.tick/2) % 2 == 0 or self.tick < 200 then
		graphics.draw_centered(self.sprite, 0, 0)
	end
end

return ScorePickup
