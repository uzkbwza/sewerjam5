local TILE_SIZE = 8

local COLLISION_SOLID = Rect(0, 0, TILE_SIZE, TILE_SIZE)

local COLLISION_TOP_1PX = Rect(0, 0, TILE_SIZE, 1)
local COLLISION_BOTTOM_1PX = Rect(0, TILE_SIZE - 1, TILE_SIZE, 1)
local COLLISION_LEFT_1PX = Rect(0, 0, 1, TILE_SIZE)
local COLLISION_RIGHT_1PX = Rect(TILE_SIZE - 1, 0, 1, TILE_SIZE)

local TILESETS = {
	{
		name = "ts1",
		data = {
			collision_rect = {
				[COLLISION_SOLID] = {
					1, 30
				}
			}
		},
	},
	{
		name = "ts3",
		data = {
			collision_rect = {
				[COLLISION_SOLID] = {
					1
				}
			}
		},
	}
}

local OBJECT_TILES = {
    test = "block1",
	ball = "ball1",
}

return {
	TILE_SIZE = TILE_SIZE,
	TILESETS = TILESETS,
	OBJECT_TILES = OBJECT_TILES
}
