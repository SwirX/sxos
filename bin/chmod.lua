local args = { ... }
if #args < 2 then
    printError("chmod: usage: chmod 777 file")
    return
end

local vfs = _ENV.sx_perms
if not vfs then
    printError("chmod: vfs disabled via installer config"); return
end
local mode = args[1]
local path = shell.resolve(args[2])

-- Basic helper: roughly converting typical 3-digit octal to string rwxrwxrwx
local function convertOctal(octalStr)
    if #octalStr ~= 3 then return mode end -- fallback to raw string if they passed 'rwxrwxrwx'
    local res = ""
    for i = 1, 3 do
        local n = tonumber(string.sub(octalStr, i, i))
        if not n then return mode end
        res = res .. ((n >= 4) and "r" or "-")
        n = n % 4
        res = res .. ((n >= 2) and "w" or "-")
        n = n % 2
        res = res .. ((n >= 1) and "x" or "-")
    end
    return res
end

local finalMode = convertOctal(mode)

local current = vfs.getPermissions()[path] or { owner = "root", group = "admin" }
vfs.setPermission(path, current.owner, current.group, finalMode)
print("Updated permissions for " .. path)
