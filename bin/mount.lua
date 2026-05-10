local args = { ... }
if #args == 0 then
    print("Active mounts:")
    local found = false
    -- List virtual mounts
    local device = require("sx.device")
    if device then
        for _, dev in ipairs(device.get_all()) do
            if dev.mounted then
                print("  " .. dev.id .. " -> " .. dev.mountpoint)
                found = true
            end
        end
    end

    -- List disk mounts
    local drives = { peripheral.find("drive") }
    for _, drive in ipairs(drives) do
        if drive.isDiskPresent() and drive.hasData() then
            print("  " .. peripheral.getName(drive) .. " -> /" .. drive.getMountPath())
            found = true
        end
    end
    if not found then print("  None") end
    return
end

if #args == 2 then
    local id, path = args[1], args[2]
    local ok, err = require("sx.device").mount(id, path)
    if ok then
        print("Mounted " .. id .. " to " .. path)
    else
        printError("mount: " .. tostring(err))
    end
    return
end

local name = args[1]
if disk.isPresent(name) and disk.hasData(name) then
    print("Disk is mounted at: /" .. disk.getMountPath(name))
else
    printError("Usage: mount <id> <path>")
end
