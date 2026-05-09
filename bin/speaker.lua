local args = { ... }
if #args < 2 then
    print("Usage:")
    print("  speaker play <sound_name> [volume] [pitch]")
    print("  speaker note <instrument> <volume> <pitch>")
    return
end

local cmd = args[1]
-- Find an attached speaker
local speaker = peripheral.find("speaker")
if not speaker then
    printError("No speaker peripheral found attached to the computer.")
    return
end

if cmd == "play" then
    local sound = args[2]
    local volume = tonumber(args[3]) or 1.0
    local pitch = tonumber(args[4]) or 1.0
    speaker.playSound(sound, volume, pitch)
    print("Playing " .. sound .. " at volume " .. volume .. ", pitch " .. pitch)
elseif cmd == "note" then
    local instrument = args[2]
    local volume = tonumber(args[3]) or 1.0
    local pitch = tonumber(args[4]) or 1.0
    speaker.playNote(instrument, volume, pitch)
    print("Playing note " .. instrument .. " at pitch " .. pitch)
else
    printError("Unknown command: " .. cmd)
end
