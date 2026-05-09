-- /bin/ping.lua
-- Ping a remote SXOS host by computer ID or hostname.
-- Reports round-trip time or timeout.

local net = dofile("/lib/net/rednet.lua")

local args = { ... }
local target = args[1]

if not target then
    print("Usage: ping <computer_id>")
    return
end

local target_id = tonumber(target)
if not target_id then
    -- Resolve hostname via discovery.
    print("Resolving '" .. target .. "'...")
    local hosts = net.discover_hosts(2)
    for _, host in ipairs(hosts) do
        if host.hostname == target then
            target_id = host.id
            break
        end
    end
    if not target_id then
        printError("ping: host not found: " .. target)
        return
    end
end

local count = tonumber(args[2]) or 4
print("PING " .. target_id .. " (" .. count .. " packets)")
local received = 0
for i = 1, count do
    local rtt = net.ping(target_id, 3)
    if rtt then
        print(string.format("  seq=%d rtt=%.1fms", i, rtt * 1000))
        received = received + 1
    else
        print(string.format("  seq=%d timeout", i))
    end
end
print(string.format("%d/%d packets received.", received, count))
