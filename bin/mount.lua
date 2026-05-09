local args = { ... }
if #args == 0 then
    -- list active disk mounts
    print("Active mounts:")
    local found = false
    local drives = { peripheral.find("drive") }
    for _, drive in ipairs(drives) do
        if drive.isDiskPresent() and drive.hasData() then
            local mountPath = drive.getMountPath()
            print("  " .. peripheral.getName(drive) .. " -> /" .. mountPath)
            found = true
        end
    end
    if not found then print("  None") end
    return
end

local name = args[1]
if disk.isPresent(name) and disk.hasData(name) then
    print("Disk is mounted at: /" .. disk.getMountPath(name))
else
    printError("No data disk found on: " .. name)
end
