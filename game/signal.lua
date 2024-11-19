local signal = {
    emitters = {},
    listeners = {},
}

function signal.register(emitter, name)
	signal.emitters[emitter] = signal.emitters[emitter] or {}
    assert(signal.emitters[emitter][name] == nil, "signal already registered")
    signal.emitters[emitter][name] = {
		listeners = {}
	}
end

function signal.get(emitter, name)
	if signal.emitters[emitter] == nil then return nil end
	return signal.emitters[emitter][name]
end

function signal.deregister(emitter, name)
	local sig = signal.get(emitter, name)

    if sig == nil then return end
	
    for listener, connection in pairs(sig) do
        for function_name, _ in pairs(connection) do
			signal.disconnect(emitter, name, listener, function_name)
		end
	end

    signal.emitters[emitter][name] = nil
	if table.is_empty(signal.emitters[emitter]) then signal.emitters[emitter] = nil end
end

function signal.deregister_object(t)
	signal._remove_listener(t)
	signal._remove_emitter(t)
end

function signal._remove_listener(listener)
    local lis = signal.listeners[listener]
    if lis ~= nil then
        for emitter, signals in pairs(lis) do
            for signal_name, functions in pairs(signals) do
                for function_name, _ in pairs(functions) do
                    signal.disconnect(emitter, signal_name, listener, function_name)
                end
            end
        end
    end
end

function signal._remove_emitter(emitter)
	local signals = signal.emitters[emitter]

    if signals ~= nil then
        for signal_name, t in pairs(signals) do
            for listener, connection in pairs(t.listeners) do
                for function_name, _ in pairs(connection) do
                    signal.disconnect(emitter, signal_name, listener, function_name)
                end
            end
        end
    end
	signal.emitters[emitter] = nil
end

function signal.connect(emitter, signal_name, listener, function_name, func, oneshot)
    assert(type(emitter) == "table", "emitter is not a table")
    assert(type(listener) == "table", "listener is not a table")
    assert(type(signal_name) == "string", "signal_name is not a string")
    assert(type(function_name) == "string", "function_name is not a string")

    assert(emitter ~= nil, "emitter is nil")
	assert(listener ~= nil, "listener is nil")

    if oneshot == nil then oneshot = false end
	
    local sig = signal.get(emitter, signal_name)
    
	if sig == nil then
		error("signal " .. signal_name .. "does not exist for object " .. tostring(emitter))
	end
	
    sig.listeners[listener] = sig.listeners[listener] or {}

	func = func or function(...) listener[function_name](listener, ...) end

    sig.listeners[listener][function_name] = {
        func = func,
		oneshot = oneshot,
	}

    local lis = table.populate_recursive(signal.listeners, listener, emitter, signal_name)

	assert(lis[function_name] == nil, "connection already exists!")
    
    lis[function_name] = {
        func = func,
		oneshot = oneshot,
	}

end

function signal.disconnect(emitter, signal_name, listener, function_name)
    assert(type(emitter) == "table", "emitter is not a table")
    assert(type(listener) == "table", "listener is not a table")
    assert(type(signal_name) == "string", "signal_name is not a string")
	assert(type(function_name) == "string", "function_name is not a string")
    local sig = signal.get(emitter, signal_name)
	assert(sig ~= nil, "signal " .. signal_name .. "does not exist for object " .. tostring(emitter))

	if sig.listeners[listener] ~= nil then  
		sig.listeners[listener][function_name] = nil

		if table.is_empty(sig.listeners[listener]) then
			sig.listeners[listener] = nil
		end
	end

	local lis = signal.listeners[listener]

    -- nil tables to avoid memory leaks
    if lis[emitter] ~= nil then
        if lis[emitter][signal_name] ~= nil then
			lis[emitter][signal_name][function_name] = nil
			if table.is_empty(lis[emitter][signal_name]) then
				lis[emitter][signal_name] = nil
			end
		end
		if table.is_empty(lis[emitter]) then
			signal.listeners[listener][emitter] = nil
		end
	end

	if table.is_empty(lis) then
		signal.listeners[listener] = nil
	end
end

function signal.emit(emitter, signal_name, ...)
    local sig = signal.get(emitter, signal_name)
	assert(sig ~= nil, "no signal " .. signal_name .. " for emitter " .. tostring(emitter))
    for listener, connection in pairs(sig.listeners) do
        for func_name, t in pairs(connection) do
            local func = t.func
            func(...)
            if t.oneshot then
				signal.disconnect(emitter, signal_name, listener, func_name)
			end
		end
	end
end

return signal
