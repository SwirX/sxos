local args = { ... }
if #args < 2 then
    printError("mv: missing file operand")
    return
end
local src = shell.resolve(args[1])
local dest = shell.resolve(args[2])
if not fs.exists(src) then
    printError("mv: cannot stat '" .. args[1] .. "': No such file or directory")
    return
end
if fs.isDir(dest) then dest = fs.combine(dest, fs.getName(src)) end
fs.move(src, dest)
