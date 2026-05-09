-- SXBoot Configuration File
return {
    -- Default boot entry index: 1 = CraftOS, 2 = SXOS
    default_entry = 2,

    -- Timeout in seconds before booting the default entry (0 to disable)
    timeout = 3,

    -- Whether to hide the menu completely. If true, boots default immediately.
    hidden = false,

    -- Colors for the bootloader UI
    colors = {
        background = colors.black,
        text = colors.lightGray,
        selected_bg = colors.gray,
        selected_text = colors.white,
        title = colors.blue
    }
}
