local args = { ... }
if #args == 0 then return end
local cmd = args[1]

local aliases = shell.aliases()
if aliases[cmd] then
    print(cmd .. ": aliased to " .. aliases[cmd])
    return
end

local p = shell.resolveProgram(cmd)
if p then
    print(p)
else
    printError("which: no " .. cmd .. " in PATH")
end
