return {
    format = "sxpkg-1",

    meta = {
        name         = "sxos-core",
        version      = "2.3.2",
        author       = "SwirX",
        description  = "SXOS kernel, bootloader, VFS, process system, and core runtime",
        channel      = "stable",
        package_type = "system",
    },

    dependencies = {},

    files = {
        -- Bootloader
        { path = "/boot/loader.lua",                    source = "boot/loader.lua" },

        -- Startup
        { path = "/startup.lua",                        source = "startup.lua" },

        -- Fallback shell
        { path = "/bin/sh.lua",                         source = "bin/sh.lua",                        executable = true },

        -- Kernel
        { path = "/sys/kernel.lua",                     source = "sys/kernel.lua" },
        { path = "/sys/env.lua",                        source = "sys/env.lua" },
        { path = "/sys/auth.lua",                       source = "sys/auth.lua" },

        -- Core runtime
        { path = "/lib/core/log.lua",                   source = "lib/core/log.lua" },
        { path = "/lib/core/env.lua",                   source = "lib/core/env.lua" },
        { path = "/lib/core/events.lua",                source = "lib/core/events.lua" },
        { path = "/lib/core/process.lua",               source = "lib/core/process.lua" },
        { path = "/lib/core/service.lua",               source = "lib/core/service.lua" },
        { path = "/lib/core/device.lua",                source = "lib/core/device.lua" },
        { path = "/lib/core/sx.lua",                    source = "lib/core/sx.lua" },

        -- Filesystem
        { path = "/lib/fs/vfs.lua",                     source = "lib/fs/vfs.lua" },
        { path = "/lib/fs/path.lua",                    source = "lib/fs/path.lua" },
        { path = "/lib/fs/permissions.lua",             source = "lib/fs/permissions.lua" },

        -- SX helpers
        { path = "/lib/sx/config.lua",                  source = "lib/sx/config.lua" },
        { path = "/lib/sx/vfs.lua",                     source = "lib/sx/vfs.lua" },

        -- Networking core
        { path = "/lib/net/rednet.lua",                 source = "lib/net/rednet.lua" },
        { path = "/lib/net/discovery.lua",              source = "lib/net/discovery.lua" },

        -- Device backends
        { path = "/lib/devices/generic.lua",            source = "lib/devices/generic.lua" },
        { path = "/lib/devices/speaker.lua",            source = "lib/devices/speaker.lua" },

        -- Compatibility
        { path = "/lib/compat/peripheral.lua",          source = "lib/compat/peripheral.lua" },

        -- Services
        { path = "/services/discoverd.lua",             source = "services/discoverd.lua" },

        -- System config
        { path = "/etc/sxos/fstab.lua",                 source = "etc/sxos/fstab.lua" },
        { path = "/etc/skel/.config/sxboot/config.lua", source = "etc/skel/.config/sxboot/config.lua" },

        -- UI core
        { path = "/lib/ui/theme.lua",                   source = "lib/ui/theme.lua" },
    },

    lifecycle = {
        post_install = "scripts/post_install.lua",
    },

    integrity = {
        sha256 = "",
    },
}
