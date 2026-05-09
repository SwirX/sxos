-- /bin/bsh.lua
-- Better SHell for SXOS.
-- This file is the thin frontend of the shell. All parsing logic lives in
-- /lib/sh/. This file owns the interactive loop, the read-line UI, and
-- the mutable shell_state table shared with builtins.

local tokenizer               = dofile("/lib/sh/tokenizer.lua")
local parser                  = dofile("/lib/sh/parser.lua")
local execute                 = dofile("/lib/sh/execute.lua")
local completion              = dofile("/lib/sh/completion.lua")

-- shell_state is passed to builtins and the executor.
-- It is the single authoritative source for mutable shell context.
local shell_state             = {
    cwd         = _ENV.ENV.HOME or "/",
    env         = _ENV.ENV,
    aliases     = { ll = "ls -l", la = "ls -a" },
    process_env = _ENV,
    history     = {},
}
_ENV.ENV.PWD                  = shell_state.cwd

-- CraftOS Compatibility Layer:
-- Expose a `shell` object so standard CC programs work seamlessly.
shell_state.process_env.shell = {
    exit = function() return end,
    dir = function()
        return string.sub(shell_state.cwd, 1, 1) == "/" and string.sub(shell_state.cwd, 2) or shell_state.cwd
    end,
    setDir = function(dir)
        local pwd = "/" .. fs.combine("", dir)
        shell_state.cwd = pwd
        shell_state.env.PWD = pwd
    end,
    path = function() return shell_state.env.PATH or "" end,
    setPath = function(p) shell_state.env.PATH = p end,
    resolve = function(path)
        if string.sub(path, 1, 1) == "/" then return fs.combine("", path) end
        return fs.combine(shell_state.cwd, path)
    end,
    resolveProgram = function(name)
        if shell_state.aliases[name] then return name end
        local path_str = shell_state.env.PATH or "/bin;/usr/bin"
        for dir in string.gmatch(path_str, "[^;:]+") do
            local candidate = fs.combine(dir, name)
            if fs.exists(candidate) and not fs.isDir(candidate) then return candidate end
            if fs.exists(candidate .. ".lua") and not fs.isDir(candidate .. ".lua") then return candidate .. ".lua" end
        end
        return nil
    end,
    aliases = function() return shell_state.aliases end,
    setAlias = function(name, value) shell_state.aliases[name] = value end,
    clearAlias = function(name) shell_state.aliases[name] = nil end,
    programs = function() return {} end,
    getRunningProgram = function() return "bsh" end
}

local user                    = _ENV.ENV.USER or "user"
local hostname                = _ENV.ENV.HOSTNAME or "sxos"
local is_installer            = _ENV.INSTALLER_MODE or false

-- -----------------------------------------------------------------------
-- Prompt rendering
-- -----------------------------------------------------------------------

local function load_theme()
    local theme_path = (shell_state.env.HOME or "/home/" .. user) ..
        "/.config/bsh/theme.lua"
    if fs.exists(theme_path) then
        local ok, result = pcall(dofile, theme_path)
        if ok and type(result) == "table" then return result end
    end
    -- Fallback default theme.
    return {
        user_color    = colors.green,
        root_color    = colors.red,
        host_color    = colors.white,
        path_color    = colors.blue,
        prompt_color  = colors.lightGray,
        cmd_color     = colors.cyan,
        cmd_err_color = colors.red,
    }
end

local theme = load_theme()

local function draw_prompt()
    local display_dir = shell_state.cwd
    if display_dir == shell_state.env.HOME then
        display_dir = "~"
    end

    local user_color = (user == "root") and theme.root_color or theme.user_color
    term.setTextColor(user_color)
    write(user)
    term.setTextColor(theme.host_color)
    write("@" .. hostname)
    term.setTextColor(colors.white)
    write(" ")
    term.setTextColor(theme.path_color)
    write(display_dir)
    term.setTextColor(theme.prompt_color)
    write((user == "root") and " # " or " $ ")
    term.setTextColor(colors.white)
end

-- -----------------------------------------------------------------------
-- Word-boundary helpers for Ctrl+arrow and Ctrl+backspace
-- -----------------------------------------------------------------------

-- Find the insertion position after skipping backward over one word.
local function prev_word_boundary(line, cursor_pos)
    local pos = cursor_pos
    while pos > 0 and string.sub(line, pos, pos) == " " do pos = pos - 1 end
    while pos > 0 and string.sub(line, pos, pos) ~= " " do pos = pos - 1 end
    return pos
