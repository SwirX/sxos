-- scripts/post_install.lua
-- Post-install hook for sxos-core.
-- Runs once after all files have been extracted to their final paths.
-- Responsible for first-time directory scaffolding that the package
-- manifest cannot describe (empty dirs, permissions baselines).

local dirs = {
    "/home",
    "/var/cache/sxpm",
    "/var/lib/sxpm",
    "/etc/sxpm",
    "/tmp",
}

for _, d in ipairs(dirs) do
    if not fs.exists(d) then
        fs.makeDir(d)
    end
end

print("sxos-core: post-install complete.")
