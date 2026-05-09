local _M = {}

function _M.getUserHome()
    return _ENV.ENV and _ENV.ENV.HOME or "/root"
end

function _M.getAppDirectory(appName)
    local home = _M.getUserHome()
    local path = fs.combine(home, ".config/" .. appName)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
    return path
end

return _M
