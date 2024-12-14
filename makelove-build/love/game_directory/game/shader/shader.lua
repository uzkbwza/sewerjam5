local shader = {}

shader.fragment_shader_paths = filesystem.get_files_of_type("shader", "frag", true)

function shader.update()
	print("Updating shaders")
	for _, v in ipairs(shader.fragment_shader_paths) do
		local name = filesystem.filename_to_asset_name(v, "frag")
		-- assert(shader[name] == nil, "Shader name collision: " .. name)
		shader[name] = love.graphics.newShader(v)
	end
end

shader.update()

return shader
