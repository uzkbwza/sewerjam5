---@diagnostic disable: lowercase-global
Vec2 = Object:extend()

function Vec2:new(x, y)
	self.x = x or 0
	self.y = y or 0
end

function Vec2.__add(a, b)
	if type(a) == "number" then
		return Vec2(b.x + a, b.y + a)
	elseif type(b) == "number" then
		return Vec2(a.x + b, a.y + b)
	else
		return Vec2(a.x + b.x, a.y + b.y)
	end
end

function Vec2.__sub(a, b)
	if type(a) == "number" then
		return Vec2(b.x - a, b.y - a)
	elseif type(b) == "number" then
		return Vec2(a.x - b, a.y - b)
	else
		return Vec2(a.x - b.x, a.y - b.y)
	end
end

function Vec2.__mul(a, b)
	if type(a) == "number" then
		return Vec2(b.x * a, b.y * a)
	elseif type(b) == "number" then
		return Vec2(a.x * b, a.y * b)
	else
		return Vec2(a.x * b.x, a.y * b.y)
	end
end

function Vec2.__div(a, b)
	if type(a) == "number" then
		return Vec2(b.x / a, b.y / a)
	elseif type(b) == "number" then
		return Vec2(a.x / b, a.y / b)
	else
		return Vec2(a.x / b.x, a.y / b.y)
	end
end

function Vec2.__eq(a, b)
	return a.x == b.x and a.y == b.y
end

