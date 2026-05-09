-- /lib/sh/builtins.lua
-- Built-in shell commands for bsh.
-- Builtins are handled before PATH lookup since they need to modify the shell's
-- own state (working directory, environment, aliases, etc.) which a child
-- process cannot do.

local builtins = {}

local expand_module = dofile("/lib/sh/expand.lua")

-- Registry: command_name -> function(shell_state, args)
-- shell_state is the mutable state table owned by bsh's main loop.
-- Functions return true to continue, false to exit the shell.
local BUILTINS = {}

BUILTINS["cd"] = function(shell_state, args)
    local target = args[2]
    if not target then
        target = shell_state.env.HOME or "/"
    end
    target = expand_module.apply(target, shell_state.env, false)
    -- Resolve relative paths.
    if string.sub(target, 1, 1) ~= "/" then
        target = "/" .. fs.combine(shell_state.cwd, target)
    else
        target = "/" .. fs.combine("", target)
    end
    if fs.exists(target) and fs.isDir(target) then
        shell_state.cwd = target
        shell_state.env.PWD = target
    else
        printError("cd: " .. target .. ": no such directory")
    end
    return true
end

BUILTINS["export"] = function(shell_state, args)
    for i = 2, #args do
        local assignment = args[i]
        local eq = string.find(assignment, "=")
        if eq then
            local key = string.sub(assignment, 1, eq - 1)
            local value = string.sub(assignment, eq + 1)
            shell_state.env[key] = value
        else
            printError("export: invalid assignment: " .. assignment)
        end
    end
    return true
end

BUILTINS["unset"] = function(shell_state, args)
    for i = 2, #args do
        shell_state.env[args[i]] = nil
    end
    return true
end

BUILTINS["alias"] = function(shell_state, args)
    if #args < 2 then
        for name, value in pairs(shell_state.aliases) do
            print(name .. "=" .. value)
        end
        return true
    end
    local definition = args[2]
    local eq = string.find(definition, "=")
    if eq then
        shell_state.aliases[string.sub(definition, 1, eq - 1)] = string.sub(definition, eq + 1)
    else
        printError("alias: expected name=value")
    end
    return true
end

BUILTINS["unalias"] = function(shell_state, args)
    for i = 2, #args do
        shell_state.aliases[args[i]] = nil
    end
    return true
end

BUILTINS["source"] = function(shell_state, args)
    local target = args[2]
    if not target then
        printError("source: filename required")
        return true
    end
    if string.sub(target, 1, 1) ~= "/" then
        target = fs.combine(shell_state.cwd, target)
    end
    if not fs.exists(target) then
        printError("source: " .. target .. ": not found")
        return true
    end
    local fn, err = loadfile(target, "t", shell_state.process_env)
    if fn then
        local ok, run_err = pcall(fn)
        if not ok then printError("source: " .. tostring(run_err)) end
    else
        printError("source: " .. tostring(err))
    end
    return true
end

BUILTINS["exit"] = function(shell_state, _args)
    return false
end

-- Check if a command name is a builtin.
function builtins.is_builtin(name)
    return BUILTINS[name] ~= nil
end

-- Execute a builtin. Returns the continue boolean.
function builtins.execute(name, shell_state, args)
    local fn = BUILTINS[name]
    if not fn then return true end
    return fn(shell_state, args)
end

return builtins
