# Architecture

SXOS strictly separates library code, system processes, and userspace binaries to maintain a secure and reliable runtime. 

## Boot Sequence

The OS boots in defined stages, initializing subsystems incrementally to guarantee dependency fulfillment.

| Stage | Component | Responsibility |
|-------|-----------|----------------|
| 1 | Bootloader | Handles OS selection and visual theme. |
| 2 | Kernel | Loads core libraries and instantiates the central event router. |
| 3 | Kernel | Initializes Virtual Filesystem (VFS) mount points, such as `/dev` and `/net`. |
| 4 | Kernel | Spawns background system services, including `discoverd`. |
| 5 | Auth | Prompts user login and establishes the session state. |
| 6 | Shell | Spawns the `bsh` shell for user interaction. |

## Event Router

Rather than calling `os.pullEvent()` independently, every subsystem in SXOS routes its events through a central dispatcher. This approach mitigates race conditions that occur when multiple concurrent systems listen to raw events simultaneously.

```lua
-- Services subscribe to specific event types
sx.events.subscribe(processId, "modem_message", function(...) 
    -- Process event
end)

-- Intra-kernel synthetic events
sx.events.emit("process_exit", targetProcessId)

-- Core kernel event loop
while true do
    local eventData = table.pack(os.pullEventRaw())
    sx.events.dispatch(eventData)
    sx.proc.tick(eventData)
end
```

## Process Model

Every running application or service exists as an isolated coroutine within a formal process object:

```lua
{
    pid        = 104,
    name       = "bsh",
    env        = {}, -- Isolated Lua environment
    cwd        = "/home/swirx",
    stdin      = system.stdin,
    stdout     = system.stdout,
    stderr     = system.stderr,
    parent_pid = 2,
    coroutine  = coroutine.create(targetFunction),
    filter     = "timer",
    status     = "running", -- "running", "suspended", "dead"
}
```

## Service Registration

Daemons (services running in the background) register themselves with the kernel and expose named Remote Procedure Call (RPC) interfaces. Any process can invoke a service abstractly without understanding the service's internal implementation logic.

```lua
-- Handled within the daemon application
sx.service.register("audioDaemon", currentProcessId, {
    play = function(audioUrl) 
        -- Implementation
    end,
    stop = function() 
        -- Implementation
    end
})

-- Handled within client applications
sx.service.call("audioDaemon", "play", "http://example.com/audio.mp3")
```
