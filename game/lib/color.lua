Color = Object:extend()

function Color:new(r, g, b, a)
    self.r = r or 1
    self.g = g or 1
    self.b = b or 1
    self.a = a or 1
end

function Color:clone()
	return Color(self.r, self.g, self.b, self.a)
end

function Color:unpack()
    return self.r, self.g, self.b, self.a
end

function Color:__tostring()
    return "Color: [" .. tostring(self.r) .. ", " ..
    tostring(self.g) .. ", " .. tostring(self.b) .. ", " .. tostring(self.a) .. "]"
end

function Color:__add(other)
	if type(other) == "number" then
		return Color(self.r + other, self.g + other, self.b + other, self.a + other)
	end
	return Color(self.r + other.r, self.g + other.g, self.b + other.b, self.a + other.a)
end

function Color:__sub(other)
	if type(other) == "number" then
		return Color(self.r - other, self.g - other, self.b - other, self.a - other)
	end
    return Color(self.r - other.r, self.g - other.g, self.b - other.b, self.a - other.a)
end

function Color:__mul(other)
	if type(other) == "number" then
		return Color(self.r * other, self.g * other, self.b * other, self.a * other)
	end
    return Color(self.r * other.r, self.g * other.g, self.b * other.b, self.a * other.a)
end

function Color:__div(other)
	if type(other) == "number" then
		return Color(self.r / other, self.g / other, self.b / other, self.a / other)
	end
    return Color(self.r / other.r, self.g / other.g, self.b / other.b, self.a / other.a)
end

function Color:__eq(other)
	if type(other) == "number" then
		return self.r == other and self.g == other and self.b == other and self.a == other
	end
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

function Color:__lt(other)
	if type(other) == "number" then
		return self.r < other and self.g < other and self.b < other and self.a < other
	end
    return self.r < other.r and self.g < other.g and self.b < other.b and self.a < other.a
end

function Color:__le(other)
	if type(other) == "number" then
		return self.r <= other and self.g <= other and self.b <= other and self.a <= other
	end
    return self.r <= other.r and self.g <= other.g and self.b <= other.b and self.a <= other.a
end

function Color:replace(r, g, b, a)
	return Color(r or self.r, g or self.g, b or self.b, a or self.a)
end
