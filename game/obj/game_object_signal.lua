local GameObjectSignal = Signal:extend()

function GameObjectSignal:new(object)
	self.object = object
	self.connected_listeners = {}
	self.connected_objects = {}
	self.connection_names = {}
end

function GameObjectSignal:connect_named(listener_object, listener_function, listener_function_name, oneshot)
    self:connect(listener_object, listener_function, oneshot)
	self.connection_names[listener_function_name] = listener_function
end


function GameObjectSignal:connect(listener_object, listener_function, oneshot)
	if listener_object ~= nil and not (Object.is(listener_object, GameObject)) then
		error("listener_object must be a GameObject or nil")
		-- listener_object = nil
	end


	self.connected_listeners[listener_function] = {
		oneshot = oneshot,
		object = listener_object
	}

	if listener_object then
		self.connected_objects[listener_object] = self.connected_listeners[listener_object] or {}
		table.insert(self.connected_objects[listener_object], listener_function)
	end
end

function GameObjectSignal:disconnect(listener)
	if Object.is(listener, GameObject) then
		local functions = self.connected_objects[listener]
		if functions then
			for i, v in ipairs(functions) do
				self.connected_listeners[v] = nil
			end
			self.connected_objects[listener] = nil
		end
		return
	end

	if self.connection_names[listener] then
		self.connected_listeners[self.connection_names[listener]] = nil
        self.connection_names[listener] = nil
		return
	end

	if self.connected_listeners[listener] == nil then
		return
	end

	local object = self.connected_listeners[listener].object
	if object then
		local functions = self.connected_objects[object]
		for i, v in ipairs(functions) do
			if v == listener then
				table.remove(functions, i)
			end
		end
		if table.is_empty(functions) then
			self.connected_objects[object] = nil
		end
	end
	self.connected_listeners[listener] = nil
end

function GameObjectSignal:emit(...)
	for k, v in pairs(self.connected_listeners) do
		local object = v.object
		if object then
			if object.screen == self.object.screen or object == self.object.screen then
				k(...)
			else
				self:disconnect(k)
			end
		else
			k(...)
		end

		if v.oneshot then
			self:disconnect(k)
		end
	end
end

function GameObjectSignal:prune(who)
	if who ~= nil then 
		if self.connected_objects[who] then
			for k, v in pairs(self.connected_objects[who]) do
				self:disconnect(v)
			end
		end
	end
	for k, v in pairs(self.connected_listeners) do
		local object = v.object
		if object and (object.screen ~= self.object.screen) then
			self:disconnect(k)
		end
	end
end

function GameObjectSignal:clear()
	self.connected_listeners = {}
end


return GameObjectSignal
