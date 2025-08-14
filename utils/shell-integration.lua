-- ZSH + tmux Shell Integration Module for WezTerm
-- Handles shell detection, tmux session management, and environment optimization

local wezterm = require('wezterm')
local platform = require('utils.platform')
local M = {}

-- Configuration constants
local DEFAULT_SHELL_PATHS = {
   zsh = { '/bin/zsh', '/usr/bin/zsh', '/usr/local/bin/zsh', '/opt/homebrew/bin/zsh' },
   tmux = { '/opt/homebrew/bin/tmux', '/usr/local/bin/tmux', '/usr/bin/tmux' },
}

-- Shell detection functions
function M.detect_shell(shell_name)
   local paths = DEFAULT_SHELL_PATHS[shell_name] or {}

   -- Try common paths first
   for _, path in ipairs(paths) do
      local f = io.open(path, 'r')
      if f then
         f:close()
         return path
      end
   end

   -- Fallback to which command
   local handle = io.popen('which ' .. shell_name .. ' 2>/dev/null')
   if handle then
      local result = handle:read('*a'):gsub('%s+', '')
      handle:close()
      if result ~= '' then
         return result
      end
   end

   return nil
end

function M.get_shell_version(shell_path)
   if not shell_path then return nil end

   local handle = io.popen(shell_path .. ' --version 2>/dev/null')
   if handle then
      local version = handle:read('*a')
      handle:close()
      return version:match('([%d%.]+)') or 'unknown'
   end

   return nil
end

-- tmux session management
function M.get_tmux_sessions()
   local tmux_path = M.detect_shell('tmux')
   if not tmux_path then
      return {}
   end

   local handle = io.popen(tmux_path .. ' list-sessions -F "#{session_name}:#{session_windows}:#{session_created}" 2>/dev/null')
   if not handle then
      return {}
   end

   local sessions = {}
   for line in handle:lines() do
      local name, windows, created = line:match('([^:]+):([^:]+):([^:]+)')
      if name then
         table.insert(sessions, {
            name = name,
            windows = tonumber(windows) or 0,
            created = created,
            active = false
         })
      end
   end
   handle:close()

   return sessions
end

function M.get_active_tmux_session()
   local tmux_path = M.detect_shell('tmux')
   if not tmux_path then
      return nil
   end

   local handle = io.popen(tmux_path .. ' display-message -p "#{session_name}" 2>/dev/null')
   if handle then
      local session = handle:read('*a'):gsub('%s+', '')
      handle:close()
      return session ~= '' and session or nil
   end

   return nil
end

function M.create_tmux_session(session_name)
   local tmux_path = M.detect_shell('tmux')
   if not tmux_path then
      return false, 'tmux not found'
   end

   session_name = session_name or ('wezterm-' .. os.time())
   local cmd = string.format('%s new-session -d -s "%s" 2>/dev/null', tmux_path, session_name)
   local success = os.execute(cmd) == 0

   if success then
      wezterm.log_info('Shell integration: Created tmux session "' .. session_name .. '"')
      return true, session_name
   else
      wezterm.log_error('Shell integration: Failed to create tmux session "' .. session_name .. '"')
      return false, 'Failed to create session'
   end
end

-- Environment optimization
function M.get_optimized_environment()
   local zsh_path = M.detect_shell('zsh')
   local tmux_path = M.detect_shell('tmux')

   local env = {
      SHELL = zsh_path or '/bin/zsh',
      TERM = 'xterm-256color',  -- Better tmux compatibility
      COLORTERM = 'truecolor',
      LANG = os.getenv('LANG') or 'en_US.UTF-8',
      LC_ALL = os.getenv('LC_ALL') or 'en_US.UTF-8',
   }

   -- tmux-specific optimizations for faster startup
   if tmux_path then
      env.TMUX_TMPDIR = os.getenv('TMPDIR') or '/tmp'
      env.TMUX_SOCKET = 'wezterm'
      -- Optimize tmux startup performance
      env.TMUX_PLUGIN_MANAGER_PATH = os.getenv('HOME') .. '/.tmux/plugins/'
      env.DISABLE_AUTO_TITLE = 'true'  -- Disable automatic title updates for speed
   end

   -- ZSH-specific optimizations for faster startup
   if zsh_path then
      env.ZSH_DISABLE_COMPFIX = 'true'           -- Disable insecure directory warnings
      env.DISABLE_AUTO_UPDATE = 'true'           -- Disable oh-my-zsh auto-updates
      env.DISABLE_UNTRACKED_FILES_DIRTY = 'true' -- Speed up git status
      env.ZSH_AUTOSUGGEST_MANUAL_REBIND = '1'    -- Improve autosuggest performance
      env.HIST_STAMPS = 'yyyy-mm-dd'             -- Optimize history timestamps
   end

   return env
