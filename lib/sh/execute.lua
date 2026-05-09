-- /lib/sh/execute.lua
-- AST executor for bsh.
-- Walks the parsed AST and carries out commands, pipelines, and sequences.
-- Handles: argument expansion, I/O redirection, pipes, builtins, and PATH lookup.

local execute         = {}

local expand_module   = dofile("/lib/sh/expand.lua")
local builtins_module = dofile("/lib/sh/builtins.lua")

-- Resolve a command name to an absolute executable path.
-- Checks aliases first, then PATH directories.
-- Returns the resolved path string, or nil if not found.
local function resolve_executable(name, shell_state)
    -- Alias expansion: replace name with alias target for resolution.
    local alias_target = shell_state.aliases[name]
    if alias_target then
        name = string.match(alias_target, "^%S+") or name
    end

    -- Absolute or explicitly relative path.
    if string.sub(name, 1, 1) == "/"
        or string.sub(name, 1, 2) == "./"
        or string.sub(name, 1, 3) == "../"
    then
        local resolved
        if string.sub(name, 1, 1) == "/" then
            resolved = fs.combine("", name)
        else
            resolved = fs.combine(shell_state.cwd, name)
        end
        if fs.exists(resolved) and not fs.isDir(resolved) then return resolved end
        if fs.exists(resolved .. ".lua") then return resolved .. ".lua" end
        return nil
    end

    -- Search PATH directories.
    local path_str = shell_state.env.PATH or "/bin;/usr/bin"
    for dir in string.gmatch(path_str, "[^;:]+") do
        local candidate = fs.combine(dir, name)
        if fs.exists(candidate) and not fs.isDir(candidate) then return candidate end
        if fs.exists(candidate .. ".lua") and not fs.isDir(candidate .. ".lua") then
            return candidate .. ".lua"
        end
    end
    return nil
end

-- Run a single external command with fully expanded args and resolved redirects.
-- stdio table: { stdin_path, stdout_path, append_stdout }
local function run_external(exec_path, expanded_args, stdio, shell_state)
    -- Set up stdout redirect by temporarily swapping print/write.
    local old_print = _G.print
    local old_write = _G.write
    local stdout_handle = nil

    if stdio.stdout_path then
        local mode = stdio.append_stdout and "a" or "w"
        stdout_handle = fs.open(stdio.stdout_path, mode)
        if stdout_handle then
            _G.print = function(...)
                local parts = {}
                for i = 1, select("#", ...) do
                    table.insert(parts, tostring(select(i, ...)))
                end
                stdout_handle.write(table.concat(parts, "\t") .. "\n")
            end
            _G.write = function(s) stdout_handle.write(tostring(s)) end
        end
    end

    -- Set up stdin redirect.
    local stdin_handle = nil
    if stdio.stdin_path then
        stdin_handle = fs.open(stdio.stdin_path, "r")
        -- Inject a replacement read function into the process env.
        if stdin_handle then
            shell_state.process_env.read = function() return stdin_handle.readLine() end
        end
    end

    local fn, err = loadfile(exec_path, "t", shell_state.process_env)
    local success = true
    if fn then
        local ok, run_err = pcall(fn, table.unpack(expanded_args, 2))
        if not ok then
            printError("bsh: " .. exec_path .. ": " .. tostring(run_err))
            success = false
        end
    else
        printError("bsh: " .. exec_path .. ": " .. tostring(err))
        success = false
    end

    -- Restore I/O.
    if stdout_handle then
        stdout_handle.close()
        _G.print = old_print
        _G.write = old_write
    end
    if stdin_handle then
        stdin_handle.close()
        shell_state.process_env.read = old_print -- restore stub; real read still in env
    end

    return success
end

-- Execute a single command AST node.
local function execute_command(node, shell_state, override_stdio)
    -- Expand all argument tokens.
    local expanded_args = {}
    for _, raw_arg in ipairs(node.args) do
        table.insert(expanded_args, expand_module.apply(raw_arg, shell_state.env, false))
    end

    if #expanded_args == 0 then return true end

    local cmd_name = expanded_args[1]

    -- Resolve redirects.
    local stdio = override_stdio or {}
    for _, redir in ipairs(node.redirs) do
        local target = expand_module.apply(redir.target, shell_state.env, false)
        if redir.direction == "REDIR_OUT" then
            stdio.stdout_path = target
            stdio.append_stdout = false
        elseif redir.direction == "REDIR_APPEND" then
            stdio.stdout_path = target
            stdio.append_stdout = true
        elseif redir.direction == "REDIR_IN" then
            stdio.stdin_path = target
        end
    end

    -- Check builtins first: they modify shell_state directly.
    if builtins_module.is_builtin(cmd_name) then
        return builtins_module.execute(cmd_name, shell_state, expanded_args)
    end

    -- Resolve external binary.
    local exec_path = resolve_executable(cmd_name, shell_state)
    if not exec_path then
        printError("bsh: " .. cmd_name .. ": command not found")
        return true
    end

    run_external(exec_path, expanded_args, stdio, shell_state)
    return true
end

-- Execute a pipeline: cmd1 | cmd2 | cmd3
-- Implements pipes by routing stdout of cmd_n to a temp file read by cmd_n+1.
local function execute_pipeline(node, shell_state)
    local commands = node.commands
    local buffer_paths = {}

    -- Generate temp file paths for the inter-command buffers.
    for i = 1, #commands - 1 do
        buffer_paths[i] = "/tmp/sxpipe_" .. os.clock() * 1000 .. "_" .. i
    end

    for index, cmd_node in ipairs(commands) do
        local stdio = {}
        if index > 1 then
            stdio.stdin_path = buffer_paths[index - 1]
        end
        if index < #commands then
            stdio.stdout_path = buffer_paths[index]
            stdio.append_stdout = false
        end
        execute_command(cmd_node, shell_state, stdio)
    end

    -- Clean up temp buffers.
    for _, buf_path in ipairs(buffer_paths) do
        if fs.exists(buf_path) then fs.delete(buf_path) end
    end
    return true
end

-- Top-level executor: handles command, pipeline, and sequence nodes.
function execute.run(ast_node, shell_state)
    if not ast_node then return true end

    if ast_node.type == "command" then
        return execute_command(ast_node, shell_state, nil)
    elseif ast_node.type == "pipeline" then
        return execute_pipeline(ast_node, shell_state)
    elseif ast_node.type == "sequence" then
        local continue_shell = true
        for _, statement in ipairs(ast_node.statements) do
            continue_shell = execute.run(statement, shell_state)
            if not continue_shell then return false end
        end
        return continue_shell
    end

    return true
end

return execute
