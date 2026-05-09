-- /lib/sx/vfs.lua
local _M = {}
local native_fs = fs

local mounts = {}
local symlinks = {}
local perms = {}

local function persistData(file, data)
    local f = native_fs.open(file, "w")
    if f then
        f.write(textutils.serialize(data)); f.close()
    end
end

local function loadData(file)
    if native_fs.exists(file) then
        local f = native_fs.open(file, "r")
        if f then
            local data = textutils.unserialize(f.readAll())
            f.close()
            return data or {}
        end
    end
    return {}
end

function _M.init()
    if not native_fs.exists("/etc/sxos") then native_fs.makeDir("/etc/sxos") end
    mounts = loadData("/etc/sxos/mounts.lua")
    symlinks = loadData("/etc/sxos/symlinks.lua")
    perms = loadData("/etc/sxos/permissions.lua")
end

function _M.save()
    persistData("/etc/sxos/mounts.lua", mounts)
    persistData("/etc/sxos/symlinks.lua", symlinks)
    persistData("/etc/sxos/permissions.lua", perms)
end

function _M.getMounts() return mounts end

function _M.setMount(path, target)
    mounts[native_fs.combine("", path)] = target; _M.save()
end

function _M.clearMount(path)
    mounts[native_fs.combine("", path)] = nil; _M.save()
end

function _M.getSymlinks() return symlinks end

function _M.setSymlink(path, target)
    symlinks[native_fs.combine("", path)] = target; _M.save()
end

function _M.clearSymlink(path)
    symlinks[native_fs.combine("", path)] = nil; _M.save()
end

function _M.getPermissions() return perms end

function _M.setPermission(path, owner, group, mode)
    perms[native_fs.combine("", path)] = { owner = owner, group = group, mode = mode }
    _M.save()
end

local function resolveNode(path)
    path = native_fs.combine("", path)
    local current = path
    local jumps = 0
    while symlinks[current] and jumps < 20 do
        current = symlinks[current]
        jumps = jumps + 1
    end
    if jumps >= 20 then error("SXOS VFS: Symbolic link loop detected at " .. path) end

    for mnt, target in pairs(mounts) do
        if current == mnt or string.sub(current, 1, #mnt + 1) == mnt .. "/" then
            return true, target .. string.sub(current, #mnt + 1)
        end
    end
    return false, current
end

function _M.canAccess(path, reqMode, user)
    if user == "root" then return true end
    path = native_fs.combine("", path)

    local matchedPerm = nil
    local matchLen = -1
    for p, perm in pairs(perms) do
        if p == path or string.sub(path, 1, #p + 1) == p .. "/" then
            if #p > matchLen then
                matchLen = #p
                matchedPerm = perm
            end
        end
    end

    if not matchedPerm then return true end -- Fail open for unspecified

    local r, w, x = false, false, false
    if matchedPerm.owner == user then
        r = string.sub(matchedPerm.mode, 1, 1) == "r"
        w = string.sub(matchedPerm.mode, 2, 2) == "w"
        x = string.sub(matchedPerm.mode, 3, 3) == "x"
    else
        r = string.sub(matchedPerm.mode, 7, 7) == "r"
        w = string.sub(matchedPerm.mode, 8, 8) == "w"
        x = string.sub(matchedPerm.mode, 9, 9) == "x"
    end

    if reqMode == "r" then return r end
    if reqMode == "w" then return w end
    if reqMode == "x" then return x end
    return false
end

function _M.create_fs(user)
    local vfs = {}
    for k, v in pairs(native_fs) do vfs[k] = v end

    local function wrap1(name, reqMode)
        return function(path, ...)
            local isMnt, resolved = resolveNode(path)
            if isMnt then if reqMode == "w" then error("VFS Mount target is read-only logic layer") end end
            if not _M.canAccess(resolved, reqMode, user) then error("Permission denied") end
            return native_fs[name](resolved, ...)
        end
    end

    local function wrap1_no_err(name, reqMode)
        return function(path, ...)
            local isMnt, resolved = resolveNode(path)
            if not isMnt and not _M.canAccess(resolved, reqMode, user) then return false end
            return native_fs[name](resolved, ...)
        end
    end

    local function wrap2(name, rmode1, rmode2)
        return function(p1, p2, ...)
            local m1, r1 = resolveNode(p1)
            local m2, r2 = resolveNode(p2)
            if m1 or m2 then error("VFS Mount target cross-IO restriction") end
            if not _M.canAccess(r1, rmode1, user) then error("Permission denied") end
            if not _M.canAccess(r2, rmode2, user) then error("Permission denied") end
            return native_fs[name](r1, r2, ...)
        end
    end

    vfs.list = wrap1("list", "r")
    vfs.exists = wrap1_no_err("exists", "r")
    vfs.isDir = wrap1_no_err("isDir", "r")
    vfs.isReadOnly = wrap1_no_err("isReadOnly", "w")
    vfs.getName = function(p)
        local _, r = resolveNode(p); return native_fs.getName(r)
    end
    vfs.getDrive = wrap1_no_err("getDrive", "r")
    vfs.getSize = wrap1_no_err("getSize", "r")
    vfs.getFreeSpace = wrap1_no_err("getFreeSpace", "r")
    vfs.makeDir = wrap1("makeDir", "w")
    vfs.move = wrap2("move", "w", "w")
    vfs.copy = wrap2("copy", "r", "w")
    vfs.delete = wrap1("delete", "w")
    vfs.combine = native_fs.combine
    vfs.find = wrap1("find", "r")
    vfs.getDir = function(p)
        local _, r = resolveNode(p); return native_fs.getDir(r)
    end
    vfs.capacity = wrap1_no_err("capacity", "r")
    vfs.attributes = wrap1("attributes", "r")

    vfs.open = function(path, mode)
        local isMnt, resolved = resolveNode(path)
        if isMnt then return nil, "VFS Mount targets unsupported natively" end
        local reqMode = (mode == "r" or mode == "rb") and "r" or "w"
        if not _M.canAccess(resolved, reqMode, user) then return nil, "Permission denied" end
        return native_fs.open(resolved, mode)
    end

    return vfs
end

return _M
