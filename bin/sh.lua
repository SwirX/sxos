-- /bin/sh.lua
-- SXOS Minimal Native Shell App
-- Provided as a fallback when no standard shell (like bsh) is configured or accessible.

local _ENV = setmetatable({}, { __index = _ENV })
local shell_env = _ENV

while true do
    term.setTextColor(colors.green)
    write((shell_env.USER or "unknown") .. "@sxos")
    term.setTextColor(colors.white)
    write(":/$ ")

    local input = read()
    if input and input ~= "" then
        local words = {}
        for w in input:gmatch("%S+") do table.insert(words, w) end
        local prog = table.remove(words, 1)

        local resolved
        for _, path in ipairs({ "/bin/", "/usr/bin/", "" }) do
            for _, ext in ipairs({ ".lua", "" }) do
                local candidate = path .. prog .. ext
                if fs.exists(candidate) and not fs.isDir(candidate) then
                    resolved = candidate
                    break
                end
            end
            if resolved then break end
        end

        if resolved then
            local fn, err = loadfile(resolved, "t", _ENV)
            if fn then
                local ok, run_err = pcall(fn, table.unpack(words))
                if not ok and run_err then printError(run_err) end
            else
                printError("Failed to load: " .. tostring(err))
            end
        else
            printError(prog .. ": command not found")
        end
    end
end
