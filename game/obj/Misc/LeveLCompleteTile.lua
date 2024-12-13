local LevelCompleteTile = GameObject:extend("LevelCompleteTile")

function LevelCompleteTile:new(x, y)
	LevelCompleteTile.super.new(self, x, y, width, height)
	self:implement(Mixins.Behavior.BumpCollision)
	self:enable_bump_layer(PHYSICS_OBJECT)
end

return LevelCompleteTile
