-- SXOS Installer
-- Downloads sxpm, then uses it to install the sxos-core package.
-- After installation, subsequent upgrades work via: sxpm upgrade sxos-core

local SXPM_BOOTSTRAP_URL = "https://raw.githubusercontent.com/SwirX/sxpm/stable/src/bin/sxpm.lua"
local SXPM_LIBS = {
    ["lib/pkg/manifest.lua"] = "https://raw.githubusercontent.com/SwirX/sxpm/stable/src/lib/pkg/manifest.lua",
    ["lib/pkg/database.lua"] = "https://raw.githubusercontent.com/SwirX/sxpm/stable/src/lib/pkg/database.lua",
    ["lib/pkg/resolve.lua"]  = "https://raw.githubusercontent.com/SwirX/sxpm/stable/src/lib/pkg/resolve.lua",
    ["lib/pkg/archive.lua"]  = "https://raw.githubusercontent.com/SwirX/sxpm/stable/src/lib/pkg/archive.lua",
}
local REPO_INDEX_URL = "https://raw.githubusercontent.com/SwirX/sxpm-repo/stable/index.json"

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

print("Select channel:")
print("  1. stable (recommended)")
print("  2. dev (latest development build)")
write("Channel [1]: ")
local channel_input = read()
local channel = "stable"
if channel_input == "2" or channel_input == "dev" then
    channel = "dev"
end

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
    if ok then print("ok") else
        print("FAILED"); printError(err); return
    end
end

-- -----------------------------------------------------------------------
-- Step 2: Seed the repo index so sxpm knows where to pull sxos-core from
-- -----------------------------------------------------------------------

print("")
print("-- Seeding repository index --")

ok, err = download(REPO_INDEX_URL, "/var/cache/sxpm/index_stable.json")
if not ok then
    printError(err); return
end
print("Repository index cached.")

-- -----------------------------------------------------------------------
-- Step 3: Install sxos-core via sxpm
-- -----------------------------------------------------------------------

print("")
print("-- Installing sxos-core --")
shell.run("/bin/sxpm.lua", "install", "sxos-core")

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
    shell.run("installers/easy.lua")
else
    shell.run("installers/advanced.lua")
end