end

-- Shell command builders
function M.build_zsh_command(options)
   options = options or {}
   local zsh_path = M.detect_shell('zsh')

   if not zsh_path then
      wezterm.log_error('Shell integration: ZSH not found')
      return nil
   end

   local cmd = { zsh_path }

   -- Add login shell flag
   if options.login ~= false then
      table.insert(cmd, '-l')
   end

   -- Add interactive flag
   if options.interactive ~= false then
      table.insert(cmd, '-i')
   end

   -- Add custom command
   if options.command then
      table.insert(cmd, '-c')
      table.insert(cmd, options.command)
   end

   return cmd
end

function M.build_tmux_command(options)
   options = options or {}
   local tmux_path = M.detect_shell('tmux')
   local zsh_path = M.detect_shell('zsh')

   if not tmux_path then
      wezterm.log_error('Shell integration: tmux not found')
      return M.build_zsh_command(options)
   end

   local sessions = M.get_tmux_sessions()

   -- Generate unique session name per tab to prevent session sharing
   local session_name
   if options.unique_session then
      session_name = string.format('wezterm-tab-%d-%d', os.time(), math.random(1000, 9999))
   elseif options.session_name then
      session_name = options.session_name
   else
      session_name = 'wezterm-main'
   end

   -- Build optimized tmux command with performance flags
   local tmux_cmd
   local performance_flags = '-2 -u'  -- Force 256 colors and UTF-8

   if #sessions > 0 and not options.new_session and not options.unique_session then
      -- Attach to existing session with performance optimizations (only for shared sessions)
      local target_session = sessions[1].name  -- Use first available session
      for _, session in ipairs(sessions) do
         if session.name == session_name then
            target_session = session.name
            break
         end
      end
      tmux_cmd = string.format('%s %s attach-session -t "%s"', tmux_path, performance_flags, target_session)
      wezterm.log_info('Shell integration: Attaching to tmux session "' .. target_session .. '"')
   else
      -- Create new session with optimizations
      local shell_cmd = table.concat(M.build_zsh_command({ login = true }) or { '/bin/zsh', '-l' }, ' ')
      -- Add socket optimization and disable initial command delay
      tmux_cmd = string.format('%s %s -S /tmp/tmux-wezterm-%s new-session -d -s "%s" "%s"; %s %s -S /tmp/tmux-wezterm-%s attach-session -t "%s"',
         tmux_path, performance_flags, session_name, session_name, shell_cmd, tmux_path, performance_flags, session_name, session_name)
      wezterm.log_info('Shell integration: Creating new tmux session "' .. session_name .. '" with performance optimizations')
   end

   -- Wrap in ZSH for proper execution with environment optimization
   return M.build_zsh_command({
      login = false,
      interactive = false,
      command = tmux_cmd
   })
end

-- Integration profiles
function M.get_shell_profile(profile_name)
   profile_name = profile_name or 'default'

   local profiles = {
      default = {
         description = 'ZSH with tmux auto-attach',
         command = M.build_tmux_command({ session_name = 'main' }),
         environment = M.get_optimized_environment(),
      },

      zsh_only = {
         description = 'ZSH without tmux',
         command = M.build_zsh_command({ login = true }),
         environment = M.get_optimized_environment(),
      },

      tmux_new = {
         description = 'ZSH with new tmux session (unique per tab)',
         command = M.build_tmux_command({ new_session = true, unique_session = true }),
         environment = M.get_optimized_environment(),
      },

      tmux_shared = {
         description = 'ZSH with shared tmux session',
         command = M.build_tmux_command({ session_name = 'shared' }),
         environment = M.get_optimized_environment(),
      },

      development = {
         description = 'Development environment with tmux',
         command = M.build_tmux_command({ session_name = 'dev' }),
         environment = (function()
            local base_env = M.get_optimized_environment()
            local dev_env = {
               EDITOR = 'nvim',
               VISUAL = 'nvim',
               PAGER = 'less',
               MANPAGER = 'less',
            }
            for k, v in pairs(dev_env) do
               base_env[k] = v
            end
            return base_env
         end)(),
      },
   }

   return profiles[profile_name] or profiles.default
