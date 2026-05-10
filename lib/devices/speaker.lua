-- /lib/devices/speaker.lua
local driver = {}

function driver.get_capabilities(native)
    return { audio = true, stream = true }
end

function driver.open(device_entry)
    local instance = {
        _device_id = device_entry.id,
        _device_type = device_entry.type
    }

    if device_entry.native then
        for k, v in pairs(device_entry.native) do
            if type(v) == "function" then
                instance[k] = function(...) return v(...) end
            end
        end
    end

    -- VFS Write override for piping (e.g. `cat song.dfpwm > /dev/speaker0`)
    -- The driver accepts raw PCM/DFPWM data and flushes it cleanly via CC audio pipeline
    local dfpwm = require("cc.audio.dfpwm")
    local decoder = dfpwm.make_decoder()

    function instance.write(chunk)
        if type(chunk) == "string" and device_entry.native then
            local decoded = decoder(chunk)
            -- Play the decoded chunk
            while not device_entry.native.playAudio(decoded) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end

    function instance.close()
        -- clean up
    end

    return instance
end

return driver
