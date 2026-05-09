-- /lib/net/rednet.lua
-- SXOS networking library built on ComputerCraft's rednet API.
-- Provides service discovery, RPC transport, and the /net VFS backend.
--
-- Protocol overview:
--   All SXOS protocol messages are tables serialized with textutils.
--   Every message carries: { protocol, type, payload, sender_id }
--
--   Discovery: broadcast SXOS_DISCOVER, collect SXOS_ANNOUNCE replies.
--   RPC:       send SXOS_RPC_REQUEST, await SXOS_RPC_RESPONSE.
--   File:      send SXOS_FILE_REQUEST, receive streamed SXOS_FILE_DATA.

local net               = {}

local log_module        = dofile("/lib/core/log.lua")

local PROTOCOL_DISCOVER = "SXOS_DISCOVER"
local PROTOCOL_ANNOUNCE = "SXOS_ANNOUNCE"
local PROTOCOL_RPC      = "SXOS_RPC"
local PROTOCOL_FILE     = "SXOS_FILE"
local DEFAULT_TIMEOUT   = 3

-- Ensure a modem is open. Opens the first available modem if none is open.
local function ensure_modem()
    if rednet.isOpen() then return true end
    local modem_names = { peripheral.find("modem") }
    for _, modem in ipairs(modem_names) do
        local side = peripheral.getName(modem)
        if side then
            rednet.open(side)
            log_module.info("net", "opened modem on " .. side)
            return true
        end
    end
    log_module.warn("net", "no modem available")
    return false
end

-- Broadcast a discovery request and collect responding SXOS hosts.
-- Returns a list of { id, hostname, services } records.
function net.discover_hosts(timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    if not ensure_modem() then return {} end

    rednet.broadcast({ type = "discover", version = 1 }, PROTOCOL_DISCOVER)

    local hosts = {}
    local deadline = os.clock() + timeout
    while os.clock() < deadline do
        local remaining = deadline - os.clock()
        local sender_id, message = rednet.receive(PROTOCOL_ANNOUNCE, remaining)
        if sender_id and type(message) == "table" then
            table.insert(hosts, {
                id       = sender_id,
                hostname = message.hostname or tostring(sender_id),
                services = message.services or {},
            })
        end
    end
    return hosts
end

-- Ping a specific computer by ID.
-- Returns round-trip time in seconds, or nil on timeout.
function net.ping(target_id, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    if not ensure_modem() then return nil end
    local start = os.clock()
    rednet.send(target_id, { type = "ping", timestamp = start }, PROTOCOL_RPC)
    local sender_id, message = rednet.receive(PROTOCOL_RPC, timeout)
    if sender_id == target_id and type(message) == "table" and message.type == "pong" then
        return os.clock() - start
    end
    return nil
end

-- Call a named RPC endpoint on a remote host.
-- Returns success_boolean, result_or_error
function net.rpc_call(target_id, service_name, endpoint_name, args, timeout)
    timeout = timeout or DEFAULT_TIMEOUT
    if not ensure_modem() then return false, "no modem" end

    local request_id = tostring(os.clock()) .. "-" .. tostring(math.random(10000))
    rednet.send(target_id, {
        type       = "rpc_request",
        request_id = request_id,
        service    = service_name,
        endpoint   = endpoint_name,
        args       = args or {},
    }, PROTOCOL_RPC)

    local deadline = os.clock() + timeout
    while os.clock() < deadline do
        local remaining = deadline - os.clock()
        local sender_id, message = rednet.receive(PROTOCOL_RPC, remaining)
        if sender_id == target_id
            and type(message) == "table"
            and message.type == "rpc_response"
            and message.request_id == request_id
        then
            return message.success, message.result
        end
    end
    return false, "rpc timeout"
end

-- stat() a path on a remote /net host.
-- /net/<hostname>/<path> -> queries the file service on that host.
local function parse_net_path(net_path)
    -- /net/<hostname>/<remote_path>
    local hostname, remote_path = string.match(net_path, "^/net/([^/]+)(/?.*)$")
    return hostname, remote_path or "/"
end

function net.stat(net_path)
    local hostname, remote_path = parse_net_path(net_path)
    if not hostname then return nil end
    -- Resolve hostname to rednet ID via discovery cache.
    local hosts = net.discover_hosts(1)
    local target_id = nil
    for _, host in ipairs(hosts) do
        if host.hostname == hostname then
            target_id = host.id
            break
        end
    end
    if not target_id then return nil end

    local ok, result = net.rpc_call(target_id, "filefs", "stat", { path = remote_path })
    return ok and result or nil
end

-- Open a remote file for reading or writing over RPC.
-- Returns a handle-like table with read/write/close, or nil + error.
function net.open_remote(net_path, mode)
    local hostname, remote_path = parse_net_path(net_path)
    if not hostname then return nil, "invalid net path: " .. tostring(net_path) end

    local hosts = net.discover_hosts(1)
    local target_id = nil
    for _, host in ipairs(hosts) do
        if host.hostname == hostname then
            target_id = host.id
            break
        end
    end
    if not target_id then return nil, "host not found: " .. hostname end

    local ok, session_token = net.rpc_call(target_id, "filefs", "open", { path = remote_path, mode = mode })
    if not ok then return nil, tostring(session_token) end

    -- Return a lightweight handle that streams data via additional RPC calls.
    return {
        read = function()
            local _, data = net.rpc_call(target_id, "filefs", "read", { token = session_token })
            return data
        end,
        readAll = function()
            local _, data = net.rpc_call(target_id, "filefs", "readAll", { token = session_token })
            return data
        end,
        write = function(data)
            net.rpc_call(target_id, "filefs", "write", { token = session_token, data = data })
        end,
        close = function()
            net.rpc_call(target_id, "filefs", "close", { token = session_token })
        end,
    }
end

return net
