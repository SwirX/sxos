local args = { ... }
if #args == 0 then
    printError("mkdir: missing operand")
    return
end
for _, dir in ipairs(args) do
    local pwd = (_ENV.ENV and _ENV.ENV.PWD) or "/"
    local p = string.sub(dir, 1, 1) == "/" and dir or ("/" .. fs.combine(pwd, dir))
    fs.makeDir(p)
end
