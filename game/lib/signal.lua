Signal = Object:extend()

local connected_listeners = {}

function Signal:new()
	self.connected_listeners = {}
end

function Signal:connect(listener, oneshot)
	self.connected_listeners[listener] = oneshot and 1 or true
end

function Signal:disconnect(listener)
	self.connected_listeners[listener] = nil
end

function Signal:emit(...)
	for k, v in pairs(self.connected_listeners) do
		k(...)
		if v == 1 then
			self:disconnect(k)
		end
	end
end

function Signal:clear()
	self.connected_listeners = {}
end
