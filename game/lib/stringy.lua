local stringy = setmetatable({}, {__index = string})

function stringy.endswith(s, e)
	local result = string.match(s, e.."$")
  return result ~= nil
end

function stringy.strip_whitespace(s, left, right)
	if left == nil then
		left = true
	end
	if right == nil then
		right = true
	end
	local result = s
	if left then
		result = string.match(result, "^%s*(.-)$")
	end
	if right then
		result = string.match(result, "^(.-)%s*$")
	end

	if result == nil then return s end
	-- local result = string.gsub(s, "^%s*(.-)%s*$", "%1")
	return result
end
-- Function to escape Lua pattern magic characters
local function pattern_escape(char)
    return char:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

function stringy.strip_char(s, char, left, right)
    if left == nil then left = true end
    if right == nil then right = true end
    local result = s
    local p_char = pattern_escape(char)
    if left then
        result = string.match(result, "^" .. p_char .. "*(.-)$")
    end
    if right then
        result = string.match(result, "^(.-)" .. p_char .. "*$")
    end
    if result == nil then return s end
    return result
end

function stringy.split(string, substr)
	if substr == nil then
		substr = "%s"
	end
	local t = {}
	for str in string.gmatch(string, "([^"..substr.."]+)") do
		table.insert(t, str)
	end
	return t
end

function stringy.join(t, separator)
	local stringy = ""
	local len = #t
	for i, v in ipairs(t) do
		stringy = stringy..v
		if i < len then
			stringy = stringy..separator
		end
	end
end

return stringy
