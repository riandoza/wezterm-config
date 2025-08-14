local wezterm = require('wezterm')
local backdrops = require('utils.backdrops')

local M = {}

-- Configuration
local AUTO_CHANGE_INTERVAL = 30 * 60 * 1000  -- 30 minutes in milliseconds (was 5 minutes)
local timer_id = nil

-- Function to change backdrop
local function change_backdrop()
    wezterm.GLOBAL.backdrop_auto_change_active = true

    -- Get all windows and change backdrop for each
    for _, window in ipairs(wezterm.gui.gui_windows()) do
        backdrops:random(window)
    end
end

-- Setup automatic backdrop rotation
function M.setup()
    -- Initial setup flag
    if wezterm.GLOBAL.backdrop_auto_change_initialized then
        return
    end
    wezterm.GLOBAL.backdrop_auto_change_initialized = true
    wezterm.GLOBAL.backdrop_auto_change_active = true

    -- Register the timer event
    wezterm.on('backdrop-auto-change', function()
        if wezterm.GLOBAL.backdrop_auto_change_active then
            change_backdrop()
        end
    end)

    -- Start the timer
    timer_id = wezterm.time.call_after(AUTO_CHANGE_INTERVAL / 1000, function()
        wezterm.emit('backdrop-auto-change')
        -- Re-register the timer for continuous rotation
        M.setup_timer()
    end)

    wezterm.log_info('Auto backdrop rotation enabled: Changes every 30 minutes')
end

-- Setup recurring timer
function M.setup_timer()
    timer_id = wezterm.time.call_after(AUTO_CHANGE_INTERVAL / 1000, function()
        wezterm.emit('backdrop-auto-change')
        -- Re-register the timer for continuous rotation
        M.setup_timer()
    end)
end

-- Toggle auto backdrop change
function M.toggle()
    wezterm.GLOBAL.backdrop_auto_change_active = not wezterm.GLOBAL.backdrop_auto_change_active

    local status = wezterm.GLOBAL.backdrop_auto_change_active and "enabled" or "disabled"
    wezterm.log_info('Auto backdrop rotation ' .. status)

    -- Show notification in all windows
    for _, window in ipairs(wezterm.gui.gui_windows()) do
        window:toast_notification('WezTerm', 'Auto backdrop rotation ' .. status, nil, 2000)
    end

    return wezterm.GLOBAL.backdrop_auto_change_active
end

-- Stop auto backdrop change
function M.stop()
    wezterm.GLOBAL.backdrop_auto_change_active = false
    if timer_id then
        -- Note: WezTerm doesn't have a direct way to cancel timers
        -- Setting the flag to false will prevent the callback from changing backdrops
        timer_id = nil
    end
    wezterm.log_info('Auto backdrop rotation stopped')
end

-- Set custom interval (in minutes)
function M.set_interval(minutes)
    AUTO_CHANGE_INTERVAL = minutes * 60 * 1000
    wezterm.log_info('Auto backdrop interval set to ' .. minutes .. ' minutes')
    -- Restart the timer with new interval
    M.stop()
    M.setup()
end

-- Register event handlers
wezterm.on('toggle-auto-backdrop', function(window, pane)
    M.toggle()
end)

wezterm.on('set-backdrop-interval', function(window, pane, minutes)
    if minutes and type(minutes) == 'number' and minutes > 0 then
        M.set_interval(minutes)
    end
end)

-- Show current status
wezterm.on('show-backdrop-status', function(window, pane)
    local status = wezterm.GLOBAL.backdrop_auto_change_active and "enabled" or "disabled"
    local interval = AUTO_CHANGE_INTERVAL / 60000  -- Convert to minutes
    local message = string.format('Auto backdrop rotation: %s\nInterval: %.1f minutes', status, interval)
    window:toast_notification('Backdrop Status', message, nil, 3000)
end)

return M