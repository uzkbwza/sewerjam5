local Object = {
	__type_name = "Object",
}
Object.__index = Object

function Object:new()
end

function Object:extend(name)
	local cls = {}
	for k, v in pairs(self) do
		if k:find("__") == 1 then
			cls[k] = v
		end
	end
	cls.__index = cls
	cls.super = self
	if name then
		cls.__tostring = function()
			return name
		end
		cls.__type_name = cls.__tostring
	end

	setmetatable(cls, self)
	return cls
end

function Object:extend_self(metatable)
	local mt = getmetatable(self)
    mt.__index = metatable
end

function Object:implement(...)
	for _, cls in pairs({ ... }) do
		for k, v in pairs(cls) do
			if type(v) == "function" and k ~= "_init" then
				if self[k] == nil then
					self[k] = v
				end
			end
		end
		if cls._init then
			cls._init(self, ...)
		end
	end
end


-- New method to override metamethods for a class
function Object:override_class_metamethod(name, func)
    assert(name:find("__") == 1, "Invalid metamethod name: " .. name)
    local mt = getmetatable(self)
    if not mt then
        mt = {}
        setmetatable(self, mt)
    end
    mt[name] = func
end

-- New method to override metamethods for an instance
function Object:override_instance_metamethod(name, func)
    assert(name:find("__") == 1, "Invalid metamethod name: " .. name)
    local mt = getmetatable(self)
    if not mt then
        mt = {}
        setmetatable(self, mt)
    end
    -- Create a new metatable that inherits from the class metatable
    if mt == self.__index then  -- If using the class's metatable
        local new_mt = {}
        for k, v in pairs(mt) do
            new_mt[k] = v
        end
        new_mt.__index = mt
        mt = new_mt
        setmetatable(self, mt)
    end
    mt[name] = func
end

function Object:get_methods(recursive, methods)

	local methods = methods or {}
    local mt = getmetatable(self)
    
    for k, v in pairs(self) do
        if type(v) == "function" then
            methods[k] = v
        end
    end
    
    -- Check if metatable exists and has an __index table
    if mt and type(mt.__index) == "table" and recursive then
        mt.__index:get_methods(methods)
    end
    
    return methods
end

function Object:is(T)
	-- if type(T) ~= "table" then return false end
	-- return self.__type_name == T.__type_name
	local mt = getmetatable(self)
	while mt do
		if mt == T then
			return true
		end
		mt = getmetatable(mt)
	end
	return false
end

function Object:__tostring()
	return "Object"
end

function Object:__call(...)
	local obj = setmetatable({}, self)
	obj:new(...)
	return obj
end

Object.__type_name = Object.__tostring

return Object
