-- /lib/core/service.lua
-- Daemon and service registry for SXOS.
-- Services are long-running background processes that expose named RPC endpoints.
-- They register themselves with the kernel at Stage 4 boot and remain active
-- for the lifetime of the OS session.
--
-- Design: services are just named processes with an additional endpoint table.
-- Any process can call a service endpoint by name via service.call().
-- This provides a lightweight IPC mechanism without external sockets.

local service = {}

local log_module = dofile("/lib/core/log.lua")

-- Registry: service_name -> { pid, endpoints }
local registry = {}

-- Register a named service.
-- service_name : unique string identifier (e.g. "discoverd", "sshd")
-- pid          : the PID of the service process (from process.spawn)
-- endpoints    : table of name -> function, callable by other processes
function service.register(service_name, pid, endpoints)
    if registry[service_name] then
        log_module.warn("service", "re-registering existing service: " .. service_name)
    end
    registry[service_name] = {
        pid       = pid,
        endpoints = endpoints or {},
        name      = service_name,
    }
    log_module.info("service", "registered: " .. service_name .. " (pid=" .. pid .. ")")
end

-- Unregister a service. Called when its process exits.
function service.unregister(service_name)
    if registry[service_name] then
        registry[service_name] = nil
        log_module.info("service", "unregistered: " .. service_name)
    end
end

-- Call a named endpoint on a registered service.
-- Returns success_boolean, result_or_error_message
function service.call(service_name, endpoint_name, ...)
    local entry = registry[service_name]
    if not entry then
        return false, "no such service: " .. tostring(service_name)
    end
    local endpoint_fn = entry.endpoints[endpoint_name]
    if not endpoint_fn then
        return false, "no such endpoint: " .. tostring(endpoint_name) .. " on " .. service_name
    end
    return pcall(endpoint_fn, ...)
end

-- Check whether a service is currently registered.
function service.is_running(service_name)
    return registry[service_name] ~= nil
end

-- List all registered services.
function service.list()
    local result = {}
    for name, entry in pairs(registry) do
        table.insert(result, { name = name, pid = entry.pid })
    end
    return result
end

-- Retrieve a service's PID.
function service.pid_of(service_name)
    local entry = registry[service_name]
    return entry and entry.pid or nil
end

return service
