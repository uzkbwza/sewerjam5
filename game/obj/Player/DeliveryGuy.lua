local DeliveryGuy = GameObject:extend("DeliveryGuy")
local Bullet = require("obj.Player.DeliveryGuyBullet")
local DeathFx = require("fx.death_effect")

function DeliveryGuy:new(x, y, invuln)
    DeliveryGuy.super.new(self, x, y)

    self.collision_rect = Rect.centered(0, 0, 1.0, 1.0)
    self.collision_offset = Vec2(0, 0)
    self.solid = false

    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self:add_signal("level_complete")
	self:add_signal("died")

    local old_bump_filter = Mixins.Behavior.BumpCollision.default_bump_filter
    self.bump_filter = function(item, other)
        local result = old_bump_filter(item, other)
        return result
    end

    self.state = "Walking"
	-- order kinda matters!
	self:implement(Mixins.Behavior.AutoStateMachine)
    self:implement(Mixins.Behavior.BumpCollision)
    self:implement(Mixins.Fx.Rumble)
    self:implement(Mixins.Behavior.FreezeFrames)
    self:implement(Mixins.Behavior.Flippable)
	self:implement(Mixins.Behavior.GridTerrainQuery)
    self:implement(Mixins.Behavior.TunnelSnapping)
	self:implement(Mixins.Behavior.Hittable)

    local hazard_sensor_config = {
        collision_rect = Rect.centered(0, 0, 4, 4),
        entered_function = function(self, other)
            self:on_hit(other)
        end,
        bump_mask = to_layer_bit(PHYSICS_HAZARD)
    }

	local pickup_sensor_config = {
        collision_rect = Rect.centered(0, 0, 16, 16),
        entered_function = function(self, other)
			if other.is_pickup then	
				other:pickup()
			end
        end,
        bump_mask = to_layer_bit(PHYSICS_OBJECT)
	}
    self:add_bump_sensor(hazard_sensor_config)
	self:add_bump_sensor(pickup_sensor_config)

    self.z_index = 0
    self:set_flip(1)

    self:enable_bump_layer(PHYSICS_PLAYER)
    self:enable_bump_mask(PHYSICS_ENEMY, PHYSICS_TERRAIN)

	self.speed = 1.5
	self.input_move_dir = Vec2(0, 0)
	

	self.left_pressed_at = -1
	self.right_pressed_at = -1
	self.up_pressed_at = -1
	self.down_pressed_at = -1

	self.can_shoot = true

	self.facing_direction_x = 0
	self.facing_direction_y = -1

	self.aim_up_pressed_at = -1
	self.aim_down_pressed_at = -1
	self.aim_left_pressed_at = -1
	self.aim_right_pressed_at = -1

	self.last_moved_x = 1
	self.last_moved_y = 1

	local old_move_to = self.move_to

    self.move_to = function(self, x, y, filter, noclip, ...)
        if self.ignore_collision then
			-- print("here")

			old_move_to(self, x, y, filter, true, ...)
			return
		end
		old_move_to(self, x, y, filter, noclip, ...)
	end
    if invuln then
		local s = self.sequencer
        self.invuln = true
		self.ignore_collision = true
        s:start(function()
            s:wait(45)
			self.ignore_collision = false
			s:wait(45)
			self.invuln = false
		end)
	end
end

function DeliveryGuy:enter()
    self:add_tag("player")
end

function DeliveryGuy:update(dt)
end

function DeliveryGuy:cooldown_end()
    self.can_shoot = true
	if self.buffering_shot then
		self.buffering_shot = false
		self:shoot_bullet()
	end
end

function DeliveryGuy:shoot_bullet(noclip)
    if self.can_shoot then
        self.can_shoot = false
		local nx, ny = vec2_normalized(self.facing_direction_x, self.facing_direction_y)
        local bullet = Bullet(self.pos.x + nx * 8, self.pos.y + ny * 8, nx, ny)
		bullet.noclip = noclip
		self:spawn_object(bullet)
		self:start_timer(8, self.cooldown_end)
	else
		-- self.buffering_shot = true
	end
end

-- Helper methods

function DeliveryGuy:on_hit(by)
	if self.invuln then
		return
	end
	self:die()
end

function DeliveryGuy:die()
	self:emit_signal("died")
	self:queue_destroy()
	local fx = DeathFx(self.pos.x, self.pos.y, self:get_texture(), self.flip)
    fx.duration = fx.duration * 2
	self:spawn_object(fx)
end

