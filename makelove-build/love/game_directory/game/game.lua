local Game = Object:extend("Game")

function Game:new()
    Game.super.new(self)
    self.layer_tree = CanvasLayer()
	self.layer_tree.root = self.layer_tree
end

function Game:load()
    self.layer_tree:transition_to(Screens.MainScreen)
end

function Game:update(dt)
    self.layer_tree:update_shared(dt)
end

return Game
