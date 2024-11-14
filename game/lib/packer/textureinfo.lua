local TextureInfo = Object:extend()

function TextureInfo:new(texture_data, texture, name)
	self.name = name
	self.image_data = texture_data
	self.image = texture
	self.width = self.image_data:getWidth()
	self.height = self.image_data:getHeight()
	self.trim_start = Vec2(0, 0)
	self.trim_end = Vec2(self.width, self.height)

	local function is_pixel_empty(x, y)
		local r, g, b, a = self.image_data:getPixel(x, y)
		return a == 0
	end

	local function is_column_empty(x)
		for y=0, self.height-1 do
			if not is_pixel_empty(x, y) then
				return false
			end
		end
		return true
	end

	local function is_row_empty(y)
		for x=0, self.width-1 do
			if not is_pixel_empty(x, y) then
				return false
			end
		end
		return true
	end

	for i=0, self.width-1 do
		if is_column_empty(i) then
			self.trim_start.x = self.trim_start.x + 1
		else
			break
		end
	end
	for i=self.width-1, 0, -1 do
		if is_column_empty(i) then
			self.trim_end.x = self.trim_end.x - 1
		else
			break
		end
	end
	for i=0, self.height-1 do
		if is_row_empty(i) then
			self.trim_start.y = self.trim_start.y + 1
		else
			break
		end
	end
	for i=self.height-1, 0, -1 do
		if is_row_empty(i) then
			self.trim_end.y = self.trim_end.y - 1
		else
			break
		end
	end

	self.trim_size = self.trim_end - self.trim_start
	self.trim_area = self.trim_size.x * self.trim_size.y

	return
end

return TextureInfo
