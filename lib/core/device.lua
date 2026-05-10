-- /lib/core/device.lua
local events        = dofile("/lib/core/events.lua")
local log           = dofile("/lib/core/log.lua")

local device        = {}

-- Store device entries here: { id = ..., type = ..., side = ..., mounted = ..., mountpoint = ..., etc }
local registry      = {}
local side_to_id    = {}
local type_counters = {}

local function generate_id(ptype)
    type_counters[ptype] = (type_counters[ptype] or -1) + 1
    return ptype .. "_" .. type_counters[ptype]
end

local function load_driver(ptype)
    local path = "/lib/devices/" .. ptype .. ".lua"
    if fs.exists(path) then
        return dofile(path)
    end
    return dofile("/lib/devices/generic.lua")
end

function device.register(side, ptype, is_remote)
    if side_to_id[side] then return end -- already registered

    local id = generate_id(ptype)
    local dev = {
        id = id,
        type = ptype,
        side = side,
        mounted = false,
        mountpoint = nil,
        remote = is_remote or false,
        owner_process = nil,
        exclusive = false,
        driver_module = load_driver(ptype)
    }

    if not is_remote then
        dev.native = peripheral.wrap(side)
    end

    if dev.driver_module and dev.driver_module.get_capabilities then
        dev.capabilities = dev.driver_module.get_capabilities(dev.native)
    else
        dev.capabilities = {}
    end

    registry[id] = dev
    side_to_id[side] = id
    log.info("device", "Attached " .. (is_remote and "remote " or "") .. "peripheral " .. id .. " on " .. side)
    return id
end

function device.unregister(side)
    local id = side_to_id[side]
    if not id then return end

    local dev = registry[id]
    if dev.mounted and dev.mountpoint then
        device.unmount(dev.mountpoint)
    end

    registry[id] = nil
    side_to_id[side] = nil
    log.info("device", "Detached peripheral " .. id .. " on " .. side)
end

function device.get_all()
    local list = {}
    for _, dev in pairs(registry) do
        table.insert(list, dev)
    end
    return list
end

function device.get(id)
    return registry[id]
end

function device.mount(id, path)
    local dev = registry[id]
    if not dev then return false, "Device not found" end
    if dev.mounted then return false, "Already mounted at " .. dev.mountpoint end

    dev.mounted = true
    dev.mountpoint = path
    log.info("device", "Mounted " .. id .. " to " .. path)
    return true
end

function device.unmount(path)
    for _, dev in pairs(registry) do
        if dev.mountpoint == path then
            dev.mounted = false
            dev.mountpoint = nil
            log.info("device", "Unmounted " .. dev.id .. " from " .. path)
            return true
        end
    end
    return false, "No device mounted at " .. path
end

function device.open(id)
    local dev = registry[id]
    if not dev then return nil, "Device not found" end

    if dev.driver_module and dev.driver_module.open then
        return dev.driver_module.open(dev)
    end
    return nil, "Driver does not support open()"
end

function device.reserve(id, process_id)
    local dev = registry[id]
    if not dev then return false, "Device not found" end
    if dev.owner_process then return false, "Already reserved by process " .. dev.owner_process end

    dev.owner_process = process_id
    dev.exclusive = true
    return true
end

function device.release(id, process_id)
    local dev = registry[id]
    if not dev then return false, "Device not found" end

    if dev.owner_process ~= process_id then
        return false, "Not owned by this process"
    end

    dev.owner_process = nil
    dev.exclusive = false
    return true
end

function device.init()
    -- Initialize with currently attached peripherals
    for _, side in ipairs(peripheral.getNames()) do
        local ptype = peripheral.getType(side)
        if ptype then
            device.register(side, ptype, false)
        end
    end

    -- Subscribe to events
    events.subscribe(0, "peripheral", function(_, side)
        local ptype = peripheral.getType(side)
        if ptype then
            device.register(side, ptype, false)
        end
    end)

    events.subscribe(0, "peripheral_detach", function(_, side)
        device.unregister(side)
    end)
end

return device
