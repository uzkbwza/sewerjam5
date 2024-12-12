local Hittable = Object:extend("Hittable")

function Hittable:_init()
	self.is_hittable = true
end

function Hittable:on_hit(by)

end


return Hittable

