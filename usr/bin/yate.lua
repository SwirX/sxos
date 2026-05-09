local args = { ... }
if #args < 1 then
    print("Usage: yate <file>")
    return
end

local path = shell.resolve(args[1])
local lines = {}

if fs.exists(path) then
    if fs.isDir(path) then
        printError("yate: Cannot edit directory")
        return
    end
    local f = fs.open(path, "r")
    if f then
        local content = f.readAll()
        f.close()
        for s in string.gmatch(content .. "\n", "(.-)\n") do
            table.insert(lines, s)
        end
        if #lines > 0 then table.remove(lines, #lines) end
    end
end
if #lines == 0 then table.insert(lines, "") end

local w, h = term.getSize()
local cx, cy = 1, 1
local scrollX, scrollY = 0, 0
local running = true

local function draw()
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" yate - " .. fs.getName(path))

    term.setBackgroundColor(colors.black)
    for i = 1, h - 2 do
        term.setCursorPos(1, i + 1)
        term.clearLine()
        local lineIdx = scrollY + i
        if lineIdx <= #lines then
            term.write(string.sub(lines[lineIdx] or "", scrollX + 1, scrollX + w))
        end
    end

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    term.write(" <F2> Save  |  <F3> Quit")

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(cx - scrollX, cy - scrollY + 1)
end

local function save()
    local f = fs.open(path, "w")
    if f then
        for i, l in ipairs(lines) do f.write(l .. "\n") end
        f.close()
        return true
    end
    return false
end

while running do
    draw()
    local event, p1 = os.pullEvent()
    if event == "key" then
        if p1 == keys.up and cy > 1 then
            cy = cy - 1
        elseif p1 == keys.down and cy < #lines then
            cy = cy + 1
        elseif p1 == keys.left and cx > 1 then
            cx = cx - 1
        elseif p1 == keys.right and cx <= #lines[cy] then
            cx = cx + 1
        elseif p1 == keys.backspace and cx > 1 then
            lines[cy] = string.sub(lines[cy], 1, cx - 2) .. string.sub(lines[cy], cx)
            cx = cx - 1
        elseif p1 == keys.delete and cx <= #lines[cy] then
            lines[cy] = string.sub(lines[cy], 1, cx - 1) .. string.sub(lines[cy], cx + 1)
        elseif p1 == keys.enter then
            local rest = string.sub(lines[cy], cx)
            lines[cy] = string.sub(lines[cy], 1, cx - 1)
            table.insert(lines, cy + 1, rest)
            cy = cy + 1
            cx = 1
        elseif p1 == keys.f2 then
            save()
        elseif p1 == keys.f3 then
            break
        end

        if cy <= scrollY then scrollY = cy - 1 end
        if cy > scrollY + (h - 2) then scrollY = cy - (h - 2) end
        if cx <= scrollX then scrollX = cx - 1 end
        if cx > scrollX + w then scrollX = cx - w end
    elseif event == "char" then
        local l = lines[cy]
        lines[cy] = string.sub(l, 1, cx - 1) .. p1 .. string.sub(l, cx)
        cx = cx + 1
        if cx > scrollX + w then scrollX = cx - w end
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
