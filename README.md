# SXOS

Hey! Welcome to my custom UNIX-style OS framework built from the ground up for [ComputerCraft: Tweaked](https://tweaked.cc/). I engineered the architecture specifically for high performance and modularity.

## Clean Architecture

This isn't a monolithic codebase. I split the infrastructure completely: the absolute core systems (kernel, virtual filesystem, and bootloader) exist here inside this repository. Everything else, including user binaries and logic utilities, has been decoupled into custom `sx-` packages. Everything routes through `sxpm`, the native package manager I wrote to guarantee system integrity.

## Quick Install

To bootstrap this environment instantly, simply execute this from any CraftOS instance:

```lua
wget run https://raw.githubusercontent.com/SwirX/sxos/dev/install.lua
```

It fetches `sxpm` and handles the entire installation dynamically.

## Upgrading

Once bootstrapped, you execute upgrades entirely through the package manager:

```sh
sxpm upgrade
```

## Project Layout

```
sxos/
  boot/         Bootloader staging
  etc/          Skeleton initialization parameters
  lib/          Runtime abstraction libraries (fs, core API)
  sys/          Kernel environment controllers
  services/     Background operational daemons
  install.lua   The minimalist bootstrap payload
  manifest.lua  Strict definition mapping for sxpkg compilation
```

*(Modules like `bsh` and `sx-coreutils` map into `/bin/` autonomously at runtime post-installation.)*

## Connected Ecosystem

| Repository | Purpose |
|------------|---------|
| [sxos](https://github.com/SwirX/sxos) | Core operating infrastructure |
| [sxpm](https://github.com/SwirX/sxpm) | Package manager logic |
| [sxpm-repo](https://github.com/SwirX/sxpm-repo) | Remote distribution indices |
