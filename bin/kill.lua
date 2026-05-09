local args = { ... }
if #args == 0 then
    printError("kill: usage: kill <pid>")
    return
end

local pid = tonumber(args[1])
if not pid then
    printError("kill: invalid pid")
    return
end

if shell.kill_bg and shell.kill_bg(pid) then
    print("Terminated process " .. pid)
else
    printError("kill: process " .. pid .. " not found")
end
