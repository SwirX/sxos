local args = { ... }
if #args == 0 then return end
for _, file in ipairs(args) do
    local p = shell.resolve(file)
    if fs.exists(p) and not fs.isDir(p) then
        local f = fs.open(p, "r")
        if f then
            local text = f.readAll()
            if text then write(text) end
            f.close()
        end
    else
        printError("cat: " .. file .. ": No such file or directory")
    end
end
print()
