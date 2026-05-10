local device = require("sx.device")
local devs = device.get_all()

print(string.format("%-12s %-10s %-10s %-10s %-10s", "ID", "TYPE", "LOCATION", "OWNER", "STATE"))
for _, dev in ipairs(devs) do
    local state = dev.mounted and "mounted" or "available"
    if dev.exclusive then state = "claimed" end
    local loc = dev.side or "remote"
    local owner = dev.owner_process and tostring(dev.owner_process) or "-"
    print(string.format("%-12s %-10s %-10s %-10s %-10s",
        dev.id, dev.type, loc, owner, state))
end
