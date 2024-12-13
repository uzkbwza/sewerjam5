local audio = {
    sfx = nil,
    music = nil,
    sfx_volume = 1.0,
    music_volume = 1.0,
    default_rolloff = 0.0001,
	default_z_pos = 300
}

audio = setmetatable(audio, { __index = love.audio })

-- TODO: audio bus? sound pool? volume control, etc

function audio.load()
    local sfx = {}
	local music = {}
    audio.sfx = sfx
	audio.music = music
	
    local wav_paths = filesystem.get_files_of_type("assets/audio", "wav", true)
    local mp3_paths = filesystem.get_files_of_type("assets/audio", "mp3", true)
	
	
    for _, v in ipairs(wav_paths) do
        local sound = audio.newSource(v, "static")
		-- print(sound:setRolloff(audio.default_rolloff))
        local name = filesystem.filename_to_asset_name(v, "wav", "audio_")
        sfx[name] = sound
    end
	
    for _, v in ipairs(mp3_paths) do
        local sound = audio.newSource(v, "stream")
        local name = filesystem.filename_to_asset_name(v, "mp3", "audio_")
        music[name] = sound
    end
end

function audio.set_position(x, y, z)
	-- love.audio.setPosition(x, y, z or audio.default_z_pos)
end

function audio.play_sfx(src, volume, pitch, loop)
	loop = loop or false
    src:setVolume(volume and (volume * audio.sfx_volume) or audio.sfx_volume)
    src:setPitch(pitch or 1.0)
	src:setLooping(loop or false)
	src:play()
end

function audio.get_sfx(name)
	return audio.sfx[name]:clone()
end

function audio.play_music(src)
	audio.stop_music(src)
    src:setVolume(audio.music_volume)
    src:setLooping(true)
    src:play()
end

function audio.stop_music(src)
    src:stop()
end

return audio
