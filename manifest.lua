-- manifest.lua
-- Package manifest for sxos-core.
-- This is the canonical descriptor for the SXOS core operating system package.
-- It is consumed by sxpm to install, upgrade, and remove the OS.

return {
    format = "sxpkg-1",

    meta = {
        name         = "sxos-core",
        version      = "2.1.0",
        author       = "SwirX",
        description  = "SXOS - core operating system for ComputerCraft",
        channel      = "stable",
        package_type = "system",
    },

    dependencies = {},

    files = {
        -- Bootloader
        { path = "/boot/loader.lua",                   source = "boot/loader.lua" },

        -- Startup dispatcher
        { path = "/startup.lua",                       source = "startup.lua" },

        -- System skeleton config
        { path = "/etc/skel/config/sxboot/config.lua", source = "etc/skel/config/sxboot/config.lua" },

        -- Kernel and core sys
        { path = "/sys/kernel.lua",                    source = "sys/kernel.lua" },
        { path = "/sys/env.lua",                       source = "sys/env.lua" },
        { path = "/sys/auth.lua",                      source = "sys/auth.lua" },

        -- Core libraries
        { path = "/lib/core/log.lua",                  source = "lib/core/log.lua" },
        { path = "/lib/core/env.lua",                  source = "lib/core/env.lua" },
        { path = "/lib/core/events.lua",               source = "lib/core/events.lua" },
        { path = "/lib/core/process.lua",              source = "lib/core/process.lua" },
        { path = "/lib/core/service.lua",              source = "lib/core/service.lua" },
        { path = "/lib/core/sx.lua",                   source = "lib/core/sx.lua" },
        { path = "/lib/core/device.lua",               source = "lib/core/device.lua" },

        -- Compatibility shims
        { path = "/lib/compat/peripheral.lua",         source = "lib/compat/peripheral.lua" },

        -- Filesystem libraries
        { path = "/lib/fs/vfs.lua",                    source = "lib/fs/vfs.lua" },
        { path = "/lib/fs/path.lua",                   source = "lib/fs/path.lua" },
        { path = "/lib/fs/permissions.lua",            source = "lib/fs/permissions.lua" },

        -- Shell libraries extracted to bsh package

        -- Network libraries
        { path = "/lib/net/discovery.lua",             source = "lib/net/discovery.lua" },
        { path = "/lib/net/rednet.lua",                source = "lib/net/rednet.lua" },

        -- SX config + VFS shim
        { path = "/lib/sx/config.lua",                 source = "lib/sx/config.lua" },
        { path = "/lib/sx/vfs.lua",                    source = "lib/sx/vfs.lua" },

        -- Device Driver Backends
        { path = "/lib/devices/generic.lua",           source = "lib/devices/generic.lua" },
        { path = "/lib/devices/speaker.lua",           source = "lib/devices/speaker.lua" },

        -- Fstab configurations
        { path = "/etc/sxos/fstab.lua",                source = "etc/fstab.lua" },

        -- UI library
        { path = "/lib/ui/theme.lua",                  source = "lib/ui/theme.lua" },

        -- Services
        { path = "/services/discoverd.lua",            source = "services/discoverd.lua" },

        -- User binaries moved to standalone packages
    },

    lifecycle = {
        post_install = "scripts/post_install.lua",
    },

    integrity = {
        sha256 = "FILL_ME",
    },
}
