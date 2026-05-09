-- File: startup.lua
-- Author: SXOS
-- Description: Entry point for the SXOS boot sequence.

-- Defer immediately to the bootloader.
local bootloaderPath = "/boot/loader.lua"

if not fs.exists(bootloaderPath) then
    error("SXOS Bootloader missing: " .. bootloaderPath, 0)
end

-- Execute the bootloader
shell.run(bootloaderPath)
