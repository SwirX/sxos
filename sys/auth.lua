local _M = {}

function _M.read_config()
    if fs.exists("/etc/sxos/config.lua") then
        local content = fs.open("/etc/sxos/config.lua", "r")
        if content then
            local data = textutils.unserialize(content.readAll())
            content.close()
            return data or {}
        end
    end
    return {}
end

function _M.read_users()
    local users = {}
    if fs.exists("/etc/sxos/users") then
        local content = fs.open("/etc/sxos/users", "r")
        if content then
            users = textutils.unserialize(content.readAll()) or {}
            content.close()
        end
    end

    if not users["root"] then
        users["root"] = {
            home = "/root",
            shell = "/bin/bsh.lua",
            groups = { "admin", "users" }
        }
    end
    return users
end

function _M.read_shadow()
    local shadow = {}
    if fs.exists("/etc/sxos/shadow") then
        local content = fs.open("/etc/sxos/shadow", "r")
        if content then
            shadow = textutils.unserialize(content.readAll()) or {}
            content.close()
        end
    end

    if not shadow["root"] then
        shadow["root"] = "sxos"
    end
    return shadow
end

function _M.authenticate(user, pass)
    local shadow = _M.read_shadow()
    if shadow[user] and shadow[user] == pass then
        return true
    end
    return false
end

function _M.do_login()
    local config = _M.read_config()
    local users = _M.read_users()

    if config.autologin and config.autologin_user then
        if users[config.autologin_user] then
            return config.autologin_user, users[config.autologin_user]
        end
    end

    -- Prompt for login
    while true do
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        print("SXOS Login")
        write("login: ")
        local user = read()
        write("password: ")
        local pass = read("*")

        if _M.authenticate(user, pass) then
            return user, users[user]
        else
            print("Login incorrect")
            sleep(2)
        end
    end
end

return _M
