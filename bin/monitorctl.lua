local args = { ... }

if #args == 0 or args[1] == "list" then
    print(string.format("%-12s %-12s %-10s", "MONITOR", "SIZE", "STATE"))
    local device = require("sx.device")
    for _, dev in ipairs(device.get_all()) do
        if dev.type == "monitor" then
            local mon = device.open(dev.id)
            local size_str = "unknown"
            if mon and type(mon.getSize) == "function" then
                local w, h = mon.getSize()
                size_str = w .. "x" .. h
            end
            print(string.format("%-12s %-12s %-10s", dev.id, size_str, dev.mounted and "mounted" or "available"))
        end
    end
    return
end

local cmd = args[1]

if cmd == "scale" then
    local id, scale = args[2], tonumber(args[3])
    if not scale then
        print("Usage: monitorctl scale <monitor_id> <scale>"); return
    end

    local mon = require("sx.device").open(id)
    if mon and mon.setTextScale then
        mon.setTextScale(scale)
        print("Set text scale to " .. scale)
    else
        printError("Monitor context invalid")
    end
elseif cmd == "clear" then
    local id = args[2]
    if not id then
        print("Usage: monitorctl clear <monitor_id>"); return
    end
    local mon = require("sx.device").open(id)
    if mon and mon.clear then
        mon.clear()
        if mon.setCursorPos then mon.setCursorPos(1, 1) end
    else
        printError("Monitor context invalid")
    end
elseif cmd == "mirror" then
    local target, tty_id = args[2], args[3]
    if not tty_id then
        print("Usage: monitorctl mirror <monitor_id> <tty_id>"); return
    end
    print("Mirroring " .. tty_id .. " on " .. target .. " (stub: waiting for Compositor)")
else
    printError("Unknown monitorctl command.")
end
