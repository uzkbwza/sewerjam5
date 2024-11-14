local binpack = require("lib.packer.binpack")
local TextureInfo = require("lib.packer.textureinfo")

local Packer = Object:extend()

function Packer:new(padding)
	self.padding = padding or 1
	self.texture_size_limit = love.graphics.getSystemLimits()["texturesize"]
	-- self.texture_size_limit = 8192
	self.textures = {}
end

function Packer:add_texture(texture_path, name)
	local info = TextureInfo(texture_path, name)
	table.insert(self.textures, info)
end

function Packer:bake()
	self:sort_textures()
	self:pack_textures()
end

function Packer:sort_textures()
	local sorted = {}
	for _, v in pairs(self.textures) do
		table.insert(sorted, v)
	end
	table.sort(sorted, function(a, b)
		return a.trim_area > b.trim_area
	end)
	self.textures = sorted
end

function Packer:pack_textures()


	local width = self.texture_size_limit
	local height = self.texture_size_limit
	local positions = {}

	local bp = binpack(width, height)

	width = 0
	height = 0
	for _, v in ipairs(self.textures) do
		local w = v.trim_size.x + self.padding * 2
		local h = v.trim_size.y + self.padding * 2
		local rect = bp:insert(w, h)


		if rect then
			width = math.max(width, rect.x + w)
			height = math.max(height, rect.y + h)
			table.insert(positions, {texture = v, position = Vec2(rect.x + self.padding - v.trim_start.x, rect.y + self.padding- v.trim_start.y)})
		else
			-- error("Texture size limit exceeded")
		end
	end

	-- width = next_power_of_2(width)
	-- height = next_power_of_2(height)

	-- width = max(width, height)
	-- height = width

	if width > self.texture_size_limit or height > self.texture_size_limit then
		error("Texture size limit exceeded")
	end
	local canvas = love.graphics.newCanvas(width, height)

	love.graphics.setCanvas(canvas)

	for _, v in ipairs(positions) do
		love.graphics.draw(v.texture.image, v.position.x, v.position.y)
		-- print(k, v)
	end
	
	love.graphics.setCanvas()

	self.canvas = canvas
	love.graphics.clear()

	-- export canvas 
	-- canvas:newImageData():encode("png", "packed.png")

end

return Packer
