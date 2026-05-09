local args = { ... }
if #args == 0 then
    printError("mkcd: missing operand")
    return
end
local dir = args[1]
local p = shell.resolve(dir)
fs.makeDir(p)
shell.setDir(p)
