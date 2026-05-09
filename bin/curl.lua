local args = { ... }
if #args < 1 then
    print("Usage: curl <url>")
    return
end

local url = args[1]
if not string.find(url, "^https?://") then
    url = "http://" .. url
end
local res = http.get(url)
if res then
    print(res.readAll())
    res.close()
else
    printError("curl: (7) Failed to connect to host")
end
