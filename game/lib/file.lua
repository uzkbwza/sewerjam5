
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

---@alias FileSystem.GetModulesRecursionType "none" | "all" | "init"
---@param path string
---@param recursive? FileSystem.GetModulesRecursionType
---@param t? table
---@param path_prefix? string
function file.get_modules(path, recursive, t, path_prefix)
	recursive = recursive or "none"

    if recursive ~= "none" and recursive ~= "all" and recursive ~= "init" then
        error("incorrect recursion type: " .. tostring(recursive))
    end
	
    path_prefix = path_prefix or ""
	
	t = t or {}
	for _, v in ipairs(love.filesystem.getDirectoryItems(path)) do
        if v:sub(-4) == ".lua" then
            local s = v:sub(1, -5)
            if s == "init" and path_prefix == "" then
                goto continue
            end

            if s ~= "init" and recursive == "init" then
                goto continue
            end
			
	            local mod = require(path:gsub("/", ".") .. "." .. s)
            
            local tab = string.split(path_prefix, ".")
			if s ~= "init" then
				table.insert(tab, s)
			end
            table.insert(tab, mod)
            table.populate_recursive_from_table(t, tab)
        end
		if recursive then 
            local info = love.filesystem.getInfo(path .. "/" .. v)
            if info and info.type == "directory" then
                local prefix = v
				if path_prefix ~= "" then prefix = "." .. prefix end
				file.get_modules(path .. "/" .. v, recursive, t, prefix)
			end
		end
		::continue::
	end
	return t
end

function file.read(path)
    local file = love.filesystem.newFile(path)
    file:open("r")
    return file:read()
end

function file.write(path, data)
    local file = love.filesystem.newFile(path)
    file:open("w")
    file:write(data)
    file:close()
end

function file.path_process(path)
    if love.system.getOS() == "Windows" then
        return string.gsub(path, "/", "\\")
    else
        return string.gsub(path, "\\", "/")
    end
end

function file.get_native_separator()
	if love.system.getOS() == "Windows" then
		return "\\"
	else
		return "/"
	end
end

function file.load_file_native(path)
    local wd = nativefs.getWorkingDirectory()
	local fp = file.path_process(wd .. file.get_native_separator() .. path)
    local file = nativefs.newFile(fp)
    file:open("r")
	return file:read()
end

function file.save_file(data, path)
	local file = love.filesystem.newFile(path)
	file:open("w")
	file:write(data)
	file:close()
end

function file.save_file_native(data, path)
    local wd = nativefs.getWorkingDirectory()

	local dirs = string.split(file.path_process(path), file.get_native_separator())
    dirs[#dirs] = nil
	local p = ""
    for _, dir in ipairs(dirs) do
		p = p .. file.get_native_separator() .. dir
		if not nativefs.getInfo(wd .. p) then
			nativefs.createDirectory(wd .. p)
		end
	end

	local fp = file.path_process(wd .. file.get_native_separator() .. path)
    local file = nativefs.newFile(fp)

	file:open("w")
	file:write(data)
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
