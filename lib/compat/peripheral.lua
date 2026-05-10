-- /lib/compat/peripheral.lua
local device = dofile("/lib/core/device.lua")
local compat = {}

function compat.isPresent(name)
    local all = device.get_all()
    for _, dev in ipairs(all) do
        if dev.side == name then return true end
    end
    return false
end

function compat.getType(name)
    local all = device.get_all()
    for _, dev in ipairs(all) do
        if dev.side == name then return dev.type end
    end
    return nil
end

function compat.getMethods(name)
    if not compat.isPresent(name) then return nil end
    local wrapped = compat.wrap(name)
    if not wrapped then return nil end
    local methods = {}
    for k, v in pairs(wrapped) do
        if type(v) == "function" then
            table.insert(methods, k)
        end
    end
    return methods
end

function compat.call(name, method, ...)
    local wrapped = compat.wrap(name)
    if not wrapped then return nil, "No such peripheral" end
    if not wrapped[method] then return nil, "No such method" end
    return wrapped[method](...)
end

function compat.wrap(name)
    local all = device.get_all()
    local target_id = nil
    for _, dev in ipairs(all) do
        if dev.side == name then
            target_id = dev.id
            break
        end
    end
    if not target_id then return nil end
    return device.open(target_id)
end

function compat.find(ptype, fn)
    local results = {}
    local all = device.get_all()
    for _, dev in ipairs(all) do
        if dev.type == ptype then
            local wrapped = device.open(dev.id)
            if wrapped then
                if fn == nil or fn(dev.side, wrapped) then
                    table.insert(results, wrapped)
                end
            end
        end
    end
    return table.unpack(results)
end

function compat.getNames()
    local names = {}
    local all = device.get_all()
    for _, dev in ipairs(all) do
        if dev.side then
            table.insert(names, dev.side)
        end
    end
    return names
end

return compat
