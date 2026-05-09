-- /lib/net/discovery.lua
-- Service discovery daemon support for SXOS.
-- This module handles the responder side of the SXOS_DISCOVER protocol.
-- Load this inside the discoverd service to make this host discoverable.

local discovery           = {}

local log_module          = dofile("/lib/core/log.lua")
local service_module      = dofile("/lib/core/service.lua")

local PROTOCOL_DISCOVER   = "SXOS_DISCOVER"
local PROTOCOL_ANNOUNCE   = "SXOS_ANNOUNCE"

-- The hostname this node advertises.
local registered_hostname = os.getComputerLabel() or ("node-" .. os.getComputerID())

-- Override the advertised hostname.
function discovery.set_hostname(name)
    registered_hostname = name
end

-- Build the announcement payload sent in response to discovery broadcasts.
local function build_announcement()
    local service_list = {}
    for _, entry in ipairs(service_module.list()) do
        table.insert(service_list, entry.name)
    end
    return {
        hostname = registered_hostname,
        id       = os.getComputerID(),
        services = service_list,
    }
end

-- Start the discovery responder loop.
-- This is a blocking loop and should run inside a process coroutine.
function discovery.run_responder()
    -- Ensure a modem is open.
    local modem_names = { peripheral.find("modem") }
    for _, modem in ipairs(modem_names) do
        local side = peripheral.getName(modem)
        if side then
            rednet.open(side)
            break
        end
    end

    log_module.info("discoverd", "responder started as '" .. registered_hostname .. "'")

    while true do
        local sender_id, message = rednet.receive(PROTOCOL_DISCOVER)
        if sender_id and type(message) == "table" and message.type == "discover" then
            rednet.send(sender_id, build_announcement(), PROTOCOL_ANNOUNCE)
        end
    end
end

return discovery
