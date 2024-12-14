local utf8 = require "utf8"
require "lib.color"


local graphics = {
    canvas = nil,
	scaled_canvas = nil,
    pre_canvas_draw_function = nil,
	screen_shader_canvases = {},
	sequencer = Sequencer(),
	packer = nil,
	textures = nil,
	texture_data = nil,
	sprite_paths = nil,
	layer_tree = nil,
	interp_fraction = 0,
	shader = require "shader.shader",
	main_canvas_start_pos = Vec2(0, 0),
	main_canvas_size = Vec2(0, 0),
	main_canvas_scale = 1,
    main_viewport_size = Vec2(0, 0),
    window_size = Vec2(0, 0),
	screen_rumble_intensity = 0,
    bg_image = nil,
	circles = {}
}

graphics = setmetatable(graphics, { __index = love.graphics })

local window_width, window_height = 0, 0
local window_size = Vec2(window_width, window_height)
local viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
local max_width_scale = 1
local max_height_scale = 1
local viewport_pixel_scale = 1
local canvas_size = viewport_size * viewport_pixel_scale
local canvas_pos = window_size / 2 - (canvas_size) / 2
local viewport_size_shader = { 0,  0} 
local canvas_pos_shader = { 0, 0 }
local canvas_size_shader = { 0, 0 }

function graphics.load_textures(texture_atlas)
	texture_atlas = texture_atlas or false

	local packer = nil

	local textures = {}
	local texture_data = {}
	local sprite_paths = filesystem.get_files_of_type("assets/sprite", "png", true)
	local image_settings = {
		mipmaps = false,
		linear = false,
	}

	-- local time = love.timer.getTime()
	-- coroutine.yield()
	for _, v in ipairs(sprite_paths) do
		local tex = graphics.new_image(v, image_settings)
		local data = graphics.new_image_data(v)
		local name = filesystem.filename_to_asset_name(v, "png", "sprite_")
		textures[name] = tex
		texture_data[tex] = data
		-- local current_time = love.timer.getTime()
		-- if current_time - time > 1 then
		-- time = current_time
		-- coroutine.yield()
		-- end
	end

	dbg("Loaded textures", table.length(textures))


	if packer then
		packer:bake()
	end

	graphics.packer = packer
	graphics.textures = textures
	graphics.texture_data = texture_data
	graphics.sprite_paths = sprite_paths
end

function graphics.load()
	
	graphics.set_default_filter("nearest", "nearest", 0)
    graphics.canvas = graphics.new_canvas(conf.viewport_size.x, conf.viewport_size.y)
	local wsx, wsy = graphics.get_dimensions()


	graphics.set_canvas(graphics.canvas)

	graphics.clear(0, 0, 0, 0)
	graphics.set_blend_mode("alpha")
	graphics.set_line_style("rough")
	graphics.set_canvas()

    -- local start = love.timer.getTime()
	-- local n = 100
    -- for i = 1, n do
    --     graphics.circles[i] = midpoint_circle(i)
    -- end
	-- print(string.format("i=%s, time=%s", n, love.timer.getTime() - start))

	graphics.load_textures(false)

	graphics.set_screen_shaders({
        -- graphics.shader.basic
		{ shader = graphics.shader.blur, args = {} },
		-- { shader = graphics.shader.screenfilter, args = {} },
		{ shader = graphics.shader.lcd, args = { pixel_texture = graphics.textures.pixeltexture } },
		{ shader = graphics.shader.aberration, args = {} },
		-- graphics.shader.lcd,
	})

	-- graphics.set_bg_image(graphics.textures.player)

	local font_paths = filesystem.get_files_of_type("assets/font", "ttf", true)
	graphics.font = {

	}

	for _, v in ipairs(font_paths) do
		graphics.font[filesystem.filename_to_asset_name(v, "ttf", "font_")] = graphics.new_font(v,
			v:find("8") and 8 or 16)
	end
	graphics.font.main = graphics.font["PixelOperator-Bold"]
    graphics.set_font(graphics.font.main)
	
	textures = graphics.textures
end

-- local ordered_draw = {}

function graphics.game_draw()
	graphics.push()

    local update_interp = true
	
	local layer = game.layer_tree

    layer.interp_fraction = update_interp and graphics.interp_fraction or layer.interp_fraction
	layer:draw_shared()

	graphics.pop()
