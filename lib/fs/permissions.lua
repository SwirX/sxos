-- /lib/fs/permissions.lua
-- API-layer permission enforcement for SXOS.
-- IMPORTANT: These permissions only apply within SXOS. Raw CraftOS fs calls
-- bypass this layer entirely. Security is sandbox-level, not kernel-level.
-- The system is designed to prevent accidental cross-user access, not
-- to prevent malicious code running inside CraftOS.

local permissions = {}

local log_module = dofile("/lib/core/log.lua")

-- Permission bits mirror simplified POSIX: owner_read, owner_write, exec
-- Stored as a flat metadata file alongside directories and key files.
-- Format in the metadata index: { path -> { owner, mode } }

local METADATA_PATH = "/var/lib/sxos/permissions.db"

local metadata_cache = nil

local function load_metadata()
    if metadata_cache then return metadata_cache end
    if fs.exists(METADATA_PATH) then
        local handle = fs.open(METADATA_PATH, "r")
        if handle then
            local raw = handle.readAll()
            handle.close()
            local parsed = textutils.unserialize(raw)
            metadata_cache = type(parsed) == "table" and parsed or {}
            return metadata_cache
        end
    end
    metadata_cache = {}
    return metadata_cache
end

local function save_metadata()
    local dir = "/var/lib/sxos"
    if not fs.exists(dir) then fs.makeDir(dir) end
    local handle = fs.open(METADATA_PATH, "w")
    if handle then
        handle.write(textutils.serialize(metadata_cache))
        handle.close()
    end
end

-- Record ownership and mode for a path.
-- mode: "rw" (default), "r" (read-only), "x" (executable)
function permissions.chown(target_path, owner_username, mode)
    local meta = load_metadata()
    meta[target_path] = { owner = owner_username, mode = mode or "rw" }
    save_metadata()
    log_module.info("permissions", "chown " .. target_path .. " -> " .. owner_username)
end

-- Retrieve ownership record for a path, or nil if unset.
function permissions.stat(target_path)
    return load_metadata()[target_path]
end

-- Check whether a given user may read a path.
-- Returns true if the path has no ownership record (unprotected) or the user matches.
function permissions.can_read(target_path, username)
    local meta = load_metadata()
    local record = meta[target_path]
    if not record then return true end
    return record.owner == username or username == "root"
end

-- Check whether a given user may write a path.
function permissions.can_write(target_path, username)
    local meta = load_metadata()
    local record = meta[target_path]
    if not record then return true end
    if record.owner == username or username == "root" then
        return record.mode == "rw" or record.mode == "x"
    end
    return false
end

-- Check whether a path is marked executable.
function permissions.is_executable(target_path)
    local meta = load_metadata()
    local record = meta[target_path]
    if not record then return false end
    return record.mode == "x"
end

-- Mark a file executable (chmod +x equivalent).
function permissions.mark_executable(target_path, requesting_user)
    local meta = load_metadata()
    local record = meta[target_path]
    if record and record.owner ~= requesting_user and requesting_user ~= "root" then
        log_module.warn("permissions", requesting_user .. " denied chmod on " .. target_path)
        return false
    end
    if not record then
        meta[target_path] = { owner = requesting_user, mode = "x" }
    else
        record.mode = "x"
    end
    save_metadata()
    return true
end

return permissions
