-- /lib/devices/generic.lua
local driver = {}

function driver.get_capabilities(native)
    return {}
end

function driver.open(device_entry)
    local instance = {
        _device_id = device_entry.id,
        _device_type = device_entry.type
    }

    if device_entry.native then
        for k, v in pairs(device_entry.native) do
            if type(v) == "function" then
                instance[k] = function(...) return v(...) end
            end
        end
    end

    -- Generic VFS Handle Close
    function instance.close()
        -- No-op
    end

    return instance
end

return driver
