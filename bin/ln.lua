local args = { ... }
if #args < 3 or args[1] ~= "-s" then
    printError("ln: Expected: ln -s <target> <link_name>")
    return
end

local ok, vfs = pcall(require, "lib.sx.vfs")
if not ok then
    printError("ln: vfs disabled"); return
end

vfs.init()
-- We treat target string raw because symbolic links can point anywhere conceptually
local target = args[2]
local link = shell.resolve(args[3])

vfs.setSymlink(link, target)
print("Created symbolic link " .. link .. " -> " .. target)
