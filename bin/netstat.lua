-- /bin/netstat.lua
-- Display active network services and host identity.

local net     = dofile("/lib/net/rednet.lua")
local svc_lib = dofile("/lib/core/service.lua")

print("SXOS Network Status")
print(string.rep("-", 40))
print("Computer ID:  " .. os.getComputerID())
print("Label:        " .. (os.getComputerLabel() or "(none)"))

local services = svc_lib.list()
if #services > 0 then
    print("")
    print("Running services:")
    for _, entry in ipairs(services) do
        print(string.format("  %-20s  pid=%d", entry.name, entry.pid))
    end
else
    print("No local services running.")
end

print("")
print("Modem status:  " .. (rednet.isOpen() and "open" or "closed"))
