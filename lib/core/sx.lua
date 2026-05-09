-- /lib/core/sx.lua
-- The public sx.* API surface for SXOS.
-- This is the only interface that binaries and userspace scripts should touch.
-- Internal modules (process, service, events, vfs) are NOT imported directly
-- by userspace. All access goes through this stable layer.
--
-- Design rationale: direct internal access creates brittle coupling that makes
-- refactoring catastrophic. This facade keeps the internal module structure free
-- to evolve while binaries stay stable.

local sx = {}

-- Lazy-load helpers so we only pay the dofile cost for subsystems actually used.
local loaded_modules = {}

local function require_internal(path)
    if not loaded_modules[path] then
        loaded_modules[path] = dofile(path)
    end
    return loaded_modules[path]
end

-- sx.fs: filesystem and VFS operations
sx.fs = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/fs/vfs.lua")[key]
    end
})

-- sx.path: path manipulation utilities
sx.path = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/fs/path.lua")[key]
    end
})

-- sx.proc: process management
sx.proc = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/core/process.lua")[key]
    end
})

-- sx.events: event subscription and emission
sx.events = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/core/events.lua")[key]
    end
})

-- sx.service: service registry and IPC
sx.service = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/core/service.lua")[key]
    end
})

-- sx.net: networking primitives
sx.net = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/net/rednet.lua")[key]
    end
})

-- sx.pkg: package management operations
sx.pkg = setmetatable({}, {
    __index = function(_, key)
        return require_internal("/lib/pkg/database.lua")[key]
    end
})

-- sx.log: logging shortcuts bound to the calling binary's name
function sx.make_logger(source)
    local log_module = require_internal("/lib/core/log.lua")
    return {
        debug = function(msg) log_module.debug(source, msg) end,
        info  = function(msg) log_module.info(source, msg) end,
        warn  = function(msg) log_module.warn(source, msg) end,
        error = function(msg) log_module.error(source, msg) end,
        fatal = function(msg) log_module.fatal(source, msg) end,
    }
end

return sx
