local args = { ... }
local targetDir = args[1] or "."
local pwd = (_ENV.ENV and _ENV.ENV.PWD) or "/"
local rootPath = string.sub(targetDir, 1, 1) == "/" and targetDir or ("/" .. fs.combine(pwd, targetDir))
local namePattern = nil

for i = 1, #args do
    if args[i] == "-name" and args[i + 1] then
        namePattern = args[i + 1]
        namePattern = string.gsub(namePattern, "%.", "%%.")
        namePattern = string.gsub(namePattern, "%*", ".*")
        namePattern = "^" .. namePattern .. "$"
    end
end

local function crawl(dir)
    if not fs.isDir(dir) then return end
    for _, f in ipairs(fs.list(dir)) do
        local p = fs.combine(dir, f)
        if not namePattern or string.find(f, namePattern) then
            print("/" .. p)
        end
        if fs.isDir(p) then crawl(p) end
    end
end

if fs.exists(rootPath) then
    if not namePattern then print("/" .. rootPath) end
    crawl(rootPath)
else
    printError("find: '" .. rootPath .. "': No such file or directory")
end
