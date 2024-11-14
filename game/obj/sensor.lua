local Sensor = Object:extend()

function Sensor:new(rect, monitoring, monitorable, filter, entered_function, update_function, exit_function, owner)
	self.rect = rect:clone()
	self.pos = Vec2(rect.x + rect.width / 2, rect.y + rect.height / 2)
	self.bump_rect = Rect.centered(0, 0, rect.width, rect.height)
	self.owner = owner
	self.monitoring = monitoring
	if filter then 
		self.filter = function(other)
			return Sensor.base_filter(other) and filter(other)
		end
	else
		self.filter = Sensor.base_filter
	end
	self.monitorable = monitorable
	self.monitored_objects = {}

	self.bump_world = owner.bump_world
	self.is_sensor = true
	self.entered_function = entered_function or self.dummy
	self.update_function = update_function or self.dummy
	self.exit_function = exit_function or self.dummy
end

function Sensor.base_filter(other)
	return ((other.is_monitorable or Object.is(other, GameObject)))
end

function Sensor:add_bump_world(bump_world)
    if bump_world ~= self.bump_world then
        self.monitored_objects = {}
    end
	
    if self.bump_world and self.bump_world:hasItem(self) then
		self.bump_world:remove(self)
	end
	
	self.bump_world = bump_world

	if bump_world and self.monitorable then
		self.bump_world:add(self, self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height)
		self:move_to(self.pos.x, self.pos.y)
	end

end

function Sensor:set_monitorable(monitorable)
	self.monitorable = monitorable
	if monitorable then
		self:add_bump_world(self.owner.bump_world)
	else
		if self.bump_world then
			self.bump_world:remove(self)
		end
	end
end

function Sensor:update(dt)
	if self.monitoring then
		self:monitor()
	end
end

function Sensor.dummy()
end

function Sensor:monitor()
    local items, len = self.bump_world:queryRect(self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height, self.filter)
    local monitored = self.monitored_objects or {}
    self.monitored_objects = monitored


    for item, _ in pairs(monitored) do
        monitored[item] = false
    end


    for i = 1, len do
        local item = items[i]
        if monitored[item] == false then
        
            monitored[item] = true
            self.update_function(self.owner, item)
        elseif monitored[item] == nil then
        
            monitored[item] = true
            self.entered_function(self.owner, item)
            self.update_function(self.owner, item)
        end
    
    end


    for item, is_monitored in pairs(monitored) do
        if is_monitored == false then
        
            monitored[item] = nil
            self.exit_function(self.owner, item)
        end
    end
end

function Sensor:move_to_local(x, y)
	self.pos.x = x
	self.pos.y = y
	self.rect = self.rect:center_to(x, y, self.rect.width, self.rect.height)

	self:move_to(self.owner.pos.x, self.owner.pos.y)
end

function Sensor:move_to(x, y)
	self.bump_rect = self.bump_rect:center_to(x + self.pos.x, y + self.pos.y, self.rect.width, self.rect.height)

	if self.monitorable and self.bump_world then
		self.bump_world:update(self, self.bump_rect.x, self.bump_rect.y, self.bump_rect.width, self.bump_rect.height)
	end
end

return Sensor