end


function graphics.set_screen_shaders(shaders)
	graphics.screen_shaders = shaders
end

function graphics.set_bg_image(image)
	if graphics.bg_image then
		graphics.bg_image:release()
	end
	local data = graphics.texture_data[image]
	local cloned = graphics.new_image(data, { mipmaps = false, linear = true })
	cloned:setFilter("linear", "linear")
	graphics.bg_image = cloned
end

function graphics.draw_bg_image(image)
	graphics.draw_cover(image, 0, 0, graphics.window_size.x, graphics.window_size.y)
end

function graphics.set_pre_canvas_draw_function(func)
	graphics.pre_canvas_draw_function = func
end

function graphics.screen_pos_to_canvas_pos(sposx, sposy)
	return ((sposx - graphics.main_canvas_start_pos.x) / graphics.main_canvas_scale),
		((sposy - graphics.main_canvas_start_pos.y) / graphics.main_canvas_scale)
end

local flash_table = {
    Color.from_hex("ffff00"),
    Color.from_hex("ff8000"),
    Color.from_hex("ffff00"),
    Color.from_hex("80ff00"),
    Color.from_hex("00ff00"),
    Color.from_hex("00ff80"),
    Color.from_hex("00ffff"),
    Color.from_hex("0080ff"),
    Color.from_hex("0000ff"),
    Color.from_hex("8000ff"),
    Color.from_hex("ff00ff"),
    Color.from_hex("ff0080"),
    -- Color.from_hex("ffffff"),

}