function Vec2.__lt(a, b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function Vec2.__le(a, b)
	return a.x <= b.x and a.y <= b.y
end

function Vec2.__tostring(a)
	return "(" .. a.x .. ", " .. a.y .. ")"
end

function Vec2:magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vec2:normalized()
	local mag = self:magnitude()
	if mag == 0 then
		return Vec2(0, 0)
	end
	return Vec2(self.x / mag, self.y / mag)
end

function Vec2:distance_to(b)
	local x = self.x - b.x
	local y = self.y - b.y
	return math.sqrt(x * x + y * y)
end

function Vec2:direction_to(b)
	return (b - self):normalized()
end

function Vec2:lerp(b, t)
	return self + (b - self) * t
end

function Vec2:project(b)
	local amt = self:dot(b) / b:dot(b)
	return b * amt
end

function Vec2:dot(b)
	return self.x * b.x + self.y * b.y
end

function Vec2:angle()
	return math.atan2(self.y, self.x)
end

function Vec2:clone()
	return Vec2(self.x, self.y)
end

function Vec2:rotated(angle)
	local x = self.x * math.cos(angle) - self.y * math.sin(angle)
	local y = self.x * math.sin(angle) + self.y * math.cos(angle)
	return Vec2(x, y)
end

function Vec2:manhattan_distance(b)
	return math.abs(self.x - b.x) + math.abs(self.y - b.y)
end

function Vec2:rounded()
	return Vec2(math.floor(self.x + 0.5), math.floor(self.y + 0.5))
end

function Vec2:distance_squared(b)
    local dx = self.x - b.x
    local dy = self.y - b.y
    return dx * dx + dy * dy
end

function Vec2:to_polar()
    local r = self:magnitude()
    local theta = self:angle()
    return r, theta
end

function Vec2.from_polar(r, theta)
    local x = r * math.cos(theta)
    local y = r * math.sin(theta)
    return Vec2(x, y)
end

-- vec3

Vec3 = Object:extend()

function Vec3:new(x, y, z)
	self.x = x or 0
	self.y = y or 0
	self.z = z or 0
end

function Vec3.__add(a, b)
	if type(a) == "number" then
		return Vec3(b.x + a, b.y + a, b.z + a)
	elseif type(b) == "number" then
		return Vec3(a.x + b, a.y + b, a.z + b)
	else
		return Vec3(a.x + b.x, a.y + b.y, a.z + b.z)
	end
end

function Vec3.__sub(a, b)
	if type(a) == "number" then
		return Vec3(b.x - a, b.y - a, b.z - a)
	elseif type(b) == "number" then
		return Vec3(a.x - b, a.y - b, a.z - b)
	else
		return Vec3(a.x - b.x, a.y - b.y, a.z - b.z)
	end
end

function Vec3.__mul(a, b)
	if type(a) == "number" then
		return Vec3(b.x * a, b.y * a, b.z * a)
	elseif type(b) == "number" then
		return Vec3(a.x * b, a.y * b, a.z * b)
	else
		return Vec3(a.x * b.x, a.y * b.y, a.z * b.z)
	end
end

function Vec3.__div(a, b)
	if type(a) == "number" then
		return Vec3(b.x / a, b.y / a, b.z / a)
	elseif type(b) == "number" then
		return Vec3(a.x / b, a.y / b, a.z / b)
	else
		return Vec3(a.x / b.x, a.y / b.y, a.z / b.z)
	end
end

function Vec3.__eq(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

function Vec3.__lt(a, b)
	return a.x < b.x or (a.x == b.x and (a.y < b.y or (a.y == b.y and a.z < b.z)))
end

function Vec3.__le(a, b)
	return a.x <= b.x and a.y <= b.y and a.z <= b.z
end

function Vec3.__tostring(a)
	return "(" .. a.x .. ", " .. a.y .. ", " .. a.z .. ")"
end

function Vec3:magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:normalized()
	local mag = self:magnitude()
	if mag == 0 then
		return Vec3(0, 0, 0)
	end
	return Vec3(self.x / mag, self.y / mag, self.z / mag)
end

function Vec3:distance_to(b)
	local x = self.x - b.x
	local y = self.y - b.y
	local z = self.z - b.z
	return math.sqrt(x * x + y * y + z * z)
end

function Vec3:direction_to(b)
	return (b - self):normalized()
end

function Vec3:lerp(b, t)
	return self + (b - self) * t
end

function Vec3:cross(b)
	local x = self.y * b.z - self.z * b.y
	local y = self.z * b.x - self.x * b.z
	local z = self.x * b.y - self.y * b.x
	return Vec3(x, y, z)
end

function Vec3:dot(b)
	return self.x * b.x + self.y * b.y + self.z * b.z
end

function Vec3:rotated_z(angle)
	local x = self.x * math.cos(angle) - self.y * math.sin(angle)
	local y = self.x * math.sin(angle) + self.y * math.cos(angle)
	return Vec3(x, y, self.z)
end

function Vec3:manhattan_distance(b)
	return math.abs(self.x - b.x) + math.abs(self.y - b.y) + math.abs(self.z - b.z)
end

function Vec3:rounded()
	return Vec3(math.floor(self.x + 0.5), math.floor(self.y + 0.5), math.floor(self.z + 0.5))
end

function Vec3:distance_squared(b)
    local dx = self.x - b.x
    local dy = self.y - b.y
    local dz = self.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function Vec3:clone()
	return Vec3(self.x, self.y, self.z)
end

-- Vec2 In-place Methods

function Vec2:add_in_place(x, y)
    if type(x) == "number" then
        self.x = self.x + x
        self.y = self.y + (y or x)
    else
        self.x = self.x + x.x
        self.y = self.y + x.y
    end
    return self
end

function Vec2:sub_in_place(x, y)
    if type(x) == "number" then
        self.x = self.x - x
        self.y = self.y - (y or x)
    else
        self.x = self.x - x.x
        self.y = self.y - x.y
    end
    return self
end

function Vec2:mul_in_place(x, y)
    if type(x) == "number" then
        self.x = self.x * x
        self.y = self.y * (y or x)
    else
        self.x = self.x * x.x
        self.y = self.y * x.y
    end
    return self
end

function Vec2:div_in_place(x, y)
    if type(x) == "number" then
        self.x = self.x / x
        self.y = self.y / (y or x)
    else
        self.x = self.x / x.x
        self.y = self.y / x.y
    end
    return self
end

function Vec2:normalize_in_place()
    local mag = self:magnitude()
	if mag == 0 then
		self.x = 0
		self.y = 0
		return self
	end
	
    self.x = self.x / mag
    self.y = self.y / mag
    return self
end

function Vec2:rotate_in_place(angle)
    local x = self.x * math.cos(angle) - self.y * math.sin(angle)
    local y = self.x * math.sin(angle) + self.y * math.cos(angle)
    self.x = x
    self.y = y
    return self
end

-- Vec3 In-place Methods

function Vec3:add_in_place(x, y, z)
    if type(x) == "number" then
        self.x = self.x + x
        self.y = self.y + (y or x)
        self.z = self.z + (z or (y or x))
    else
        self.x = self.x + x.x
        self.y = self.y + x.y
        self.z = self.z + x.z
    end
    return self
end

function Vec3:sub_in_place(x, y, z)
    if type(x) == "number" then
        self.x = self.x - x
        self.y = self.y - (y or x)
        self.z = self.z - (z or (y or x))
    else
        self.x = self.x - x.x
        self.y = self.y - x.y
        self.z = self.z - x.z
    end
    return self
end

function Vec3:mul_in_place(x, y, z)
    if type(x) == "number" then
        self.x = self.x * x
        self.y = self.y * (y or x)
        self.z = self.z * (z or (y or x))
    else
        self.x = self.x * x.x
        self.y = self.y * x.y
        self.z = self.z * x.z
    end
    return self
end

function Vec3:div_in_place(x, y, z)
    if type(x) == "number" then
        self.x = self.x / x
        self.y = self.y / (y or x)
        self.z = self.z / (z or (y or x))
    else
        self.x = self.x / x.x
        self.y = self.y / x.y
        self.z = self.z / x.z
    end
    return self
end

function Vec3:normalize_in_place()
    local mag = self:magnitude()
	if mag == 0 then
		self.x = 0
		self.y = 0
		self.z = 0
		return self
	end
    self.x = self.x / mag
    self.y = self.y / mag
    self.z = self.z / mag
    return self
end

function Vec3:rotate_z_in_place(angle)
    local x = self.x * math.cos(angle) - self.y * math.sin(angle)
    local y = self.x * math.sin(angle) + self.y * math.cos(angle)
    self.x = x
    self.y = y
    return self
end


-- Functions that take individual x, y arguments
function vec2_add(a_x, a_y, b_x, b_y)
    return a_x + b_x, a_y + b_y
end

-- Alternative function that takes tables
function vec2_add_table(a, b)
    return a.x + b.x, a.y + b.y
end

function vec2_add_scalar(x, y, scalar)
    return x + scalar, y + scalar
end

function vec2_add_scalar_table(a, scalar)
    return a.x + scalar, a.y + scalar
end

function vec2_sub(a_x, a_y, b_x, b_y)
    return a_x - b_x, a_y - b_y
end

function vec2_sub_table(a, b)
    return a.x - b.x, a.y - b.y
end

function vec2_sub_scalar(x, y, scalar)
    return x - scalar, y - scalar
end

function vec2_sub_scalar_table(a, scalar)
    return a.x - scalar, a.y - scalar
end

function vec2_mul(a_x, a_y, b_x, b_y)
    return a_x * b_x, a_y * b_y
end

function vec2_mul_table(a, b)
    return a.x * b.x, a.y * b.y
end

function vec2_mul_scalar(x, y, scalar)
    return x * scalar, y * scalar
end

function vec2_mul_scalar_table(a, scalar)
    return a.x * scalar, a.y * scalar
end

function vec2_div(a_x, a_y, b_x, b_y)
    return a_x / b_x, a_y / b_y
end

function vec2_div_table(a, b)
    return a.x / b.x, a.y / b.y
end

function vec2_div_scalar(x, y, scalar)
    return x / scalar, y / scalar
end

function vec2_div_scalar_table(a, scalar)
    return a.x / scalar, a.y / scalar
end

function vec2_eq(a_x, a_y, b_x, b_y)
    return a_x == b_x and a_y == b_y
end

function vec2_eq_table(a, b)
    return a.x == b.x and a.y == b.y
end

function vec2_lt(a_x, a_y, b_x, b_y)
    return a_x < b_x or (a_x == b_x and a_y < b_y)
end

function vec2_lt_table(a, b)
    return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vec2_le(a_x, a_y, b_x, b_y)
    return a_x <= b_x and a_y <= b_y
end

function vec2_le_table(a, b)
    return a.x <= b.x and a.y <= b.y
end

function vec2_tostring(x, y)
    return "(" .. x .. ", " .. y .. ")"
end

function vec2_tostring_table(a)
    return "(" .. a.x .. ", " .. a.y .. ")"
end

function vec2_magnitude(x, y)
    return math.sqrt(x * x + y * y)
end

function vec2_magnitude_table(a)
    return math.sqrt(a.x * a.x + a.y * a.y)
end

function vec2_normalized(x, y)
    local mag = vec2_magnitude(x, y)
	if mag == 0 then
		return 0, 0
	end
    return x / mag, y / mag
end

function vec2_normalized_table(a)
    local mag = vec2_magnitude_table(a)
    return a.x / mag, a.y / mag
end

function vec2_distance_to(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

function vec2_distance_to_table(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

function vec2_direction_to(x1, y1, x2, y2)
    return vec2_normalized(x2 - x1, y2 - y1)
end

function vec2_direction_to_table(a, b)
    return vec2_normalized(b.x - a.x, b.y - a.y)
end

function vec2_lerp(x1, y1, x2, y2, t)
    return x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
end

function vec2_lerp_table(a, b, t)
    return a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t
end

function vec2_project(x1, y1, x2, y2)
    local dot_product = vec2_dot(x1, y1, x2, y2)
    local b_dot_b = vec2_dot(x2, y2, x2, y2)
    local amt = dot_product / b_dot_b
    return x2 * amt, y2 * amt
end

function vec2_project_table(a, b)
    local dot_product = vec2_dot_table(a, b)
    local b_dot_b = vec2_dot_table(b, b)
    local amt = dot_product / b_dot_b
    return b.x * amt, b.y * amt
end

function vec2_dot(x1, y1, x2, y2)
    return x1 * x2 + y1 * y2
end

function vec2_dot_table(a, b)
    return a.x * b.x + a.y * b.y
end

function vec2_angle(x, y)
    return math.atan2(y, x)
end

function vec2_angle_table(a)
    return math.atan2(a.y, a.x)
end

function vec2_rotated(x, y, angle)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return x * cos_a - y * sin_a, x * sin_a + y * cos_a
end

function vec2_rotated_table(a, angle)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return a.x * cos_a - a.y * sin_a, a.x * sin_a + a.y * cos_a
end

function vec2_manhattan_distance(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

function vec2_manhattan_distance_table(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

function vec2_rounded(x, y)
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

function vec2_rounded_table(a)
    return math.floor(a.x + 0.5), math.floor(a.y + 0.5)
end

function vec2_distance_squared(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

function vec2_distance_squared_table(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return dx * dx + dy * dy
end

function vec2_to_polar(x, y)
    local r = vec2_magnitude(x, y)
    local theta = vec2_angle(x, y)
    return r, theta
end

function vec2_from_polar(r, theta)
    local x = r * math.cos(theta)
    local y = r * math.sin(theta)
    return x, y
end

-- For table format
function vec2_to_polar_table(a)
    return vec2_magnitude_table(a), vec2_angle_table(a)
end

function vec2_from_polar_table(r, theta)
    local x = r * math.cos(theta)
    local y = r * math.sin(theta)
    return { x = x, y = y }
end

-- Vec3 Functions

-- Functions that take individual x, y, z arguments
function vec3_add(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x + b_x, a_y + b_y, a_z + b_z
end

-- Alternative function that takes tables
function vec3_add_table(a, b)
    return a.x + b.x, a.y + b.y, a.z + b.z
end

function vec3_add_scalar(x, y, z, scalar)
    return x + scalar, y + scalar, z + scalar
end

function vec3_add_scalar_table(a, scalar)
    return a.x + scalar, a.y + scalar, a.z + scalar
end

function vec3_sub(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x - b_x, a_y - b_y, a_z - b_z
end

function vec3_sub_table(a, b)
    return a.x - b.x, a.y - b.y, a.z - b.z
end

function vec3_sub_scalar(x, y, z, scalar)
    return x - scalar, y - scalar, z - scalar
end

function vec3_sub_scalar_table(a, scalar)
    return a.x - scalar, a.y - scalar, a.z - scalar
end

function vec3_mul(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x * b_x, a_y * b_y, a_z * b_z
end

function vec3_mul_table(a, b)
    return a.x * b.x, a.y * b.y, a.z * b.z
end

function vec3_mul_scalar(x, y, z, scalar)
    return x * scalar, y * scalar, z * scalar
end

function vec3_mul_scalar_table(a, scalar)
    return a.x * scalar, a.y * scalar, a.z * scalar
end

function vec3_div(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x / b_x, a_y / b_y, a_z / b_z
end

function vec3_div_table(a, b)
    return a.x / b.x, a.y / b.y, a.z / b.z
end

function vec3_div_scalar(x, y, z, scalar)
    return x / scalar, y / scalar, z / scalar
end

function vec3_div_scalar_table(a, scalar)
    return a.x / scalar, a.y / scalar, a.z / scalar
end

function vec3_eq(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x == b_x and a_y == b_y and a_z == b_z
end

function vec3_eq_table(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function vec3_lt(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x < b_x or (a_x == b_x and (a_y < b_y or (a_y == b_y and a_z < b_z)))
end

function vec3_lt_table(a, b)
    return a.x < b.x or (a.x == b.x and (a.y < b.y or (a.y == b.y and a.z < b.z)))
end

function vec3_le(a_x, a_y, a_z, b_x, b_y, b_z)
    return a_x <= b_x and a_y <= b_y and a_z <= b_z
end

function vec3_le_table(a, b)
    return a.x <= b.x and a.y <= b.y and a.z <= b.z
end

function vec3_tostring(x, y, z)
    return "(" .. x .. ", " .. y .. ", " .. z .. ")"
end

function vec3_tostring_table(a)
    return "(" .. a.x .. ", " .. a.y .. ", " .. a.z .. ")"
end

function vec3_magnitude(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function vec3_magnitude_table(a)
    return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

function vec3_normalized(x, y, z)
    local mag = vec3_magnitude(x, y, z)
	if mag == 0 then
		return 0, 0, 0
	end
    return x / mag, y / mag, z / mag
end

function vec3_normalized_table(a)
    local mag = vec3_magnitude_table(a)
	if mag == 0 then
		return 0, 0, 0
	end
    return a.x / mag, a.y / mag, a.z / mag
end

function vec3_distance_to(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function vec3_distance_to_table(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function vec3_direction_to(x1, y1, z1, x2, y2, z2)
    return vec3_normalized(x2 - x1, y2 - y1, z2 - z1)
end

function vec3_direction_to_table(a, b)
    return vec3_normalized(b.x - a.x, b.y - a.y, b.z - a.z)
end

function vec3_lerp(x1, y1, z1, x2, y2, z2, t)
    return x1 + (x2 - x1) * t, y1 + (y2 - y1) * t, z1 + (z2 - z1) * t
end

function vec3_lerp_table(a, b, t)
    return a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t
end

function vec3_cross(x1, y1, z1, x2, y2, z2)
    local x = y1 * z2 - z1 * y2
    local y = z1 * x2 - x1 * z2
    local z = x1 * y2 - y1 * x2
    return x, y, z
end

function vec3_cross_table(a, b)
	local x = a.y * b.z - a.z * b.y
    local y = a.z * b.x - a.x * b.z
    local z = a.x * b.y - a.y * b.x
    return x, y, z
end

function vec3_dot(x1, y1, z1, x2, y2, z2)
	return x1 * x2 + y1 * y2 + z1 * z2
end

function vec3_dot_table(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function vec3_rotated_z(x, y, z, angle)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return x * cos_a - y * sin_a, x * sin_a + y * cos_a, z
end

function vec3_rotated_z_table(a, angle)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return a.x * cos_a - a.y * sin_a, a.x * sin_a + a.y * cos_a, a.z
end

function vec3_manhattan_distance(x1, y1, z1, x2, y2, z2)
    return math.abs(x1 - x2) + math.abs(y1 - y2) + math.abs(z1 - z2)
end

function vec3_manhattan_distance_table(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

function vec3_rounded(x, y, z)
    return math.floor(x + 0.5), math.floor(y + 0.5), math.floor(z + 0.5)
end

function vec3_rounded_table(a)
    return math.floor(a.x + 0.5), math.floor(a.y + 0.5), math.floor(a.z + 0.5)
end

function vec3_distance_squared(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return dx * dx + dy * dy + dz * dz
end

function vec3_distance_squared_table(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

