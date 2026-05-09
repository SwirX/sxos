-- /lib/ui/theme.lua
-- SXOS terminal theme system.
-- Loads and validates a user theme from ~/.config/bsh/theme.lua.
-- Falls back to a built-in default if the user file is absent or malformed.

local theme = {}

-- The default SXOS theme.
local DEFAULT_THEME = {
    background    = colors.black,
    foreground    = colors.lightGray,
    user_color    = colors.green,
    root_color    = colors.red,
    host_color    = colors.white,
    path_color    = colors.blue,
    prompt_color  = colors.lightGray,
    cmd_color     = colors.cyan,
    cmd_err_color = colors.red,
    selection_bg  = colors.blue,
    selection_fg  = colors.white,
    border_color  = colors.gray,
    title_color   = colors.white,
}

-- Load a theme file. Returns the merged theme table.
-- user_home: the user's home directory
function theme.load(user_home)
    local theme_path = (user_home or "/root") .. "/.config/bsh/theme.lua"
    if not fs.exists(theme_path) then
        return DEFAULT_THEME
    end

    local ok, user_theme = pcall(dofile, theme_path)
    if not ok or type(user_theme) ~= "table" then
        return DEFAULT_THEME
    end

    -- Merge user overrides on top of the default.
    local merged = {}
    for key, value in pairs(DEFAULT_THEME) do
        merged[key] = user_theme[key] or value
    end
    return merged
end

-- Apply a theme's background and foreground to the terminal.
function theme.apply_to_terminal(loaded_theme)
    term.setBackgroundColor(loaded_theme.background or colors.black)
    term.setTextColor(loaded_theme.foreground or colors.lightGray)
end

-- Return the default theme for reference.
function theme.default()
    return DEFAULT_THEME
end

return theme
