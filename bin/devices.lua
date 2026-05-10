local device = require("sx.device")
local all_devices = device.get_all()

print(string.format("%-15s %-10s %-10s %-15s", "ID", "TYPE", "STATE", "MOUNT"))
for _, dev in ipairs(all_devices) do
    local state = "detached"
    if dev.mounted then
        state = "mounted"
    elseif dev.side or dev.remote then
        state = "available"
    end

    if dev.exclusive then state = "claimed" end

    local mountpoint = dev.mounted and dev.mountpoint or "-"

    print(string.format("%-15s %-10s %-10s %-15s",
        dev.id, dev.type, state, mountpoint))
end
