local args = { ... }
if #args < 1 then
    print("Usage: umount <path_or_side_or_id>")
    return
end

local target = args[1]
local device = require("sx.device")

-- First try to unmount a virtual path or ID
if device then
    -- Try by path first
    local ok, err = device.unmount(target)
    if ok then
        print("Unmounted " .. target)
        return
    end

    -- Try by ID
    local dev = device.get(target)
    if dev and dev.mounted then
        device.unmount(dev.mountpoint)
        print("Unmounted device " .. target)
        return
    end
end

-- Fallback to disk ejection logic
if disk.isPresent(target) then
    disk.eject(target)
    print("Ejected disk from " .. target)
else
    local targetNode = string.gsub(target, "^/+", "")
    local devs = { peripheral.find("drive") }
    local found = false
    for _, d in ipairs(devs) do
        if d.isDiskPresent() and d.getMountPath() == targetNode then
            d.eject()
            print("Ejected disk via path " .. target)
            found = true
            break
        end
    end
    if not found then
        printError("umount: No such disk, drive, or mounted path")
    end
end
