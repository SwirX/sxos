-- /lib/devices/monitor.lua
local driver = {}

function driver.get_capabilities(native)
    return {
        text_scale = true,
        color = native and native.isColor and native.isColor() or false,
        mirror = true
    }
end

function driver.open(device_entry)
    local instance = {}
    if device_entry.native then
        for k, v in pairs(device_entry.native) do
            if type(v) == "function" then
                instance[k] = function(...) return v(...) end
            end
        end
    end
    instance._device_id = device_entry.id
    return instance
end

return driver
