local game = {}

game.screen_stack = {}
game.queue = {}
game.sequencer = Sequencer()

game.screens = {
	Base = "game_screen",
	Pause = "pause_screen",
    LevelEdit = "level_editor",
	Game = "main_game_screen"
}

function game.load()
	graphics.screen_stack = game.screen_stack
    graphics.load()
	tilesets.load()
	game.transition_to_screen("Game")
end

function game.push_deferred(screen)
	table.push_back(game.queue, screen)
end

function game.pop_deferred(screen)
	table.push_back(game.queue, "pop")
end

function game.push_screen(screen)
	screen = game.screen_from_name(screen)
	table.push_front(game.screen_stack, screen)
	game.init_screen(screen)
end



function game.init_screen(screen)
	screen.screen_pushed:connect(game.push_deferred)
	screen.screen_popped:connect(game.pop_deferred)
	screen:enter_shared()
end

function game.replace_screen(screen, new)
	for i, v in ipairs(game.screen_stack) do 
		if v == screen then 
			v:exit_shared()
			
			local new_screen = game.screen_from_name(new)
			game.screen_stack[i] = new_screen
			game.init_screen(new_screen)
		end
	end
end


function game.pop_screen()
	local screen = table.pop_front(game.screen_stack)
	if screen then
		screen:exit_shared()
	end
	return screen
end

function game.screen_from_name(screen)
	if type(screen) == "string" then
		return require("screen." .. game.screens[screen])()
	end
	return screen
end

function game.transition_to_screen(new_screen)

	game.pop_screen()
	game.screen_stack = {}
	game.push_deferred(new_screen)
end

function game.update_input_stack(table)
	local screen_process_input = true
	for _, v in ipairs(game.screen_stack) do
		v.input = screen_process_input and table or input.dummy
		if v.blocks_input then
			screen_process_input = false
		end
	end
end

function game.update(dt)
	-- input
	game.update_input_stack(input)
	
	-- update
	while table.length(game.queue) > 0 do
		local screen = table.pop_front(game.queue)
		if screen == "pop" then
			game.pop_screen()
		else
			game.push_screen(screen)
		end
	end

	for _, v in ipairs(game.screen_stack) do
		v:update_shared(dt)	
		if v.blocks_logic then
			break
		end
	end
	game.sequencer:update(dt)
	graphics.update(dt)
end


function game.draw()
	graphics.screen_stack = game.screen_stack
	graphics.draw_loop()
end

return game
