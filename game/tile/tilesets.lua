local Tileset = require "tile.tileset"

local tilesets = {}

function tilesets.load()
	tilesets.ts1 = Tileset(textures.tileset_ts1, 8, 8)
end

function tilesets.get_all()
	local t = {}
    for k, v in pairs(tilesets) do
        if type(v) == "table" then
            t[k] = v
        end
    end
	return t
end

return tilesets
