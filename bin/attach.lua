local device = require("sx.device")
local all_devices = device.get_all()

local available = {}
local mounted = {}
local claimed = {}
local remote = {}

for _, dev in ipairs(all_devices) do
    if dev.mounted then
        table.insert(mounted, dev)
    elseif dev.remote then
        table.insert(remote, dev)
    elseif dev.exclusive then
        table.insert(claimed, dev)
    else
        table.insert(available, dev)
    end
end

if #available > 0 then
    print("AVAILABLE:")
    for _, dev in ipairs(available) do
        print(dev.side .. " " .. dev.type)
    end
    print()
end

if #mounted > 0 then
    print("MOUNTED:")
    for _, dev in ipairs(mounted) do
        print(dev.id .. " -> " .. dev.mountpoint)
    end
    print()
end

if #claimed > 0 then
    print("CLAIMED:")
    for _, dev in ipairs(claimed) do
        print(dev.id .. " [by PID " .. tostring(dev.owner_process) .. "]")
    end
    print()
end

if #remote > 0 then
    print("REMOTE:")
    for _, dev in ipairs(remote) do
        print(dev.id .. " (" .. tostring(dev.side) .. ")")
    end
    print()
end

if #all_devices == 0 then
    print("No peripherals detected.")
end
