# Manual Installation Guide

When deploying SXOS outside the Easy Installer, administrators must manually structure the operating system environment. 

If you use the **Advanced Installer** option via `install.lua`, the setup drops you into an unrestrained `bsh` root shell environment. If you transfer the `sxos` folder entirely to the computer directly, you might be similarly forced into a minimal state upon reboot. In either circumstance, follow these explicit steps to finalize the base operating environment.

## 1. Directory Structure

Construct the required OS directory tree structure if it does not naturally exist yet. Use the bundled command modules for this layout parsing:

```bash
mkdir /bin /etc /home /lib /root /tmp /usr /var /.config
mkdir /usr/bin /usr/lib /usr/lib/sxpm
mkdir /etc/sxpm /var/lib/sxpm /var/cache/sxpm
mkdir /etc/sxos
```

## 2. User Context Configuration

You must create your user hierarchy. Replace `<user>` with your desired unique username.

```bash
mkdir /home/<user>
```

SXOS requires a valid users mapping file defining system identities to core permissions, and a securely abstracted shadow file for credentials. Use the bundled editor `yate` to construct these tables globally.

### Creating `/etc/sxos/users`

Execute the editor targeting your user path:

```bash
yate /etc/sxos/users
```
Add the following table logic, strictly formatting it as standard serialized Lua format:
```lua
{
    ["<user>"] = {
        home = "/home/<user>",
        shell = "/bin/bsh.lua",
        groups = { "admin", "users" }
    }
}
```

### Creating `/etc/sxos/shadow`

Execute the editor targeting your shadow definitions:

```bash
yate /etc/sxos/shadow
```
Insert the password definition table explicitly. For automatic login sequences bypassing prompt barriers, pass an empty string logic instead of strict text.
```lua
{
    ["<user>"] = "your_secure_password"
}
```

## 3. Core System Logic Layer

Configure your global system behavior definitions inside the boot controller sequence parameters.

Execute the editor targeting your global config mappings:

```bash
yate /etc/sxos/config.lua
```

Generate the core configuration array layout securely:
```lua
{
    autologin = false,
    autologin_user = nil,
    installed = true
}
```

*Note: For autonomous headless environments demanding instant functional operational entry, securely declare `autologin = true` and `autologin_user = "<user>"` accordingly.*

## 4. Finalization Execution

Once all core layout logics are saved mechanically to the `/etc` layer framework successfully, commit the runtime logic:

```bash
reboot
```

Upon boot, the SXOS core intercepts the underlying runtime payload, reads your newly defined tables, and cleanly spawns the required authentication barriers prior to delegating the primary user `bsh` shell runtime execution flow mechanically.
