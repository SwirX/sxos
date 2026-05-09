local args = { ... }
if #args < 2 then
    printError("grep: usage: grep <pattern> <file>")
    return
end
local pattern = args[1]
local path = shell.resolve(args[2])

if not fs.exists(path) or fs.isDir(path) then
    printError("grep: " .. args[2] .. ": No such file")
    return
end
local f = fs.open(path, "r")
if f then
    local lineNo = 1
    local line = f.readLine()
    while line do
        if string.find(line, pattern) then
            term.setTextColor(colors.green)
            write(tostring(lineNo) .. ": ")
            term.setTextColor(colors.white)
            print(line)
        end
        line = f.readLine()
        lineNo = lineNo + 1
    end
    f.close()
end
