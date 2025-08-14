-- WezTerm Default Keybindings Foundation
-- Use WezTerm's built-in defaults first, then add customizations

local wezterm = require('wezterm')
local platform = require('utils.platform')
local act = wezterm.action

local M = {}

-- Platform-aware modifier keys
M.mod = {}
if platform.is_mac then
    M.mod.SUPER = 'SUPER'
    M.mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
    M.mod.SUPER = 'ALT'
    M.mod.SUPER_REV = 'ALT|CTRL'
end

-- WezTerm default keybindings for macOS (from documentation and show-keys)
M.default_keys = {
    -- Basic system keybindings
    { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
    { key = 'q', mods = 'SUPER', action = act.QuitApplication },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentTab { confirm = true } },
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },

    -- Tab management - plain zsh tabs
    { key = 't', mods = 'SUPER', action = act.SpawnTab('CurrentPaneDomain') },
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },

    -- Tab navigation
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = '[', mods = 'SUPER', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'SUPER', action = act.ActivateTabRelative(1) },

    -- Pane management
    { key = 'd', mods = 'SUPER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SHIFT|SUPER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'w', mods = 'SHIFT|SUPER', action = act.CloseCurrentPane { confirm = true } },

    -- Font size
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },

    -- Search
    { key = 'f', mods = 'SUPER', action = act.Search({ CaseInSensitiveString = '' }) },

    -- Full screen
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'Enter', mods = 'SUPER', action = act.TogglePaneZoomState },

    -- Scrollback
    { key = 'k', mods = 'SUPER', action = act.ClearScrollback('ScrollbackOnly') },

    -- Debug and help
    { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowDebugOverlay },
    { key = 'p', mods = 'SUPER|SHIFT', action = act.ActivateCommandPalette },

    -- Select all
    {
        key = 'a',
        mods = 'SUPER',
        action = wezterm.action_callback(function(window, pane)
            local dims = pane:get_dimensions()
            local selected = pane:get_lines_as_text(dims.scrollback_rows)
            window:copy_to_clipboard(selected, 'Clipboard')
        end)
    },

    -- Reload configuration
    { key = 'r', mods = 'SUPER|SHIFT', action = act.ReloadConfiguration },

    -- Hide application (macOS)
    { key = 'h', mods = 'SUPER', action = act.Hide },
    { key = 'h', mods = 'SUPER|ALT', action = act.HideApplication },

    -- Minimize (macOS)
    { key = 'm', mods = 'SUPER', action = act.Hide },
}

