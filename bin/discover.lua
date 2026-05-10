local PROTOCOL_DISCOVER = "SXOS_DISCOVER"
local PROTOCOL_ANNOUNCE = "SXOS_ANNOUNCE"

local has_open_modem = false
for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
        if not rednet.isOpen(side) then rednet.open(side) end
        has_open_modem = true
    end
end
if not has_open_modem then
    printError("No network modem available.")
    return
end

print("Scanning network...")
rednet.broadcast({ type = "discover" }, PROTOCOL_DISCOVER)

local hosts = {}
local host_services = {}
local host_devices = {}

local timeout = os.startTimer(1.5)

while true do
    local e, p1, p2, p3 = os.pullEvent()
    if e == "timer" and p1 == timeout then
        break
    elseif e == "rednet_message" then
        local sender, msg, protocol = p1, p2, p3
        if protocol == PROTOCOL_ANNOUNCE and type(msg) == "table" then
            local hname = msg.hostname or tostring(sender)
            hosts[hname] = true
            if msg.services then
                for _, s in ipairs(msg.services) do
                    host_services[s] = true
                end
            end
            if msg.devices then
                for _, d in ipairs(msg.devices) do
                    table.insert(host_devices, hname .. "/" .. d)
                end
            end
        end
    end
end

print("\nHOSTS")
local has_hosts = false
for h in pairs(hosts) do
    print(h); has_hosts = true
end
if not has_hosts then print("  None") end

print("\nSERVICES")
local has_svcs = false
for s in pairs(host_services) do
    print(s); has_svcs = true
end
if not has_svcs then print("  None") end

print("\nDEVICES")
local has_devs = false
for _, d in ipairs(host_devices) do
    print(d); has_devs = true
end
if not has_devs then print("  None") end
