local State = Object:extend()

function State.dummy()
end

function State._create(...)
	return State(...)
end

function State:new(table)
	for _, unimplemented in ipairs({
		"enter",
		"exit",
		"update",
		"step",
		"draw"
	}) do
		self[unimplemented] = State.dummy
	end

	local go = function(to, ...) self:transition(to, ...) end

	for k, v in pairs(table) do
		if type(v) == "function" then
			self[k] = function(...) v(go, ...) end
		else
			self[k] = v
		end
	end

	self.transition_started = Signal()
end

function State:transition(to, ...)
	self.transition_started:emit(to, ...)
end

return State
