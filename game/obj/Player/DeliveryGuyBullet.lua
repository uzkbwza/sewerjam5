local DeliveryGuyBullet = GameObject:extend("DeliveryGuyBullet")
local BulletHitEffect = Effect:extend("BulletHitEffect")

local SPEED = 10

local sensor_config = {
	collision_rect = Rect.centered(0, 0, 15, 15),
	entered_function = function(self, other)
        if other.is_hittable then
            other:on_hit(self)
		end
		self:hit_something()
	end,
	bump_mask = to_layer_bit(PHYSICS_ENEMY, PHYSICS_TERRAIN)
}

function DeliveryGuyBullet:new(x, y, direction_x, direction_y)
    DeliveryGuyBullet.super.new(self, x, y)
    self.collision_rect = Rect.centered(0, 0, 1,1)
	self.collision_offset = Vec2(-1, -1)
    self:implement(Mixins.Behavior.BumpCollision)
	self:add_elapsed_ticks()
	self.direction = Vec2(direction_x, direction_y)
	self.z_index = 0
	self.damage = 1
    self:add_bump_sensor(sensor_config)
    self:enable_bump_mask(PHYSICS_TERRAIN, PHYSICS_ENEMY)
end

function DeliveryGuyBullet:enter()
	self.last_positions = { self.pos.x, self.pos.y }
end

function DeliveryGuyBullet:bump_filter(other)
    if other.bullet_blocker then
        return "slide"
    end
	return "cross"
end

function DeliveryGuyBullet:update(dt)

    if self.tick > 120 then
        self:queue_destroy()
    end
    self:move(SPEED * self.direction.x * dt, SPEED * self.direction.y * dt)
    DeliveryGuyBullet.super.update(self, dt)
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
		if col.item.is_hittable then
			col.item:on_hit(self)
		elseif not self.noclip and not col.item.bullet_passthrough then
			self:hit_something()
		end
	end
end

function DeliveryGuyBullet:process_collision(col)

	if (not self.noclip) then
        if (not col.other.bullet_passthrough) then
			self:hit_something()
		end
	end
end

function DeliveryGuyBullet:hit_something()
    self:queue_destroy()
    self.hit = true
	self:spawn_object(BulletHitEffect(self.pos.x, self.pos.y))
end

function DeliveryGuyBullet:draw()
    graphics.set_color(graphics.color_flash(0, 2))
	local local_points = {}
    for i = 1, #self.last_positions, 2 do
        local_points[i] = self.last_positions[i] - self.pos.x
        local_points[i + 1] = self.last_positions[i + 1] - self.pos.y
    end
	local_points[#local_points + 1] = 0
	local_points[#local_points + 1] = 0
	if self.last_positions and #self.last_positions > 2 then
		graphics.line(local_points)
	end
	-- graphics.draw_centered(textures.player_bullet, 0, 0, 0, 1, 1, 0, 1)
end


local DURATION = 2
local BulletHitSpriteSheet = SpriteSheet(textures.fx_bullethit, 16, 16)


function BulletHitEffect:new(x, y)
	BulletHitEffect.super.new(self, x, y)
	self.duration = DURATION
	self.z_index = 1
end

function BulletHitEffect:enter()
end

function BulletHitEffect:draw(elapsed, ticks, t)
	-- graphics.set_color(graphics.color_flash(0, 2))

	graphics.set_color(palette.white)
	graphics.draw_centered(BulletHitSpriteSheet:interpolate(t), 0, 0, 0, 1, 1, 0, 1)
end

return DeliveryGuyBullet