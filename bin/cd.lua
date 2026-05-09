local args = { ... }
local tDir = args[1] or _ENV.ENV.HOME or "/"
local pwd = (_ENV.ENV and _ENV.ENV.PWD) or "/"
tDir = string.sub(tDir, 1, 1) == "/" and tDir or ("/" .. fs.combine(pwd, tDir))
if fs.isDir(tDir) then
    _ENV.ENV.PWD = tDir
else
    printError("cd: " .. tostring(args[1]) .. ": No such directory")
end
