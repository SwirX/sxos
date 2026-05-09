local args = { ... }
if #args < 2 then
    print("Usage:")
    print("  pastebin put <file>")
    print("  pastebin get <code> <file>")
    print("  pastebin run <code>")
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

local command = args[1]

if command == "put" then
    local path = shell.resolve(args[2])
    if not fs.exists(path) then
        printError("File not found.")
        return
    end
    local f = fs.open(path, "r")
    if not f then
        printError("Failed to open file."); return
    end
    local data = f.readAll()
    f.close()

    print("Connecting to pastebin.com...")
    local key = "0rZ94E2z" -- Standard CC pastebin key
    local requestBody = "api_option=paste&api_dev_key=" ..
        textutils.urlEncode(key) ..
        "&api_paste_format=lua&api_paste_name=" ..
        textutils.urlEncode(fs.getName(path)) .. "&api_paste_code=" .. textutils.urlEncode(data)

    local res = http.post("https://pastebin.com/api/api_post.php", requestBody)
    if res then
        local responseBody = res.readAll()
        res.close()
        local pasteCode = string.match(responseBody, "^https?://pastebin.com/(.+)$")
        if pasteCode then
            print("Success! Uploaded to:")
            print(responseBody)
        else
            printError("Upload failed: " .. responseBody)
        end
    else
        printError("Failed to connect to pastebin.com")
    end
elseif command == "get" or command == "run" then
    local code = args[2]

    local paste = string.match(code, "[a-zA-Z0-9]+$")
    if not paste then
        printError("Invalid paste code")
        return
    end

    print("Connecting to pastebin.com...")
    local res = http.get("https://pastebin.com/raw/" .. textutils.urlEncode(paste))
    if not res then
        printError("Failed to download.")
        return
    end
    local data = res.readAll()
    res.close()

    if command == "get" then
        if #args < 3 then
            print("Usage: pastebin get <code> <file>")
            return
        end
        local path = shell.resolve(args[3])
        local f = fs.open(path, "w")
        if not f then
            printError("Failed to open file for writing."); return
        end
        f.write(data)
        f.close()
        print("Downloaded as " .. args[3])
    else
        if not check_security() then return end
        local func, err = load(data, "pastebin", "t", _ENV)
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
    end
else
    print("Usage:")
    print("  pastebin put <file>")
    print("  pastebin get <code> <file>")
    print("  pastebin run <code>")
end
