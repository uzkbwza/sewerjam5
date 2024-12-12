local Enemy = GameObject:extend("Enemy")
local DeathFx = require("fx.death_effect")
local ObjectScore = require("fx.object_score")

-- local DeathFxSpriteSheet = SpriteSheet(textures.fx_enemydeath, 32, 32)
-- local DeathFxAnimation = DeathFxSpriteSheet:get_animation(4)

function Enemy:new(x, y)
	Enemy.super.new(self, x, y)

	local old_bump_filter = Mixins.Behavior.BumpCollision.default_bump_filter

	self.collision_rect = Rect(0, 0, 14, 14)
	self.collision_offset = Vec2(0, 0)

	self.bump_filter = function(item, other)
		local result = old_bump_filter(item, other)
		return result
	end

	self:add_elapsed_ticks()
	self:add_sequencer()

	self:implement(Mixins.Fx.Rumble)
	self:implement(Mixins.Behavior.Flippable)
	self:implement(Mixins.Behavior.FreezeFrames)
	self:implement(Mixins.Behavior.BumpCollision)
	self:implement(Mixins.Behavior.Hittable)
	self:implement(Mixins.Behavior.GridTerrainQuery)
	self:enable_bump_layer(PHYSICS_ENEMY, PHYSICS_HAZARD)

	self:set_flip(1)

	self.hazard = true
	self.is_enemy = true

    self.z_index = 0
    
	self.score = 150
	
	self:init_health(1)
end

function Enemy:init_health(health)
	self.max_health = health
	self.health = health
end

function Enemy:on_hit(by)
	self.health = self.health - by.damage
	if self.health <= 0 then
		self:die()
	end
end

function Enemy:die()
	self:queue_destroy()
	local tex =  self:get_texture()
    self:spawn_object(DeathFx(self.pos.x, self.pos.y, tex, self.flip))
	self:spawn_object(ObjectScore(self.pos.x, self.pos.y, self.score))
end

function Enemy:enter()
	self:add_tag("enemy")
end

function Enemy:get_texture()
	return textures.enemy_placeholder1
end

function Enemy:get_player()
	return self.world:get_first_object_with_tag("player")
end

function Enemy:draw()
	graphics.draw_centered(self:get_texture(), 0, 0, 0, self.flip, 1, 0, 1)
end

return Enemy