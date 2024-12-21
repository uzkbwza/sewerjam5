---@diagnostic disable: lowercase-global
Object = require "lib.object"

table = require "lib.tabley"
string = require "lib.stringy"
debug = require "debuggy"
filesystem = require "lib.file"
ease = require "lib.ease"
usersettings = require "usersettings"

require "lib.mathy"
require "lib.vector"
require "lib.rect"
require "lib.random_crap"
require "lib.sequencer"
require "physics_layers"

require "lib.anim"

require "datastructure.bst"
require "datastructure.bst2"

local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

local conf = {
    -- game settings
    room_size = Vec2(
        256,
		192
	),

	-- display
	viewport_size = Vec2(
		256,
		192
	),
	display_scale = 5,

	-- delta
	use_fixed_delta = false,
	fixed_tickrate = 60,
    max_delta_seconds = 1/60,
	max_fps = 500,
    max_fixed_ticks_per_frame = 1,

	-- input
	input_actions = {
		primary = {
			keyboard = { "z", "return" },
			joystick = { "a" }
		},

		secondary = {
			keyboard = { "x", "rshift" },
			joystick = { "b" }
		},

		menu = {
			keyboard = { "escape", },
			joystick = { "start" }
		},

		move_up = {
			keyboard = {"w"},
			joystick = {"dpup"},
			joystick_axis = {
				axis = "lefty",
				dir = -1
			}
		},

		move_down = {
			keyboard = {"s"},
			joystick = {"dpdown"},
			joystick_axis = {
				axis = "lefty",
				dir = 1
			}
		},

		move_left = {
			keyboard = {"a"},
			joystick = {"dpleft"},
			joystick_axis = {
				axis = "leftx",
				dir = -1
			}
		},

		move_right = {
			keyboard = {"d"},
			joystick = {"dpright"},
			joystick_axis = {
				axis = "leftx",
				dir = 1
			}
		},

		aim_up = {
            keyboard = { "up" },
			joystick = { "y" },
			joystick_axis = {
				axis = "righty",
				dir = -1
			}
		},

		aim_down = {
			keyboard = {"down"},
			joystick = { "a" },
			joystick_axis = {
				axis = "righty",
				dir = 1
			}
		},
		
		aim_left = {
			keyboard = {"left"},
			joystick = { "x" },
			joystick_axis = {
				axis = "rightx",
				dir = -1
			}
		},

		aim_right = {
			keyboard = {"right"},
			joystick = { "b" },
			joystick_axis = {
				axis = "rightx",
				dir = 1
			}
		},

		fullscreen_toggle = {
			keyboard = {
				"f11",
				{"ralt", "return"},
				{"lalt", "return"}
			}
		},

		confirm = {
			keyboard = { "return", },
			joystick = { "start", "a" }
		},

		debug_editor_toggle = {
			debug = true,
			keyboard = { 
				{ "lctrl", "e" }, 
				{ "rctrl", "e" } 
			}
		},

		debug_draw_toggle = {
			debug = true,
			keyboard = { 
				{ "lctrl", "d" }, 
				{ "rctrl", "d" } 
			}
		},

		debug_shader_toggle = {
			debug = true,
			keyboard = { 
				{"lctrl", "s"}, 
				{"rctrl", "s"}
			}
		},

		debug_count_memory = {
			debug = true,
			keyboard = { 
				{"lctrl", "m"}, 
				{"rctrl", "m"}
			}
		},
	},

	input_vectors = {
		move = {
			left = "move_left",
			right = "move_right",
			up = "move_up",
			down = "move_down",
        },
		aim = {
			left = "aim_left",
			right = "aim_right",
			up = "aim_up",
			down = "aim_down",
		}
	},

}

-- https://love2d.org/wiki/Config_Files
function love.conf(t)
	t.identity              = "FAMULUS"
	t.appendidentity        = false
	t.version               = "11.4"
	t.console               = false
	t.accelerometerjoystick = false
	t.externalstorage       = false
    t.gammacorrect          = false
	-- t.renderers = {"vulkan"}
	
	t.audio.mic             = false
	t.audio.mixwithsystem   = true

	t.window.title          = "FAMULUS"
	t.window.icon           = nil
	t.window.width          = conf.viewport_size.x * conf.display_scale
    t.window.height         = conf.viewport_size.y * conf.display_scale
    -- t.window.width          = 1280
	-- t.window.height         = 720
	t.window.borderless     = false
	t.window.resizable      = true
	t.window.minwidth       = conf.viewport_size.x
	t.window.minheight      = conf.viewport_size.y
	t.window.fullscreen     = usersettings.fullscreen
    t.window.fullscreentype = "desktop"
	if usersettings.vsync then
        t.window.vsync = -1
    else
		t.window.vsync = 0
	end
	-- t.window.vsync
	t.window.msaa           = 0
	t.window.depth          = nil
	t.window.stencil        = nil
	t.window.displayindex    = 1
	-- t.window.highdpi        = false
	-- t.window.usedpiscale    = true
	t.window.x              = nil
	t.window.y              = nil

	t.modules.audio         = true
	t.modules.data          = true
	t.modules.event         = true
	t.modules.font          = true
	t.modules.graphics      = true
	t.modules.image         = true
	t.modules.joystick      = true
	t.modules.keyboard      = true
	t.modules.math          = true
	t.modules.mouse         = true
	t.modules.physics       = true
	t.modules.sound         = true
	t.modules.system        = true
	t.modules.thread        = true
	t.modules.timer         = true
	t.modules.touch         = true
	t.modules.video         = true
	t.modules.window        = true
end

return conf
