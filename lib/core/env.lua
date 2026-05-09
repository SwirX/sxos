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

    local core_path = "/lib/?.lua;/lib/?/init.lua;?;?.lua"
    local final_path = core_path
    if parent_env.package and parent_env.package.path then
        final_path = core_path .. ";" .. parent_env.package.path
    end

    process_env.package = {
        loaded = {},
        path = final_path
    }

    if parent_env.package and parent_env.package.loaded then
        for k, v in pairs(parent_env.package.loaded) do
            process_env.package.loaded[k] = v
        end
    end

    process_env.require = function(modname)
        if type(modname) ~= "string" then
            error("bad argument #1 to 'require' (string expected, got " .. type(modname) .. ")", 2)
        end

        if process_env.package.loaded[modname] ~= nil then
            return process_env.package.loaded[modname]
        end

        local errors = {}
        local pathStr = process_env.package.path or "?;?.lua"
        local modpath = string.gsub(modname, "%.", "/")

        for path in string.gmatch(pathStr, "[^;]+") do
            local filename = string.gsub(path, "%?", modpath)

            if process_env.fs.exists(filename) and not process_env.fs.isDir(filename) then
                local fn, err = loadfile(filename, "t", process_env)
                if fn then
                    local result = fn(modname)
                    if result == nil then
                        result = true
                    end
                    process_env.package.loaded[modname] = result
                    return result
                else
                    error(
                        "error loading module '" .. modname .. "' from file '" .. filename .. "':\n  " .. tostring(err),
                        2)
                end
            else
                table.insert(errors, "no file '" .. filename .. "'")
            end
        end

        if parent_env.require then
            local ok, result = pcall(parent_env.require, modname)
            if ok then
                process_env.package.loaded[modname] = result
                return result
            else
                table.insert(errors, result)
            end
        end

        local errStr = "module '" .. modname .. "' not found:\n  " .. table.concat(errors, "\n  ")
        error(errStr, 2)
    end

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