function DeliveryGuy:process_collision(collision)
    local tile_data = table.get_recursive(collision.other, "tile", "data")
    if tile_data and tile_data.hazard then
        self:on_hit(tile_data)
    end
end

function DeliveryGuy:get_texture()
	return floor(self.tick / 10) % 2 == 0 and textures.player_placeholder1 or textures.player_placeholder2	
end

function DeliveryGuy:draw()
	if self.invuln and floor(self.tick / 2) % 2 == 0 then
		return
	end
	graphics.push()
	graphics.origin()
	graphics.translate(self.pos.x, self.pos.y - self.world.scroll)
    graphics.draw_centered(self:get_texture(), 0, 0, 0, self.flip, 1, 0, 1)
	graphics.pop()
end


function DeliveryGuy:check_solid_tile(x, y)
	local tile = self:get_bump_tile_relative(x, y, 0)
	if tile and tile.solid then
		return true
	end
	return false
end

function DeliveryGuy:handle_movement_input()
	local input = self:get_input_table()

    -- if input.move_up_pressed then
    --     self.up_pressed_at = self.tick
    -- elseif input.move_down_pressed then
    --     self.down_pressed_at = self.tick
    -- elseif input.move_left_pressed then
    --     self.left_pressed_at = self.tick
    -- elseif input.move_right_pressed then
    --     self.right_pressed_at = self.tick
    -- end

	-- if input.move_up_released then
	-- 	self.up_pressed_at = -1
	-- end

	-- if input.move_down_released then
	-- 	self.down_pressed_at = -1
	-- end

	-- if input.move_left_released then
	-- 	self.left_pressed_at = -1
	-- end

    -- if input.move_right_released then
    --     self.right_pressed_at = -1
    -- end
	
	-- local latest_time = -1

    -- if self.up_pressed_at > latest_time then
    --     latest_time = self.up_pressed_at
	-- 	self.input_move_dir.y = -1
	-- 	self.input_move_dir.x = 0	
	-- end

    -- if self.down_pressed_at > latest_time then
	-- 	latest_time = self.down_pressed_at
	-- 	self.input_move_dir.y = 1
	-- 	self.input_move_dir.x = 0	
	-- end

    -- if self.left_pressed_at > latest_time then
    --     latest_time = self.left_pressed_at
	-- 	self.input_move_dir.y = 0
	-- 	self.input_move_dir.x = -1	
	-- end

    -- if self.right_pressed_at > latest_time then
    --     latest_time = self.right_pressed_at
    --     self.input_move_dir.y = 0
    --     self.input_move_dir.x = 1
    -- end
	
    -- if latest_time == -1 then
    --     self.input_move_dir.x = 0
    --     self.input_move_dir.y = 0
    -- end

	self.input_move_dir.x = input.move_normalized.x
    self.input_move_dir.y = input.move_normalized.y

	if self.input_move_dir.x ~= 0 then
		self.last_moved_x = self.input_move_dir.x
	end

	if self.input_move_dir.y ~= 0 then
		self.last_moved_y = self.input_move_dir.y
	end

end

