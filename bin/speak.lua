local args = { ... }

if #args < 1 then
    print("Usage: speak [file.dfpwm]")
    print("Or pipe data: cat song.dfpwm > /dev/speaker0")
    return
end

local path = args[1]
if not fs.exists(path) then
    print("File not found: " .. path)
    return
end

-- Fallback speak command logic routing
-- A wrapper specifically looking to write the raw encoded file iteratively to a speaker
local device = require("sx.device")

-- Find the first available speaker
local def_id
for _, dev in ipairs(device.get_all()) do
    if dev.type == "speaker" then
        def_id = dev.id
        break
    end
end

if not def_id then
    printError("No speakers available")
    return
end

local speaker_vfs_path = nil
-- Does the user have this mounted somewhere?
local dev = device.get(def_id)
if dev and dev.mounted then
    speaker_vfs_path = dev.mountpoint
end

if speaker_vfs_path then
    -- We can just execute a synthetic shell command bridging it through VFS natively
    print("Pumping " .. path .. " through VFS to " .. speaker_vfs_path)
    local inp = fs.open(path, "rb")
    local out = require("sx").fs.open(speaker_vfs_path, "w")
    if inp and out then
        while true do
            local chunk = inp.read(16 * 1024)
            if not chunk or chunk == "" then break end
            out.write(chunk)
        end
        inp.close()
        out.close()
        print("Done playing.")
    else
        printError("IO Error")
    end
else
    -- Fallback via direct driver API
    local mon = device.open(def_id)
    print("Playing via pure API to " .. def_id)
    if mon and mon.write then
        local inp = fs.open(path, "rb")
        while true do
            local chunk = inp.read(16 * 1024)
            if not chunk or chunk == "" then break end
            mon.write(chunk)
        end
        inp.close()
        print("Done playing.")
    end
end
