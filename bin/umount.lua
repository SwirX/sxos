local args = { ... }
if #args < 1 then
    print("Usage: umount <side or path>")
    print("Note: ComputerCraft disk drives cannot be unmounted via software.")
    print("      Use 'umount' to pop the disk out instead.")
    return
end

local target = args[1]
if disk.isPresent(target) then
    disk.eject(target)
    print("Ejected disk from " .. target)
else
    -- Find if they passed a path like /disk
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
        printError("umount: No such disk or drive")
    end
end
