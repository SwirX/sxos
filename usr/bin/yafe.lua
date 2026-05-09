-- /usr/bin/yafe.lua
-- YAFE - Yet Another File Explorer
-- Arrow-key driven directory browser. Enter opens dirs or runs yate on files.
-- Q exits. Scrolls automatically when the list is taller than the terminal.

local dir      = (shell and shell.dir()) or "/"
local scroll   = 0
local selected = 1
local w, h     = term.getSize()

-- Normalise a directory path so navigating ".." from "/" stays at "/".
local function safe_parent(current_dir)
    local parent = fs.getDir(current_dir)
    if parent == "" or parent == current_dir then
        return "/"
    end
    return parent
end

local function read_dir(current_dir)
    local resolved = fs.combine("/", current_dir)
    local items = {}
    if resolved ~= "/" then
        table.insert(items, "..")
    end
    local ok, listing = pcall(fs.list, resolved)
    if ok then
        table.sort(listing)
        for _, f in ipairs(listing) do
            table.insert(items, f)
        end
    end
    return items
end

while true do
    local items = read_dir(dir)

    if selected > #items then selected = #items end
    if selected < 1 then selected = 1 end

    -- Header bar
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" yafe  " .. dir)

    -- File list
    term.setBackgroundColor(colors.black)
    for row = 1, h - 2 do
        term.setCursorPos(1, row + 1)
        term.clearLine()
        local idx = scroll + row
        if idx <= #items then
            local item = items[idx]
            local full_path = fs.combine(dir, item)

            if idx == selected then
                term.setBackgroundColor(colors.gray)
            else
                term.setBackgroundColor(colors.black)
            end

            if item == ".." then
                term.setTextColor(colors.yellow)
            elseif fs.isDir(full_path) then
                term.setTextColor(colors.cyan)
            else
                term.setTextColor(colors.white)
            end

            term.write((idx == selected and "> " or "  ") .. item)
            term.setBackgroundColor(colors.black)
        end
    end

    -- Footer bar
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    term.write(" <Enter> Open   <Q> Quit")
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

    local event, key = os.pullEvent("key")

    if key == keys.up and selected > 1 then
        selected = selected - 1
    elseif key == keys.down and selected < #items then
        selected = selected + 1
    elseif key == keys.enter then
        local item = items[selected]
        if item == ".." then
            dir      = safe_parent(dir)
            selected = 1
            scroll   = 0
        else
            local full_path = fs.combine(dir, item)
            if fs.isDir(full_path) then
                dir      = full_path
                selected = 1
                scroll   = 0
            else
                shell.run("yate", full_path)
                -- Restore terminal state that yate may not have cleaned up.
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            end
        end
    elseif key == keys.q then
        break
    end

    if selected <= scroll then scroll = selected - 1 end
    if selected > scroll + (h - 2) then scroll = selected - (h - 2) end
end

-- Clean exit: reset terminal state so the calling shell is unaffected.
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
