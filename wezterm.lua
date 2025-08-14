local wezterm = require('wezterm')
local Config = require('config')

-- macOS system integration setup
local macos_integration = require('utils.macos-integration')

-- Initialize macOS integration on startup
if macos_integration.is_macos() then
   macos_integration.auto_setup()
end


-- Initialize nano scroll fix
local nano_scroll_fix = require('config.nano-scroll-fix')
nano_scroll_fix.setup_nano_mouse_support()

-- Initialize launch backdrop for visual startup with available images
local launch_backdrop = require('utils.launch-backdrop')
launch_backdrop.configure({
   duration = 2.0,  -- Show for 2 seconds (longer to see the image)
   backdrop_type = 'image',  -- Use available images instead of gradient
   show_message = true,
   image_brightness = 0.6,  -- Brighter images for better visibility
   overlay_opacity = 0.2,   -- Very light overlay so images are clearly visible
})

-- Startup optimizations: tmux integration removed for better performance

-- Optional: Create manual trigger for shell validation
wezterm.on('user-validate-shell', function()
   local shell_validation = require('utils.shell-validation')
   shell_validation.quick_validation()
   wezterm.log_info('Shell validation completed')
end)

-- Load key binding hints immediately (no delay needed)
wezterm.log_info('Key bindings: Complex key binding system loaded')
wezterm.log_info('Key bindings: Use Cmd+? for help, Leader key is Cmd+Ctrl+Space')

local backdrops = require('utils.backdrops')
backdrops:set_images()
backdrops:random()  -- Select a random backdrop on startup

require('events.left-status').setup()
require('events.right-status').setup({ date_format = '%a %H:%M:%S' })
require('events.tab-title').setup({ hide_active_tab_unseen = false, unseen_icon = 'circle' })
require('events.new-tab-button').setup()
require('events.ssh-status').setup()
require('events.launch-backdrop').setup()
require('events.auto-backdrop').setup()  -- Enable automatic backdrop rotation every 5 minutes

-- Load performance monitoring
require('performance-monitor')

-- Performance optimizations applied - all delayed operations removed

-- Optional: Load utilities only when needed via keybindings
wezterm.on('user-troubleshoot', function()
   local troubleshoot_validation = require('utils.troubleshoot-validation')
   troubleshoot_validation.setup()
   wezterm.log_info('Troubleshoot validation loaded on-demand')
end)

return Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
