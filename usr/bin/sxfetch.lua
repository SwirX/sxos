local w, h = term.getSize()
local host = "sxos"
local user = _ENV.ENV and _ENV.ENV.USER or "root"
local shellPath = "/bin/bsh"

local lines = {
    user .. "@" .. host,
    "---------------",
    "OS: SXOS 1.0",
    "Kernel: SX Kernel",
    "Uptime: " .. math.floor(os.clock()) .. "s",
    "Shell: " .. shellPath,
    "Resolution: " .. w .. "x" .. h,
    "Lua Version: " .. _VERSION
}

local logo = {
    "     .--------.     ",
    "    /  .----.  \\    ",
    "    |  |    |  |    ",
    "    |  '----'  |    ",
    "    '--------'      "
}

print()
for i = 1, math.max(#logo, #lines) do
    term.setTextColor(colors.cyan)
    if i <= #logo then
        write(logo[i])
    else
        write(string.rep(" ", #logo[1] or 20))
    end

    term.setTextColor(colors.white)
    if i <= #lines then
        if i == 1 then term.setTextColor(colors.yellow) end
        write(lines[i])
    end
    print()
end
print()
term.setTextColor(colors.white)
