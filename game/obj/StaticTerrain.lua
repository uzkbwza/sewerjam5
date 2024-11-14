local StaticTerrain = Object:extend()

function StaticTerrain:new(bump_world, x, y, w, h, solid, depth)
    self.pos = Vec2(x, y)
	self.size = Vec2(w, h)
	self.collision_rect = Rect.centered(0, 0, w, h)
    self.solid = solid or false
    self.z_index = depth or 0

    bump_world:add(self, self.pos.x - self.size.x / 2, self.pos.y - self.size.y / 2, self.size.x, self.size.y)
end

function StaticTerrain:get_draw_rect()
	return self.pos.x - self.size.x, self.pos.y - self.size.y, self.size.x * 2, self.size.y * 2
end

function StaticTerrain:graphics_transform()
	-- using the api here directly because it's faster
	local pos = self.pos
	love.graphics.translate(pos.x, pos.y)
	love.graphics.setColor(1, 1, 1, 1)
end

function StaticTerrain:draw()
end

function StaticTerrain:draw_shared()
	love.graphics.push()
    self:graphics_transform()
    self:draw()
	love.graphics.pop()
end

return StaticTerrain