function graphics.color_flash(offset, tick_length)
    local color = flash_table[floor(((gametime.ticks / tick_length) + offset) % #flash_table) + 1]
	return color
end


function graphics.start_rumble(intensity, duration, easing_function)
    local s = graphics.sequencer
    if graphics.rumble_coroutine then
        s:stop(graphics.rumble_coroutine)
    end
	
    easing_function = easing_function or ease("outQuad")
    graphics.rumble_coroutine = s:start(function()
	
        s:tween_property(graphics, "screen_rumble_intensity", intensity * usersettings.screen_shake_amount, 0, duration, easing_function)
        graphics.rumble_coroutine = nil
		graphics.screen_rumble_intensity = 0
    end)
end

function graphics.draw_loop()
	local wsx, wsy = graphics.get_dimensions()
    graphics.window_size.x = wsx
    graphics.window_size.y = wsy
	
    graphics.set_canvas(graphics.canvas)
	
	graphics.clear(0, 0, 0)

	graphics.game_draw()

	graphics.set_color(1, 1, 1)
	graphics.set_canvas()

	local process = usersettings.pixel_perfect and math.floor or identity_function

	-- TODO: stop generating garbage with vec2s
	window_width, window_height = graphics.get_dimensions()
    window_size.x = window_width
	window_size.y = window_height
    viewport_size.x = conf.viewport_size.x
	viewport_size.y = conf.viewport_size.y
	max_width_scale = process(window_size.x / viewport_size.x)
	max_height_scale = process(window_size.y / viewport_size.y)
	viewport_pixel_scale = process(math.min(max_width_scale, max_height_scale))
	canvas_size.x = viewport_size.x * viewport_pixel_scale
	canvas_size.y = viewport_size.y * viewport_pixel_scale
    canvas_pos.x = window_size.x / 2 - (canvas_size.x) / 2
    canvas_pos.y = window_size.y / 2 - (canvas_size.y) / 2

	if graphics.screen_rumble_intensity > 0 then
		local dx, dy = rng.random_vec2()
		local rumble_offset_x, rumble_offset_y = (dx * rng.randf(graphics.screen_rumble_intensity*0.5, graphics.screen_rumble_intensity)), (dy * rng.randf(graphics.screen_rumble_intensity*0.5, graphics.screen_rumble_intensity))
        canvas_pos.x = canvas_pos.x + rumble_offset_x * viewport_pixel_scale
		canvas_pos.y = canvas_pos.y + rumble_offset_y * viewport_pixel_scale
	end



    viewport_size_shader[1] = viewport_size.x
    viewport_size_shader[2] = viewport_size.y
    canvas_pos_shader[1] = canvas_pos.x
    canvas_pos_shader[2] = canvas_pos.y
    canvas_size_shader[1] = canvas_size.x
	canvas_size_shader[2] = canvas_size.y

	graphics.main_canvas_start_pos.x = canvas_pos.x
	graphics.main_canvas_start_pos.y = canvas_pos.y
	graphics.main_canvas_size.x = canvas_size.x
	graphics.main_canvas_size.y = canvas_size.y
	graphics.main_canvas_scale = viewport_pixel_scale
	graphics.main_viewport_size = viewport_size
	graphics.window_size.x = window_size.x
	graphics.window_size.y = window_size.y

	if graphics.pre_canvas_draw_function then
		graphics.pre_canvas_draw_function()
	elseif graphics.bg_image then
		graphics.draw_bg_image(graphics.bg_image)
	end

	local canvas_to_draw = graphics.canvas

	if usersettings.use_screen_shader and viewport_pixel_scale > 1 then
		if gametime.ticks % 10 == 0 then
			-- pcall(graphics.shader.update)
		end


        for i, shader_table in ipairs(graphics.screen_shaders) do
            local shader = shader_table.shader
			local args = shader_table.args
			local shader_canvas = graphics.screen_shader_canvases[i]

			if not shader_canvas then
				shader_canvas = graphics.new_canvas(canvas_size.x, canvas_size.y)
				graphics.screen_shader_canvases[i] = shader_canvas
			end

			if shader_canvas:getWidth() ~= canvas_size.x or shader_canvas:getHeight() ~= canvas_size.y then
				shader_canvas:release()
				shader_canvas = graphics.new_canvas(canvas_size.x, canvas_size.y)
				graphics.screen_shader_canvases[i] = shader_canvas
			end

			graphics.set_canvas(shader_canvas)

			if shader:hasUniform("viewport_size") then
				shader:send("viewport_size", viewport_size_shader )
			end
			if shader:hasUniform("canvas_size") then
				shader:send("canvas_size", canvas_size_shader )
			end
			if shader:hasUniform("canvas_pos") then
				shader:send("canvas_pos", canvas_pos_shader )
			end

            for arg, value in pairs(args) do
				if shader:hasUniform(arg) then
					shader:send(arg, value)
				end 
			end
				
            
			graphics.set_shader(shader)
			graphics.push()
            graphics.origin()

			graphics.draw(canvas_to_draw, 0, 0, 0, viewport_pixel_scale, viewport_pixel_scale)
			graphics.pop()

			canvas_to_draw = shader_canvas
			viewport_pixel_scale = 1
		end
	end

    graphics.set_canvas()
	
    -- if conf.pixel_perfect then
	graphics.draw(canvas_to_draw, math.floor(canvas_pos.x), math.floor(canvas_pos.y), 0, viewport_pixel_scale,
		viewport_pixel_scale)
    -- else
    --     local scaled_canvas = graphics.scaled_canvas
		
    --     local wsx, wsy = canvas_size.x, canvas_size.y
    --     if scaled_canvas == nil or scaled_canvas:getWidth() ~= wsx or scaled_canvas:getHeight() ~= wsy then
    --         if scaled_canvas then
    --             scaled_canvas:release()
    --         end
    --         scaled_canvas = graphics.new_canvas(wsx, wsy)
    --         scaled_canvas:setFilter("linear", "linear")
    --         graphics.scaled_canvas = scaled_canvas
    --     end
	-- 	-- TODO: apply shader *after* scaling
	-- 	graphics.set_canvas(scaled_canvas)
	-- 	graphics.clear(0, 0, 0, 0)
	-- 	graphics.draw(canvas_to_draw, 0, 0, 0, viewport_pixel_scale, viewport_pixel_scale)
	-- 	graphics.set_canvas()
	-- 	graphics.draw_fit(scaled_canvas, 0, 0, graphics.window_size.x, graphics.window_size.y)
    -- end
	
	graphics.set_shader()

	graphics.set_canvas()

	debug.printlines(0, 0)
end

--- love API wrappers
function graphics.set_color(r, g, b, a)
	if type(r) == "string" then
		graphics.set_color(Color.from_hex_unpack(r))
		return
	end
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.setColor(r, g, b, a)
end

function graphics.get_color() return love.graphics.getColor() end

function graphics.set_font(font)
	love.graphics.setFont(font)
end

function graphics.new_font(path, size)
	return love.graphics.newFont(path, size)
end

function graphics.new_image_font(path, glyphs, spacing)
	return love.graphics.newImageFont(path, glyphs, spacing)
end

function graphics.new_quad(x, y, width, height, sw, sh)
	return love.graphics.newQuad(x, y, width, height, sw, sh)
end

function graphics.new_text(text, font)
	return love.graphics.newText(font, text)
end

function graphics.new_sprite_batch(texture, size, usage)
	return love.graphics.newSpriteBatch(texture, size, usage)
end

function graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
    -- remove this if you arent using sprite sheets
	if texture == nil then return end
	if texture.__isquad then
		love.graphics.draw(texture.texture, texture.quad, x, y, r, sx, sy, ox, oy, kx, ky)
	else
		love.graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	end
end

function graphics.draw_cover(texture, start_x, start_y, end_x, end_y)
	local tex_width = texture:getWidth()
	local tex_height = texture:getHeight()
	local tex_ratio = tex_width / tex_height
	local screen_ratio = (end_x - start_x) / (end_y - start_y)

	-- Calculate the scale factor
	local scale
	if tex_ratio > screen_ratio then
		-- If the texture is wider than the screen, scale by height
		scale = (end_y - start_y) / tex_height
	else
		-- If the texture is taller than the screen, scale by width
		scale = (end_x - start_x) / tex_width
	end

	-- Calculate new texture dimensions
	local new_tex_width = tex_width * scale
	local new_tex_height = tex_height * scale

	-- Calculate the offsets to center the texture within the rectangle
	local offset_x = (new_tex_width - (end_x - start_x)) / 2
	local offset_y = (new_tex_height - (end_y - start_y)) / 2

	-- Draw the texture, adjusting the position to center it if necessary
	graphics.draw(texture, start_x - offset_x, start_y - offset_y, 0, scale, scale)
end

function graphics.draw_fit(texture, start_x, start_y, end_x, end_y)
	local tex_width = texture:getWidth()
	local tex_height = texture:getHeight()
	local tex_ratio = tex_width / tex_height
	local screen_ratio = (end_x - start_x) / (end_y - start_y)

	-- Calculate the scale factor
	local scale
	if tex_ratio < screen_ratio then
		-- If the texture is wider than the screen, scale by height
		scale = (end_y - start_y) / tex_height
	else
		-- If the texture is taller than the screen, scale by width
		scale = (end_x - start_x) / tex_width
	end

	-- Calculate new texture dimensions
	local new_tex_width = tex_width * scale
	local new_tex_height = tex_height * scale

	-- Calculate the offsets to center the texture within the rectangle
	local offset_x = (new_tex_width - (end_x - start_x)) / 2
	local offset_y = (new_tex_height - (end_y - start_y)) / 2

	-- Draw the texture, adjusting the position to center it if necessary
	graphics.draw(texture, start_x - offset_x, start_y - offset_y, 0, scale, scale)
end

function graphics.get_canvas()
	return love.graphics.getCanvas()
end

function graphics.draw_quad_centered(texture, quad, width, height, x, y, r, sx, sy, ox, oy, kx, ky)
	ox = ox or 0
	oy = oy or 0
	local offset_x = width / 2
	local offset_y = height / 2
	graphics.draw(texture, quad, x, y, r, sx, sy, ox + offset_x, oy + offset_y, kx, ky)

end

function graphics.draw_centered(texture, x, y, r, sx, sy, ox, oy, kx, ky)

	if texture == nil then return end

	if texture.__isquad then
		return graphics.draw_quad_centered(texture.texture, texture.quad, texture.width, texture.height, x, y, r, sx, sy, ox, oy, kx, ky)
	end

	ox = ox or 0
	oy = oy or 0
	local offset_x = round(texture:getWidth() / 2)
	local offset_y = round(texture:getHeight() / 2)
	graphics.draw(texture, x, y, r, sx, sy, ox + offset_x, oy + offset_y, kx, ky)
end

function graphics.clear(r, g, b, a)
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.clear(r, g, b, a)
end

function graphics.set_canvas(canvas)
	love.graphics.setCanvas(canvas)
end

function graphics.set_blend_mode(mode)
	love.graphics.setBlendMode(mode)
end

function graphics.set_line_style(style)
	love.graphics.setLineStyle(style)
end

function graphics.set_default_filter(min, mag, anisotropy)
	love.graphics.setDefaultFilter(min, mag, anisotropy)
end

function graphics.get_dimensions()
	return love.graphics.getDimensions()
end

function graphics.new_canvas(width, height)
	return love.graphics.newCanvas(width, height)
end

function graphics.new_image(path, settings)
	return love.graphics.newImage(path, settings)
end

function graphics.new_image_data(path)
	return love.image.newImageData(path)
end

function graphics.points(...)
love.graphics.points(...)
end

function graphics.circle(mode, x, y, radius, segments)
	-- radius = floor(radius)
	-- local r = floor(radius)
    -- if mode == "line" and graphics.circles[radius] then

	-- 	love.graphics.points(graphics.circles[radius])

	-- 	return
	-- end
	love.graphics.circle(mode, x, y, radius, segments)
end

function graphics.rect(mode, rect)
	love.graphics.rectangle(mode, rect.x, rect.y, rect.width, rect.height)
end

-- function graphics.rectangle(mode, x, y, width, height)
-- 	love.graphics.rectangle(mode, x, y, width, height)
-- end

-- function graphics.line(x1, y1, x2, y2, ...)
-- 	love.graphics.line(x1, y1, x2, y2, ...)
-- end
-- function graphics.polygon(mode, ...)

-- 	love.graphics.polygon(mode, ...)
-- end

function graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push()

	love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.pop()
end

function graphics.print_outline(outline_color, text, x, y, r, sx, sy, ox, oy, kx, ky)
    graphics.push("all")
    love.graphics.print(text, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    graphics.set_color(outline_color)
    love.graphics.print(text, x - 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x + 1, y - 1, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x - 1, y + 1, r, sx, sy, ox, oy, kx, ky)
	love.graphics.print(text, x + 1, y + 1, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x + 1, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x - 1, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x, y + 1, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
    love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.print_outline_no_diagonals(outline_color, text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push("all")
    graphics.set_color(outline_color)
    love.graphics.print(text, x + 1, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x - 1, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x, y + 1, r, sx, sy, ox, oy, kx, ky)
    love.graphics.print(text, x, y - 1, r, sx, sy, ox, oy, kx, ky)
    graphics.pop()
    love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.dashline(p1x, p1y, p2x, p2y, dash, gap)
    local dy, dx = p2y - p1y, p2x - p1x
    local an, st = math.atan2(dy, dx), dash + gap
    local len    = math.sqrt(dx * dx + dy * dy)
    local nm     = (len - dash) / st
    graphics.push()
    graphics.translate(p1x, p1y)
    graphics.rotate(an)
    for i = 0, nm do
        graphics.line(i * st, 0, i * st + dash, 0)
    end
    graphics.line(nm * st, 0, nm * st + dash, 0)
    graphics.pop()
end
 
function graphics.dashrect(x, y, w, h, dash, gap)
	graphics.dashline(x, y, x + w, y, dash, gap)
	graphics.dashline(x + w, y, x + w, y + h, dash, gap)
	graphics.dashline(x + w, y + h, x, y + h, dash, gap)
	graphics.dashline(x, y + h, x, y, dash, gap)
end

function graphics.draw_collision_box(rect, color, alpha)
    alpha = alpha or 1
	love.graphics.push("all")
	love.graphics.setColor(color.r, color.g, color.b, alpha * 0.25)
	love.graphics.rectangle("fill", rect.x + 1, rect.y + 1, rect.width - 1, rect.height - 1)
	love.graphics.setColor(color.r, color.g, color.b, alpha * 0.5)
    love.graphics.rectangle("line", rect.x + 1, rect.y + 1, rect.width - 1, rect.height - 1)
	love.graphics.pop()
end

function graphics.reset()
	love.graphics.reset()
end

function graphics.set_shader(shader)
	love.graphics.setShader(shader)
end

return graphics
