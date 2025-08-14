---@diagnostic disable: undefined-global
-- macOS Integration Module for WezTerm
-- Handles setting WezTerm as default terminal and system integration

local wezterm = require('wezterm')
local M = {}

-- Configuration constants
local WEZTERM_BUNDLE_ID = 'com.github.wez.wezterm'
local WEZTERM_APP_PATH = '/Users/' .. os.getenv('USER') .. '/Applications/WezTerm.app'
local TERMINAL_URL_SCHEME = 'x-man-page'

-- System detection
function M.is_macos()
   local uname = io.popen('uname -s'):read('*a'):gsub('%s+', '')
   return uname == 'Darwin'
end

function M.get_macos_version()
   if not M.is_macos() then
      return nil
   end
   local version = io.popen('sw_vers -productVersion'):read('*a'):gsub('%s+', '')
   return version
end

-- WezTerm installation detection
function M.detect_wezterm_installation()
   local install_paths = {
      '/Applications/WezTerm.app',
      '/Users/' .. os.getenv('USER') .. '/Applications/WezTerm.app',
      '/opt/homebrew/Applications/WezTerm.app',
   }

   for _, path in ipairs(install_paths) do
      local info_plist = path .. '/Contents/Info.plist'
      local f = io.open(info_plist, 'r')
      if f then
         f:close()
         return path
      end
   end

   return nil
end

-- Launch Services integration
function M.register_url_scheme()
   if not M.is_macos() then
      wezterm.log_warn('macOS integration: Not running on macOS')
      return false
   end

   local app_path = M.detect_wezterm_installation()
   if not app_path then
      wezterm.log_error('macOS integration: WezTerm.app not found')
      return false
   end

   -- Register WezTerm for terminal URL schemes
   local register_cmd = string.format(
      'defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \'{LSHandlerContentType="public.unix-executable";LSHandlerRoleAll="%s";}\'',
      WEZTERM_BUNDLE_ID
   )

   local success = os.execute(register_cmd)
   if success == 0 then
      -- Refresh Launch Services database
      os.execute('/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user')
      wezterm.log_info('macOS integration: Successfully registered URL scheme handler')
      return true
   else
      wezterm.log_error('macOS integration: Failed to register URL scheme handler')
      return false
   end
end

-- Terminal.app replacement
function M.set_default_terminal()
   if not M.is_macos() then
      wezterm.log_warn('macOS integration: Not running on macOS')
      return false
   end

   local app_path = M.detect_wezterm_installation()
   if not app_path then
      wezterm.log_error('macOS integration: WezTerm.app not found')
      return false
   end

   -- Set WezTerm as default terminal application
   local set_default_cmd = string.format(
      'defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \'{LSHandlerContentType="public.shell-script";LSHandlerRoleAll="%s";}\'',
      WEZTERM_BUNDLE_ID
   )

   local success = os.execute(set_default_cmd)
   if success == 0 then
      wezterm.log_info('macOS integration: Set WezTerm as default terminal')

      -- Also handle .command files
      local command_handler = string.format(
         'defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \'{LSHandlerContentType="com.apple.terminal.shell-script";LSHandlerRoleAll="%s";}\'',
         WEZTERM_BUNDLE_ID
      )
      os.execute(command_handler)

      -- Refresh Launch Services
      os.execute('/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user')
      return true
   else
      wezterm.log_error('macOS integration: Failed to set as default terminal')
      return false
   end
end

-- Dock integration
function M.setup_dock_integration()
   if not M.is_macos() then
      return false
   end

   local app_path = M.detect_wezterm_installation()
   if not app_path then
      return false
   end

   -- Add WezTerm to Dock if not present
   local dock_check = string.format(
      'defaults read com.apple.dock persistent-apps | grep -q "%s"',
      WEZTERM_BUNDLE_ID
   )

   if os.execute(dock_check) ~= 0 then
      local add_to_dock = string.format([[
         defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%s</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
      ]], app_path)

      if os.execute(add_to_dock) == 0 then
         os.execute('killall Dock')
         wezterm.log_info('macOS integration: Added WezTerm to Dock')
         return true
      end
   end

   return false
end

-- System preferences integration
function M.setup_system_preferences()
   if not M.is_macos() then
      return false
   end

   -- Set Terminal preferences to use WezTerm
   local prefs = {
      -- Set WezTerm as preferred terminal
      'defaults write com.apple.Terminal "Default Window Settings" -string "WezTerm"',
      -- Set shell integration
      'defaults write com.apple.Terminal Shell -string "/bin/zsh"',
   }

   local success = true
   for _, cmd in ipairs(prefs) do
      if os.execute(cmd) ~= 0 then
         success = false
         wezterm.log_warn('macOS integration: Failed to set preference: ' .. cmd)
      end
   end

   return success
end

-- Validation functions
function M.validate_integration()
   if not M.is_macos() then
      return { success = false, reason = 'Not running on macOS' }
   end

   local app_path = M.detect_wezterm_installation()
   if not app_path then
      return { success = false, reason = 'WezTerm.app not found' }
   end

   -- Check Launch Services registration
   local ls_check = string.format(
      '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -q "%s"',
      WEZTERM_BUNDLE_ID
   )

   if os.execute(ls_check) == 0 then
      return {
         success = true,
         app_path = app_path,
         bundle_id = WEZTERM_BUNDLE_ID,
         registered = true
      }
   else
      return {
         success = false,
         reason = 'Not registered with Launch Services',
         app_path = app_path
      }
   end
end

-- Main setup function
function M.setup()
   if not M.is_macos() then
      wezterm.log_warn('macOS integration: Skipping setup on non-macOS system')
      return false
   end

   wezterm.log_info('macOS integration: Starting setup...')

   local steps = {
      { name = 'URL Scheme Registration', func = M.register_url_scheme },
      { name = 'Default Terminal Setup', func = M.set_default_terminal },
      { name = 'Dock Integration', func = M.setup_dock_integration },
      { name = 'System Preferences', func = M.setup_system_preferences },
   }

   local success_count = 0
   for _, step in ipairs(steps) do
      wezterm.log_info('macOS integration: ' .. step.name .. '...')
      if step.func() then
         success_count = success_count + 1
         wezterm.log_info('macOS integration: ' .. step.name .. ' - SUCCESS')
      else
         wezterm.log_warn('macOS integration: ' .. step.name .. ' - FAILED')
      end
   end

   local validation = M.validate_integration()
   if validation.success then
      wezterm.log_info(string.format(
         'macOS integration: Setup complete (%d/%d steps successful)',
         success_count, #steps
      ))
      return true
   else
      wezterm.log_error('macOS integration: Setup failed - ' .. validation.reason)
      return false
   end
end

-- Auto-setup on module load (can be disabled)
function M.auto_setup()
   if M.is_macos() then
      -- OPTIMIZED: Remove the blocking 2-second delay
      -- Make setup truly asynchronous and optional
      wezterm.log_info('macOS integration: Skipping auto-setup to prevent startup delays')
      wezterm.log_info('macOS integration: Run manual setup via user-macos-setup event if needed')
   end
end

-- Manual setup trigger for on-demand configuration
wezterm.on('user-macos-setup', function()
   if M.is_macos() then
      wezterm.log_info('macOS integration: Starting manual setup...')
      M.setup()
   else
      wezterm.log_warn('macOS integration: Not running on macOS')
   end
end)

return M