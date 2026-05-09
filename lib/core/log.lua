-- /lib/core/log.lua
-- Centralized system logger for SXOS.
-- Writes structured log entries to /var/log/ and optionally to a terminal.
-- Severity levels: DEBUG, INFO, WARN, ERROR, FATAL

local log = {}

local LOG_DIR = "/var/log"
local LOG_FILE = LOG_DIR .. "/sxos.log"
local MAX_LOG_BYTES = 64 * 1024 -- 64 KB rolling cap before rotation

local LEVEL_WEIGHT = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
    FATAL = 5,
}

-- Minimum severity that gets written to disk. Can be changed at runtime.
local current_min_level = "INFO"

local function ensure_log_dir()
    if not fs.exists(LOG_DIR) then
        fs.makeDir(LOG_DIR)
    end
end

-- Rotate the log file if it has grown beyond the size cap.
local function rotate_if_needed()
    if fs.exists(LOG_FILE) and fs.getSize(LOG_FILE) >= MAX_LOG_BYTES then
        local rotated = LOG_FILE .. ".1"
        if fs.exists(rotated) then fs.delete(rotated) end
        fs.move(LOG_FILE, rotated)
    end
end

local function format_entry(level, source, message)
    -- Produces: [HH:MM:SS] [LEVEL] [source] message
    local timestamp = os.time()
    local t = string.format("%02d:%02d:%02d",
        math.floor(timestamp / 3600) % 24,
        math.floor(timestamp / 60) % 60,
        math.floor(timestamp) % 60
    )
    return string.format("[%s] [%s] [%s] %s\n", t, level, source, message)
end

local function write_entry(level, source, message)
    if (LEVEL_WEIGHT[level] or 0) < (LEVEL_WEIGHT[current_min_level] or 0) then
        return
    end
    ensure_log_dir()
    rotate_if_needed()
    local handle = fs.open(LOG_FILE, "a")
    if handle then
        handle.write(format_entry(level, source, message))
        handle.close()
    end
end

function log.debug(source, message) write_entry("DEBUG", source, message) end

function log.info(source, message) write_entry("INFO", source, message) end

function log.warn(source, message) write_entry("WARN", source, message) end

function log.error(source, message) write_entry("ERROR", source, message) end

-- FATAL logs the message then halts the OS with a kernel panic message.
function log.fatal(source, message)
    write_entry("FATAL", source, message)
    error("[SXOS FATAL] " .. source .. ": " .. message, 0)
end

-- Set the minimum level written to disk at runtime.
function log.set_min_level(level)
    assert(LEVEL_WEIGHT[level], "log: invalid level: " .. tostring(level))
    current_min_level = level
end

-- Read all current log entries as a list of strings.
function log.read()
    if not fs.exists(LOG_FILE) then return {} end
    local handle = fs.open(LOG_FILE, "r")
    if not handle then return {} end
    local lines = {}
    local line = handle.readLine()
    while line do
        table.insert(lines, line)
        line = handle.readLine()
    end
    handle.close()
    return lines
end

return log
