-- /lib/sh/expand.lua
-- Variable and tilde expansion for bsh.
-- Processes WORD tokens before they are passed to the executor.
-- Only called on tokens that did NOT come from single-quoted strings
-- (single quotes suppress all expansion).

local expand = {}

-- Expand $VAR and ${VAR} references in a string against the given environ table.
-- The environ table should be the process_env.ENV flat dict.
function expand.variables(str, environ)
    if type(str) ~= "string" then return str end

    -- ${VAR_NAME} longer form first to avoid partial matches on $VAR.
    str = string.gsub(str, "%${([%w_]+)}", function(name)
        local value = environ[name]
        return value ~= nil and tostring(value) or ""
    end)

    -- $VAR_NAME shorter form.
    str = string.gsub(str, "%$([%w_]+)", function(name)
        local value = environ[name]
        return value ~= nil and tostring(value) or ""
    end)

    return str
end

-- Expand a leading tilde to the user's home directory.
function expand.tilde(str, home_dir)
    if type(str) ~= "string" then return str end
    if str == "~" then return home_dir or "/" end
    if string.sub(str, 1, 2) == "~/" then
        return (home_dir or "/") .. string.sub(str, 2)
    end
    return str
end

-- Apply all applicable expansions to a token string.
-- is_single_quoted: if true, skip all expansion (literal string).
function expand.apply(str, environ, is_single_quoted)
    if is_single_quoted then return str end
    local home = environ and environ.HOME or "/"
    str = expand.tilde(str, home)
    str = expand.variables(str, environ or {})
    return str
end

return expand
