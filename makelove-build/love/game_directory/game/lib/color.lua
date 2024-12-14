Color = Object:extend("Color")

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

function Color.from_hex(str)
    return Color(
        tonumber("0x" .. string.sub(str, 1, 2)) / 255,
        tonumber("0x" .. string.sub(str, 3, 4)) / 255,
        tonumber("0x" .. string.sub(str, 5, 6)) / 255,
        1)
end

function Color.from_hex_unpack(str)
    return tonumber("0x" .. string.sub(str, 1, 2)) / 255,
           tonumber("0x" .. string.sub(str, 3, 4)) / 255,
           tonumber("0x" .. string.sub(str, 5, 6)) / 255,
           1
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


-- arne's famicube palette
palette = {
	[1] =   "000000",
	[2] =   "00177D",
	[3] =   "024ACA",
	[4] =   "0084FF",
	[5] =   "5BA8FF",
	[6] =   "98DCFF",
	[7] =   "9BA0EF",
	[8] =   "6264DC",
	[9] =   "3D34A5",
	[10] =  "211640",
	[11] =  "5A1991",
	[12] =  "6A31CA",
	[13] =  "A675FE",
	[14] =  "E2C9FF",
	[15] =  "FEC9ED",
	[16] =  "D59CFC",
	[17] =  "CC69E4",
	[18] =  "A328B3",
	[19] =  "871646",
	[20] =  "CF3C71",
	[21] =  "FF82CE",
	[22] =  "FFE9C5",
	[23] =  "F5B784",
	[24] =  "E18289",
	[25] =  "DA655E",
	[26] =  "823C3D",
	[27] =  "4F1507",
	[28] =  "E03C28",
	[29] =  "E2D7B5",
	[30] =  "C59782",
	[31] =  "AE6C37",
	[32] =  "5C3C0D",
	[33] =  "231712",
	[34] =  "AD4E1A",
	[35] =  "F68F37",
	[36] =  "FFE737",
	[37] =  "FFBB31",
	[38] =  "CC8F15",
	[39] =  "939717",
	[40] =  "B6C121",
	[41] =  "EEFFA9",
	[42] =  "BEEB71",
	[43] =  "8CD612",
	[44] =  "6AB417",
	[45] =  "376D03",
	[46] =  "172808",
	[47] =  "004E00",
	[48] =  "139D08",
	[49] =  "58D332",
	[50] =  "20B562",
	[51] =  "00604B",
	[52] =  "005280",
	[53] =  "0A98AC",
	[54] =  "25E2CD",
	[55] =  "BDFFCA",
	[56] =  "71A6A1",
	[57] =  "415D66",
	[58] =  "0D2030",
	[59] =  "151515",
	[60] =  "343434",
	[61] =  "7B7B7B",
	[62] =  "A8A8A8",
	[63] =  "D7D7D7",
	[64] =  "FFFFFF",
}

for i, v in ipairs(palette) do
    palette[i] = Color.from_hex(v)
    palette["c" .. tostring(i)] = palette[i]
end

palette.black = palette[1]
palette.darkergrey = palette[58]
palette.darkgrey = palette[59]
palette.grey = palette[60]
palette.lightgrey = palette[61]
palette.lightergrey = palette[62]
palette.white = palette[64]
palette.red = palette[28]
palette.blue = palette[3]
palette.green = palette[48]
palette.yellow = palette[36]
palette.orange = palette[35]
palette.purple = palette[12]
palette.pink = palette[21]
palette.brown = palette[32]
palette.darkblue = palette[2]
palette.darkgreen = palette[47]
palette.darkred = palette[25]
palette.darkpurple = palette[10]
palette.lilac = palette[14]
palette.navyblue = palette[2]