-- Default key tables
M.default_key_tables = {
    copy_mode = {
        { key = 'Tab', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'Tab', mods = 'SHIFT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'Enter', mods = 'NONE', action = act.CopyMode('MoveToStartOfNextLine') },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'Space', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = '$', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = '0', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine') },
        { key = 'G', mods = 'NONE', action = act.CopyMode('MoveToScrollbackBottom') },
        { key = 'H', mods = 'NONE', action = act.CopyMode('MoveToViewportTop') },
        { key = 'L', mods = 'NONE', action = act.CopyMode('MoveToViewportBottom') },
        { key = 'M', mods = 'NONE', action = act.CopyMode('MoveToViewportMiddle') },
        { key = 'O', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEndHoriz') },
        { key = 'V', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        { key = '^', mods = 'NONE', action = act.CopyMode('MoveToStartOfLineContent') },
        { key = 'b', mods = 'NONE', action = act.CopyMode('MoveBackwardWord') },
        { key = 'c', mods = 'CTRL', action = act.CopyMode('Close') },
        { key = 'd', mods = 'CTRL', action = act.CopyMode({ MoveByPage = 0.5 }) },
        { key = 'e', mods = 'NONE', action = act.CopyMode('MoveForwardWordEnd') },
        { key = 'f', mods = 'CTRL', action = act.CopyMode('PageDown') },
        { key = 'g', mods = 'NONE', action = act.CopyMode('MoveToScrollbackTop') },
        { key = 'g', mods = 'CTRL', action = act.CopyMode('Close') },
        { key = 'h', mods = 'NONE', action = act.CopyMode('MoveLeft') },
        { key = 'j', mods = 'NONE', action = act.CopyMode('MoveDown') },
        { key = 'k', mods = 'NONE', action = act.CopyMode('MoveUp') },
        { key = 'l', mods = 'NONE', action = act.CopyMode('MoveRight') },
        { key = 'o', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEnd') },
        { key = 'q', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'u', mods = 'CTRL', action = act.CopyMode({ MoveByPage = -0.5 }) },
        { key = 'v', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = 'v', mods = 'CTRL', action = act.CopyMode({ SetSelectionMode = 'Block' }) },
        { key = 'w', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'y', mods = 'NONE', action = act.Multiple({
            { CopyTo = 'ClipboardAndPrimarySelection' },
            { CopyMode = 'Close' }
        }) },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode('PageUp') },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode('PageDown') },
        { key = 'End', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = 'Home', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine') },
        { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode('MoveLeft') },
        { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'RightArrow', mods = 'NONE', action = act.CopyMode('MoveRight') },
        { key = 'RightArrow', mods = 'ALT', action = act.CopyMode('MoveForwardWord') },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('MoveUp') },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('MoveDown') },
    },

    search_mode = {
        { key = 'Enter', mods = 'NONE', action = act.CopyMode('PriorMatch') },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'n', mods = 'CTRL', action = act.CopyMode('NextMatch') },
        { key = 'p', mods = 'CTRL', action = act.CopyMode('PriorMatch') },
        { key = 'r', mods = 'CTRL', action = act.CopyMode('CycleMatchType') },
        { key = 'u', mods = 'CTRL', action = act.CopyMode('ClearPattern') },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode('PriorMatchPage') },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode('NextMatchPage') },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('PriorMatch') },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('NextMatch') },
    },
}

-- Default mouse bindings
M.default_mouse_bindings = {
    -- Left click
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = act.CompleteSelection('ClipboardAndPrimarySelection'),
    },

    -- Left double-click
    {
        event = { Up = { streak = 2, button = 'Left' } },
        mods = 'NONE',
        action = act.CompleteSelection('ClipboardAndPrimarySelection'),
    },

    -- Left triple-click
    {
        event = { Up = { streak = 3, button = 'Left' } },
        mods = 'NONE',
        action = act.CompleteSelection('ClipboardAndPrimarySelection'),
    },

    -- Middle click paste
    {
        event = { Up = { streak = 1, button = 'Middle' } },
        mods = 'NONE',
        action = act.PasteFrom('PrimarySelection'),
    },

    -- Ctrl+click for links
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor,
    },

    -- Wheel scrolling
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = 'NONE',
        action = act.ScrollByCurrentEventWheelDelta,
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = 'NONE',
        action = act.ScrollByCurrentEventWheelDelta,
    },
}

-- Get configuration with defaults enabled
function M.get_default_config()
    return {
        disable_default_key_bindings = false,
        disable_default_mouse_bindings = false,
        -- Override specific defaults while keeping the rest
        keys = M.default_keys,
        key_tables = M.default_key_tables,
        mouse_bindings = M.default_mouse_bindings,
    }
end

-- Get configuration for layering custom bindings
function M.get_layered_config(custom_keys, custom_key_tables, custom_mouse_bindings)
    local config = M.get_default_config()

    -- Layer custom keys on top of defaults
    if custom_keys then
        for _, key in ipairs(custom_keys) do
            table.insert(config.keys, key)
        end
    end

    -- Merge custom key tables
    if custom_key_tables then
        for table_name, table_keys in pairs(custom_key_tables) do
            config.key_tables[table_name] = table_keys
        end
    end

    -- Layer custom mouse bindings
    if custom_mouse_bindings then
        for _, binding in ipairs(custom_mouse_bindings) do
            table.insert(config.mouse_bindings, binding)
        end
    end

    return config
end

return M
