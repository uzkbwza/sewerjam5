local base_map = [[
###############
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
#.............#
###############
]]

local default_tile_data = {
	["#"] = { wall = true },
	["@"] = { player_spawn = true },
	["t"] = { torch = true }
}

local maps = filesystem.get_modules("map/maps")
local mods = filesystem.get_modules("map")
mods.maps = maps
mods.default_build_tile_data = default_tile_data
return mods
