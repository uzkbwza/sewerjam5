---@diagnostic disable: lowercase-global
function UUID()
	local fn = function(x)
		local r = love.math.random(16) - 1
		r = (x == "x") and (r + 1) or (r % 4) + 9
		return ("0123456789abcdef"):sub(r, r)
	end
	return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end

function frames_to_seconds(n)
	return n / 60
end

function seconds_to_frames(n)
	return n * 60
end

function flood_fill(x, y, fill, check_solid)
	local stack = { Vec2(x, y) }
	while not table.is_empty(stack) do
		local coord = table.pop_front(stack)
		if not check_solid(coord.x, coord.y) then
			fill(coord.x, coord.y)
			table.insert(stack, coord + Vec2(-1, 0))
			table.insert(stack, coord + Vec2(1, 0))
			table.insert(stack, coord + Vec2(0, -1))
			table.insert(stack, coord + Vec2(0, 1))
		end
	end
end

function bresenham_los_callback(x0, y0, x1, y1, callback)
    local sx, sy, dx, dy

    if x0 < x1 then
        sx = 1
        dx = x1 - x0
    else
        sx = -1
        dx = x0 - x1
    end

    if y0 < y1 then
        sy = 1
        dy = y1 - y0
    else
        sy = -1
        dy = y0 - y1
    end

    local err, e2 = dx - dy, nil

    if not callback(x0, y0) then return false end

    while not (x0 == x1 and y0 == y1) do
        e2 = err + err
        if e2 > -dy then
            err = err - dy
            x0  = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0  = y0 + sy
        end
        if not callback(x0, y0) then return false end
    end

    return true
end


function identity_function(x)
	return x
end

function bresenham_los(x0, y0, x1, y1, points)
	local sx, sy, dx, dy

	if x0 < x1 then
		sx = 1
		dx = x1 - x0
	else
		sx = -1
		dx = x0 - x1
	end

	if y0 < y1 then
		sy = 1
		dy = y1 - y0
	else
		sy = -1
		dy = y0 - y1
	end

    local err, e2 = dx - dy, nil
	
	table.insert(points, Vec2(x0, y0))

	while not (x0 == x1 and y0 == y1) do
		e2 = err + err
		if e2 > -dy then
			err = err - dy
			x0  = x0 + sx
		end
        if e2 < dx then
            err = err + dx
            y0  = y0 + sy
        end
		
		table.insert(points, Vec2(x0, y0))
	end
end

function bresenham_line(x0, y0, x1, y1, callback)
    local points = {}
    local count = 0
    if callback then
        local result = bresenham_los_callback(x0, y0, x1, y1, function(x, y)
            if callback and not callback(x, y) then return false end
            count = count + 1
            points[count] = Vec2(x, y)
            return true
        end)
        return points, result
    end
    bresenham_los(x0, y0, x1, y1, points)
	return points
end
