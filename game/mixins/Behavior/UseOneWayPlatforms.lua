local UseOneWayPlatforms = Object:extend("UseOneWayPlatforms")

function UseOneWayPlatforms:_init()
    local filter = self.bump_filter
    if not filter then
        error("UseOneWayPlatforms mixin added but member variable `bump_filter` does not exist")
    end

    local one_way_platform_filter = function(item, other)
		local o = table.get_recursive(other, "tile", "data") or other
        if o.one_way_platform then
			return "oneway"
		end
		return filter(item, other)
	end
	self.bump_filter = one_way_platform_filter
end

return UseOneWayPlatforms
