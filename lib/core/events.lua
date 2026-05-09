-- /lib/core/events.lua
-- Central event routing system for SXOS.
-- Replaces direct os.pullEvent() calls throughout the OS internals.
-- Processes and services register handlers for specific event types.
-- The kernel's main loop calls events.dispatch() on each raw event.
--
-- Design rationale: ComputerCraft is fundamentally event-driven.
-- Every subsystem pulling from os.pullEvent independently creates
-- race conditions and non-deterministic wakeup order.
-- This router gives the kernel ownership of the event queue and
-- lets all consumers declare their interests up front.

local events = {}

-- Subscriptions are keyed by event name.
-- Each entry is a list of { owner_pid, handler_fn } records.
local subscriptions = {}

-- Wildcard handlers receive every event regardless of type.
local wildcard_handlers = {}

-- Subscribe a handler function to a specific event type.
-- owner_pid: the PID of the subscribing process (used for cleanup on exit)
-- event_name: string event name, or "*" for all events
-- handler: function(event_name, ...) called with event arguments
function events.subscribe(owner_pid, event_name, handler)
    if event_name == "*" then
        table.insert(wildcard_handlers, { pid = owner_pid, fn = handler })
        return
    end
    if not subscriptions[event_name] then
        subscriptions[event_name] = {}
    end
    table.insert(subscriptions[event_name], { pid = owner_pid, fn = handler })
end

-- Remove all subscriptions belonging to a given PID.
-- Called automatically when a process exits.
function events.unsubscribe_all(owner_pid)
    for event_name, handlers in pairs(subscriptions) do
        local remaining = {}
        for _, entry in ipairs(handlers) do
            if entry.pid ~= owner_pid then
                table.insert(remaining, entry)
            end
        end
        subscriptions[event_name] = remaining
    end
    local remaining_wildcards = {}
    for _, entry in ipairs(wildcard_handlers) do
        if entry.pid ~= owner_pid then
            table.insert(remaining_wildcards, entry)
        end
    end
    wildcard_handlers = remaining_wildcards
end

-- Deliver a pre-pulled event to all relevant subscribers.
-- event_packet: table.pack(os.pullEventRaw()) result
-- Returns the number of handlers that were invoked.
function events.dispatch(event_packet)
    local event_name = event_packet[1]
    local invoked = 0

    -- Deliver to specific subscribers first.
    local specific = subscriptions[event_name]
    if specific then
        for _, entry in ipairs(specific) do
            local ok, err = pcall(entry.fn, table.unpack(event_packet, 1, event_packet.n))
            if not ok then
                -- Handler errors are isolated; they never crash the dispatcher.
                printError("[events] handler error for '" .. event_name .. "': " .. tostring(err))
            end
            invoked = invoked + 1
        end
    end

    -- Deliver to wildcard subscribers.
    for _, entry in ipairs(wildcard_handlers) do
        local ok, err = pcall(entry.fn, table.unpack(event_packet, 1, event_packet.n))
        if not ok then
            printError("[events] wildcard handler error: " .. tostring(err))
        end
        invoked = invoked + 1
    end

    return invoked
end

-- Emit a synthetic event into the routing system without going through
-- os.queueEvent. Useful for intra-kernel communication.
function events.emit(event_name, ...)
    local packet = table.pack(event_name, ...)
    events.dispatch(packet)
end

-- Expose current subscriber counts for diagnostics.
function events.stats()
    local counts = {}
    for name, handlers in pairs(subscriptions) do
        counts[name] = #handlers
    end
    counts["*"] = #wildcard_handlers
    return counts
end

return events
