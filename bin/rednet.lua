local args = { ... }
if #args < 1 then
    print("Usage:")
    print("  rednet open <side|down|top|back|front|left|right>")
    print("  rednet close <side>")
    print("  rednet send <id> <msg> [protocol]")
    print("  rednet broadcast <msg> [protocol]")
    print("  rednet listen [timeout]")
    return
end

local cmd = args[1]
if cmd == "open" then
    if not args[2] then
        printError("Missing side"); return
    end
    rednet.open(args[2])
    print("Opened rednet on " .. args[2])
elseif cmd == "close" then
    if not args[2] then
        printError("Missing side"); return
    end
    rednet.close(args[2])
    print("Closed rednet on " .. args[2])
elseif cmd == "send" then
    local id = tonumber(args[2])
    if not id then
        printError("Invalid ID"); return
    end
    local msg = args[3]
    local protocol = args[4]
    rednet.send(id, msg, protocol)
    print("Sent message to " .. id)
elseif cmd == "broadcast" then
    local msg = args[2]
    local protocol = args[3]
    if not msg then
        printError("Missing message"); return
    end
    rednet.broadcast(msg, protocol)
    print("Broadcasted message")
elseif cmd == "listen" then
    local timeout = tonumber(args[2])
    print("Listening for messages" .. (timeout and (" for " .. timeout .. "s") or " indefinitely") .. "...")
    while true do
        local id, msg, protocol = rednet.receive(nil, timeout)
        if not id then
            print("Receiving timed out.")
            break
        end
        print(string.format("[%d] %s (proto: %s)", id, tostring(msg), tostring(protocol)))
        if timeout then break end
    end
else
    printError("Unknown command: " .. cmd)
end
