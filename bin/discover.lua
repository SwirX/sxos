-- /bin/discover.lua
-- Show all SXOS nodes and services visible on the network.
-- Broadcasts a discovery request and prints a formatted host table.

local net = dofile("/lib/net/rednet.lua")

local timeout = tonumber(arg and arg[1]) or 3
print("Scanning network (" .. timeout .. "s)...")

local hosts = net.discover_hosts(timeout)

if #hosts == 0 then
    print("No SXOS hosts found.")
    return
end

print(string.format("%-20s %-8s %s", "HOSTNAME", "ID", "SERVICES"))
print(string.rep("-", 52))
for _, host in ipairs(hosts) do
    local services = table.concat(host.services, ", ")
    if services == "" then services = "-" end
    print(string.format("%-20s %-8s %s", host.hostname, host.id, services))
end
print(#hosts .. " host(s) found.")