end

-- Find the insertion position after skipping forward over one word.
local function next_word_boundary(line, cursor_pos)
    local len = #line
    local pos = cursor_pos
    while pos < len and string.sub(line, pos + 1, pos + 1) == " " do pos = pos + 1 end
    while pos < len and string.sub(line, pos + 1, pos + 1) ~= " " do pos = pos + 1 end
    return pos
end

-- -----------------------------------------------------------------------
-- Read-line with history, cursor blink, word navigation, multi-tab completion
-- -----------------------------------------------------------------------

local function read_line()
    draw_prompt()

    local start_x, start_y = term.getCursorPos()
    local term_width       = term.getSize()
    local line             = ""
    local cursor_pos       = 0
    local history_pos      = #shell_state.history + 1
    local scroll_offset    = 0
    local ctrl_held        = false

    -- Tab-cycling state; nil when not in a cycle.
    local tab_candidates   = nil
    local tab_prefix       = nil
    local tab_index        = 0
    local tab_base_line    = nil

    local function reset_tab_cycle()
        tab_candidates = nil
        tab_prefix     = nil
        tab_index      = 0
        tab_base_line  = nil
    end

    local function redraw()
        local visible_width = term_width - start_x
        if cursor_pos - scroll_offset > visible_width then
            scroll_offset = cursor_pos - visible_width
        elseif cursor_pos < scroll_offset then
            scroll_offset = cursor_pos
        end

        term.setCursorPos(start_x, start_y)
        local visible   = string.sub(line, scroll_offset + 1, scroll_offset + visible_width)

        local space_pos = string.find(visible, " ")
        local cmd_part  = space_pos and string.sub(visible, 1, space_pos - 1) or visible
        local remainder = space_pos and string.sub(visible, space_pos) or ""

        if #cmd_part > 0 then
            local first_word = string.match(line, "^%S+") or ""
            local path_str   = shell_state.env.PATH or "/bin;/usr/bin"
            local cmd_exists = shell_state.aliases[first_word] ~= nil
            if not cmd_exists then
                for dir in string.gmatch(path_str, "[^;:]+") do
                    if fs.exists(fs.combine(dir, first_word))
                        or fs.exists(fs.combine(dir, first_word .. ".lua"))
                    then
                        cmd_exists = true; break
                    end
                end
            end
            term.setTextColor(cmd_exists and theme.cmd_color or theme.cmd_err_color)
            write(cmd_part)
        end
        term.setTextColor(colors.white)
        write(remainder)

        -- Ghost-text inline hint only when not cycling completions.
        local hint = ""
        if not is_installer and cursor_pos == #line and #line > 0 and tab_candidates == nil then
            local suffix = completion.complete(line, cursor_pos, shell_state)
            if suffix then
                hint = suffix
                term.setTextColor(colors.gray)
                local hint_visible = string.sub(hint, 1, visible_width - #visible)
                write(hint_visible)
            end
        end

        local cx = term.getCursorPos()
        if cx <= term_width then
            term.write(string.rep(" ", term_width - cx + 1))
        end
        term.setCursorPos(start_x + (cursor_pos - scroll_offset), start_y)
        term.setTextColor(colors.white)
        return hint
    end

    term.setCursorBlink(true)
    local current_hint = redraw()

    while true do
        local event, p1 = os.pullEvent()

        if event == "key" then
            local key = p1

            if key == keys.leftCtrl or key == keys.rightCtrl then
                ctrl_held = true
            elseif key == keys.enter then
                reset_tab_cycle()
                term.setCursorBlink(false)
                print()
                break
            elseif key == keys.backspace then
                reset_tab_cycle()
                if ctrl_held then
                    if cursor_pos > 0 then
                        local new_pos = prev_word_boundary(line, cursor_pos)
                        line          = string.sub(line, 1, new_pos) .. string.sub(line, cursor_pos + 1)
                        cursor_pos    = new_pos
                        current_hint  = redraw()
                    end
                elseif cursor_pos > 0 then
                    line         = string.sub(line, 1, cursor_pos - 1) .. string.sub(line, cursor_pos + 1)
                    cursor_pos   = cursor_pos - 1
                    current_hint = redraw()
                end
            elseif key == keys.left then
                reset_tab_cycle()
                if ctrl_held then
                    cursor_pos = prev_word_boundary(line, cursor_pos)
                elseif cursor_pos > 0 then
                    cursor_pos = cursor_pos - 1
                end
                current_hint = redraw()
            elseif key == keys.right then
                reset_tab_cycle()
                if ctrl_held then
                    cursor_pos = next_word_boundary(line, cursor_pos)
                elseif cursor_pos < #line then
                    cursor_pos = cursor_pos + 1
                elseif #current_hint > 0 then
                    line       = line .. current_hint
                    cursor_pos = #line
                end
                current_hint = redraw()
            elseif key == keys.tab then
                local shift_held = keys.isHeld and (keys.isHeld(keys.leftShift) or keys.isHeld(keys.rightShift)) or false

                if tab_candidates == nil then
                    local cands, pfx = completion.candidates(line, cursor_pos, shell_state)
                    if #cands == 0 then
                        -- No completions: nothing to do.
                    elseif #cands == 1 then
                        local suffix = string.sub(cands[1], #pfx + 1)
                        line         = string.sub(line, 1, cursor_pos - #pfx) .. cands[1]
                        cursor_pos   = #line
                        current_hint = redraw()
                    else
                        -- Show all candidates, then start cycling.
                        tab_candidates = cands
                        tab_prefix     = pfx
                        tab_base_line  = line
                        tab_index      = 1

                        print()
                        for _, cand in ipairs(cands) do
                            write(cand .. "  ")
                        end
                        print()
                        draw_prompt()
                        start_x, start_y = term.getCursorPos()

                        local base       = string.sub(tab_base_line, 1, #tab_base_line - #tab_prefix)
                        line             = base .. tab_candidates[tab_index]
                        cursor_pos       = #line
                        current_hint     = redraw()
                    end
                else
                    if shift_held then
                        tab_index = tab_index - 1
                        if tab_index < 1 then tab_index = #tab_candidates end
                    else
                        tab_index = tab_index + 1
                        if tab_index > #tab_candidates then tab_index = 1 end
                    end
                    local base   = string.sub(tab_base_line, 1, #tab_base_line - #tab_prefix)
                    line         = base .. tab_candidates[tab_index]
                    cursor_pos   = #line
                    current_hint = redraw()
                end
            elseif key == keys.up then
                reset_tab_cycle()
                if history_pos > 1 then
                    history_pos  = history_pos - 1
                    line         = shell_state.history[history_pos] or ""
                    cursor_pos   = #line
                    current_hint = redraw()
                end
            elseif key == keys.down then
                reset_tab_cycle()
                if history_pos < #shell_state.history then
                    history_pos  = history_pos + 1
                    line         = shell_state.history[history_pos] or ""
                    cursor_pos   = #line
                    current_hint = redraw()
                elseif history_pos == #shell_state.history then
                    history_pos  = history_pos + 1
                    line         = ""
                    cursor_pos   = 0
                    current_hint = redraw()
                end
            end
        elseif event == "key_up" then
            if p1 == keys.leftCtrl or p1 == keys.rightCtrl then
                ctrl_held = false
            end
        elseif event == "char" then
            reset_tab_cycle()
            line         = string.sub(line, 1, cursor_pos) .. p1 .. string.sub(line, cursor_pos + 1)
            cursor_pos   = cursor_pos + 1
            current_hint = redraw()
        end
    end

    if #line > 0 and line ~= shell_state.history[#shell_state.history] then
        table.insert(shell_state.history, line)
    end
    return line
end

-- -----------------------------------------------------------------------
-- Main shell loop
-- -----------------------------------------------------------------------

term.setTextColor(colors.lightGray)
if is_installer then
    print("SXOS Installer TTY. Type 'exit' to finish.")
else
    print("bsh " .. (os.date and os.date("%Y-%m-%d") or "") .. "  Type 'help' for help.")
end

while true do
    local ok, line = pcall(read_line)
    if not ok then
        print()
        break
    end

    -- Skip blank lines.
    if string.match(line, "^%s*$") then
        goto continue
    end

    -- Parse and execute.
    local tokens = tokenizer.tokenize(line)
    local ast, parse_err = parser.parse(tokens)

    if parse_err then
        printError("bsh: parse error: " .. parse_err)
    elseif ast then
        local keep_running = execute.run(ast, shell_state)
        if not keep_running then break end
    end

    ::continue::
end
