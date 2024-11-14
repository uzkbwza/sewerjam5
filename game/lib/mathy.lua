---@diagnostic disable: lowercase-global
log, floor, ceil, min, abs, sqrt, cos, sin, atan2, pi, max, deg, rad, tau, pow
= math.log, math.floor, math.ceil, math.min, math.abs, math.sqrt, math.cos, math.sin, math.atan2, math.pi, math.max, math.deg, math.rad, math.pi * 2, math.pow


function clamp(x, min, max)
  return min(max(x, min), max)
end

function sign(x)
  return x > 0 and 1 or x < 0 and -1 or 0
end

function remap(value, istart, istop, ostart, ostop)
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
end

function remap_pow(value, istart, istop, ostart, ostop, power)
    return ostart + (ostop - ostart) * pow((value - istart) / (istop - istart), power)
end

function stepify(value, step)
	return floor(value / step) * step
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function round(x)
	return floor(x + 0.5)
end

function dtlerp(power, delta)
    return 1 - pow(pow(0.1, power), delta)
end

function ease_out(num, pow)
    assert(num <= 1 and num >= 0)
    return 1.0 - pow(1.0 - num, pow)
end

function clamp(value, min_val, max_val)
    if value < min_val then return min_val end
    if value > max_val then return max_val end
    return value
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function lerp_clamp(a, b, t)
    return lerp(a, b, clamp(t, 0.0, 1.0))
end

function inverse_lerp(a, b, v)
    return (v - a) / (b - a)
end

function inverse_lerp_clamp(a, b, v)
    return clamp(inverse_lerp(a, b, v), 0.0, 1.0)
end

function angle_diff(a, b)
    local diff = a - b
    return (diff + math.pi) % (2 * math.pi) - math.pi
end

function sin_0_1(value)
    return (sin(value) / 2.0) + 0.5
end

function round(n)
    return floor(n + 0.5)
end

function stepify_safe(s, step)
	if step == 0 then return s end
    return round(s / step) * step
end

function stepify(s, step)
    return round(s / step) * step
end

function stepify_ceil_safe(s, step)
	if step == 0 then return ceil(s) end
	return ceil(s / step) * step
end

function stepify_ceil(s, step)
	return ceil(s / step) * step
end

function stepify_floor_safe(s, step)
	if step == 0 then return floor(s) end
	return floor(s / step) * step
end

function stepify_floor(s, step)
    return floor(s / step) * step
end

function wave(from, to, duration, offset)
    if offset == nil then offset = 0 end
    local t = os.clock()
    local a = (to - from) * 0.5
    return from + a + sin(((t + duration * offset) / duration) * (2 * pi)) * a
end

function pulse(duration, width)
    if duration == nil then duration = 1.0 end
    if width == nil then width = 0.5 end
    return wave(0.0, 1.0, duration) < width
end

function snap(value, step)
    return round(value / step) * step
end

function approach(a, b, amount)
    if a < b then
        a = a + amount
        if a > b then return b end
    else
        a = a - amount
        if a < b then return b end
    end
    return a
end

function next_power_of_2(n)
	power = 1
	while(power < n) do
		power = power * 2
	end
	return power
end

-- Vector functions using Vec2 and Vec3 classes
function angle_to_vec2(angle)
    return Vec2(cos(angle), sin(angle))
end

-- Exponential decay function (splerp) for scalars
function splerp(a, b, delta, half_life)
    return b + (a - b) * pow(2, -delta / (half_life / 60))
end

-- Exponential decay function (splerp) for Vec2
function splerp_vec(a, b, delta, half_life)
    local t = pow(2, -delta / (half_life / 60))
    return b + (a - b) * t  -- Uses Vec2 operations
end

function splerp_vec_unpacked(ax, ay, bx, by, delta, half_life)
	local t = pow(2, -delta / (half_life / 60))
	return bx + (ax - bx) * t, by + (ay - by) * t
end

-- Exponential decay function (splerp) for Vec3
function splerp_vec3(a, b, delta, half_life)
    local t = pow(2, -delta / (half_life / 60))
    return b + (a - b) * t  -- Uses Vec3 operations
end

function splerp_vec3_unpacked(ax, ay, az, bx, by, bz, delta, half_life)
	local t = pow(2, -delta / (half_life / 60))
	return bx + (ax - bx) * t, by + (ay - by) * t, bz + (az - bz) * t
end

function lerp_angle(a, b, t)
    local diff = ((b - a + pi) % (2 * pi)) - pi
    return a + diff * t
end

function splerp_angle(a, b, delta, half_life)
    local t = 1 - pow(2, -delta / (half_life / 60))
    return lerp_angle(a, b, t)
end

function lerp_wrap(a, b, mod_value, t)
    local delta = ((b - a) % mod_value + mod_value) % mod_value
    if delta > mod_value / 2 then
        delta = delta - mod_value
    end
    return ((a + delta * t) % mod_value + mod_value) % mod_value
end

function splerp_wrap(a, b, mod_value, delta, half_life)
    local t = 1 - pow(2, -delta / (half_life / 60))
    return lerp_wrap(a, b, mod_value, t)
end

function wrap_diff(a, b, period)
    local diff = a - b
    return (diff + period / 2) % period - period / 2
end

function wrap_dist_from_center(from_value, center, wrap)
    return wrap_diff(from_value, center, wrap)
end

function ping_pong_interpolate(value, a, b, ease_value)
    if ease_value == nil then ease_value = 1.0 end
    local start = min(a, b)
    local finish = max(a, b)
    local t = inverse_lerp(start, finish, value)
    local f = t % 1.0
    if (floor(t) % 2) ~= 0 then
        f = 1.0 - f
    end
    return start + pow(f, ease_value) * (finish - start)
end

function damp(source, target, smoothing, dt)
    return lerp(source, target, dtlerp(smoothing, dt))
end

function damp_angle(source, target, smoothing, dt)
    return lerp_angle(source, target, 1 - pow(smoothing, dt))
end

function damp_vec2(source, target, smoothing, dt)
    local t = 1 - pow(smoothing, dt)
    return source + (target - source) * t  -- Uses Vec2 operations
end

function damp_vec3(source, target, smoothing, dt)
    local t = 1 - pow(smoothing, dt)
    return source + (target - source) * t  -- Uses Vec3 operations
end

function vec_dir(vec_1, vec_2)
    return (vec_2 - vec_1):normalized()  -- Uses Vec2 methods
end

-- Example function for clamping a cell within a map's dimensions
function clamp_cell(cell, map)
    return Vec2(
        clamp(cell.x, 0, map.width - 1),
        clamp(cell.y, 0, map.height - 1)
    )
end

function fposmod(x, y)
	return x - y * floor(x / y)
end

function floor_div(a, b)
	return floor(a / b)
end

function iposmod(x, y)
	return x - y * floor_div(x, y)
end
