-- WezTerm Unified Key Bindings Configuration
-- Combines platform-aware defaults with advanced customizations
-- Consolidated from: default-bindings.lua + bindings.lua

local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local keybind_manager = require('utils.keybind-manager')
local keybind_hints = require('events.keybind-hints')
local nano_scroll_fix = require('config.nano-scroll-fix')
local constants = require('config.constants')
local act = wezterm.action

-- ============================================================================
-- PLATFORM DETECTION & MODIFIER KEYS
-- ============================================================================

-- Platform-aware modifier keys
local mod = {}
if platform.is_mac then
    mod.SUPER = 'SUPER'
    mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
    mod.SUPER = 'ALT'
    mod.SUPER_REV = 'ALT|CTRL'
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize key binding systems
keybind_manager.setup()
keybind_hints.setup()

-- Debug key bindings: wezterm show-keys --lua

-- ============================================================================
-- CORE KEY BINDINGS
-- ============================================================================

local keys = {
    -- ========================================
    -- SYSTEM & APPLICATION CONTROLS
    -- ========================================
    { key = 'c', mods = mod.SUPER, action = act.CopyTo('Clipboard') },
    { key = 'v', mods = mod.SUPER, action = act.PasteFrom('Clipboard') },
    { key = 'q', mods = mod.SUPER, action = act.QuitApplication },
    { key = 'r', mods = 'SUPER|SHIFT', action = act.ReloadConfiguration },
    { key = 'Copy', mods = 'NONE', action = act.CopyTo 'Clipboard' },
    { key = 'Paste', mods = 'NONE', action = act.PasteFrom 'Clipboard' },

    -- macOS specific
    { key = 'h', mods = mod.SUPER, action = act.Hide },
    { key = 'h', mods = 'SUPER|ALT', action = act.HideApplication },
    { key = 'm', mods = mod.SUPER, action = act.Hide },

    -- ========================================
    -- WINDOW MANAGEMENT
    -- ========================================
    { key = 'n', mods = mod.SUPER, action = act.SpawnWindow },
    { key = 'w', mods = mod.SUPER, action = act.CloseCurrentTab { confirm = true } },

    -- Window resizing
    {
        key = '-',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            local dimensions = window:get_dimensions()
            if dimensions.is_full_screen then return end
            local new_width = dimensions.pixel_width - constants.DIMENSIONS.WINDOW_RESIZE_STEP
            local new_height = dimensions.pixel_height - constants.DIMENSIONS.WINDOW_RESIZE_STEP
            window:set_inner_size(new_width, new_height)
        end)
    },
    {
        key = '=',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            local dimensions = window:get_dimensions()
            if dimensions.is_full_screen then return end
            local new_width = dimensions.pixel_width + constants.DIMENSIONS.WINDOW_RESIZE_STEP
            local new_height = dimensions.pixel_height + constants.DIMENSIONS.WINDOW_RESIZE_STEP
            window:set_inner_size(new_width, new_height)
        end)
    },

    -- ========================================
    -- TAB MANAGEMENT
    -- ========================================
    { key = 't', mods = mod.SUPER, action = act.SpawnTab('CurrentPaneDomain') },
    { key = 't', mods = mod.SUPER_REV, action = act.SpawnTab('CurrentPaneDomain') },

    -- Tab navigation by number
    { key = '1', mods = mod.SUPER, action = act.ActivateTab(0) },
    { key = '2', mods = mod.SUPER, action = act.ActivateTab(1) },
    { key = '3', mods = mod.SUPER, action = act.ActivateTab(2) },
    { key = '4', mods = mod.SUPER, action = act.ActivateTab(3) },
    { key = '5', mods = mod.SUPER, action = act.ActivateTab(4) },
    { key = '6', mods = mod.SUPER, action = act.ActivateTab(5) },
    { key = '7', mods = mod.SUPER, action = act.ActivateTab(6) },
    { key = '8', mods = mod.SUPER, action = act.ActivateTab(7) },
    { key = '9', mods = mod.SUPER, action = act.ActivateTab(-1) },

    -- Tab navigation by direction
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = '[', mods = mod.SUPER, action = act.ActivateTabRelative(-1) },
    { key = ']', mods = mod.SUPER, action = act.ActivateTabRelative(1) },
    { key = '[', mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
    { key = ']', mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

    -- Tab title management
    { key = '0', mods = mod.SUPER, action = act.EmitEvent('tabs.manual-update-tab-title') },
    { key = '0', mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },
    { key = '9', mods = mod.SUPER, action = act.EmitEvent('tabs.toggle-tab-bar') },

    -- ========================================
    -- PANE MANAGEMENT
    -- ========================================
    { key = 'd', mods = mod.SUPER, action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SHIFT|SUPER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = [[\]], mods = mod.SUPER, action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = [[\]], mods = mod.SUPER_REV, action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },

    { key = 'w', mods = 'SHIFT|SUPER', action = act.CloseCurrentPane { confirm = true } },
    { key = 'Enter', mods = mod.SUPER, action = act.TogglePaneZoomState },

    -- Pane navigation (vim-style)
    { key = 'k', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
    { key = 'j', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
    { key = 'h', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
    { key = 'l', mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },
    { key = 'p', mods = mod.SUPER_REV, action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }) },

    -- ========================================
    -- FONT CONTROLS (consolidated)
    -- ========================================
    { key = '=', mods = mod.SUPER, action = act.IncreaseFontSize },
    { key = '-', mods = mod.SUPER, action = act.DecreaseFontSize },
    { key = '0', mods = mod.SUPER, action = act.ResetFontSize },

    -- ========================================
    -- SEARCH & NAVIGATION
    -- ========================================
    { key = 'f', mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
    { key = 'k', mods = mod.SUPER, action = act.ClearScrollback('ScrollbackOnly') },

    -- Quick URL opener
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

    -- ========================================
    -- FULLSCREEN & ZOOM CONTROLS
    -- ========================================
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'F11', mods = 'NONE', action = act.ToggleFullScreen },

    -- ========================================
    -- CURSOR MOVEMENT IMPROVEMENTS
    -- ========================================
    { key = 'LeftArrow', mods = mod.SUPER, action = act.SendString '\u{1b}OH' },
    { key = 'RightArrow', mods = mod.SUPER, action = act.SendString '\u{1b}OF' },
    { key = 'Backspace', mods = mod.SUPER, action = act.SendString '\u{15}' },

    -- ========================================
    -- TEXT SELECTION
    -- ========================================
    -- Select all with enhanced functionality
    {
        key = "a",
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, pane)
            local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
            window:copy_to_clipboard(selected, 'Clipboard')
        end)
    },

    -- ========================================
    -- FUNCTION KEYS & UTILITIES
    -- ========================================
    { key = 'F1', mods = 'NONE', action = act.ActivateCopyMode },
    { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
    { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
    { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
    { key = 'F5', mods = 'NONE', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES', title = 'Launch' } },
    { key = 'F12', mods = 'NONE', action = act.ShowDebugOverlay },
    { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowDebugOverlay },
    { key = 'p', mods = 'SUPER|SHIFT', action = act.ActivateCommandPalette },

    -- ========================================
    -- HELP & ASSISTANCE
    -- ========================================
    -- Help system
    {
        key = '?',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            keybind_hints.show_help_overlay(window)
        end),
    },

    -- Performance monitoring
    {
        key = 'p',
        mods = mod.SUPER_REV,
        action = wezterm.action.EmitEvent('show-performance-report'),
    },

    -- ========================================
    -- BACKGROUND CONTROLS
    -- ========================================
    {
        key = [[/]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            backdrops:random(window)
        end),
    },
    {
        key = [[,]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            backdrops:cycle_back(window)
        end),
    },
    {
        key = [[.]],
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
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
            action = wezterm.action_callback(function(window, _, idx)
                if not idx then return end
                ---@diagnostic disable-next-line: param-type-mismatch
                backdrops:set_img(window, tonumber(idx))
            end),
        }),
    },
    {
        key = 'b',
        mods = mod.SUPER,
        action = wezterm.action_callback(function(window, _)
            backdrops:toggle_focus(window)
        end)
    },

    -- Auto backdrop rotation controls
    { key = 'b', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('toggle-auto-backdrop') },
    { key = 'i', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('show-backdrop-status') },

    -- Launch backdrop controls
    { key = 'l', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('restart-launch-backdrop') },
    { key = 't', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('test-launch-backdrop') },
    { key = 'v', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('validate-launch-backdrop') },
    { key = 's', mods = mod.SUPER_REV, action = wezterm.action.EmitEvent('validate-startup-sequence') },
    {
        key = 'r',
        mods = mod.SUPER_REV,
        action = wezterm.action_callback(function(window, pane)
            wezterm.emit('restart-launch-backdrop', window, pane)
        end),
    },

    -- ========================================
    -- KEY TABLE ACTIVATORS
    -- ========================================
    -- Font resize mode
    {
        key = 'f',
        mods = 'LEADER',
        action = act.ActivateKeyTable({
            name = 'resize_font',
            one_shot = false,
            timeout_milliseconds = constants.TIMEOUTS.LEADER_KEY,
        }),
    },

    -- Pane resize mode
    {
        key = 'p',
        mods = 'LEADER',
        action = act.ActivateKeyTable({
            name = 'resize_pane',
            one_shot = false,
            timeout_milliseconds = constants.TIMEOUTS.LEADER_KEY,
        }),
    },
}

-- ============================================================================
-- DYNAMIC KEY BINDINGS INTEGRATION
-- ============================================================================

-- Add complex key bindings from keybind_manager
local complex_keys = keybind_manager.generate_bindings()
for _, binding in ipairs(complex_keys) do
    table.insert(keys, binding)
end

-- Add nano scroll bindings
local nano_scroll_keys = nano_scroll_fix.get_nano_scroll_bindings()
for _, binding in ipairs(nano_scroll_keys) do
    table.insert(keys, binding)
end

-- ============================================================================
-- KEY TABLES
-- ============================================================================

local key_tables = {
    -- ========================================
    -- COPY MODE (Enhanced vim-like navigation)
    -- ========================================
    copy_mode = {
        { key = 'Tab', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'Tab', mods = 'SHIFT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'Enter', mods = 'NONE', action = act.CopyMode('MoveToStartOfNextLine') },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'Space', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },

        -- Line navigation
        { key = '$', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = '$', mods = 'SHIFT', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = '0', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine') },
        { key = '^', mods = 'NONE', action = act.CopyMode('MoveToStartOfLineContent') },
        { key = '^', mods = 'SHIFT', action = act.CopyMode('MoveToStartOfLineContent') },

        -- Viewport navigation
        { key = 'G', mods = 'NONE', action = act.CopyMode('MoveToScrollbackBottom') },
        { key = 'G', mods = 'SHIFT', action = act.CopyMode('MoveToScrollbackBottom') },
        { key = 'g', mods = 'NONE', action = act.CopyMode('MoveToScrollbackTop') },
        { key = 'H', mods = 'NONE', action = act.CopyMode('MoveToViewportTop') },
        { key = 'H', mods = 'SHIFT', action = act.CopyMode('MoveToViewportTop') },
        { key = 'L', mods = 'NONE', action = act.CopyMode('MoveToViewportBottom') },
        { key = 'L', mods = 'SHIFT', action = act.CopyMode('MoveToViewportBottom') },
        { key = 'M', mods = 'NONE', action = act.CopyMode('MoveToViewportMiddle') },
        { key = 'M', mods = 'SHIFT', action = act.CopyMode('MoveToViewportMiddle') },

        -- Selection modes
        { key = 'V', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        { key = 'V', mods = 'SHIFT', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        { key = 'v', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = 'v', mods = 'CTRL', action = act.CopyMode({ SetSelectionMode = 'Block' }) },
        { key = 'O', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEndHoriz') },
        { key = 'O', mods = 'SHIFT', action = act.CopyMode('MoveToSelectionOtherEndHoriz') },
        { key = 'o', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEnd') },

        -- Word movement
        { key = 'b', mods = 'NONE', action = act.CopyMode('MoveBackwardWord') },
        { key = 'b', mods = 'ALT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'w', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'e', mods = 'NONE', action = act.CopyMode('MoveForwardWordEnd') },
        { key = 'f', mods = 'ALT', action = act.CopyMode('MoveForwardWord') },
        { key = 'm', mods = 'ALT', action = act.CopyMode('MoveToStartOfLineContent') },

        -- Character movement
        { key = 'h', mods = 'NONE', action = act.CopyMode('MoveLeft') },
        { key = 'j', mods = 'NONE', action = act.CopyMode('MoveDown') },
        { key = 'k', mods = 'NONE', action = act.CopyMode('MoveUp') },
        { key = 'l', mods = 'NONE', action = act.CopyMode('MoveRight') },

        -- Jump functionality
        { key = ',', mods = 'NONE', action = act.CopyMode('JumpReverse') },
        { key = ';', mods = 'NONE', action = act.CopyMode('JumpAgain') },
        { key = 'F', mods = 'NONE', action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
        { key = 'F', mods = 'SHIFT', action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
        { key = 'T', mods = 'NONE', action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
        { key = 'T', mods = 'SHIFT', action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
        { key = 'f', mods = 'NONE', action = act.CopyMode({ JumpForward = { prev_char = false } }) },
        { key = 't', mods = 'NONE', action = act.CopyMode({ JumpForward = { prev_char = true } }) },

        -- Page movement
        { key = 'b', mods = 'CTRL', action = act.CopyMode('PageUp') },
        { key = 'f', mods = 'CTRL', action = act.CopyMode('PageDown') },
        { key = 'd', mods = 'CTRL', action = act.CopyMode({ MoveByPage = 0.5 }) },
        { key = 'u', mods = 'CTRL', action = act.CopyMode({ MoveByPage = -0.5 }) },

        -- Copy and quit
        { key = 'y', mods = 'NONE', action = act.Multiple({ { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } }) },
        { key = 'q', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'c', mods = 'CTRL', action = act.CopyMode('Close') },
        { key = 'g', mods = 'CTRL', action = act.CopyMode('Close') },

        -- Arrow keys
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

    -- ========================================
    -- SEARCH MODE
    -- ========================================
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

    -- ========================================
    -- FONT RESIZE TABLE
    -- ========================================
    resize_font = {
        { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
        { key = 'j', mods = 'NONE', action = act.DecreaseFontSize },
        { key = 'k', mods = 'NONE', action = act.IncreaseFontSize },
        { key = 'q', mods = 'NONE', action = act.PopKeyTable },
        { key = 'r', mods = 'NONE', action = act.ResetFontSize },
    },

    -- ========================================
    -- PANE RESIZE TABLE
    -- ========================================
    resize_pane = {
        { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
        { key = 'h', mods = 'NONE', action = act.AdjustPaneSize { 'Left', 1 } },
        { key = 'j', mods = 'NONE', action = act.AdjustPaneSize { 'Down', 1 } },
        { key = 'k', mods = 'NONE', action = act.AdjustPaneSize { 'Up', 1 } },
        { key = 'l', mods = 'NONE', action = act.AdjustPaneSize { 'Right', 1 } },
        { key = 'q', mods = 'NONE', action = act.PopKeyTable },
    },
}

-- Add complex key tables from keybind_manager
local complex_key_tables = keybind_manager.generate_key_tables()
for table_name, table_keys in pairs(complex_key_tables) do
    key_tables[table_name] = table_keys
end

-- ============================================================================
-- MOUSE BINDINGS
-- ============================================================================

local mouse_bindings = {
    -- ========================================
    -- TEXT SELECTION WITH DRAG SUPPORT
    -- ========================================
    -- Single-click selection
    { event = { Down = { streak = 1, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Cell") },
    { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.Nop },
    { event = { Drag = { streak = 1, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Cell") },

    -- Double-click word selection
    { event = { Down = { streak = 2, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Word") },
    { event = { Up = { streak = 2, button = "Left" } }, mods = "NONE", action = act.Nop },
    { event = { Drag = { streak = 2, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Word") },

    -- Triple-click line selection
    { event = { Down = { streak = 3, button = "Left" } }, mods = "NONE", action = act.SelectTextAtMouseCursor("Line") },
    { event = { Up = { streak = 3, button = "Left" } }, mods = "NONE", action = act.Nop },
    { event = { Drag = { streak = 3, button = "Left" } }, mods = "NONE", action = act.ExtendSelectionToMouseCursor("Line") },

    -- ========================================
    -- LINK HANDLING
    -- ========================================
    { event = { Down = { streak = 1, button = "Left" } }, mods = mod.SUPER, action = act.Nop },
    { event = { Up = { streak = 1, button = "Left" } }, mods = mod.SUPER, action = act.OpenLinkAtMouseCursor },
    { event = { Drag = { streak = 1, button = "Left" } }, mods = mod.SUPER, action = act.ExtendSelectionToMouseCursor("Cell") },

    -- ========================================
    -- RIGHT CLICK CONTEXT ACTIONS
    -- ========================================
    { event = { Down = { streak = 1, button = "Right" } }, mods = "NONE", action = act.Nop },
    {
        event = { Up = { streak = 1, button = "Right" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""

            local context
            if keybind_manager and keybind_manager.detect_context then
                local success, result = pcall(keybind_manager.detect_context, window, pane)
                context = success and result or "default"
            else
                context = "default"
            end

            if has_selection then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
                if keybind_hints and keybind_hints.show_contextual_hints then
                    pcall(keybind_hints.show_contextual_hints, window, pane, context)
                end
            else
                window:perform_action(act.PasteFrom("Clipboard"), pane)
            end
        end),
    },

    -- ========================================
    -- MIDDLE CLICK CONTEXTUAL HINTS
    -- ========================================
    { event = { Down = { streak = 1, button = "Middle" } }, mods = "NONE", action = act.Nop },
    {
        event = { Up = { streak = 1, button = "Middle" } },
        mods = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local context
            if keybind_manager and keybind_manager.detect_context then
                local success, result = pcall(keybind_manager.detect_context, window, pane)
                context = success and result or "default"
            else
                context = "default"
            end

            if keybind_hints and keybind_hints.show_contextual_hints then
                pcall(keybind_hints.show_contextual_hints, window, pane, context)
            end
        end),
    },

    -- ========================================
    -- SCROLL WHEEL
    -- ========================================
    { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
    { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "NONE", action = act.ScrollByCurrentEventWheelDelta },
}

-- Add nano scroll mouse bindings
local nano_mouse_bindings = nano_scroll_fix.get_nano_mouse_bindings()
for _, binding in ipairs(nano_mouse_bindings) do
    table.insert(mouse_bindings, binding)
end

-- ============================================================================
-- CONFIGURATION ASSEMBLY
-- ============================================================================

local config = {
    -- Disable WezTerm defaults to use our comprehensive bindings
    disable_default_key_bindings = false,
    disable_default_mouse_bindings = false,

    -- Our unified bindings
    keys = keys,
    key_tables = key_tables,
    mouse_bindings = mouse_bindings,

    -- Leader key configuration
    leader = {
        key = 'Space',
        mods = mod.SUPER_REV,
        timeout_milliseconds = constants.TIMEOUTS.LEADER_KEY
    },
}

return config