local args = { ... }
if #args < 1 then
    print("Usage: wget <url> <filename>")
    print("       wget run <url>")
    return
end

local function check_security()
    local user = _ENV.ENV and _ENV.ENV.USER or "root"
    local configPath = "/home/" .. user .. "/.config/sxos/security.lua"
    if user == "root" then configPath = "/etc/sxos/security.lua" end

    local config = {}
    if fs.exists(configPath) then
        local f = fs.open(configPath, "r")
        if f then
            config = textutils.unserialize(f.readAll() or "{}") or {}; f.close()
        end
    end

    if config.allow_unmanaged_scripts then return true end

    printError("This script is not managed by SXPM.")
    print("\nRunning arbitrary remote code may:")
    print(" - bypass dependency validation")
    print(" - overwrite SXOS files")
    print(" - conflict with installed packages")
    print(" - compromise system integrity")
    write("\nContinue? [y/N] ")

    local ans = read()
    if ans:lower() == "y" then
        config.allow_unmanaged_scripts = true
        if not fs.exists(fs.getDir(configPath)) then fs.makeDir(fs.getDir(configPath)) end
        local f = fs.open(configPath, "w")
        if f then
            f.write(textutils.serialize(config)); f.close()
        end
        return true
    end
    printError("Aborted.")
    return false
end

local isRun = false
local url = ""
local path = ""

if args[1] == "run" then
    if #args < 2 then
        print("Usage: wget run <url>")
        return
    end
    isRun = true
    url = args[2]
else
    if #args < 2 then
        print("Usage: wget <url> <filename>")
        return
    end
    url = args[1]
    path = shell.resolve(args[2])
end

if not string.find(url, "^https?://") then
    url = "http://" .. url
end

print("Connecting to " .. url)
local res = http.get(url)
if not res then
    printError("Failed to download.")
    return
end

local data = res.readAll()
res.close()

if isRun then
    if not check_security() then return end
    local func, err = load(data, url, "t", _ENV)
    if not func then
        printError("Failed to compile downloaded code: " .. tostring(err))
        return
    end
    local runArgs = {}
    for i = 3, #args do table.insert(runArgs, args[i]) end
    local ok, runErr = pcall(func, table.unpack(runArgs))
    if not ok then
        printError("Runtime error: " .. tostring(runErr))
    end
else
    local f = fs.open(path, "w")
    if f then
        f.write(data)
        f.close()
        print("Downloaded " .. #data .. " bytes to " .. args[2])
    else
        printError("Failed to open file for writing.")
    end
end
