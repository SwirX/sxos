-- /lib/sh/completion.lua
-- Tab and inline completion for bsh.
-- Provides command name completion (from PATH and aliases) and
-- filename completion for arguments.

local completion = {}

-- Complete a command name from aliases and PATH-available binaries.
-- prefix: the partial word typed so far
-- Returns the common suffix to append, or nil if no match.
local function complete_command(prefix, shell_state)
    -- Alias names.
    for alias_name in pairs(shell_state.aliases) do
        if string.sub(alias_name, 1, #prefix) == prefix and alias_name ~= prefix then
            return string.sub(alias_name, #prefix + 1)
        end
    end

    -- Binaries in PATH.
    local path_str = shell_state.env.PATH or "/bin;/usr/bin"
    for dir in string.gmatch(path_str, "[^;:]+") do
        if fs.exists(dir) and fs.isDir(dir) then
            for _, filename in ipairs(fs.list(dir)) do
                local stem = string.gsub(filename, "%.lua$", "")
                if string.sub(stem, 1, #prefix) == prefix and stem ~= prefix then
                    return string.sub(stem, #prefix + 1)
                end
            end
        end
    end
    return nil
end

-- Complete a filename relative to cwd.
-- prefix: partial filename typed
-- Returns the common suffix to append, or nil.
local function complete_filename(prefix, shell_state)
    local dir = shell_state.cwd
    local name_part = prefix

    -- Handle partial directory paths.
    local last_slash = 0
    for i = #prefix, 1, -1 do
        if string.sub(prefix, i, i) == "/" then
            last_slash = i
            break
        end
    end
    if last_slash > 0 then
        local dir_part = string.sub(prefix, 1, last_slash - 1)
        dir = fs.combine(dir, dir_part)
        name_part = string.sub(prefix, last_slash + 1)
    end

    if not fs.exists(dir) or not fs.isDir(dir) then return nil end

    for _, entry in ipairs(fs.list(dir)) do
        if string.sub(entry, 1, #name_part) == name_part and entry ~= name_part then
            local suffix = string.sub(entry, #name_part + 1)
            if fs.isDir(fs.combine(dir, entry)) then
                suffix = suffix .. "/"
            end
            return suffix
        end
    end
    return nil
end

-- Primary completion entry point.
-- line: the current input line
-- cursor_pos: position of the cursor in the line
-- Returns the suffix string to append, or nil.
function completion.complete(line, cursor_pos, shell_state)
    local partial = string.sub(line, 1, cursor_pos)

    -- Determine how many words have been typed.
    local words = {}
    for word in string.gmatch(partial, "%S+") do
        table.insert(words, word)
    end
    local ends_with_space = string.sub(partial, -1) == " "

    local word_count = #words + (ends_with_space and 1 or 0)

    if word_count <= 1 then
        -- Still typing the command name.
        local prefix = words[1] or ""
        return complete_command(prefix, shell_state)
    else
        -- Typing an argument: do filename completion.
        local prefix = ends_with_space and "" or (words[#words] or "")
        return complete_filename(prefix, shell_state)
    end
end

return completion
