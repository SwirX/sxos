-- /sys/env.lua
-- Process environment façade for the SXOS installer tools.
-- This file is intentionally loaded via dofile() by the advanced installer,
-- so it must NOT call require() at the module level (package.path is not yet
-- configured at that point).  All dependencies are loaded with loadfile().

local _M = {}

-- Load the canonical implementation from lib/core/env.lua.
local core_env_chunk, err = loadfile("/lib/core/env.lua")
if not core_env_chunk then
    error("sys/env.lua: cannot load /lib/core/env.lua: " .. tostring(err), 0)
end
local core_env = core_env_chunk()

-- Re-export create_process_env so callers can use this file transparently.
_M.create_process_env = core_env.create_process_env

return _M
