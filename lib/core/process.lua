-- /lib/core/process.lua
-- Process lifecycle management for SXOS.
-- A process is a coroutine with a formal identity: pid, environment,
-- working directory, stdio handles, event subscriptions, and a parent.
-- The kernel scheduler resumes and manages all live processes each tick.
--
-- Pipes are implemented by substituting stdout of one process with a
-- write-only file handle that stdin of the next process reads from.

local process       = {}

local events_module = dofile("/lib/core/events.lua")
local log_module    = dofile("/lib/core/log.lua")

-- Master process table: pid -> process_record
local process_table = {}
local next_pid      = 1

-- Formal process record structure:
-- {
--   pid          = number,
--   name         = string,
--   env          = table,         -- isolated Lua environment
--   cwd          = string,        -- current working directory
--   stdin        = file_handle,   -- readable handle (or nil for terminal)
--   stdout       = file_handle,   -- writable handle (or nil for terminal)
--   stderr       = file_handle,   -- writable handle (or nil for terminal)
--   parent_pid   = number | nil,
--   coroutine    = coroutine,
--   filter       = string | nil,  -- coroutine yield filter (like CraftOS yield filter)
--   status       = "running" | "suspended" | "dead",
--   exit_code    = number | nil,
-- }

local function new_pid()
    local pid = next_pid
    next_pid = next_pid + 1
    return pid
end

-- Spawn a new process from a loaded function.
-- Options table:
--   name       : display name (default "unnamed")
--   env        : environment table
--   cwd        : starting directory (default "/")
--   parent_pid : pid of spawner (optional)
--   stdin      : readable file handle (optional)
--   stdout     : writable file handle (optional)
--   stderr     : writable file handle (optional)
function process.spawn(fn, options)
    options = options or {}
    local pid = new_pid()
    local record = {
        pid        = pid,
        name       = options.name or "unnamed",
        env        = options.env or _ENV,
        cwd        = options.cwd or "/",
        stdin      = options.stdin or nil,
        stdout     = options.stdout or nil,
        stderr     = options.stderr or nil,
        parent_pid = options.parent_pid or nil,
        coroutine  = coroutine.create(fn),
        filter     = nil,
        status     = "running",
        exit_code  = nil,
    }
    process_table[pid] = record
    log_module.info("proc", "spawned pid=" .. pid .. " name=" .. record.name)
    return pid
end

-- Retrieve a process record by PID.
function process.get(pid)
    return process_table[pid]
end

-- List all live process records.
function process.list()
    local result = {}
    for pid, record in pairs(process_table) do
        if record.status ~= "dead" then
            table.insert(result, record)
        end
    end
    return result
end

-- Deliver an event packet to a single process coroutine.
-- Returns true if the coroutine is still alive after the resume.
local function resume_process(record, event_packet)
    if record.status == "dead" then return false end

    -- Only resume if the coroutine is waiting for this event type or any.
    local event_name = event_packet[1]
    if record.filter and record.filter ~= event_name and event_name ~= "terminate" then
        return true -- not interested in this event, leave suspended
    end

    local ok, yield_or_err = coroutine.resume(record.coroutine, table.unpack(event_packet, 1, event_packet.n))

    if coroutine.status(record.coroutine) == "dead" then
        record.status = "dead"
        record.exit_code = ok and 0 or 1
        events_module.unsubscribe_all(record.pid)
        log_module.info("proc", "exited pid=" .. record.pid .. " code=" .. record.exit_code)
        if not ok then
            log_module.error("proc", "pid=" .. record.pid .. " crashed: " .. tostring(yield_or_err))
        end
        return false
    else
        -- yield_or_err is the event filter string the coroutine is waiting for.
        record.filter = yield_or_err
        record.status = "suspended"
        return true
    end
end

-- Tick all live processes with the given event packet.
-- Called by the kernel event loop on each iteration.
function process.tick(event_packet)
    for pid, record in pairs(process_table) do
        if record.status ~= "dead" then
            resume_process(record, event_packet)
        end
    end

    -- Reap dead processes from the table.
    for pid, record in pairs(process_table) do
        if record.status == "dead" then
            process_table[pid] = nil
        end
    end
end

-- Forcibly terminate a process by PID.
-- Sends a "terminate" event to the coroutine.
function process.kill(pid)
    local record = process_table[pid]
    if not record or record.status == "dead" then return false end
    resume_process(record, table.pack("terminate"))
    return true
end

return process
