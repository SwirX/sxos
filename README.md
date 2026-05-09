# SXOS

A UNIX-like operating system for [ComputerCraft: Tweaked](https://tweaked.cc/).

## Quick Install

Run this inside any ComputerCraft computer with HTTP access:

```lua
wget run https://raw.githubusercontent.com/SwirX/sxos/stable/install.lua
```

The installer will:
1. Download and bootstrap `sxpm` (the package manager)
2. Use `sxpm` to install the `sxos-core` package
3. Walk you through initial setup

## Upgrading

After the first install, upgrading the OS is a single command:

```sh
sxpm upgrade
```

## Shell (bsh) Keyboard Reference

| Key | Action |
|-----|--------|
| `Tab` | Complete or list all matches |
| `Shift+Tab` | Cycle completions backwards |
| `Ctrl+Left/Right` | Jump one word |
| `Ctrl+Backspace` | Delete one word |
| `Up/Down` | History |
| `Right` (at end) | Accept inline ghost hint |

## Project Layout

```
sxos/
  bin/          Core binaries (bsh, ls, diff, wget, ...)
  usr/bin/      User binaries (yafe, yate, sxfetch)
  lib/          Runtime libraries (sh, fs, net, core, ...)
  sys/          Kernel and environment
  boot/         Bootloader
  etc/          Default skeleton config
  services/     Background daemons
  install.lua   Installer entry point
  manifest.lua  sxpkg-1 package manifest (consumed by sxpm)
```

## Repositories

| Repo | Description |
|------|-------------|
| [sxos](https://github.com/SwirX/sxos) | OS source code |
| [sxpm](https://github.com/SwirX/sxpm) | Package manager |
| [sxpm-repo](https://github.com/SwirX/sxpm-repo) | Package repository index |
