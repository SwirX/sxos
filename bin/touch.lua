local args = { ... }
if #args == 0 then
    printError("touch: missing file operand")
    return
end
for _, file in ipairs(args) do
    local pwd = (_ENV.ENV and _ENV.ENV.PWD) or "/"
    local p = string.sub(file, 1, 1) == "/" and file or ("/" .. fs.combine(pwd, file))
    if not fs.exists(p) then
        local f = fs.open(p, "w")
        if f then f.close() end
    end
end
