local device = require("sx.device")
local all_devices = device.get_all()

print(string.format("%-12s %-8s %-10s", "NAME", "SIZE", "SIDE"))
for _, dev in ipairs(all_devices) do
    if dev.type == "monitor" then
        local mon = device.open(dev.id)
        local size_str = "unknown"
        if mon and type(mon.getSize) == "function" then
            local w, h = mon.getSize()
            size_str = w .. "x" .. h
        end
        print(string.format("%-12s %-8s %-10s", dev.id, size_str, dev.side or "remote"))
    end
end
