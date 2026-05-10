-- /sys/kernel.lua
-- SXOS Kernel: Stages 2-6 of the boot sequence.
-- Stage 2: Load core libraries and initialize the event router.
-- Stage 3: Mount virtual filesystems (/dev, /net) via the VFS layer.
-- Stage 4: Start background services (discoverd).
-- Stage 5: Authenticate the user via the auth module.
-- Stage 6: Spawn the shell process and drive the main event loop.

local function load_lib(path)
    local chunk, err = loadfile(path)
    if not chunk then
        error("Kernel: failed to load " .. path .. ": " .. tostring(err), 0)
    end
    return chunk()
end

-- Stage 2: Core library initialization.
local log     = load_lib("/lib/core/log.lua")
local env_lib = load_lib("/lib/core/env.lua")
local events  = load_lib("/lib/core/events.lua")
local device  = load_lib("/lib/core/device.lua")
local proc    = load_lib("/lib/core/process.lua")
local svc     = load_lib("/lib/core/service.lua")
local vfs     = load_lib("/lib/fs/vfs.lua")
local auth    = load_lib("/sys/auth.lua")

-- Initialize device registry immediately tracking peripherals
device.init(events)

log.info("kernel", "Stage 2 complete: core libraries loaded")

-- Stage 3: Mount virtual filesystems.
vfs.mount_builtin_drivers(device)
log.info("kernel", "Stage 3 complete: VFS mounted")

-- Process fstab auto-mounts
local fstab_path = "/etc/sxos/fstab.lua"
if fs.exists(fstab_path) then
    local ok, fstab = pcall(load_lib, fstab_path)
    if ok and fstab.auto_mount and fstab.devices then
        for _, entry in ipairs(fstab.devices) do
            for _, dev in pairs(device.get_all()) do
                if dev.type == entry.peripheral and not dev.mounted then
                    device.mount(dev.id, entry.path)
                    break
                end
            end
        end
        log.info("kernel", "Stage 3.5: Processed " .. tostring(#fstab.devices) .. " fstab device mounts")
    end
end

-- Stage 4: Start background services.
-- discoverd makes this host visible on the network to other SXOS machines.
local discoverd_path = "/services/discoverd.lua"
if fs.exists(discoverd_path) then
    local discovery_lib = load_lib("/lib/net/discovery.lua")
    local discoverd_pid = proc.spawn(function()
        discovery_lib.run_responder()
    end, { name = "discoverd", cwd = "/" })
    svc.register("discoverd", discoverd_pid, {})
    log.info("kernel", "Stage 4: discoverd started (pid=" .. discoverd_pid .. ")")
else
    log.warn("kernel", "Stage 4: discoverd not found, skipping")
end

log.info("kernel", "Stage 4 complete: services up")

-- Stage 5: Login and user resolution.
local username, userinfo = auth.do_login()
if not userinfo then
    log.fatal("kernel", "Stage 5: login failed for '" .. tostring(username) .. "'")
end
log.info("kernel", "Stage 5 complete: user=" .. username)

-- Stage 6: Build the shell process environment and launch bsh.
local system_config      = auth.read_config()

local shell_env          = env_lib.create_process_env(_ENV, {
    PATH     = "/bin:/usr/bin",
    HOME     = userinfo.home,
    USER     = username,
    SHELL    = userinfo.shell or "/bin/bsh.lua",
    TERM     = "sxos",
    PWD      = userinfo.home,
    HOSTNAME = os.getComputerLabel() or ("sxos-" .. os.getComputerID()),
})
shell_env.INSTALLER_MODE = system_config.installer_shell or false

-- Extend Lua module search path so sxpm-installed packages are requireable.
-- Format: /lib/?.lua;/lib/?/init.lua plus per-package subdirs.
local LIB_PATHS          = {
    "/lib/?.lua",
    "/lib/?/init.lua",
    "/lib/sxui/?.lua",
    "/lib/sxmusic/?.lua",
    "/lib/core/?.lua",
    "/lib/fs/?.lua",
    "/lib/sh/?.lua",
    "/lib/net/?.lua",
    "/lib/sx/?.lua",
    "/lib/ui/?.lua",
    "/usr/lib/?.lua",
}
-- Prepend our paths; keep whatever CraftOS already has at the end.
local base_path          = package and package.path or ""
shell_env.package        = shell_env.package or {}
shell_env.package.path   = table.concat(LIB_PATHS, ";") .. (base_path ~= "" and (";" .. base_path) or "")

-- Inject the sx.* API surface and the VFS into the shell environment.
-- Binaries get sx by loading /lib/core/sx.lua from their own code.
-- The shell itself gets direct references for performance.
shell_env.sx_vfs         = vfs
shell_env.sx_proc        = proc
shell_env.sx_events      = events
shell_env.sx_service     = svc
shell_env.sx_log         = log
shell_env.peripheral     = load_lib("/lib/compat/peripheral.lua")

if system_config.enable_vfs then
    local sx_perms = load_lib("/lib/sx/vfs.lua")
    sx_perms.init()
    shell_env.fs = sx_perms.create_fs(username)
    shell_env.sx_perms = sx_perms
end

local shell_path = userinfo.shell or "/bin/bsh.lua"
if not fs.exists(shell_path) then
    log.fatal("kernel", "Stage 6: shell not found: " .. shell_path)
end

local shell_fn, load_err = loadfile(shell_path, "t", shell_env)
if not shell_fn then
    log.fatal("kernel", "Stage 6: failed to load shell: " .. tostring(load_err))
end

log.info("kernel", "Stage 6: launching shell")

term.setBackgroundColor(colors.black)
term.setTextColor(colors.lightGray)
term.clear()
term.setCursorPos(1, 1)

-- Main kernel event loop.
-- The kernel owns os.pullEvent and dispatches each event to:
--   1. The event router (for all subscribers)
--   2. The process scheduler (for all coroutines)
while true do
    -- Spawn the shell as a tracked process.
    local shell_pid = proc.spawn(shell_fn, {
        name = "bsh",
        env  = shell_env,
        cwd  = userinfo.home,
    })

    log.info("kernel", "Shell started with pid=" .. shell_pid)

    while proc.get(shell_pid) do
        local event_packet = table.pack(os.pullEventRaw())
        events.dispatch(event_packet)
        proc.tick(event_packet)
    end

    log.warn("kernel", "Shell process died unexpectedly.")
    printError("\n[KERNEL PANIC] Shell process terminated!")
    printError("Re-launching shell in 3 seconds. Press Ctrl+T to abort and reboot.")

    local timer = os.startTimer(3)
    local abort = false
    while true do
        local e, p1 = os.pullEventRaw()
        if e == "timer" and p1 == timer then
            break
        elseif e == "terminate" then
            abort = true
            break
        end
        -- Keep ticking other processes
        local packet = table.pack(e, p1)
        events.dispatch(packet)
        proc.tick(packet)
    end

    if abort then
        break
    end
    -- Otherwise, loops back and respawns
end

printError("\n[KERNEL] System halted. Rebooting...")
os.sleep(1)
os.reboot()
