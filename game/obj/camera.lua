local Camera = GameObject:extend()

function Camera:new(x, y)
	Camera.super.new(self, x, y)
	self:add_sequencer()
	self:add_elapsed_time()
	self:add_elapsed_ticks()
	self.following = nil
	self.viewport_size = Vec2()
	self.zoom = 1
end

function Camera:follow(obj)
	self.following = obj

	if obj == nil then
		return
	end

	obj.destroyed:connect(self, function()
		self.following = nil
	end)

	obj.removed:connect(self, function()
		self.following = nil
	end)
end

function Camera:set_limits(xstart, ystart, xend, yend)
	self.limits = {
		xstart = xstart,
		xend = xend,
		ystart = ystart,
		yend = yend
	}
end


function Camera:update(dt)
end


function Camera:clamp_to_limits(offset)
	if not self.limits then
		return offset
	end
	local x, y = offset.x, offset.y
	local xstart, xend, ystart, yend = self.limits.xstart, self.limits.xend, self.limits.ystart, self.limits.yend

	local xcenter, ycenter = (xstart + xend) / 2, (ystart + yend) / 2
	local xdiff, ydiff = xend - xstart, yend - ystart

	if xdiff < self.viewport_size.x then
		xstart = xcenter - self.viewport_size.x / 2
		xend = xcenter + self.viewport_size.x / 2
	end
	if ydiff < self.viewport_size.y then
		ystart = ycenter - self.viewport_size.y / 2
		yend = ycenter + self.viewport_size.y / 2
	end

	offset.x = clamp(x, xstart + self.viewport_size.x / 2, xend - self.viewport_size.x / 2)
	offset.y = clamp(y, ystart + self.viewport_size.y / 2, yend - self.viewport_size.y / 2)
	return offset
end

return Camera
