local EnemyLaser = GameObject:extend("EnemyLaser")
local BulletHitEffect = Effect:extend("BulletHitEffect")
local DeathEffect = require"fx.death_effect"


local BulletHitSpriteSheet = SpriteSheet(textures.fx_bullethit, 16, 16)

local sensor_config = {
	collision_rect = Rect.centered(0, 0, 3, 3),
	entered_function = function(self, other)
        if other.is_player then
            other:on_hit(self)
		end
		self:hit_something()
	end,
	bump_mask = to_layer_bit(PHYSICS_TERRAIN, PHYSICS_PLAYER)
}

function EnemyLaser:new(x, y, direction_x, direction_y)
    EnemyLaser.super.new(self, x, y)
    self.collision_rect = Rect.centered(0, 0, 1,1)
	self.collision_offset = Vec2(-1, -1)
    self:implement(Mixins.Behavior.BumpCollision)
	self:add_elapsed_ticks()
	self.direction = Vec2(direction_x, direction_y):normalized()
	self.z_index = 0
    self.damage = 1
	self.speed = 1.5
    self:add_bump_sensor(sensor_config)
    self:enable_bump_mask(PHYSICS_TERRAIN, PHYSICS_PLAYER)
	-- self:enable_bump_layer(PHYSICS_PLAYER)
	
end

function EnemyLaser:enter()
	self.last_positions = { self.pos.x, self.pos.y }
	-- self:spawn_object(BulletHitEffect(self.pos.x, self.pos.y)).duration = 5
	-- self:spawn_object(BulletHitEffect(self.pos.x, self.pos.y))
	local death_effect = self:spawn_object(DeathEffect(self.pos.x, self.pos.y, BulletHitSpriteSheet:get_frame(1)))
	death_effect.flash = false
	death_effect.color_flash = {0, 2}
    death_effect.size_mod = 0.2
	death_effect.duration = death_effect.duration * 0.25
end

function EnemyLaser:bump_filter(other)
    if other.bullet_blocker then
        return "slide"
    end
	return "cross"
end

function EnemyLaser:update(dt)

    if self.tick > 120 then
        self:queue_destroy()
    end
    self:move(self.speed * self.direction.x * dt, self.speed * self.direction.y * dt)
    EnemyLaser.super.update(self, dt)
    if self.is_new_tick then
        self.last_positions[#self.last_positions + 1] = self.pos.x
        self.last_positions[#self.last_positions + 1] = self.pos.y
        while #self.last_positions > 12 do
            table.remove(self.last_positions, 1)
        end
    end
    local startx, starty = self.last_positions[1], self.last_positions[2]
	local col = self.bump_world:raycast(startx, starty, self.pos.x, self.pos.y, nil, PHYSICS_TERRAIN)
    if col then
		if col.item.is_player then
			col.item:on_hit(self)
		elseif not self.noclip and not col.item.bullet_passthrough then
			self:hit_something()
		end
	end
	-- if self.pos.x < self.world.player_min_x - 8 or self.pos.x > self.world.player_max_x + 8 then
	-- 	self:hit_something()
	-- end
end

function EnemyLaser:process_collision(col)
	if (not self.noclip) then
        if (not col.other.bullet_passthrough) then
			self:hit_something()
		end
	end
end

function EnemyLaser:hit_something()
    self:queue_destroy()
    -- self.hit = true
    self:spawn_object(BulletHitEffect(self.pos.x, self.pos.y))
	local death_effect = self:spawn_object(DeathEffect(self.pos.x, self.pos.y, BulletHitSpriteSheet:get_frame(1)))
	death_effect.flash = false
	death_effect.color_flash = {0, 2}
    death_effect.size_mod = 0.25
	death_effect.duration = death_effect.duration * 0.4
end

function EnemyLaser:draw()
	local local_points = {}
    for i = 1, #self.last_positions, 2 do
        local_points[i] = self.last_positions[i] - self.pos.x
        local_points[i + 1] = self.last_positions[i + 1] - self.pos.y
    end
	local_points[#local_points + 1] = 0
    local_points[#local_points + 1] = 0
	
    if self.last_positions and #self.last_positions > 2 then
    
		graphics.push()
        graphics.translate(0, 1)
        graphics.set_color(palette.black)
        if self.noclip then
			local startx, starty = self:to_local(self.last_positions[1], self.last_positions[2])
            local endx, endy = self:to_local(self.pos.x, self.pos.y)
			local res = 30
            for i = 1, res do
				local x, y = lerp(startx, endx, i / res), lerp(starty, endy, i / res)
				graphics.circle("fill", x, y + 4, 4)
			end
		end
        graphics.line(local_points)
		graphics.pop()
		graphics.set_color(graphics.color_flash(6, 1))
		graphics.line(local_points)
	end
	-- graphics.draw_centered(textures.player_bullet, 0, 0, 0, 1, 1, 0, 1)
end


local DURATION = 2


function BulletHitEffect:new(x, y)
	BulletHitEffect.super.new(self, x, y)
	self.duration = DURATION
	self.z_index = 1
end

function BulletHitEffect:enter()
end

function BulletHitEffect:draw(elapsed, ticks, t)
	-- graphics.set_color(graphics.color_flash(0, 2))
	graphics.set_color(graphics.color_flash(0, 2))
	-- graphics.set_color(palette.white)
	graphics.draw_centered(BulletHitSpriteSheet:interpolate(t), 0, 0, 0, 1, 1, 0, 1)
end

return EnemyLaser