end

-- Validation functions
function M.validate_shell_integration()
   local results = {
      zsh = { available = false, path = nil, version = nil },
      tmux = { available = false, path = nil, version = nil },
      environment = {},
      sessions = {},
      recommendations = {},
   }

   -- Check ZSH
   local zsh_path = M.detect_shell('zsh')
   if zsh_path then
      results.zsh.available = true
      results.zsh.path = zsh_path
      results.zsh.version = M.get_shell_version(zsh_path)
   else
      table.insert(results.recommendations, 'Install ZSH: brew install zsh')
   end

   -- Check tmux
   local tmux_path = M.detect_shell('tmux')
   if tmux_path then
      results.tmux.available = true
      results.tmux.path = tmux_path
      results.tmux.version = M.get_shell_version(tmux_path)
      results.sessions = M.get_tmux_sessions()
   else
      table.insert(results.recommendations, 'Install tmux: brew install tmux')
   end

   -- Check environment
   results.environment = M.get_optimized_environment()

   -- Generate integration score
   local score = 0
   if results.zsh.available then score = score + 50 end
   if results.tmux.available then score = score + 40 end
   if #results.sessions > 0 then score = score + 10 end

   results.integration_score = score
   results.status = score >= 90 and 'excellent' or score >= 50 and 'good' or 'needs_improvement'

   return results
end

function M.test_shell_integration()
   wezterm.log_info('Shell integration: Running integration tests...')

   local tests = {
      { name = 'ZSH Detection', func = function() return M.detect_shell('zsh') ~= nil end },
      { name = 'tmux Detection', func = function() return M.detect_shell('tmux') ~= nil end },
      { name = 'Environment Generation', func = function()
         local env = M.get_optimized_environment()
         return env.SHELL and env.TERM and env.COLORTERM
      end },
      { name = 'Command Building', func = function()
         local cmd = M.build_zsh_command({ login = true })
         return cmd and #cmd > 0
      end },
      { name = 'Session Detection', func = function()
         local sessions = M.get_tmux_sessions()
         return sessions ~= nil  -- Should return table even if empty
      end },
   }

   local results = {}
   local passed = 0

   for _, test in ipairs(tests) do
      local success, result = pcall(test.func)
      local status = success and result

      results[test.name] = {
         passed = status,
         error = not success and result or nil
      }

      if status then
         passed = passed + 1
         wezterm.log_info('Shell integration test: ' .. test.name .. ' - PASS')
      else
         wezterm.log_error('Shell integration test: ' .. test.name .. ' - FAIL: ' .. (result or 'Unknown error'))
      end
   end

   local test_score = (passed / #tests) * 100
   wezterm.log_info(string.format('Shell integration: Tests completed (%d/%d passed, %.0f%%)', passed, #tests, test_score))

   return {
      total = #tests,
      passed = passed,
      failed = #tests - passed,
      score = test_score,
      results = results,
      status = test_score >= 80 and 'pass' or 'fail'
   }
end

-- Integration setup
function M.setup()
   wezterm.log_info('Shell integration: Initializing ZSH + tmux integration...')

   local validation = M.validate_shell_integration()

   -- Log validation results
   wezterm.log_info(string.format(
      'Shell integration: Status %s (score: %d/100)',
      validation.status,
      validation.integration_score
   ))

   if validation.zsh.available then
      wezterm.log_info('Shell integration: ZSH available at ' .. validation.zsh.path .. ' (version: ' .. (validation.zsh.version or 'unknown') .. ')')
   end

   if validation.tmux.available then
      wezterm.log_info('Shell integration: tmux available at ' .. validation.tmux.path .. ' (version: ' .. (validation.tmux.version or 'unknown') .. ')')
      if #validation.sessions > 0 then
         wezterm.log_info('Shell integration: Found ' .. #validation.sessions .. ' tmux sessions')
      end
   end

   -- Print recommendations
   if #validation.recommendations > 0 then
      wezterm.log_warn('Shell integration: Recommendations:')
      for _, rec in ipairs(validation.recommendations) do
         wezterm.log_warn('  - ' .. rec)
      end
   end

   return validation.status ~= 'needs_improvement'
end

return M