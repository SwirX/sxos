-- /lib/fs/vfs.lua
-- Virtual Filesystem layer for SXOS.
-- Provides a mount-point system that intercepts file operations at specific
-- path prefixes and dispatches them to registered backend drivers.
--
-- Mounts can represent:
--   devfs  - peripheral device nodes under /dev
--   netfs  - RPC-backed remote nodes under /net
--   ramfs  - in-memory scratch filesystems
--   real   - pass-through to CraftOS fs (the default for all other paths)
--
-- All binaries should call sx.fs.* (which delegates here) rather than
-- calling the CraftOS fs API directly, so that mounts are transparent.

local vfs         = {}

local path_module = dofile("/lib/fs/path.lua")
local log_module  = dofile("/lib/core/log.lua")

-- Mount table: ordered list of { prefix, driver }
-- Checked in registration order; first prefix match wins.
-- The real CraftOS fs is always the fallback.
local mounts      = {}

-- A driver is a table of functions mirroring the CraftOS fs API:
--   driver.open(path, mode)  -> file_handle | nil, err
--   driver.exists(path)      -> bool
--   driver.isDir(path)       -> bool
--   driver.list(path)        -> table | nil
--   driver.makeDir(path)
--   driver.delete(path)
--   driver.move(from, to)
--   driver.copy(from, to)
--   driver.getSize(path)     -> number
-- Drivers do not need to implement every method.
-- Missing methods fall through to the real fs.

function vfs.mount(prefix, driver)
    prefix = path_module.normalize(prefix)
    -- Check for duplicate before inserting.
    for _, entry in ipairs(mounts) do
        if entry.prefix == prefix then
            log_module.warn("vfs", "replacing existing mount at " .. prefix)
            entry.driver = driver
            return
        end
    end
    table.insert(mounts, { prefix = prefix, driver = driver })
    log_module.info("vfs", "mounted driver at " .. prefix)
end

function vfs.unmount(prefix)
    prefix = path_module.normalize(prefix)
    for index, entry in ipairs(mounts) do
        if entry.prefix == prefix then
            table.remove(mounts, index)
            log_module.info("vfs", "unmounted " .. prefix)
            return true
        end
    end
    return false
end

-- Resolve which driver handles a given path.
-- Returns the driver (or nil for real fs) and the path as seen by the driver.
local function resolve_driver(target_path)
    local normalized = path_module.normalize(target_path)
    for _, entry in ipairs(mounts) do
        local prefix = entry.prefix
        if normalized == prefix
            or string.sub(normalized, 1, #prefix + 1) == prefix .. "/"
        then
            return entry.driver, normalized
        end
    end
    return nil, normalized
end

-- File open: returns a CraftOS-compatible file handle.
function vfs.open(target_path, mode)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.open then
        return driver.open(resolved, mode)
    end
    return fs.open(resolved, mode)
end

function vfs.exists(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.exists then return driver.exists(resolved) end
    return fs.exists(resolved)
end

function vfs.isDir(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.isDir then return driver.isDir(resolved) end
    return fs.isDir(resolved)
end

function vfs.list(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.list then return driver.list(resolved) end
    if fs.exists(resolved) and fs.isDir(resolved) then return fs.list(resolved) end
    return nil
end

function vfs.makeDir(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.makeDir then return driver.makeDir(resolved) end
    fs.makeDir(resolved)
end

function vfs.delete(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.delete then return driver.delete(resolved) end
    fs.delete(resolved)
end

function vfs.move(source_path, dest_path)
    local driver, resolved_src = resolve_driver(source_path)
    if driver and driver.move then return driver.move(resolved_src, dest_path) end
    fs.move(resolved_src, dest_path)
end

function vfs.copy(source_path, dest_path)
    local driver, resolved_src = resolve_driver(source_path)
    if driver and driver.copy then return driver.copy(resolved_src, dest_path) end
    fs.copy(resolved_src, dest_path)
end

function vfs.getSize(target_path)
    local driver, resolved = resolve_driver(target_path)
    if driver and driver.getSize then return driver.getSize(resolved) end
    return fs.getSize(resolved)
end

-- -----------------------------------------------------------------------
-- devfs: peripheral device nodes under /dev
-- Accessing /dev/<name> returns a thin wrapper over peripheral.wrap(name).
-- The node name maps to a peripheral name by stripping the /dev/ prefix.
-- -----------------------------------------------------------------------
local devfs = {}

local function dev_peripheral_name(dev_path)
    -- /dev/speaker0 -> "speaker0"
    return string.match(dev_path, "^/dev/(.+)$")
end

function devfs.exists(dev_path)
    local pname = dev_peripheral_name(dev_path)
    if not pname then return pname == nil and dev_path == "/dev" end
    return peripheral.isPresent(pname)
end

function devfs.isDir(dev_path)
    return dev_path == "/dev"
end

function devfs.list(dev_path)
    if dev_path ~= "/dev" then return nil end
    return peripheral.getNames()
end

-- open() on a /dev node returns the peripheral API table directly,
-- wrapped in a table with the standard handle interface for reads/writes.
-- Callers should check for peripheral-specific methods via handle.native.
function devfs.open(dev_path, _mode)
    local pname = dev_peripheral_name(dev_path)
    if not pname then return nil, "cannot open /dev as a file" end
    local wrapped = peripheral.wrap(pname)
    if not wrapped then
        return nil, "device not present: " .. pname
    end
    -- Expose the peripheral API as the handle's native table.
    return { native = wrapped, close = function() end }
end

-- -----------------------------------------------------------------------
-- netfs: network-transparent nodes under /net
-- /net/<hostname>/<path>  resolves via service discovery + RPC transport.
-- The actual data flow goes through the networking library.
-- -----------------------------------------------------------------------
local netfs = {}

function netfs.exists(net_path)
    -- Lazily delegate to the net discovery layer.
    local ok, result = pcall(function()
        local net_module = dofile("/lib/net/rednet.lua")
        return net_module.stat(net_path) ~= nil
    end)
    return ok and result
end

function netfs.isDir(net_path)
    return net_path == "/net"
end

function netfs.list(net_path)
    if net_path == "/net" then
        local ok, result = pcall(function()
            local net_module = dofile("/lib/net/rednet.lua")
            return net_module.discover_hosts()
        end)
        return ok and result or {}
    end
    return {}
end

function netfs.open(net_path, mode)
    local net_module = dofile("/lib/net/rednet.lua")
    return net_module.open_remote(net_path, mode)
end

-- Mount devfs and netfs at their canonical prefixes.
-- This is called by the kernel at Stage 3 (Mounting).
function vfs.mount_builtin_drivers()
    vfs.mount("/dev", devfs)
    vfs.mount("/net", netfs)
    log_module.info("vfs", "built-in drivers mounted")
end

return vfs
