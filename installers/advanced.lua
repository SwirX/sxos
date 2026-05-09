print("SXOS Advanced Installer")
print("-----------------------")
print("You have requested a fully manual installation.")
print("The prompt will now drop you into an unrestrained root shell.")
print("You must manually build the directory skeleton, config files, and reboot.\n")
print("Walkthrough of SXOS tools available in this environment:")
print(" - Use 'mkdir' and 'touch' to lay out your filesystem.")
print(" - Use 'yate <file>' to edit /etc/sxos/config.lua and /etc/sxos/users.")
print(" - Configuration syntax is standard Lua serialization.")
print("Type `reboot` to finalize setup when done.\n")

if not fs.exists("/bin/bsh.lua") then
    printError("Live environment missing /bin/bsh.lua framework.")
    return
end

local ok, sys_env = pcall(dofile, "/sys/env.lua")
if not ok or not sys_env then
    printError("Failed to load /sys/env.lua: " .. tostring(sys_env))
    return
end
local process_env = sys_env.create_process_env(_G, {
    PATH = "/bin;/usr/bin",
    HOME = "/root",
    USER = "root"
})

process_env.INSTALLER_MODE = true
local bsh, berr = loadfile("/bin/bsh.lua", nil, process_env)
if bsh then
    bsh()
else
    printError("Failed to start shell: " .. tostring(berr))
end
