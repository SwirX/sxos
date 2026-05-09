local args = { ... }
if #args < 2 then
    printError("chown: usage: chown user[:group] file")
    return
end

local vfs = _ENV.sx_perms
if not vfs then
    printError("chown: vfs disabled via installer config"); return
end
local newOwner = args[1]
local path = shell.resolve(args[2])

local current = vfs.getPermissions()[path] or { mode = "rwxr-xr-x", group = "admin" }

local parts = {}
for part in string.gmatch(newOwner, "[^:]+") do table.insert(parts, part) end

vfs.setPermission(path, parts[1], parts[2] or current.group, current.mode)
print("Updated ownership for " .. path)
