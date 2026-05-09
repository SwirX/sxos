local dir = shell.dir()
local scroll = 0
local selected = 1
local running = true
local w, h = term.getSize()

local function readDir()
    local p = shell.resolve(dir)
    local items = { ".." }
    for _, f in ipairs(fs.list(p)) do table.insert(items, f) end
    return items
end

while running do
    local items = readDir()
    if selected > #items then selected = #items end
    if selected < 1 then selected = 1 end

    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" yafe - " .. dir)

    term.setBackgroundColor(colors.black)
    for i = 1, h - 2 do
        term.setCursorPos(1, i + 1)
        term.clearLine()
        local idx = scroll + i
        if idx <= #items then
            local item = items[idx]
            local p = fs.combine(shell.resolve(dir), item)
            local prefix = "  "
            if idx == selected then
                term.setBackgroundColor(colors.gray)
                prefix = "> "
            else
                term.setBackgroundColor(colors.black)
            end

            if fs.isDir(p) then
                term.setTextColor(colors.cyan)
            else
                term.setTextColor(colors.white)
            end
            term.write(tostring(prefix) .. tostring(item))
        end
        term.setBackgroundColor(colors.black)
    end

    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    term.write(" <Enter> Open/File   <Q> Quit")

    local event, p1 = os.pullEvent("key")
    if p1 == keys.up and selected > 1 then
        selected = selected - 1
    elseif p1 == keys.down and selected < #items then
        selected = selected + 1
    elseif p1 == keys.enter then
        local item = items[selected]
        if item == ".." then
            dir = fs.getDir(dir)
            selected = 1
            scroll = 0
        else
            local p = fs.combine(shell.resolve(dir), item)
            if fs.isDir(p) then
                dir = p
                selected = 1
                scroll = 0
            else
                shell.run("yate", p)
            end
        end
    elseif p1 == keys.q then
        break
    end

    if selected <= scroll then scroll = selected - 1 end
    if selected > scroll + (h - 2) then scroll = selected - (h - 2) end
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
