local Tile = Object:extend()

function Tile:new( tileset, id, quad, texture, data )
    self.quad = quad
	self.texture = texture
    self.data = data
	self.tileset = tileset
	self.id = id
end

function Tile:draw(x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.draw(self.texture, self.quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

return Tile
