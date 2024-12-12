local MainScreen = CanvasLayer:extend("MainScreen")

local GameLayer = CanvasLayer:extend("GameScreen")
local AppLayer = CanvasLayer:extend("AppScreen")
local HUDLayer = CanvasLayer:extend("HUDLayer")
local PauseLayer = CanvasLayer:extend("PauseLayer")

local PlatformerWorld = World:extend("PlatformerWorld")

local O = require("obj")

function GameLayer:new()
	GameLayer.super.new(self)
	self.clear_color = Color.from_hex("bac1cf")
	self.world = self:add_world(PlatformerWorld())
end

function AppLayer:new()
	AppLayer.super.new(self)
end

function HUDLayer:new()
	HUDLayer.super.new(self)
end

function MainScreen:new()
	MainScreen.super.new(self)
	local hud_layer = self:insert_layer(HUDLayer)
	local app_layer = self:insert_layer(AppLayer)
	local game_layer = self:insert_layer(GameLayer)
end

function MainScreen:update(dt)
	MainScreen.super.update(self, dt)
    if self.input.debug_editor_toggle_pressed then
        self:transition_to("LevelEditor")
    end
    if self.input.menu_pressed then
        self:push_to_parent(PauseLayer)
    end
end

function PlatformerWorld:new()
    PlatformerWorld.super.new(self)
    
	self:add_signal("changed_room")
	
	self:create_draw_grid()
    self:create_camera()
	self:create_bump_world()
    self.map = GameMap.load("test")
	self:process_map_data(self.map)
	self.map:build()
	self.map:bump_init(self.bump_world)
	-- self.map:erase_tiles()
    self.draw_sort = self.z_sort
	
    self.room_size = conf.room_size

	self.object_map = {
		enemy = O.Enemy.Enemy,
        skullbird = O.Enemy.SkullBird,
		cart = O.Misc.Cart,
    }
	
    for x, y, z, object in self.map:query_objects_world_space() do
		if object == "player" then
            self.room_following_object = self:add_object(O.Player.DeliveryGuy(x, y + 2))
		end
		if self.object_map[object] then
			self:add_object(self.object_map[object](x, y))
		end
	end

	-- TODO: implement this
	self.monster_locations = {}
	self.hungry_monsters = {}

	self:update_room()
end

function PlatformerWorld:process_map_data(map)
	-- print("map data:")
	-- table.pretty_print(map.data)
end

function PlatformerWorld:enter()
	if not self.room_following_object then return end
	PlatformerWorld.super.enter(self)
	self.room_id = world_to_room_id(self.room_following_object.pos.x, self.room_following_object.pos.y)
end
function PlatformerWorld:update(dt)

	PlatformerWorld.super.update(self, dt)
	self:update_camera(dt)
	self:update_room()
end

function PlatformerWorld:update_room(dt)
    if not self.room_following_object then return end
    local posx, posy = self.room_following_object.pos.x, self.room_following_object.pos.y
    local room_id = world_to_room_id(posx, posy)
    if room_id ~= self.room_id then
        self:transition_to_room(room_id)
    end
end

function PlatformerWorld:destroy_out_of_room_object(obj)
	if world_to_room_id(obj.pos.x, obj.pos.y) ~= self.room_id then
		obj:queue_destroy()
	end
end

function PlatformerWorld:add_object(obj)
    local obj = PlatformerWorld.super.add_object(self, obj)
    if (not obj.world_persistent) and signal.get(obj, "moved") then
        -- signal.connect(obj, "moved", self, "moved_out_of_room", function() self:destroy_out_of_room_object(obj) end)
		-- signal.connect(self, "changed_room", obj, "destroy_out_of_room_object", function() self:destroy_out_of_room_object(obj) end)
	end
	return obj
end

function PlatformerWorld:transition_to_room(room_id)
	self:clear_active_room()
	self.room_id = room_id
    self:initialize_room(room_id)
	self:emit_signal("changed_room")
end

function PlatformerWorld:clear_active_room()
	self.room_objects = self.room_objects or {}
	for _, object in ipairs(self.room_objects) do
		object:destroy()
	end
	table.clear(self.room_objects)
end

function PlatformerWorld:add_room_object(obj)
	self:add_object(obj)
	table.insert(self.room_objects, obj)
end

function PlatformerWorld:initialize_room(room_id)
	local room_start_x, room_start_y = room_id_to_world(room_id)

end

function PlatformerWorld:update_camera(dt)
	if not self.room_following_object then return end

	local target_x, target_y =
		stepify_floor(self.room_following_object.pos.x + self.room_size.x, self.room_size.x) - self.room_size.x / 2,
		stepify_floor(self.room_following_object.pos.y + self.room_size.y, self.room_size.y) - self.room_size.y / 2
	-- self.camera.pos.x, self.camera.pos.y = splerp_vec_unpacked(self.camera.pos.x, self.camera.pos.y, target_x, target_y, dt, seconds_to_frames(4))
    -- self.camera.pos.x, self.camera.pos.y = target_x, target_y
	self.camera.pos.x, self.camera.pos.y = self.room_following_object.pos.x, self.room_following_object.pos.y
end

function PlatformerWorld:draw()
	graphics.set_color(palette.white)
	local x1, y1, w, h, x2, y2 = self:get_draw_rect()
    self.map:draw_world_space("dynamic", x1, y1, x2, y2, nil, 0)
	-- self.map:draw("static", nil, nil, nil, nil, nil, 0)
    PlatformerWorld.super.draw(self)
	graphics.set_color(palette.white)

    self.map:draw_world_space("dynamic", x1, y1, x2, y2, 1, nil)
	-- self.map:draw("static", nil, nil, nil, nil, 1, nil)
	
	-- graphics.draw_centered(spritesheet[2], self.room_following_object.pos.x, self.room_following_object.pos.y)
end

return MainScreen
