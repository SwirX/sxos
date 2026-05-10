# Manual Installation Guide

Hey! If you are configuring SXOS from absolute scratch, this guide covers the technical bootstrap execution bypassing my standard UI installers. 

## 1. Bootstrapping Package Protocol

Because I shifted the entire architecture to a decoupled modular standard, you'll need `sxpm` first. Fetch the installer manually:

```lua
wget run https://raw.githubusercontent.com/SwirX/sxpm/stable/install.lua
```

This globally injects `sxpm` and sets up the local database mappings.

## 2. Syncing Indices

Update the local definitions cache:

```sh
/usr/bin/sxpm.lua sync
```

## 3. Base OS Integration

Acquire the underlying `sxos-core` kernel framework. This securely establishes `/sys`, `/boot`, `/lib`, and `/etc`:

```sh
/usr/bin/sxpm.lua install sxos-core
```

## 4. Subsystem Deployments

The environment currently functions practically as a headless logic state. Inject standard capability logic explicitly:

```sh
/usr/bin/sxpm.lua install bsh
/usr/bin/sxpm.lua install sx-coreutils
/usr/bin/sxpm.lua install sx-netutils
```

*(If you require desktop integration rapidly, running `sxpm.lua install sxos-desktop` natively pulls all base dependencies asynchronously.)*

## 5. Security & Configuration Context

Generate explicit system paths handling your targeted alias:

```sh
mkdir /home/admin
```

Construct identity configurations using my modal editor tool, `yate`:

```sh
/usr/bin/sxpm.lua install yate
yate /etc/sxos/users
```

Bind mapping configurations specifically matching your alias, properly directing `/bin/bsh.lua` correctly as the runtime execution point. Create your encrypted or null representation inside `/etc/sxos/shadow`.

## 6. System Reset

Commit all explicit filesystem configurations:

```sh
reboot
```
