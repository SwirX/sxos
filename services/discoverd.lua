-- /services/discoverd.lua
-- SXOS Discovery Daemon.
-- Makes this host visible to other SXOS nodes on the network.
-- Loaded by the kernel at Stage 4 boot and runs for the OS lifetime.
-- To customize the advertised hostname, set the computer label in CraftOS.

local discovery = dofile("/lib/net/discovery.lua")

-- The kernel registers this service; we just start the responder loop.
discovery.run_responder()
