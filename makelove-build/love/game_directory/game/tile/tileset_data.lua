local TILE_SIZE = 16

local COLLISION_SOLID = Rect(0, 0, TILE_SIZE, TILE_SIZE)

local COLLISION_TOP_1PX = Rect(0, 0, TILE_SIZE, 1)
local COLLISION_BOTTOM_1PX = Rect(0, TILE_SIZE - 1, TILE_SIZE, 1)
local COLLISION_LEFT_1PX = Rect(0, 0, 1, TILE_SIZE)
local COLLISION_RIGHT_1PX = Rect(TILE_SIZE - 1, 0, 1, TILE_SIZE)

-- formatted this way to retain order

local TILESETS = {
	{
		name = "ts1",
		data = {
			collision_rect = {
				[COLLISION_SOLID] = {
					1
                },
            },
			terrain_pit = {
				9
			}
        },
    },
	-- {
	-- 	name="ts1_1",
    -- },
    -- {
	-- 	name="ts1_2"
	-- }
	-- {
	-- 	name = "ts2",
	-- 	data = {
	-- 		collision_rect = {
	-- 			[COLLISION_SOLID] = {
	-- 				1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
    --             },
	-- 			[Rect(2, 2, 4, 4)] = {
	-- 				19
	-- 			}
    --         },
    --         hazard = {
	-- 			19
    --         },
    --         passable = {
	-- 			19
	-- 		}
	-- 	},
	-- },

}

local OBJECT_TILES = {
    -- test = "block1",
    player = "player_placeholder",
    -- cart = "friendly_placeholder1",
    skullbird = "enemy_skullbird1",
    skull_up = "su",
	skull_down = "sd",
    flyer1 = "f1",
	flyer2 = "f2",
    flyer3 = "f3",
    devil = "d",
    kebab = "object_kebab1",
	screen_clear = "sc",
	bear = "br",
	tower = "enemy_tower_projectile_icon1",
	level_complete_tile = "friendly_placeholder1",
	-- pit = "terrain_pit",
}

return {
	TILE_SIZE = TILE_SIZE,
	TILESETS = TILESETS,
	OBJECT_TILES = OBJECT_TILES
}
