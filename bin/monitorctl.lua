local args = { ... }
if #args < 2 then
    print("Usage: monitorctl <monitor_id> <command> [args...]")
    print("Commands:")
    print("  scale <size>")
    print("  clear")
    print("  mirror <side>")
    return
end

local id = args[1]
local cmd = args[2]

local mon = require("sx.device").open(id)
if not mon then
    printError("Monitor " .. id .. " not found or failed to open")
    return
end

if cmd == "scale" then
    local scale = tonumber(args[3])
    if not scale then
        printError("Usage: monitorctl <id> scale <size>")
        return
    end
    if mon.setTextScale then
        mon.setTextScale(scale)
        print("Set text scale to " .. scale)
    else
        printError("Monitor does not support scaling")
    end
elseif cmd == "clear" then
    if mon.clear then
        mon.clear()
        if mon.setCursorPos then mon.setCursorPos(1, 1) end
        print("Cleared monitor " .. id)
    else
        printError("Monitor does not support clearing")
    end
elseif cmd == "mirror" then
    -- Not fully natively supported in CraftOS simply by API out of the box,
    -- typically achieved via window redirection or multishell. But we can stub it.
    print("Mirroring currently handled via userspace compositors.")
else
    printError("Unknown command: " .. cmd)
end
