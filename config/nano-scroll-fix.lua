local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

-- Enable mouse reporting for nano and other terminal applications
function M.setup_nano_mouse_support()
    -- Set TERM environment variable for better compatibility
    wezterm.on('spawn-tab-domain', function(cmd, env, cwd)
        if not env then
            env = {}
        end
        -- Ensure proper terminal type for nano
        env.TERM = 'xterm-256color'
        return cmd, env, cwd
    end)

    -- Configure mouse event handling for nano
    wezterm.on('update-status', function(window, pane)
        local process_name = pane:get_foreground_process_name()
        if process_name and process_name:match('nano') then
            -- Enable mouse support when nano is active
            window:set_config_overrides({
                enable_mouse_reporting = true,
                mouse_reporting_mode = 'ButtonEventTracking',
            })
        else
            -- Disable mouse reporting for other programs
            window:set_config_overrides({
                enable_mouse_reporting = false,
            })
        end
    end)
end

-- Alternative approach: Custom key bindings for nano scrolling
function M.get_nano_scroll_bindings()
    return {
        -- Scroll up/down in nano using Cmd+U/D (matches WezTerm's pane scrolling)
        {
            key = 'u',
            mods = 'SUPER',
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Page Up key to nano
                    window:perform_action(
                        act.SendKey({ key = 'PageUp' }),
                        pane
                    )
                else
                    -- Normal WezTerm scroll
                    window:perform_action(
                        act.ScrollByLine(-5),
                        pane
                    )
                end
            end),
        },
        {
            key = 'd',
            mods = 'SUPER',
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Page Down key to nano
                    window:perform_action(
                        act.SendKey({ key = 'PageDown' }),
                        pane
                    )
                else
                    -- Normal WezTerm scroll
                    window:perform_action(
                        act.ScrollByLine(5),
                        pane
                    )
                end
            end),
        },
    }
end

-- Mouse wheel scrolling for nano
function M.get_nano_mouse_bindings()
    return {
        -- Mouse wheel up - scroll up in nano
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = "NONE",
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Ctrl+Y (scroll up one line in nano)
                    window:perform_action(
                        act.SendKey({ key = 'y', mods = 'CTRL' }),
                        pane
                    )
                else
                    -- Normal WezTerm scroll
                    window:perform_action(
                        act.ScrollByLine(-3),
                        pane
                    )
                end
            end),
        },
        -- Mouse wheel down - scroll down in nano
        {
            event = { Down = { streak = 1, button = { WheelDown = 1 } } },
            mods = "NONE",
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Ctrl+V (scroll down one page in nano)
                    window:perform_action(
                        act.SendKey({ key = 'v', mods = 'CTRL' }),
                        pane
                    )
                else
                    -- Normal WezTerm scroll
                    window:perform_action(
                        act.ScrollByLine(3),
                        pane
                    )
                end
            end),
        },
        -- Option + scroll for page-based scrolling in nano
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = "OPT",
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Page Up to nano
                    window:perform_action(
                        act.SendKey({ key = 'PageUp' }),
                        pane
                    )
                else
                    -- Normal WezTerm page scroll
                    window:perform_action(
                        act.ScrollByPage(-0.5),
                        pane
                    )
                end
            end),
        },
        {
            event = { Down = { streak = 1, button = { WheelDown = 1 } } },
            mods = "OPT",
            action = wezterm.action_callback(function(window, pane)
                local process_name = pane:get_foreground_process_name()
                if process_name and process_name:match('nano') then
                    -- Send Page Down to nano
                    window:perform_action(
                        act.SendKey({ key = 'PageDown' }),
                        pane
                    )
                else
                    -- Normal WezTerm page scroll
                    window:perform_action(
                        act.ScrollByPage(0.5),
                        pane
                    )
                end
            end),
        },
    }
end

return M