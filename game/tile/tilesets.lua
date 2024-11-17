local Tileset = require "tile.tileset"

local tilesets = {}


function tilesets.add(name, tileset)
	assert(type(name) == "string", "tileset name must be a string")
    tilesets[name] = tileset
    tilesets[#tilesets + 1] = tileset
	tileset.name = name
end

function tilesets.load()
	tilesets.add("ts1", Tileset(textures.tileset_ts1, 8, 8))
	tilesets.add("ts2", Tileset(textures.tileset_ts2, 8, 8))
	-- tilesets.ts3 = Tileset(textures.tileset_ts1, 8, 8)
end

function tilesets.get_all()
	local t = {}
    for i, v in ipairs(tilesets) do
        if type(v) == "table" then
			table.insert(t, {name = v.name, tileset = v})
        end
    end
	return t
end

return tilesets
