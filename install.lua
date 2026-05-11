-- SXOS Installer
-- Downloads sxpm, then uses it to install the sxos-core package.
-- After installation, subsequent upgrades work via: sxpm upgrade sxos-core

-- -----------------------------------------------------------------------
-- Minimal download helper with progress indicator
-- -----------------------------------------------------------------------

local function download(url, dest_path)
    local res = http.get(url)
    if not res then return false, "HTTP GET failed: " .. url end
    local data = res.readAll()
    res.close()

    local dir = fs.getDir(dest_path)
    if dir ~= "" and not fs.exists(dir) then fs.makeDir(dir) end

    local f = fs.open(dest_path, "w")
    if not f then return false, "Cannot write: " .. dest_path end
    f.write(data)
    f.close()
    return true
end

-- -----------------------------------------------------------------------
-- Branch selection
-- -----------------------------------------------------------------------

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.white)
print("SXOS Installer")
print("Installs the SXOS operating system via sxpm.")
print("")

print("Select sxpm branch:")
print("  1. stable (recommended)")
print("  2. dev (latest development build)")
write("sxpm Branch [1]: ")
local sxpm_input = read()
local sxpm_branch = "stable"
if sxpm_input == "2" or sxpm_input == "dev" then
    sxpm_branch = "dev"
end

print("")
print("Select sxos branch:")
print("  1. stable (recommended)")
print("  2. dev (latest development build)")
write("sxos Branch [1]: ")
local sxos_input = read()
local sxos_branch = "stable"
if sxos_input == "2" or sxos_input == "dev" then
    sxos_branch = "dev"
end

print("")
write("Format entire computer before installation? (y/n) [n]: ")
local format_input = read()
local do_format = (format_input == "y" or format_input == "Y")

if do_format then
    print("\nFormatting...")
    for _, file in ipairs(fs.list("/")) do
        if file ~= "install.lua" and file ~= "sxpm" then
            shell.run("rm", file)
        end
    end
else
    print("\nPreserving root files...")
    if not fs.exists("/.old_root") then fs.makeDir("/.old_root") end
    for _, file in ipairs(fs.list("/")) do
        if file ~= "install.lua" and file ~= "sxpm" and file ~= "rom" and file ~= ".old_root" then
            pcall(fs.move, "/" .. file, "/.old_root/" .. file)
        end
    end
end

-- Setup URLs based on channels
local SXPM_BOOTSTRAP_URL   = "https://raw.githubusercontent.com/SwirX/sxpm/" .. sxpm_branch .. "/src/bin/sxpm.lua"
local SXPM_LIBS            = {
    ["lib/pkg/manifest.lua"] = "https://raw.githubusercontent.com/SwirX/sxpm/" ..
        sxpm_branch .. "/src/lib/pkg/manifest.lua",
    ["lib/pkg/database.lua"] = "https://raw.githubusercontent.com/SwirX/sxpm/" ..
        sxpm_branch .. "/src/lib/pkg/database.lua",
    ["lib/pkg/resolve.lua"]  = "https://raw.githubusercontent.com/SwirX/sxpm/" ..
        sxpm_branch .. "/src/lib/pkg/resolve.lua",
    ["lib/pkg/archive.lua"]  = "https://raw.githubusercontent.com/SwirX/sxpm/" ..
        sxpm_branch .. "/src/lib/pkg/archive.lua",
}
local REPO_INDEX_URL       = "https://raw.githubusercontent.com/SwirX/sxpm-repo/" .. sxos_branch .. "/index.json"
local EASY_INSTALL_URL     = "https://raw.githubusercontent.com/SwirX/sxos/" .. sxos_branch .. "/installers/easy.lua"
local ADVANCED_INSTALL_URL = "https://raw.githubusercontent.com/SwirX/sxos/" .. sxos_branch .. "/installers/advanced.lua"


-- -----------------------------------------------------------------------
-- Step 1: Bootstrap sxpm
-- -----------------------------------------------------------------------

print("")
print("-- Bootstrapping sxpm --")

local ok, err

print("Downloading sxpm...")
ok, err = download(SXPM_BOOTSTRAP_URL, "/bin/sxpm.lua")
if not ok then
    printError(err); return
end

for dest, url in pairs(SXPM_LIBS) do
    write("  " .. dest .. "... ")
    ok, err = download(url, "/" .. dest)
    if ok then
        print("ok")
    else
        print("FAILED"); printError(err); return
    end
end

-- -----------------------------------------------------------------------
-- Step 2: Seed the repo index so sxpm knows where to pull sxos-core from
-- -----------------------------------------------------------------------

print("")
print("-- Seeding repository index --")

ok, err = download(REPO_INDEX_URL, "/var/cache/sxpm/index_" .. sxos_branch .. ".json")
if not ok then
    printError(err); return
end
print("Repository index cached.")

-- -----------------------------------------------------------------------
-- Step 3: Install sxos-core via sxpm
-- -----------------------------------------------------------------------

print("")
print("-- Installing sxos-core --")

-- Clear any existing package DB so we can definitively check if install succeeded
if fs.exists("/var/lib/sxpm/installed.db") then
    fs.delete("/var/lib/sxpm/installed.db")
end

shell.run("/bin/sxpm.lua", "install", "sxos-core")

local success = false
if fs.exists("/var/lib/sxpm/installed.db") then
    local f = fs.open("/var/lib/sxpm/installed.db", "r")
    if f then
        local db = textutils.unserialize(f.readAll() or "")
        if db and db["sxos-core"] then success = true end
        f.close()
    end
end

if not success then
    printError("\n[FATAL] sxos-core failed to install.")
    print("Please review the error messages above.")
    print("Press any key to abort...")
    os.pullEvent("key")
    return
end

-- -----------------------------------------------------------------------
-- Step 4: Download Setup Scripts
-- -----------------------------------------------------------------------

print("")
print("Fetching setup scripts...")
ok, err = download(EASY_INSTALL_URL, "/installers/easy.lua")
if not ok then
    printError("Failed to fetch easy installer"); return
end

ok, err = download(ADVANCED_INSTALL_URL, "/installers/advanced.lua")
if not ok then
    printError("Failed to fetch advanced installer"); return
end

-- -----------------------------------------------------------------------
-- Post-install: Present installer menu for user setup
-- -----------------------------------------------------------------------

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.white)
print("SXOS core installed.")
print("")
print("Select setup mode:")
print("")

local w, h     = term.getSize()
local options  = {
    "1. Easy Install (guided setup)",
    "2. Advanced Install (TTY for manual setup)",
}
local selected = 1

local function draw_menu()
    for i, opt in ipairs(options) do
        term.setCursorPos(2, math.floor(h / 2) + i)
        if i == selected then
            term.setTextColor(colors.black)
            term.setBackgroundColor(colors.white)
        else
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
        end
        term.write(opt)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
    end
end

draw_menu()
while true do
    local event, key = os.pullEvent("key")
    if key == keys.up then
        selected = math.max(1, selected - 1)
        draw_menu()
    elseif key == keys.down then
        selected = math.min(#options, selected + 1)
        draw_menu()
    elseif key == keys.enter then
        break
    end
end

term.clear()
term.setCursorPos(1, 1)

if selected == 1 then
    shell.run("/installers/easy.lua")
else
    shell.run("/installers/advanced.lua")
end

-- Cleanup installer dir since they are one-time use
fs.delete("/installers")
