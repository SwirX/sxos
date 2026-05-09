-- SXOS Custom Bootloader
local configPath = "/.config/sxboot/config.lua"

local config = {
    default_entry = 2,
    timeout = 2,
    hidden = false,
    colors = {
        background = colors.gray,
        box_bg = colors.black,
        text = colors.lightGray,
        selected_bg = colors.cyan,
        selected_text = colors.white,
        title = colors.white,
        border = colors.lightGray
    }
}

if fs.exists(configPath) then
    local loadedConfig = dofile(configPath)
    if type(loadedConfig) == "table" then
        for k, v in pairs(loadedConfig) do
            if type(v) == "table" and type(config[k]) == "table" then
                for ik, iv in pairs(v) do config[k][ik] = iv end
            else
                config[k] = v
            end
        end
    end
end

local entries = {
    "CraftOS Native",
    "SXOS"
}

if config.hidden then
    if config.default_entry == 2 then
        shell.run("/sys/kernel.lua")
    end
    return
end

local selected = config.default_entry
local w, h = term.getSize()
local timer = os.startTimer(config.timeout)
local timeoutRemaining = config.timeout

local boxW = 30
local boxH = #entries + 4
local boxX = math.floor((w - boxW) / 2) + 1
local boxY = math.floor((h - boxH) / 2) + 1

local function drawMenu()
    term.setBackgroundColor(config.colors.background)
    term.clear()

    -- Draw shadow
    term.setBackgroundColor(colors.gray)
    for i = 1, boxH do
        term.setCursorPos(boxX + 1, boxY + i)
        term.write(string.rep(" ", boxW))
    end

    -- Draw central box
    term.setBackgroundColor(config.colors.box_bg)
    for i = 1, boxH do
        term.setCursorPos(boxX, boxY + i - 1)
        term.write(string.rep(" ", boxW))
    end

    -- Title
    local title = " SX BOOTLOADER "
    term.setCursorPos(boxX + math.floor((boxW - #title) / 2), boxY)
    term.setTextColor(config.colors.title)
    term.write(title)

    -- Border/accent line
    term.setCursorPos(boxX + 2, boxY + 1)
    term.setTextColor(config.colors.selected_bg)
    term.write(string.rep("-", boxW - 4))

    -- Entries
    local menuY = boxY + 2
    for i, entry in ipairs(entries) do
        term.setCursorPos(boxX + 2, menuY + i - 1)
        if i == selected then
            term.setBackgroundColor(config.colors.selected_bg)
            term.setTextColor(config.colors.selected_text)
            term.write(" " .. entry .. string.rep(" ", boxW - 5 - #entry) .. ">")
        else
            term.setBackgroundColor(config.colors.box_bg)
            term.setTextColor(config.colors.text)
            term.write(" " .. entry .. string.rep(" ", boxW - 4 - #entry))
        end
    end

    -- Footer info
    term.setBackgroundColor(config.colors.background)
    term.setTextColor(config.colors.text)
    term.setCursorPos(1, h)
    term.clearLine()

    if timeoutRemaining > 0 then
        term.setCursorPos(boxX + math.floor((boxW - 18) / 2), boxY + boxH)
        term.setTextColor(colors.white)
        term.setBackgroundColor(config.colors.background)
        term.write("Default in " .. math.ceil(timeoutRemaining) .. "s...")
    end
end

drawMenu()

while true do
    local event, p1, p2, p3 = os.pullEvent()

    if event == "key" then
        if p1 == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #entries end
            timeoutRemaining = 0
            drawMenu()
        elseif p1 == keys.down then
            selected = selected + 1
            if selected > #entries then selected = 1 end
            timeoutRemaining = 0
            drawMenu()
        elseif p1 == keys.enter then
            break
        end
    elseif event == "timer" and p1 == timer and timeoutRemaining > 0 then
        timeoutRemaining = timeoutRemaining - 1
        if timeoutRemaining <= 0 then
            break
        else
            timer = os.startTimer(1)
            drawMenu()
        end
    end
end

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if selected == 1 then
    print("Executing native CraftOS...")
    return
elseif selected == 2 then
    print("Initialize SXOS environment...")
    shell.run("/sys/kernel.lua")
end
