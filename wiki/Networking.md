# Networking and Discovery

Because SXOS is designed from the ground up to support distributed processing, network nodes are fundamental to operation.

## Network Discovery

All external queries proceed natively through `/lib/net/`.

```bash
# Show all SXOS nodes responding dynamically
discover

# Ping target ID statically
ping 5

# Ping fully-qualified hostnames automatically resolved
ping storage-node

# View all RPC endpoints localized on the machine 
netstat
```

## Abstracted RPC Paths

The VFS masks all complex internal operations under the uniform standard `/net/*`.

* `/net/storage-node/sys/state.txt` maps explicitly to a VFS handler querying RPC read actions against the `storage-node` host.
* `/net/display-server/monitor_1` behaves identically.
