local args = { ... }
if #args == 0 then
    printError("rm: missing operand")
    return
end
for _, file in ipairs(args) do
    if string.sub(file, 1, 1) ~= "-" then
        local p = shell.resolve(file)
        if fs.exists(p) then
            if fs.isReadOnly(p) then
                printError("rm: cannot remove '" .. file .. "': Read-only file system")
            else
                fs.delete(p)
            end
        else
            printError("rm: cannot remove '" .. file .. "': No such file or directory")
        end
    end
end
