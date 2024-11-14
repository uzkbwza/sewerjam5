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
	return Color(self.r + other.r, self.g + other.g, self.b + other.b, self.a + other.a)
end

function Color:__sub(other)
    return Color(self.r - other.r, self.g - other.g, self.b - other.b, self.a - other.a)
end

function Color:__mul(other)
    return Color(self.r * other.r, self.g * other.g, self.b * other.b, self.a * other.a)
end

function Color:__div(other)
    return Color(self.r / other.r, self.g / other.g, self.b / other.b, self.a / other.a)
end

function Color:__eq(other)
    return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a
end

function Color:__lt(other)
    return self.r < other.r and self.g < other.g and self.b < other.b and self.a < other.a
end

function Color:__le(other)
    return self.r <= other.r and self.g <= other.g and self.b <= other.b and self.a <= other.a
end

function Color:replace(r, g, b, a)
	return Color(r or self.r, g or self.g, b or self.b, a or self.a)
end
