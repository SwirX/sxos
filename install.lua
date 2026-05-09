-- SXOS Installation Selector

local filesToDownload = {
    -- Root
    "/startup.lua",
    "/README.md",

    -- Installer selectors
    "/installers/easy.lua",
    "/installers/advanced.lua",

    -- Bootloader
    "/boot/loader.lua",

    -- System skeleton
    "/etc/skel/config/sxboot/config.lua",

    -- Kernel and core sys modules
    "/sys/kernel.lua",
    "/sys/env.lua",
    "/sys/auth.lua",

    -- Core libraries
    "/lib/core/log.lua",
    "/lib/core/env.lua",
    "/lib/core/events.lua",
    "/lib/core/process.lua",
    "/lib/core/service.lua",
    "/lib/core/sx.lua",

    -- Filesystem libraries
    "/lib/fs/vfs.lua",
    "/lib/fs/path.lua",
    "/lib/fs/permissions.lua",

    -- Shell libraries
    "/lib/sh/builtins.lua",
    "/lib/sh/completion.lua",
    "/lib/sh/execute.lua",
    "/lib/sh/expand.lua",
    "/lib/sh/parser.lua",
    "/lib/sh/tokenizer.lua",

    -- Network libraries
    "/lib/net/discovery.lua",
    "/lib/net/rednet.lua",

    -- Package manager libraries
    "/lib/pkg/database.lua",
    "/lib/pkg/manifest.lua",
    "/lib/pkg/resolve.lua",

    -- SX config + VFS shim
    "/lib/sx/config.lua",
    "/lib/sx/vfs.lua",

    -- UI library
    "/lib/ui/theme.lua",

    -- Services
    "/services/discoverd.lua",

    -- Core binaries
    "/bin/bsh.lua",
    "/bin/cat.lua",
    "/bin/cd.lua",
    "/bin/chmod.lua",
    "/bin/chown.lua",
    "/bin/clear.lua",
    "/bin/cp.lua",
    "/bin/curl.lua",
    "/bin/discover.lua",
    "/bin/echo.lua",
    "/bin/env.lua",
    "/bin/find.lua",
    "/bin/git.lua",
    "/bin/grep.lua",
    "/bin/help.lua",
    "/bin/jobs.lua",
    "/bin/kill.lua",
    "/bin/ln.lua",
    "/bin/ls.lua",
    "/bin/lua.lua",
    "/bin/mkcd.lua",
    "/bin/mkdir.lua",
    "/bin/mount.lua",
    "/bin/mv.lua",
    "/bin/netstat.lua",
    "/bin/ping.lua",
    "/bin/printf.lua",
    "/bin/ps.lua",
    "/bin/pwd.lua",
    "/bin/reboot.lua",
    "/bin/rm.lua",
    "/bin/shutdown.lua",
    "/bin/sxpm.lua",
    "/bin/touch.lua",
    "/bin/umount.lua",
    "/bin/wget.lua",
    "/bin/which.lua",

    -- User binaries
    "/usr/bin/sxfetch.lua",
    "/usr/bin/yafe.lua",
    "/usr/bin/yate.lua",
}


term.clear()
term.setCursorPos(1, 1)
print("Welcome to the SXOS Live Environment")

write("Do you want to download SXOS files from GitHub? (y/n) ")
if read() == "y" then
    print("\nSelect deploy branch:")
    print("1. dev (Default)")
    print("2. main")
    write("Branch [1]: ")
    local branchChoice = read()
    local branch = "dev"
    if branchChoice == "2" or string.lower(branchChoice) == "main" then
        branch = "main"
    end
    local repoBase = "https://raw.githubusercontent.com/SwirX/ComputerCraft/" .. branch .. "/sxos"

    print("\nDownloading core system files...")
    for i, path in ipairs(filesToDownload) do
        local url = repoBase .. path
        local cx, cy = term.getCursorPos()
        term.setCursorPos(1, cy)
        term.clearLine()
        term.setTextColor(colors.gray)
        write("Downloading (" .. i .. "/" .. #filesToDownload .. "): " .. fs.getName(path))

        local res = http.get(url)
        if res then
            local data = res.readAll()
            res.close()

            local fullPath = string.sub(path, 2) -- remove leading slash for CC combine logic safety
            local dir = fs.getDir(fullPath)
            if dir and dir ~= "" and dir ~= ".." and not fs.exists(dir) then
                fs.makeDir(dir)
            end

            local f = fs.open(fullPath, "w")
            if f then
                f.write(data)
                f.close()
            else
                printError("\nFailed to write " .. fullPath)
            end
        else
            printError("\nFailed to download: " .. path)
        end
    end
    print("\n\nDownload complete!")
    term.setTextColor(colors.white)
    sleep(1)
end

term.clear()
term.setCursorPos(1, 1)
print("Welcome to the SXOS Live Environment")
print("Please select an installation mode:\n")

local w, h = term.getSize()
local options = {
    "1. Easy Install (Guided setup for beginners)",
    "2. Advanced Install (Minimal TTY for manual setup)"
}
local selected = 1

local function drawMenu()
    for i, opt in ipairs(options) do
        term.setCursorPos(2, math.floor(h / 2) + i)
        if i == selected then
            term.setTextColor(colors.black)
            term.setBackgroundColor(colors.white)
            term.write(opt)
        else
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
            term.write(opt)
        end
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

drawMenu()
while true do
    local event, key = os.pullEvent("key")
    if key == keys.up then
        selected = selected - 1
        if selected < 1 then selected = #options end
        drawMenu()
    elseif key == keys.down then
        selected = selected + 1
        if selected > #options then selected = 1 end
        drawMenu()
    elseif key == keys.enter then
        break
    end
end

term.clear()
term.setCursorPos(1, 1)

if selected == 1 then
    shell.run("installers/easy.lua")
elseif selected == 2 then
    shell.run("installers/advanced.lua")
end
