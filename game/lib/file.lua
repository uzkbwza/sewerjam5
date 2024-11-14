
local file = {}

function file.get_files_of_type(folder, extension, recursive)
	if type(folder) == "table" then
		local output = {}
		for _, v in ipairs(folder) do
			for _, v2 in ipairs(file.get_files_of_type(v, extension, recursive)) do
				table.insert(output, v2)
			end
		end
		return output
	end
	extension = extension or "*"
	recursive = recursive or false
	folder = string.strip_whitespace(folder) or ""

	if folder == "" then
		print("root directory won't be scanned")
	end
	local all = love.filesystem.getDirectoryItems(folder)
	local output = {}
	for _,v in ipairs(all) do
		local file_path = folder.."/"..v
		local info = love.filesystem.getInfo(file_path)
		if info then
			if info.type == "file" and folder ~= "" then

				if extension == "*" then
					table.insert(output, file_path)
				else if string.endswith(file_path, extension) then
						table.insert(output, file_path)
					end
				end
			elseif recursive and info.type == "directory" then
				for _, v2 in ipairs(file.get_files_of_type(file_path, extension, true)) do
					table.insert(output, v2)
				end
			end
		end
		::continue::
	end
	return output
end

function file.filename_to_asset_name(filename, extension, prefix)
	prefix = prefix or ""
	return string.sub(string.gsub(string.match(filename, "/(.+)." .. extension .. "$"), "/", "_"), #prefix + 1)
end

function file.get_modules(path, t)
	t = t or {}
	for _, v in ipairs(love.filesystem.getDirectoryItems(path)) do
		if v:sub(-4) == ".lua" then
			local s = v:sub(1, -5)
			if s == "init" then 
				goto continue
			end
			local mod = require(path .. "." .. v:sub(1, -5))
			t[s] = mod
		end
		::continue::
	end
	return t

end

function file.save_image(image, name)
	local prevcanvas = love.graphics.getCanvas()
	local canvas = love.graphics.newCanvas(image:getWidth(), image:getHeight())
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	love.graphics.draw(image)
	love.graphics.setCanvas(prevcanvas)
	canvas:newImageData():encode("png", name .. ".png")
end

return file

