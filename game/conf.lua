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
require "lib.sequencer"
require "lib.random_crap"
require "lib.color"


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
	-- display
	viewport_size = Vec2(
	240,
	160
        -- 384,
		-- 216

	),
	display_scale = 3,

	-- delta
	use_fixed_delta = false,
	fixed_tickrate = 60,
    max_delta_seconds = 0.05,
	max_fps = 500,
	max_fixed_ticks_per_frame = 10,

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
			keyboard = {"up"},
			joystick = {"dpup"},
			joystick_axis = {
				axis = "lefty",
				dir = -1
			}
		},

		move_down = {
			keyboard = {"down"},
			joystick = {"dpdown"},
			joystick_axis = {
				axis = "lefty",
				dir = 1
			}
		},

		move_left = {
			keyboard = {"left"},
			joystick = {"dpleft"},
			joystick_axis = {
				axis = "leftx",
				dir = -1
			}
		},

		move_right = {
			keyboard = {"right"},
			joystick = {"dpright"},
			joystick_axis = {
				axis = "leftx",
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
		}
	},
}

-- https://love2d.org/wiki/Config_Files
function love.conf(t)
	t.identity              = nil
	t.appendidentity        = false
	t.version               = "11.4"
	t.console               = false
	t.accelerometerjoystick = false
	t.externalstorage       = false
	t.gammacorrect          = false

	t.audio.mic             = false
	t.audio.mixwithsystem   = true

	t.window.title          = "Untitled"
	t.window.icon           = nil
	t.window.width          = conf.viewport_size.x * conf.display_scale
    t.window.height         = conf.viewport_size.y * conf.display_scale
    -- t.window.width          = 1280
	-- t.window.height         = 720
	t.window.borderless     = false
	t.window.resizable      = true
	t.window.minwidth       = conf.viewport_size.x
	t.window.minheight      = conf.viewport_size.y
	t.window.fullscreen     = false
	t.window.fullscreentype = "desktop"
	t.window.vsync          = 0
	t.window.msaa           = 0
	t.window.depth          = nil
	t.window.stencil        = nil
	t.window.display        = 1
	t.window.highdpi        = false
	t.window.usedpiscale    = true
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
