print("SXOS Easy Installer")
print("-------------------")
write("\nEnter new username: ")
local username = read()

write("Enter password (leave blank for auto-login): ")
local password = read("*")

write("\nEnter computer hostname (default: sxos): ")
local host = read()
if host == "" then host = "sxos" end

write("\nEnable Virtual Filesystem (VFS) to enforce file permissions/ownership system-wide? (y/n) [y]: ")
local vfsChoice = read()
local enableVFS = (vfsChoice == "" or vfsChoice:lower() == "y")

print("\nCreating directories...")
local dirs = { "/bin", "/etc", "/home", "/lib", "/root", "/tmp", "/usr/bin", "/usr/lib", "/var", "/.config", "/etc/sxpm",
    "/var/lib/sxpm", "/var/cache/sxpm", "/usr/lib/sxpm" }
for _, dir in ipairs(dirs) do
    if not fs.exists(dir) then fs.makeDir(dir) end
end

print("Setting up user space...")
fs.makeDir("/home/" .. username)

local shadow = {}
local users = {}
local autoLogin = false

users[username] = {
    home = "/home/" .. username,
    shell = "/bin/bsh.lua",
    groups = { "admin", "users" }
}

if password == "" then
    autoLogin = true
    shadow[username] = ""
else
    shadow[username] = password
end

local function saveFile(path, data)
    local f = fs.open(path, "w")
    f.write(textutils.serialize(data))
    f.close()
end

if not fs.exists("/etc/sxos") then fs.makeDir("/etc/sxos") end
saveFile("/etc/sxos/shadow", shadow)
saveFile("/etc/sxos/users", users)

local config = {
    autologin = autoLogin,
    autologin_user = autoLogin and username or nil,
    installed = true,
    enable_vfs = enableVFS
}
saveFile("/etc/sxos/config.lua", config)

print("\n------------------------------")
print("INSTALLATION COMPLETE")
print("------------------------------")
print("Welcome to SXOS!")
print("Here is a quick walkthrough of your new system:")
print(" - bsh: Your shell features tab completion and colorized syntax.")
print(" - yate <file>: Yet Another Text Editor, for basic file editing.")
print(" - yafe: Terminal-based interface for exploring your drives.")
print(" - sxfetch: Display your current system and user info.")
print(" - sxpm: Use the package manager to install stable, testing, or nightly packages.")
print("Configurations automatically save to ~/.config/<app>.")
print("\nPress any key to reboot and enter your new system.")
os.pullEvent("key")

os.setComputerLabel(host)
os.reboot()
