local rng = {}

local random = love.math.random

love.math.setRandomSeed(os.time())

function rng.randi(...)
	return random(...)
end

function rng.randf(min, max)
	return min + random() * (max - min)
end

function rng.percent(chance)
	return (rng() * 100) < chance
end

function rng.randf_range(min, max)
	return rng.randf(min, max)
end

function rng.randi_range(min, max)
	return random(min, max)
end

function rng.sign()
	return rng() < 0.5 and -1 or 1
end

function rng.random_seed(seed)
	love.math.setRandomSeed(seed)
end

function rng.randfn(mean, std_dev)
	return love.math.randomNormal(std_dev, mean)
end

function rng.coin_flip()
	return rng() < 0.5
end

function rng.random_angle()
	-- for i =1, 10 do print(random(0, tau)) end
	return rng.randf(0, tau)
end

function rng.random_vec2()
	return angle_to_vec2_unpacked(rng.random_angle())
end

local function _meta_call_random(table, min, max)
	return random(min, max)
end

local mt = {
	__call = _meta_call_random
}

setmetatable(rng, mt)


return rng
