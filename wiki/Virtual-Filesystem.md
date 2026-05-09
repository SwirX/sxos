# Virtual Filesystem (VFS)

The Virtual Filesystem represents SXOS's approach to abstract data access. Instead of directly interacting with internal ComputerCraft nodes, the VFS intercepts path operations at registered prefixes and directs them to the respective handler.

## Device Mounts

```lua
vfs.mount("/dev", devfs)
vfs.mount("/net", netfs)
```

### Peripheral Abstraction (`/dev`)

Accessing paths inside `/dev` maps transparently to ComputerCraft's `peripheral.wrap()`.

```lua
-- Interacts with peripheral 'speaker_0'
local speakerFile = sx.fs.open("/dev/speaker_0", "w")
speakerFile.native.playAudio(dataBuffer)
```

### Networked Nodes (`/net`)

Paths within `/net` utilize service discovery combined with Remote Procedure Calls to interact with data entirely over the network.

```lua
local remoteFile = sx.fs.open("/net/external-database/data/log.txt", "r")
```

## Permissions Architecture

SXOS enforces filesystem permissions actively at the internal API layer (`sx.fs`, `sx.proc`). However, raw CC operations via the standard `fs` API bypass this logic natively by design. SXOS focuses on maintaining a robust, organized runtime for its subsystem abstraction instead of forcing a strict bare-metal security hypervisor layer.
