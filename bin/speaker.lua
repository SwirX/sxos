local args = { ... }
local device = require("sx.device")

local function parse_args(raw_args)
    local opts = { flags = {}, pos = {} }
    local i = 1
    while i <= #raw_args do
        local a = raw_args[i]
        if string.sub(a, 1, 2) == "--" then
            local key = string.sub(a, 3)
            opts.flags[key] = raw_args[i + 1]
            i = i + 2
        else
            table.insert(opts.pos, a)
            i = i + 1
        end
    end
    return opts
end

local parsed = parse_args(args)
local cmd = parsed.pos[1]

if not cmd then
    print("Usage: speaker [options] <command> <args>")
    print("Commands:")
    print("  play <sound> [volume] [pitch]")
    print("  note <instrument> [volume] [pitch]")
    print("Options:")
    print("  --device <id>    Target specific speaker (e.g. speaker_0)")
    print("  --group <name>   Target speaker group (e.g. livingroom)")
    return
end

local target_speakers = {}

if parsed.flags.device then
    local dev = device.open(parsed.flags.device)
    if dev then
        table.insert(target_speakers, dev)
    else
        printError("Speaker " .. parsed.flags.device .. " not found")
        return
    end
elseif parsed.flags.group then
    -- For now, broadcast to all speakers in hypothetical groups
    -- Since group metadata isn't fully implemented in base registry yet, we fall back to all.
    print("Broadcasting to group " .. parsed.flags.group)
    for _, dev in ipairs(device.get_all()) do
        if dev.type == "speaker" then
            table.insert(target_speakers, device.open(dev.id))
        end
    end
else
    -- Fallback to first speaker
    for _, dev in ipairs(device.get_all()) do
        if dev.type == "speaker" then
            table.insert(target_speakers, device.open(dev.id))
            break
        end
    end
end

if #target_speakers == 0 then
    printError("No speaker device available.")
    return
end

for _, speaker in ipairs(target_speakers) do
    if cmd == "play" then
        local sound = parsed.pos[2]
        local volume = tonumber(parsed.pos[3]) or 1.0
        local pitch = tonumber(parsed.pos[4]) or 1.0
        if sound then
            speaker.playSound(sound, volume, pitch)
            print("Playing " .. sound .. " on " .. tostring(speaker._device_id))
        end
    elseif cmd == "note" then
        local instrument = parsed.pos[2]
        local volume = tonumber(parsed.pos[3]) or 1.0
        local pitch = tonumber(parsed.pos[4]) or 1.0
        if instrument then
            speaker.playNote(instrument, volume, pitch)
            print("Playing note " .. instrument .. " on " .. tostring(speaker._device_id))
        end
    else
        printError("Unknown command: " .. cmd)
    end
end
