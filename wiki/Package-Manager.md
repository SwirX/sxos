# Package Management (SXPM)

SXPM stands as the package installer and environment resolution system engineered for SXOS. It handles dependency tracking natively.

## Basic Operations

```bash
sxpm install music
sxpm remove music
sxpm search ui
sxpm list
sxpm update
sxpm upgrade
sxpm info music
sxpm build /usr/local/src/musicManifest.lua
```

## Package Manifest Construction

Packages are distributed and constructed using standard Lua tables as manifest files.

```lua
return {
    name         = "music",
    version      = "1.2.0",
    description  = "High-level background audio daemon",
    author       = "SwirX",
    license      = "MIT",
    channel      = "stable",
    dependencies = {
        "sxui >=1.0.0"
    },
    binaries = { "music" },
    files    = {
        { src = "gui.lua", dest = "/usr/lib/sxpkg/music/gui.lua" }
    },
}
```

SXPM deploys package assets exclusively inside `/usr/lib/sxpkg/<packageName>/`, placing associated binary execution wrappers internally into `/usr/bin/`.
