-- manifest.lua
-- Package manifest for sxos-core.
-- This is the canonical descriptor for the SXOS core operating system package.
-- It is consumed by sxpm to install, upgrade, and remove the OS.

return {
    format = "sxpkg-1",

    meta = {
        name        = "sxos-core",
        version     = "2.0.2",
        author      = "SwirX",
        description = "SXOS - core operating system for ComputerCraft",
        channel     = "stable",
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

        -- Filesystem libraries
        { path = "/lib/fs/vfs.lua",                    source = "lib/fs/vfs.lua" },
        { path = "/lib/fs/path.lua",                   source = "lib/fs/path.lua" },
        { path = "/lib/fs/permissions.lua",            source = "lib/fs/permissions.lua" },

        -- Shell libraries
        { path = "/lib/sh/builtins.lua",               source = "lib/sh/builtins.lua" },
        { path = "/lib/sh/completion.lua",             source = "lib/sh/completion.lua" },
        { path = "/lib/sh/execute.lua",                source = "lib/sh/execute.lua" },
        { path = "/lib/sh/expand.lua",                 source = "lib/sh/expand.lua" },
        { path = "/lib/sh/parser.lua",                 source = "lib/sh/parser.lua" },
        { path = "/lib/sh/tokenizer.lua",              source = "lib/sh/tokenizer.lua" },

        -- Network libraries
        { path = "/lib/net/discovery.lua",             source = "lib/net/discovery.lua" },
        { path = "/lib/net/rednet.lua",                source = "lib/net/rednet.lua" },

        -- SX config + VFS shim
        { path = "/lib/sx/config.lua",                 source = "lib/sx/config.lua" },
        { path = "/lib/sx/vfs.lua",                    source = "lib/sx/vfs.lua" },

        -- UI library
        { path = "/lib/ui/theme.lua",                  source = "lib/ui/theme.lua" },

        -- Services
        { path = "/services/discoverd.lua",            source = "services/discoverd.lua" },

        -- Core binaries
        { path = "/bin/bsh.lua",                       source = "bin/bsh.lua",                      executable = true },
        { path = "/bin/cat.lua",                       source = "bin/cat.lua",                      executable = true },
        { path = "/bin/cd.lua",                        source = "bin/cd.lua",                       executable = true },
        { path = "/bin/chmod.lua",                     source = "bin/chmod.lua",                    executable = true },
        { path = "/bin/chown.lua",                     source = "bin/chown.lua",                    executable = true },
        { path = "/bin/clear.lua",                     source = "bin/clear.lua",                    executable = true },
        { path = "/bin/cp.lua",                        source = "bin/cp.lua",                       executable = true },
        { path = "/bin/curl.lua",                      source = "bin/curl.lua",                     executable = true },
        { path = "/bin/diff.lua",                      source = "bin/diff.lua",                     executable = true },
        { path = "/bin/discover.lua",                  source = "bin/discover.lua",                 executable = true },
        { path = "/bin/echo.lua",                      source = "bin/echo.lua",                     executable = true },
        { path = "/bin/env.lua",                       source = "bin/env.lua",                      executable = true },
        { path = "/bin/find.lua",                      source = "bin/find.lua",                     executable = true },
        { path = "/bin/git.lua",                       source = "bin/git.lua",                      executable = true },
        { path = "/bin/grep.lua",                      source = "bin/grep.lua",                     executable = true },
        { path = "/bin/help.lua",                      source = "bin/help.lua",                     executable = true },
        { path = "/bin/jobs.lua",                      source = "bin/jobs.lua",                     executable = true },
        { path = "/bin/kill.lua",                      source = "bin/kill.lua",                     executable = true },
        { path = "/bin/ln.lua",                        source = "bin/ln.lua",                       executable = true },
        { path = "/bin/ls.lua",                        source = "bin/ls.lua",                       executable = true },
        { path = "/bin/lua.lua",                       source = "bin/lua.lua",                      executable = true },
        { path = "/bin/mkcd.lua",                      source = "bin/mkcd.lua",                     executable = true },
        { path = "/bin/mkdir.lua",                     source = "bin/mkdir.lua",                    executable = true },
        { path = "/bin/mount.lua",                     source = "bin/mount.lua",                    executable = true },
        { path = "/bin/mv.lua",                        source = "bin/mv.lua",                       executable = true },
        { path = "/bin/netstat.lua",                   source = "bin/netstat.lua",                  executable = true },
        { path = "/bin/ping.lua",                      source = "bin/ping.lua",                     executable = true },
        { path = "/bin/printf.lua",                    source = "bin/printf.lua",                   executable = true },
        { path = "/bin/ps.lua",                        source = "bin/ps.lua",                       executable = true },
        { path = "/bin/pwd.lua",                       source = "bin/pwd.lua",                      executable = true },
        { path = "/bin/reboot.lua",                    source = "bin/reboot.lua",                   executable = true },
        { path = "/bin/rm.lua",                        source = "bin/rm.lua",                       executable = true },
        { path = "/bin/shutdown.lua",                  source = "bin/shutdown.lua",                 executable = true },
        { path = "/bin/touch.lua",                     source = "bin/touch.lua",                    executable = true },
        { path = "/bin/umount.lua",                    source = "bin/umount.lua",                   executable = true },
        { path = "/bin/wget.lua",                      source = "bin/wget.lua",                     executable = true },
        { path = "/bin/which.lua",                     source = "bin/which.lua",                    executable = true },

        -- User binaries
        { path = "/usr/bin/sxfetch.lua",               source = "usr/bin/sxfetch.lua",              executable = true },
        { path = "/usr/bin/yafe.lua",                  source = "usr/bin/yafe.lua",                 executable = true },
        { path = "/usr/bin/yate.lua",                  source = "usr/bin/yate.lua",                 executable = true },
    },

    lifecycle = {
        post_install = "scripts/post_install.lua",
    },

    integrity = {
        sha256 = "FILL_ME",
    },
}
