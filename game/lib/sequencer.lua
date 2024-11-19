
Sequencer = Object:extend()

-- Example usage: 
--[[
s:start(function()
		-- wait for one second
		s:wait(60)
		-- print hello
		print("hello")
		-- tween my position to the left over a second
		s:tween_property(self.pos, "x", self.pos.x, -30, 60.0, "inOutQuad")
		-- wait until i move back to the right
		s:wait_for(function() return self.pos.x >= 0 end)
		-- print hello again
		print("hello again")
		-- wait for the self.died signal to fire, presumably when i die
		s:wait_for(self.died)
		-- print goodbye
		print("goodbye")
end)
]]

function Sequencer:new()
	self.running = {}
	self.suspended = {}
	self.dt = 0
	self.elapsed = 0
end

function Sequencer:start(func)
	local co = coroutine.create(func)
	self:init_coroutine(co)
end

-- function Sequencer:chain_funcs(funcs)
-- 	for _, func in ipairs(funcs) do
-- 		self:call(func)
-- 	end
-- end

-- function Sequencer:chain(...)
-- 	local funcs = {...}
-- 	local func = (function()
-- 		self:chain_funcs(funcs)
-- 	end)
-- 	return func
-- end

function Sequencer:do_while(condition, f)

	local func = (function()
		while condition() do
			self:call(f)
		end
	end)

	self:start(func)
end

function Sequencer:start_chain(...)
	self:start(self:chain(...))
end

function Sequencer:loop(func, times)
	assert(times == nil or type(times) == "number", "times must be a number")
	if times == nil then
		while true do
			self:call(func)
		end
	end
	for i = 1, times do
		self:call(func)
	end
end

function Sequencer:init_coroutine(co)
	table.insert(self.running, co)
end

function Sequencer:update(dt)
	if table.is_empty(self.running) then
		return
	end

	self.dt = dt

	for _, value in ipairs(self.running) do
		self.current_chain = value
		if self.suspended[value] == nil then
			coroutine.resume(value)
		end
	end

	table.fast_remove(self.running, function(t, i, j)
		local co = t[i]
		return self.suspended[co] ~= nil or coroutine.status(co) ~= "dead"
	end)

	self.elapsed = self.elapsed + dt

end

function Sequencer:wait(duration)
	local start = self.elapsed
	local finish = self.elapsed + duration
	while self.elapsed < finish do
		coroutine.yield()
	end
end

function Sequencer:tween(func, value_start, value_end, duration, easing, step)
	local start = self.elapsed
	local finish = self.elapsed + duration
	local ease_func = ease(easing)

	if step == nil then
		step = 0
	end

	while self.elapsed < finish do
		local t = clamp(ease_func(stepify_safe((self.elapsed - start) / duration, step)), 0, 1)
		func(value_start + t * (value_end - value_start))
		coroutine.yield()
	end
end

function Sequencer:tween_property(obj, property, value_start, value_end, duration, easing, step)

	return self:tween(function(value) obj[property] = value end, value_start, value_end, duration, easing, step)
end

function Sequencer:suspend(chain)
	self.suspended[chain] = true
	self.running[chain] = nil
end

function Sequencer:resume(chain)
	self.suspended[chain] = nil
	self.running[chain] = true
	self:init_coroutine(chain)
end

function Sequencer:wait_for(func)
	-- if Object.is(func, Signal) then
		-- self:suspend(self.current_chain)
		-- if Object.is(func, GameObjectSignal) then 
		-- 	func:connect(nil, function() self:resume(self.current_chain) end, true)
		-- else
		-- func:connect(function() self:resume(self.current_chain) end, true)
		-- end
		-- return
	-- end
	while not func() do
		coroutine.yield()
	end
end

function Sequencer:call(func)
	local co = coroutine.create(func)
	while coroutine.status(co) ~= "dead" do
		local status, val = coroutine.resume(co)
		if not status then
			error(val)
		end
		if val then 
			self:call(val)
		end
		coroutine.yield()
	end
end

function Sequencer:destroy()
	self.running = nil
	self.suspended = nil
	self.dt = 0
	self.elapsed = 0
end
