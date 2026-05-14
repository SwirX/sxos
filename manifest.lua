-- manifest.lua
-- Package manifest for sx-coreutils.
-- Core UNIX-style utilities required by SXOS userspace.

return {
    format = "sxpkg-1",

    meta = {
        name         = "sxos-core",
        version      = "2.3.1",
        author       = "SwirX",
        description  = "Core filesystem and shell utilities for SXOS",
        channel      = "stable",
        package_type = "system",
    },

    dependencies = {},

    files = {
        -- Core filesystem navigation
        { path = "/bin/cd.lua",     source = "bin/cd.lua",     executable = true },
        { path = "/bin/pwd.lua",    source = "bin/pwd.lua",    executable = true },
        { path = "/bin/ls.lua",     source = "bin/ls.lua",     executable = true },

        -- File inspection
        { path = "/bin/cat.lua",    source = "bin/cat.lua",    executable = true },
        { path = "/bin/find.lua",   source = "bin/find.lua",   executable = true },
        { path = "/bin/which.lua",  source = "bin/which.lua",  executable = true },

        -- File manipulation
        { path = "/bin/touch.lua",  source = "bin/touch.lua",  executable = true },
        { path = "/bin/mkdir.lua",  source = "bin/mkdir.lua",  executable = true },
        { path = "/bin/mkcd.lua",   source = "bin/mkcd.lua",   executable = true },
        { path = "/bin/rm.lua",     source = "bin/rm.lua",     executable = true },
        { path = "/bin/cp.lua",     source = "bin/cp.lua",     executable = true },
        { path = "/bin/mv.lua",     source = "bin/mv.lua",     executable = true },
        { path = "/bin/ln.lua",     source = "bin/ln.lua",     executable = true },

        -- Text utilities
        { path = "/bin/echo.lua",   source = "bin/echo.lua",   executable = true },
        { path = "/bin/printf.lua", source = "bin/printf.lua", executable = true },
        { path = "/bin/grep.lua",   source = "bin/grep.lua",   executable = true },
        { path = "/bin/diff.lua",   source = "bin/diff.lua",   executable = true },

        -- Environment + shell helpers
        { path = "/bin/env.lua",    source = "bin/env.lua",    executable = true },
        { path = "/bin/clear.lua",  source = "bin/clear.lua",  executable = true },

        -- Mounting + filesystem management
        { path = "/bin/mount.lua",  source = "bin/mount.lua",  executable = true },
        { path = "/bin/umount.lua", source = "bin/umount.lua", executable = true },

        -- Permissions
        { path = "/bin/chmod.lua",  source = "bin/chmod.lua",  executable = true },
        { path = "/bin/chown.lua",  source = "bin/chown.lua",  executable = true },

        -- Lua userspace
        { path = "/bin/lua.lua",    source = "bin/lua.lua",    executable = true },
    },

    lifecycle = {},

    integrity = {
        sha256 = "",
    },
}
