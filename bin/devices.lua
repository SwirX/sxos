local device = require("sx.device")
local devs = device.get_all()

print(string.format("%-12s %-10s %-10s %-10s", "NAME", "TYPE", "SIDE", "STATUS"))
for _, dev in ipairs(devs) do
    local status = dev.mounted and "mounted" or "available"
    if dev.remote then
        status = "remote " .. status
    end
    if dev.exclusive then
        status = "busy"
    end
    print(string.format("%-12s %-10s %-10s %-10s",
        dev.id, dev.type, dev.side or "remote", status))
end
