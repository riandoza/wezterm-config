local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local keybind_manager = require('utils.keybind-manager')
local keybind_hints = require('events.keybind-hints')
local nano_scroll_fix = require('config.nano-scroll-fix')
local default_bindings = require('config.default-bindings')
local act = wezterm.action

-- Use platform-aware modifiers from default bindings
local mod = default_bindings.mod

-- Initialize key binding systems
keybind_manager.setup()
keybind_hints.setup()

-- for debug key : wezterm show-keys --lua

-- Custom keybindings to layer on top of WezTerm defaults
local custom_keys = {
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
    -- tabs: spawn+close (Cmd+T moved to default-bindings.lua to avoid conflicts)
    -- { key = 't', mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },  -- Moved to default-bindings.lua
    { key = 't', mods = mod.SUPER_REV, action = act.SpawnTab('CurrentPaneDomain') },  -- Alternative tab spawn
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

    -- Help system --
    {
        key = '?',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, pane)
            keybind_hints.show_help_overlay(window)
        end),
    },

    -- Performance monitor --
    {
        key = 'p',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('show-performance-report'),
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
    -- auto backdrop rotation control --
    {
        key = 'b',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('toggle-auto-backdrop'),
    },
    {
        key = 'i',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('show-backdrop-status'),
    },
    -- launch backdrop controls --
    {
        key = 'l',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('restart-launch-backdrop'),
    },
    {
        key = 't',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('test-launch-backdrop'),
    },
    {
        key = 'v',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('validate-launch-backdrop'),
    },
    {
        key = 's',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('validate-startup-sequence'),
    },
    {
        key = 'r',
        mods = mod.SUPER_REV,
        action = wezterm.action_callback(function(window, _pane)
            -- Trigger random image launch backdrop
            wezterm.emit('restart-launch-backdrop', window, _pane)
        end),
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

    -- panes: scroll pane (replaced with nano-aware scrolling below)

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

-- Combine custom keys with complex key bindings
local complex_keys = keybind_manager.generate_bindings()
for _, binding in ipairs(complex_keys) do
    table.insert(custom_keys, binding)
end

-- Add nano scroll bindings
local nano_scroll_keys = nano_scroll_fix.get_nano_scroll_bindings()
for _, binding in ipairs(nano_scroll_keys) do
    table.insert(custom_keys, binding)
end

-- Custom key tables to layer on top of defaults
local custom_key_tables = {
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

-- Combine custom key tables with complex key tables
local complex_key_tables = keybind_manager.generate_key_tables()
for table_name, table_keys in pairs(complex_key_tables) do
    custom_key_tables[table_name] = table_keys
end

-- Custom mouse bindings to layer on top of defaults
local custom_mouse_bindings = {
    -- Left mouse drag for text selection - enable proper drag behavior
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = "NONE",
        action = act.SelectTextAtMouseCursor("Cell"),  -- Start selection at cursor
    },
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "NONE",
        action = act.Nop,  -- Let WezTerm handle selection completion
    },
    {
        event = { Drag = { streak = 1, button = "Left" } },
        mods = "NONE",
        action = act.ExtendSelectionToMouseCursor("Cell"),  -- Extend selection during drag
    },

    -- Double-click word selection with drag support
    {
        event = { Down = { streak = 2, button = "Left" } },
        mods = "NONE",
        action = act.SelectTextAtMouseCursor("Word"),  -- Select word on double-click
    },
    {
        event = { Up = { streak = 2, button = "Left" } },
        mods = "NONE",
        action = act.Nop,
    },
    {
        event = { Drag = { streak = 2, button = "Left" } },
        mods = "NONE",
        action = act.ExtendSelectionToMouseCursor("Word"),  -- Extend word selection
    },

    -- Triple-click line selection with drag support
    {
        event = { Down = { streak = 3, button = "Left" } },
        mods = "NONE",
        action = act.SelectTextAtMouseCursor("Line"),  -- Select line on triple-click
    },
    {
        event = { Up = { streak = 3, button = "Left" } },
        mods = "NONE",
        action = act.Nop,
    },
    {
        event = { Drag = { streak = 3, button = "Left" } },
        mods = "NONE",
        action = act.ExtendSelectionToMouseCursor("Line"),  -- Extend line selection
    },

    -- Cmd/Ctrl+click for links with drag support
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = mod.SUPER,
        action = act.Nop,
    },
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = mod.SUPER,
        action = act.OpenLinkAtMouseCursor,
    },
    {
        event = { Drag = { streak = 1, button = "Left" } },
        mods = mod.SUPER,
        action = act.ExtendSelectionToMouseCursor("Cell"),  -- Allow selection with Cmd+drag
    },

    -- Right click for copy/paste with context awareness
    {
        event = { Down = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = act.Nop,  -- Proper Down event handling
    },
    {
        event = { Up = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""

            -- Add error handling for keybind_manager
            local context
            if keybind_manager and keybind_manager.detect_context then
                local success, result = pcall(keybind_manager.detect_context, window, pane)
                if success then
                    context = result
                else
                    context = "default"
                end
            else
                context = "default"
            end

            if has_selection then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
                -- Show contextual hints after copy (with error handling)
                if keybind_hints and keybind_hints.show_contextual_hints then
                    pcall(keybind_hints.show_contextual_hints, window, pane, context)
                end
            else
                window:perform_action(act.PasteFrom("Clipboard"), pane)
            end
        end),
    },

    -- Middle click for contextual hints
    {
        event = { Down = { streak = 1, button = "Middle" } },
        mods = "NONE",
        action = act.Nop,
    },
    {
        event = { Up = { streak = 1, button = "Middle" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            -- Add error handling for context detection
            local context
            if keybind_manager and keybind_manager.detect_context then
                local success, result = pcall(keybind_manager.detect_context, window, pane)
                if success then
                    context = result
                else
                    context = "default"
                end
            else
                context = "default"
            end

            -- Show contextual hints with error handling
            if keybind_hints and keybind_hints.show_contextual_hints then
                pcall(keybind_hints.show_contextual_hints, window, pane, context)
            end
        end),
    },

    -- Trackpad scrolling for WezTerm (replaced with nano-aware scrolling below)
}

-- Add nano mouse scroll bindings
local nano_mouse_bindings = nano_scroll_fix.get_nano_mouse_bindings()
for _, binding in ipairs(nano_mouse_bindings) do
    table.insert(custom_mouse_bindings, binding)
end

-- Get layered configuration: defaults + customs
local config = default_bindings.get_layered_config(
    custom_keys,
    custom_key_tables,
    custom_mouse_bindings
)

-- Add leader key configuration
config.leader = { key = 'Space', mods = mod.SUPER_REV, timeout_milliseconds = 2000 }

return config