function DeliveryGuy:handle_aim_input()
	local input = self:get_input_table()

    -- if input.aim_up_pressed then
	-- 	self.aim_up_pressed_at = self.tick
	-- elseif input.aim_down_pressed then
    --     self.aim_down_pressed_at = self.tick
	-- elseif input.aim_left_pressed then
    --     self.aim_left_pressed_at = self.tick
    -- elseif input.aim_right_pressed then
    --     self.aim_right_pressed_at = self.tick
    -- end

	-- local latest_time = -1

	-- if input.aim_up_released then
	-- 	self.aim_up_pressed_at = -1
	-- end

	-- if input.aim_down_released then
	-- 	self.aim_down_pressed_at = -1
	-- end

	-- if input.aim_left_released then
	-- 	self.aim_left_pressed_at = -1
	-- end

	-- if input.aim_right_released then
	-- 	self.aim_right_pressed_at = -1
	-- end

    -- if self.aim_up_pressed_at > latest_time then
    --     latest_time = self.aim_up_pressed_at
    --     self.facing_direction_y = -1
    --     self.facing_direction_x = 0
    -- end
	
	-- if self.aim_down_pressed_at > latest_time then
	-- 	latest_time = self.aim_down_pressed_at
	-- 	self.facing_direction_y = 1
	-- 	self.facing_direction_x = 0
	-- end	

	-- if self.aim_left_pressed_at > latest_time then
	-- 	latest_time = self.aim_left_pressed_at
	-- 	self.facing_direction_y = 0
	-- 	self.facing_direction_x = -1
	-- end

    -- if self.aim_right_pressed_at > latest_time then
    --     latest_time = self.aim_right_pressed_at
    --     self.facing_direction_y = 0
    --     self.facing_direction_x = 1
    -- end

	self.facing_direction_x = input.aim.x
	self.facing_direction_y = input.aim.y

	if not self.state == "PitJump" then
		if self.facing_direction_x > 0 and self.snapped_east then
			self.facing_direction_x = 0
			if self.facing_direction_y == 0 then
				self.facing_direction_y = self.last_moved_y
			end
		end

		if self.facing_direction_x < 0 and self.snapped_west then
			self.facing_direction_x = 0
			if self.facing_direction_y == 0 then
				self.facing_direction_y = self.last_moved_y
			end
		end

		if self.facing_direction_y > 0 and self.snapped_south then
			self.facing_direction_y = 0
			if self.facing_direction_x == 0 then
				self.facing_direction_x = self.last_moved_x
			end
		end

		if self.facing_direction_y < 0 and self.snapped_north then
			self.facing_direction_y = 0
			if self.facing_direction_x == 0 then
				self.facing_direction_x = self.last_moved_x
			end
		end
	end

	if self.facing_direction_x == 0 and self.facing_direction_y == 0 then
		self.facing_direction_y = self.last_moved_y
	end

	if self.facing_direction_x ~= 0 then
		self:set_flip(self.facing_direction_x)
	end

	-- print(self.aim_up_pressed_at, self.aim_down_pressed_at, self.aim_left_pressed_at, self.aim_right_pressed_at)

end

------------------------------------------
-- States
------------------------------------------

-- State: Walking
function DeliveryGuy:state_Walking_update(dt)
    self:handle_movement_input()
    self:handle_aim_input()

    if self.input_move_dir.y == 0 then
        self:move(0, dt * self.world.scroll_speed * self.world.scroll_direction, nil, false)
    end

    if self.input_move_dir.x ~= 0 or self.input_move_dir.y ~= 0 then
        local ymod = dt * self.world.scroll_speed * self.world.scroll_direction * abs(self.input_move_dir.y)
        self:move(self.input_move_dir.x * self.speed * dt, (self.input_move_dir.y * self.speed * dt) + ymod)
        if self.input_move_dir.x > 0 then
            self.snapped_east = false
        elseif self.input_move_dir.x < 0 then
            self.snapped_west = false
        end
    end

    if input.aim_up or input.aim_down or input.aim_left or input.aim_right then
        self:shoot_bullet()
    end

    local tile = self:get_tile_relative(0, 0, 0)

    if tile and tile.data and tile.data.terrain_pit then
        self.pit_moving_dir = Vec2(0, 0)

        local cx, cy = self:get_cell()
        local wx, wy = self:cell_to_world(cx, cy)
        local diff = Vec2(wx - self.pos.x, wy - self.pos.y)
        if abs(diff.x) > abs(diff.y) then
            self.pit_moving_dir.x = sign(diff.x)
        else
            self.pit_moving_dir.y = diff.y ~= 0 and sign(diff.y) or self.world.scroll_direction
        end

		local relative_cx = cx - self.pit_moving_dir.x
		local relative_cy = cy - self.pit_moving_dir.y
		local world_pos_x, world_pos_y = self:cell_to_world(relative_cx, relative_cy)
		self.pos = Vec2(world_pos_x, world_pos_y)

		if not self.ignore_collision and not self:is_cell_solid(cx + self.pit_moving_dir.x * 1, cy + self.pit_moving_dir.y * 1) then
			self:change_state("PitJump")
			return
		end
	end
end

function DeliveryGuy:state_PitJump_enter()
	
    local s = self.sequencer
    s:start(function()
		local startx, starty = self:get_cell()
		local endx, endy = startx + self.pit_moving_dir.x * 2, starty + self.pit_moving_dir.y * 2
        s:tween(function(t)
            local x, y = vec2_lerp(startx, starty, endx, endy, t)
			local wx, wy = self:cell_to_world(x, y)
			self.pos = Vec2(wx, wy - math.bump(t) * 12)
        end, 0, 1, 30, "linear")
		self:change_state("Walking")
	end)
end

function DeliveryGuy:state_PitJump_update(dt)
	self:handle_aim_input()
	if input.aim_up or input.aim_down or input.aim_left or input.aim_right then
		self:shoot_bullet(true)
	end
end

return DeliveryGuy
