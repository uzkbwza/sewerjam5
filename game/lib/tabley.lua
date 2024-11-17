local tabley = setmetatable({}, {__index = table})

function tabley.length (t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function tabley.push_back(t, value)
  table.insert(t, value)
end

function tabley.pop_back(t)
  return table.remove(t)
end

function tabley.push_front(t, value)
  table.insert(t, 1, value)
end

function tabley.pop_front(t)
  return table.remove(t, 1)
end

function tabley.push(t, value)
  table.insert(t, value)
end

function tabley.pop(t)
  return table.remove(t)
end

function table.list_has(t, value)
    for i, v in ipairs(t) do
		if v == value then 
			return true
		end
	end
end

function table.search_list(t, value)
    for i, v in ipairs(t) do
		if v == value then 
			return i
		end
	end
end

function tabley.is_empty(t)
	local next = next
	return next(t) == nil
end

function tabley.sorted(t, sort)
	local sorted = {}
	for _, v in ipairs(t) do
		table.insert(sorted, v)
	end
	table.sort(sorted, sort)
	return sorted
end

function tabley.deepcopy(orig, copies)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[tabley.deepcopy(orig_key, copies)] = tabley.deepcopy(orig_value, copies)
			end
			setmetatable(copy, tabley.deepcopy(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function tabley.pretty_print(t, max_depth, fd)
	max_depth = max_depth or math.huge
    fd = fd or io.stdout
    local function print(str)
       str = str or ""
       fd:write(str.."\n")
    end
    local print_r_cache={}
    local function sub_print_r(t,indent, depth)
		depth = depth or 0
		if depth >= max_depth then 
			print(indent.."..." )
			return 
		end
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
					pos = tostring(pos)
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8), depth + 1)
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function tabley.merge(t1, t2, overwrite)
	for k, v in pairs(t2) do
		if overwrite or t1[k] == nil then
			t1[k] = v
		end
	end
end

function tabley.merged(t1, t2, overwrite)
	local t = {}
	if t1 == nil then t1 = {} end
	if t2 == nil then t2 = {} end
	tabley.merge(t, t1, overwrite)
	tabley.merge(t, t2, overwrite)
	return t
end

function tabley.serialize(t, indent, start)
    if start == nil then start = true end
    indent = indent or ""
    local serialized = (start and "return " or "") .. "{\n"
    local next_indent = indent .. "\t"
    
    for key, value in pairs(t) do
        local formatted_key
        if type(key) == "string" then
            formatted_key = string.format("[%q]", key)
        else
            formatted_key = "[" .. tostring(key) .. "]"
        end
        
        if type(value) == "table" then
            local format_func = value.__table_format
            if format_func then
				local output = (format_func(value, next_indent))
				if type(output) == "string" then
					serialized = serialized .. next_indent .. formatted_key .. " = " .. (output) .. ",\n"
				elseif type(output) == "table" then
                    serialized = serialized ..
                        next_indent .. formatted_key .. " = " .. tabley.serialize(output, next_indent, false) .. ",\n"
				else 
                    serialized = serialized .. next_indent .. formatted_key .. " = " .. tostring(output) .. ",\n"
				end
			else
				serialized = serialized .. next_indent .. formatted_key .. " = " .. tabley.serialize(value, next_indent, false) .. ",\n"
			end
        elseif type(value) == "string" then
            serialized = serialized .. next_indent .. formatted_key .. " = " .. string.format("%q", value) .. ",\n"
        else
            serialized = serialized .. next_indent .. formatted_key .. " = " .. tostring(value) .. ",\n"
        end
    end

    serialized = serialized .. indent .. "}"
    return serialized
end

function tabley.deserialize(str) 
	return assert(loadstring(str))()
end


function tabley.fast_remove_at(t, index)
	local length = #t
	t[index] = t[length]
	t[length] = nil
end

function tabley.fast_remove(t, fnKeep)
	if type(fnKeep) == "number" then return tabley.fast_remove_at(t, fnKeep) end 

	if tabley.is_empty(t) then return t end

    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;

end

return tabley

