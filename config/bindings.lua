local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local act = wezterm.action

local mod = {}

if platform.is_mac then
    mod.SUPER = 'SUPER'
    mod.SUPER_REV = 'SUPER|CTRL'
    mod.SUPER_CB = mod.SUPER
elseif platform.is_win or platform.is_linux then
    mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
    mod.SUPER_REV = 'ALT|CTRL'
    mod.SUPER_CB = 'CTRL|SHIFT'
end

-- for debug key : wezterm show-keys --lua

-- stylua: ignore
local keys = {
    -- misc/useful --
    { key = 'F1',  mods = 'NONE',    action = act.ActivateCopyMode },
    { key = 'F2',  mods = 'NONE',    action = act.ActivateCommandPalette },
    { key = 'F3',  mods = 'NONE',    action = act.ShowLauncher },
    { key = 'F4',  mods = 'NONE',    action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
    { key = 'F5',  mods = 'NONE',    action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES', title = 'Launch' } },
    { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
    { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
    { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
    {
        key = 'u',
        mods = mod.SUPER_REV,
        action = wezterm.action.QuickSelectArgs({
            label = 'open url',
            patterns = {
                '\\((https?://\\S+)\\)',
                '\\[(https?://\\S+)\\]',
                '\\{(https?://\\S+)\\}',
                '<(https?://\\S+)>',
                '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
            },
            action = wezterm.action_callback(function(window, pane)
                local url = window:get_selection_text_for_pane(pane)
                wezterm.log_info('opening: ' .. url)
                wezterm.open_with(url)
            end),
        }),
    },

    -- cursor movement --
    { key = 'LeftArrow',  mods = mod.SUPER,                                     action = act.SendString '\u{1b}OH' },
    { key = 'RightArrow', mods = mod.SUPER,                                     action = act.SendString '\u{1b}OF' },
    { key = 'Backspace',  mods = mod.SUPER,                                     action = act.SendString '\u{15}' },
    { key = 'Tab',        mods = 'CTRL',                                        action = act.ActivateTabRelative(1) },
    { key = 'Tab',        mods = 'SHIFT|CTRL',                                  action = act.ActivateTabRelative(-1) },
    { key = 'Enter',      mods = 'ALT',                                         action = act.ToggleFullScreen },
    { key = 'Enter',      mods = 'SUPER',                                       action = act.TogglePaneZoomState },

    -- copy/paste --
    { key = 'c',          mods = platform.is_mac and mod.SUPER or 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
    { key = 'v',          mods = platform.is_mac and mod.SUPER or 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
    { key = 'Copy',       mods = 'NONE',                                        action = act.CopyTo 'Clipboard' },
    { key = 'Paste',      mods = 'NONE',                                        action = act.PasteFrom 'Clipboard' },

    -- select all --
    {
        key = "a",
        mods = platform.is_mac and mod.SUPER or 'CTRL|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
            window:copy_to_clipboard(selected, 'Clipboard')
        end)
    },

    -- tabs --
    -- tabs: spawn+close
    { key = 't', mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },
    { key = 't', mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
    { key = 'w', mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },

    -- tabs: navigation
    { key = '[', mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
    { key = ']', mods = mod.SUPER,     action = act.ActivateTabRelative(1) },
    { key = '[', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
    { key = ']', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

    -- tab: title
    { key = '0', mods = mod.SUPER,     action = act.EmitEvent('tabs.manual-update-tab-title') },
    { key = '0', mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },

    -- tab: hide tab-bar
    { key = '9', mods = mod.SUPER,     action = act.EmitEvent('tabs.toggle-tab-bar'), },

    -- window --
    -- window: spawn windows
    { key = 'n', mods = mod.SUPER,     action = act.SpawnWindow },

    -- window: zoom window
    {
        key = '-',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            local dimensions = window:get_dimensions()
            if dimensions.is_full_screen then
                return
            end
            local new_width = dimensions.pixel_width - 50
            local new_height = dimensions.pixel_height - 50
            window:set_inner_size(new_width, new_height)
        end)
    },
    {
        key = '=',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            local dimensions = window:get_dimensions()
            if dimensions.is_full_screen then
                return
            end
            local new_width = dimensions.pixel_width + 50
            local new_height = dimensions.pixel_height + 50
            window:set_inner_size(new_width, new_height)
        end)
    },

    -- background controls --
    {
        key = [[/]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            backdrops:random(window)
        end),
    },
    {
        key = [[,]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            backdrops:cycle_back(window)
        end),
    },
    {
        key = [[.]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            backdrops:cycle_forward(window)
        end),
    },
    {
        key = [[/]],
        mods = mod.SUPER_REV,
        action = act.InputSelector({
            title = 'InputSelector: Select Background',
            choices = backdrops:choices(),
            fuzzy = true,
            fuzzy_description = 'Select Background: ',
            action = wezterm.action_callback(function(window, _pane, idx)
                if not idx then
                    return
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                backdrops:set_img(window, tonumber(idx))
            end),
        }),
    },
    {
        key = 'b',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _pane)
            backdrops:toggle_focus(window)
        end)
    },

    -- panes --
    -- panes: split panes
    {
        key = [[\]],
        mods = mod.SUPER,
        action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
    },
    {
        key = [[\]],
        mods = mod.SUPER_REV,
        action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
    },

    -- panes: zoom+close pane
    { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
    { key = 'w',     mods = mod.SUPER,     action = act.CloseCurrentPane({ confirm = false }) },

    -- panes: navigation
    { key = 'k',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
    { key = 'j',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
    { key = 'h',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
    { key = 'l',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },
    {
        key = 'p',
        mods = mod.SUPER_REV,
        action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
    },

    -- panes: scroll pane
    { key = 'u',        mods = mod.SUPER, action = act.ScrollByLine(-5) },
    { key = 'd',        mods = mod.SUPER, action = act.ScrollByLine(5) },
    { key = 'PageUp',   mods = 'NONE',    action = act.ScrollByPage(-0.75) },
    { key = 'PageDown', mods = 'NONE',    action = act.ScrollByPage(0.75) },

    -- key-tables --
    -- resizes fonts
    {
        key = 'f',
        mods = 'LEADER',
        action = act.ActivateKeyTable({
            name = 'resize_font',
            one_shot = false,
            timemout_miliseconds = 1000,
        }),
    },
    -- resize panes
    {
        key = 'p',
        mods = 'LEADER',
        action = act.ActivateKeyTable({
            name = 'resize_pane',
            one_shot = false,
            timemout_miliseconds = 1000,
        }),
    },
}

-- stylua: ignore
local key_tables = {
    copy_mode = {
        { key = 'Tab',        mods = 'NONE',  action = act.CopyMode 'MoveForwardWord' },
        { key = 'Tab',        mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },
        { key = 'Enter',      mods = 'NONE',  action = act.CopyMode 'MoveToStartOfNextLine' },
        { key = 'Escape',     mods = 'NONE',  action = act.CopyMode 'Close' },
        { key = 'Space',      mods = 'NONE',  action = act.CopyMode { SetSelectionMode = 'Cell' } },
        { key = '$',          mods = 'NONE',  action = act.CopyMode 'MoveToEndOfLineContent' },
        { key = '$',          mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },
        { key = ',',          mods = 'NONE',  action = act.CopyMode 'JumpReverse' },
        { key = '0',          mods = 'NONE',  action = act.CopyMode 'MoveToStartOfLine' },
        { key = ';',          mods = 'NONE',  action = act.CopyMode 'JumpAgain' },
        { key = 'F',          mods = 'NONE',  action = act.CopyMode { JumpBackward = { prev_char = false } } },
        { key = 'F',          mods = 'SHIFT', action = act.CopyMode { JumpBackward = { prev_char = false } } },
        { key = 'G',          mods = 'NONE',  action = act.CopyMode 'MoveToScrollbackBottom' },
        { key = 'G',          mods = 'SHIFT', action = act.CopyMode 'MoveToScrollbackBottom' },
        { key = 'H',          mods = 'NONE',  action = act.CopyMode 'MoveToViewportTop' },
        { key = 'H',          mods = 'SHIFT', action = act.CopyMode 'MoveToViewportTop' },
        { key = 'L',          mods = 'NONE',  action = act.CopyMode 'MoveToViewportBottom' },
        { key = 'L',          mods = 'SHIFT', action = act.CopyMode 'MoveToViewportBottom' },
        { key = 'M',          mods = 'NONE',  action = act.CopyMode 'MoveToViewportMiddle' },
        { key = 'M',          mods = 'SHIFT', action = act.CopyMode 'MoveToViewportMiddle' },
        { key = 'O',          mods = 'NONE',  action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
        { key = 'O',          mods = 'SHIFT', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
        { key = 'T',          mods = 'NONE',  action = act.CopyMode { JumpBackward = { prev_char = true } } },
        { key = 'T',          mods = 'SHIFT', action = act.CopyMode { JumpBackward = { prev_char = true } } },
        { key = 'V',          mods = 'NONE',  action = act.CopyMode { SetSelectionMode = 'Line' } },
        { key = 'V',          mods = 'SHIFT', action = act.CopyMode { SetSelectionMode = 'Line' } },
        { key = '^',          mods = 'NONE',  action = act.CopyMode 'MoveToStartOfLineContent' },
        { key = '^',          mods = 'SHIFT', action = act.CopyMode 'MoveToStartOfLineContent' },
        { key = 'b',          mods = 'NONE',  action = act.CopyMode 'MoveBackwardWord' },
        { key = 'b',          mods = 'ALT',   action = act.CopyMode 'MoveBackwardWord' },
        { key = 'b',          mods = 'CTRL',  action = act.CopyMode 'PageUp' },
        { key = 'c',          mods = 'CTRL',  action = act.CopyMode 'Close' },
        { key = 'd',          mods = 'CTRL',  action = act.CopyMode { MoveByPage = (0.5) } },
        { key = 'e',          mods = 'NONE',  action = act.CopyMode 'MoveForwardWordEnd' },
        { key = 'f',          mods = 'NONE',  action = act.CopyMode { JumpForward = { prev_char = false } } },
        { key = 'f',          mods = 'ALT',   action = act.CopyMode 'MoveForwardWord' },
        { key = 'f',          mods = 'CTRL',  action = act.CopyMode 'PageDown' },
        { key = 'g',          mods = 'NONE',  action = act.CopyMode 'MoveToScrollbackTop' },
        { key = 'g',          mods = 'CTRL',  action = act.CopyMode 'Close' },
        { key = 'h',          mods = 'NONE',  action = act.CopyMode 'MoveLeft' },
        { key = 'j',          mods = 'NONE',  action = act.CopyMode 'MoveDown' },
        { key = 'k',          mods = 'NONE',  action = act.CopyMode 'MoveUp' },
        { key = 'l',          mods = 'NONE',  action = act.CopyMode 'MoveRight' },
        { key = 'm',          mods = 'ALT',   action = act.CopyMode 'MoveToStartOfLineContent' },
        { key = 'o',          mods = 'NONE',  action = act.CopyMode 'MoveToSelectionOtherEnd' },
        { key = 'q',          mods = 'NONE',  action = act.CopyMode 'Close' },
        { key = 't',          mods = 'NONE',  action = act.CopyMode { JumpForward = { prev_char = true } } },
        { key = 'u',          mods = 'CTRL',  action = act.CopyMode { MoveByPage = (-0.5) } },
        { key = 'v',          mods = 'NONE',  action = act.CopyMode { SetSelectionMode = 'Cell' } },
        { key = 'v',          mods = 'CTRL',  action = act.CopyMode { SetSelectionMode = 'Block' } },
        { key = 'w',          mods = 'NONE',  action = act.CopyMode 'MoveForwardWord' },
        { key = 'y',          mods = 'NONE',  action = act.Multiple { { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } } },
        { key = 'PageUp',     mods = 'NONE',  action = act.CopyMode 'PageUp' },
        { key = 'PageDown',   mods = 'NONE',  action = act.CopyMode 'PageDown' },
        { key = 'End',        mods = 'NONE',  action = act.CopyMode 'MoveToEndOfLineContent' },
        { key = 'Home',       mods = 'NONE',  action = act.CopyMode 'MoveToStartOfLine' },
        { key = 'LeftArrow',  mods = 'NONE',  action = act.CopyMode 'MoveLeft' },
        { key = 'LeftArrow',  mods = 'ALT',   action = act.CopyMode 'MoveBackwardWord' },
        { key = 'RightArrow', mods = 'NONE',  action = act.CopyMode 'MoveRight' },
        { key = 'RightArrow', mods = 'ALT',   action = act.CopyMode 'MoveForwardWord' },
        { key = 'UpArrow',    mods = 'NONE',  action = act.CopyMode 'MoveUp' },
        { key = 'DownArrow',  mods = 'NONE',  action = act.CopyMode 'MoveDown' },
    },

    resize_font = {
        { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
        { key = 'j',      mods = 'NONE', action = act.DecreaseFontSize },
        { key = 'k',      mods = 'NONE', action = act.IncreaseFontSize },
        { key = 'q',      mods = 'NONE', action = act.PopKeyTable },
        { key = 'r',      mods = 'NONE', action = act.ResetFontSize },
    },
    resize_pane = {
        { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
        { key = 'h',      mods = 'NONE', action = act.AdjustPaneSize { 'Left', 1 } },
        { key = 'j',      mods = 'NONE', action = act.AdjustPaneSize { 'Down', 1 } },
        { key = 'k',      mods = 'NONE', action = act.AdjustPaneSize { 'Up', 1 } },
        { key = 'l',      mods = 'NONE', action = act.AdjustPaneSize { 'Right', 1 } },
        { key = 'q',      mods = 'NONE', action = act.PopKeyTable },
    },
    -- built in --
    search_mode = {
        { key = 'Enter',     mods = 'NONE', action = act.CopyMode 'PriorMatch' },
        { key = 'Escape',    mods = 'NONE', action = act.CopyMode 'Close' },
        { key = 'n',         mods = 'CTRL', action = act.CopyMode 'NextMatch' },
        { key = 'p',         mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
        { key = 'r',         mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
        { key = 'u',         mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
        { key = 'PageUp',    mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
        { key = 'PageDown',  mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
        { key = 'UpArrow',   mods = 'NONE', action = act.CopyMode 'PriorMatch' },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
    },
}

local mouse_bindings = {
    -- Change the default selection behavior so that it only selects text,
    -- but doesn't copy it to a clipboard or open hyperlinks.
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "NONE",
        action = wezterm.action({ ExtendSelectionToMouseCursor = "Cell" }),
    },
    -- Don't automatically copy the selection to the clipboard
    -- when double clicking a word
    {
        event = { Up = { streak = 2, button = "Left" } },
        mods = "NONE",
        action = "Nop",
    },
    -- Ctrl-click will open the link under the mouse cursor
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = mod.SUPER,
        action = "OpenLinkAtMouseCursor",
    },
    {
        event = { Down = { streak = 3, button = 'Left' } },
        action = wezterm.action.SelectTextAtMouseCursor 'SemanticZone',
        mods = 'NONE',
    },
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""
            if has_selection then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
            end
        end),
    },

}

return {
    disable_default_key_bindings = true,
    -- disable_default_mouse_bindings = true,
    leader = { key = 'Space', mods = mod.SUPER_REV },
    keys = keys,
    key_tables = key_tables,
    mouse_bindings = mouse_bindings,
}
