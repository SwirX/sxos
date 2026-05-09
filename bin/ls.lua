local args = { ... }
local flags = {}
local targetDir = nil

for _, arg in ipairs(args) do
    if string.sub(arg, 1, 1) == "-" then
        for i = 2, #arg do flags[string.sub(arg, i, i)] = true end
    else
        targetDir = arg
    end
end

local tDir = targetDir or (_ENV.ENV and _ENV.ENV.PWD or "/")
local pwd = (_ENV.ENV and _ENV.ENV.PWD) or "/"
local p = string.sub(tDir, 1, 1) == "/" and tDir or ("/" .. fs.combine(pwd, tDir))

if not fs.exists(p) then
    printError("ls: cannot access '" .. tDir .. "': No such file or directory"); return
end
if not fs.isDir(p) then
    print(tDir); return
end

local files = fs.list(p)
table.sort(files)

local ok, vfs = pcall(require, "lib.sx.vfs")
local perms = {}
if ok then
    vfs.init(); perms = vfs.getPermissions()
end

for _, file in ipairs(files) do
    if flags["a"] or string.sub(file, 1, 1) ~= "." then
        local fp = fs.combine(p, file)
        if flags["l"] then
            local isDir = fs.isDir(fp) and "d" or "-"
            local perm = perms[fp] or { owner = "root", group = "admin", mode = "rwxr-xr-x" }
            local size = math.floor((fs.getSize(fp) or 0) / 1024) .. "K"
            local meta = isDir .. perm.mode .. " " .. perm.owner .. " " .. perm.group .. " " .. size
            write(meta .. " ")
        end

        if fs.isDir(fp) then
            term.setTextColor(colors.blue)
        else
            term.setTextColor(flags["l"] and colors.white or colors.white)
        end

        if flags["l"] then print(file) else write(file .. "  ") end
        term.setTextColor(colors.white)
    end
end
if not flags["l"] then print() end
term.setTextColor(colors.white)
