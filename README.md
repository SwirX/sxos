# SXOS

**Version 2.0.0**

SXOS is a highly modular, event-driven operating system designed explicitly for the ComputerCraft environment. Taking a tailored approach rather than strictly mimicking Linux, it prioritizes native Lua coroutines, unified event routing, peripheral access abstraction, and a fully distributed network topology layout.

For comprehensive architectural specifics regarding the package management, filesystem abstractions, and shell functionality, refer to the [Wiki Documentation](wiki/Home.md).

## Core Concepts
* **Virtual Filesystem (VFS)**: Mounts remote networks and native peripherals uniformly (for example, `/dev`, `/net`).
* **Event Dispatching**: Centralized `os.pullEventRaw` processing ensuring total race-condition elimination.
* **Network Object Distribution**: Background discovery handling via transparent Remote Procedure Call bindings.
* **Component Modularity**: A robust package controller (`sxpm`) safely resolving package dependencies.

---

## Installation 

SXOS natively provides dual provisioning styles depending on the user environment setup desired.

### Method 1: The Live Installer (Recommended)

Run the remote installer directly from your ComputerCraft terminal instance to initiate the setup wizard.

```bash
wget run https://raw.githubusercontent.com/SwirX/ComputerCraft/dev/sxos/install.lua
```

This live installer generates the necessary bootstrap configuration, downloads core dependencies, and prompts you to select one of two available installation types:

1. **Easy Install**: An interactive, guided setup targeted towards standard environments. It constructs default user credentials and automatic environment profiles dynamically.
2. **Advanced Install**: A minimal terminal module providing granular administrative control. Designed exclusively for administrators looking to configure custom deployment settings or headless daemon modes manually.

### Method 2: Manual Source Installation

Administrators can directly copy the source directory into the root environment and set `startup.lua` to route to the main `sxos` launch file. Upon rebooting, the system triggers the bootstrap and prompts standard operational behaviors mechanically.

## Advanced Installation Guidelines

If deploying SXOS via the **Advanced Install** wizard or building via a direct source hierarchy layout blindly, please strictly consult our complete [Manual Installation Guide](wiki/Manual-Installation.md) for explicit file configurations.

Ensure that:
* You layout the core directories like `/etc/sxos` effectively.
* You construct `/etc/sxos/users` and `/etc/sxos/shadow` accurately ensuring your core user is defined properly.
* You initialize the final `/etc/sxos/config.lua` setting `installed = true`.

This process eliminates redundant background configurations for dedicated cluster deployment usage.

---
*SXOS is a ComputerCraft-native operating system. It is built around what makes CC unique: events, peripherals, and distributed networking.*
