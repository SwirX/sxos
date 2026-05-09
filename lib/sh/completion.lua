-- /lib/sh/completion.lua
-- Tab and inline completion for bsh.
-- Provides command name completion (from PATH and aliases) and
-- filename completion for arguments.
-- Returns full candidate lists so bsh can cycle through them.

local completion = {}

-- Collect all command names starting with prefix.
local function gather_commands(prefix, shell_state)
    local candidates = {}
    local seen = {}

    for alias_name in pairs(shell_state.aliases) do
        if string.sub(alias_name, 1, #prefix) == prefix and alias_name ~= prefix then
            if not seen[alias_name] then
                seen[alias_name] = true
                table.insert(candidates, alias_name)
            end
        end
    end

    local path_str = shell_state.env.PATH or "/bin;/usr/bin"
    for dir in string.gmatch(path_str, "[^;:]+") do
        if fs.exists(dir) and fs.isDir(dir) then
            for _, filename in ipairs(fs.list(dir)) do
                local stem = string.gsub(filename, "%.lua$", "")
                if string.sub(stem, 1, #prefix) == prefix and stem ~= prefix then
                    if not seen[stem] then
                        seen[stem] = true
                        table.insert(candidates, stem)
                    end
                end
            end
        end
    end

    table.sort(candidates)
    return candidates
end

-- Collect all filenames starting with prefix, relative to cwd.
local function gather_filenames(prefix, shell_state)
    local dir = shell_state.cwd
    local name_part = prefix

    local last_slash = 0
    for i = #prefix, 1, -1 do
        if string.sub(prefix, i, i) == "/" then
            last_slash = i
            break
        end
    end

    local dir_prefix = ""
    if last_slash > 0 then
        dir_prefix = string.sub(prefix, 1, last_slash)
        local dir_part = string.sub(prefix, 1, last_slash - 1)
        if string.sub(dir_part, 1, 1) == "/" then
            dir = dir_part
        else
            dir = fs.combine(dir, dir_part)
        end
        name_part = string.sub(prefix, last_slash + 1)
    end

    if not fs.exists(dir) or not fs.isDir(dir) then return {} end

    local candidates = {}
    for _, entry in ipairs(fs.list(dir)) do
        if string.sub(entry, 1, #name_part) == name_part and entry ~= name_part then
            local full_entry = dir_prefix .. entry
            if fs.isDir(fs.combine(dir, entry)) then
                full_entry = full_entry .. "/"
            end
            table.insert(candidates, full_entry)
        end
    end
    table.sort(candidates)
    return candidates
end

-- Return a list of completion candidates for the current line.
-- Returns: candidates (list of full replacement strings for the last word), prefix (the part typed so far)
function completion.candidates(line, cursor_pos, shell_state)
    local partial = string.sub(line, 1, cursor_pos)

    local words = {}
    for word in string.gmatch(partial, "%S+") do
        table.insert(words, word)
    end
    local ends_with_space = string.sub(partial, -1) == " "
    local word_count = #words + (ends_with_space and 1 or 0)

    if word_count <= 1 then
        local prefix = words[1] or ""
        return gather_commands(prefix, shell_state), prefix
    else
        local prefix = ends_with_space and "" or (words[#words] or "")
        return gather_filenames(prefix, shell_state), prefix
    end
end

-- Legacy single-result API used by inline ghost hint.
function completion.complete(line, cursor_pos, shell_state)
    local candidates, prefix = completion.candidates(line, cursor_pos, shell_state)
    if #candidates == 0 then return nil end
    -- Return the suffix of the first candidate only, for ghost-text display.
    return string.sub(candidates[1], #prefix + 1)
end

return completion
