-- /lib/core/env.lua
-- Environment management for SXOS process contexts.
-- Each process runs inside an isolated environment table that inherits from
-- the kernel's global environment. This prevents userspace from polluting
-- the kernel's namespace while still allowing access to CC globals.

local env = {}

-- Creates a sandboxed process environment.
-- parent_env: the environment to inherit globals from (usually _G or kernel env)
-- initial_vars: a flat key=value table of ENV variables (PATH, HOME, USER, etc.)
-- Returns an environment table suitable for use with loadfile(..., env).
function env.create_process_env(parent_env, initial_vars)
    local process_env = setmetatable({}, { __index = parent_env })

    -- ENV is the userspace dictionary equivalent of POSIX environ.
    process_env.ENV = {}
    for key, value in pairs(initial_vars or {}) do
        process_env.ENV[key] = value
    end

    -- expose standard print/write into the process scope
    process_env.print = parent_env.print
    process_env.write = parent_env.write
    process_env.printError = parent_env.printError
    process_env.read = parent_env.read
    process_env.pairs = parent_env.pairs
    process_env.ipairs = parent_env.ipairs
    process_env.tostring = parent_env.tostring
    process_env.tonumber = parent_env.tonumber
    process_env.type = parent_env.type
    process_env.error = parent_env.error
    process_env.assert = parent_env.assert
    process_env.pcall = parent_env.pcall
    process_env.xpcall = parent_env.xpcall
    process_env.setmetatable = parent_env.setmetatable
    process_env.getmetatable = parent_env.getmetatable
    process_env.rawget = parent_env.rawget
    process_env.rawset = parent_env.rawset
    process_env.require = parent_env.require
    process_env.select = parent_env.select
    process_env.unpack = parent_env.unpack or table.unpack
    process_env.string = parent_env.string
    process_env.table = parent_env.table
    process_env.math = parent_env.math
    process_env.os = parent_env.os
    process_env.fs = parent_env.fs
    process_env.term = parent_env.term
    process_env.colors = parent_env.colors
    process_env.keys = parent_env.keys
    process_env.textutils = parent_env.textutils
    process_env.peripheral = parent_env.peripheral
    process_env.rednet = parent_env.rednet
    process_env.http = parent_env.http
    process_env.coroutine = parent_env.coroutine
    process_env.io = parent_env.io
    process_env._ENV = process_env

    return process_env
end

-- Expands a string containing $VAR or ${VAR} references against a given
-- environment variable table (the flat ENV table, not the process_env).
function env.expand_vars(str, environ)
    if type(str) ~= "string" then return str end
    -- Replace ${VAR} first (longer form), then $VAR
    str = string.gsub(str, "%${([%w_]+)}", function(key)
        return tostring(environ[key] or "")
    end)
    str = string.gsub(str, "%$([%w_]+)", function(key)
        return tostring(environ[key] or "")
    end)
    return str
end

return env
