-- Shell Integration Validation and Testing Framework
-- Comprehensive testing and validation for ZSH + tmux integration

local wezterm = require('wezterm')
local shell_integration = require('utils.shell-integration')
local M = {}

-- Test suite configuration
local TEST_CONFIG = {
   timeout = 5000,  -- 5 seconds timeout for shell commands
   retry_count = 3,
   session_name = 'wezterm-test-' .. os.time(),
}

-- Utility functions for testing
local function run_command_with_timeout(cmd, timeout)
   timeout = timeout or TEST_CONFIG.timeout

   local handle = io.popen(cmd .. ' 2>&1')
   if not handle then
      return false, 'Failed to execute command'
   end

   local result = handle:read('*a')
   local success = handle:close()

   return success, result:gsub('%s+$', '')  -- Trim trailing whitespace
end

local function test_command_exists(command)
   local success, output = run_command_with_timeout('which ' .. command)
   return success and output ~= '', output
end

-- Shell availability tests
function M.test_shell_availability()
   local tests = {
      zsh = {
         name = 'ZSH Availability',
         test = function()
            local exists, path = test_command_exists('zsh')
            if not exists then
               return false, 'ZSH not found in PATH'
            end

            local success, version = run_command_with_timeout(path .. ' --version')
            if not success then
               return false, 'ZSH version check failed'
            end

            return true, { path = path, version = version }
         end
      },

      tmux = {
         name = 'tmux Availability',
         test = function()
            local exists, path = test_command_exists('tmux')
            if not exists then
               return false, 'tmux not found in PATH'
            end

            local success, version = run_command_with_timeout(path .. ' -V')
            if not success then
               return false, 'tmux version check failed'
            end

            return true, { path = path, version = version }
         end
      },

      shell_integration_module = {
         name = 'Shell Integration Module',
         test = function()
            local success, error = pcall(require, 'utils.shell-integration')
            if not success then
               return false, 'Failed to load shell-integration module: ' .. error
            end

            -- Test key functions
            local functions_to_test = {
               'detect_shell',
               'get_tmux_sessions',
               'build_zsh_command',
               'build_tmux_command',
               'get_optimized_environment',
               'get_shell_profile'
            }

            for _, func_name in ipairs(functions_to_test) do
               if type(shell_integration[func_name]) ~= 'function' then
                  return false, 'Missing function: ' .. func_name
               end
            end

            return true, 'All functions available'
         end
      }
   }

   return M.run_test_suite('Shell Availability', tests)
end

-- Shell integration functionality tests
function M.test_shell_integration_functions()
   local tests = {
      detect_zsh = {
         name = 'ZSH Detection',
         test = function()
            local zsh_path = shell_integration.detect_shell('zsh')
            if not zsh_path then
               return false, 'ZSH detection returned nil'
            end

            -- Verify the path exists
            local f = io.open(zsh_path, 'r')
            if not f then
               return false, 'Detected ZSH path does not exist: ' .. zsh_path
            end
            f:close()

            return true, 'ZSH detected at: ' .. zsh_path
         end
      },

      detect_tmux = {
         name = 'tmux Detection',
         test = function()
            local tmux_path = shell_integration.detect_shell('tmux')
            if not tmux_path then
               return false, 'tmux detection returned nil'
            end

            -- Verify the path exists
            local f = io.open(tmux_path, 'r')
            if not f then
               return false, 'Detected tmux path does not exist: ' .. tmux_path
            end
            f:close()

            return true, 'tmux detected at: ' .. tmux_path
         end
      },

      environment_generation = {
         name = 'Environment Variable Generation',
         test = function()
            local env = shell_integration.get_optimized_environment()

            if type(env) ~= 'table' then
               return false, 'Environment generation returned non-table'
            end

            local required_vars = { 'SHELL', 'TERM', 'COLORTERM' }
            for _, var in ipairs(required_vars) do
               if not env[var] then
                  return false, 'Missing required environment variable: ' .. var
               end
            end

            return true, string.format('Generated %d environment variables', #env)
         end
      },

      command_building = {
         name = 'Command Building',
         test = function()
            -- Test ZSH command building
            local zsh_cmd = shell_integration.build_zsh_command({ login = true })
            if not zsh_cmd or type(zsh_cmd) ~= 'table' or #zsh_cmd == 0 then
               return false, 'ZSH command building failed'
            end

            -- Test tmux command building
            local tmux_cmd = shell_integration.build_tmux_command({ session_name = TEST_CONFIG.session_name })
            if not tmux_cmd or type(tmux_cmd) ~= 'table' or #tmux_cmd == 0 then
               return false, 'tmux command building failed'
            end

            return true, 'Commands built successfully'
         end
      },

      profile_generation = {
         name = 'Shell Profile Generation',
         test = function()
            local profiles = { 'default', 'zsh_only', 'tmux_new', 'development' }

            for _, profile_name in ipairs(profiles) do
               local profile = shell_integration.get_shell_profile(profile_name)

               if type(profile) ~= 'table' then
                  return false, 'Profile "' .. profile_name .. '" is not a table'
               end

               if not profile.command or not profile.environment or not profile.description then
                  return false, 'Profile "' .. profile_name .. '" missing required fields'
               end
            end

            return true, 'All profiles generated successfully'
         end
      }
   }

   return M.run_test_suite('Shell Integration Functions', tests)
end

-- tmux session management tests
function M.test_tmux_session_management()
   local tests = {
      session_listing = {
         name = 'Session Listing',
         test = function()
            local sessions = shell_integration.get_tmux_sessions()

            if type(sessions) ~= 'table' then
               return false, 'Session listing returned non-table'
            end

            -- Validate session structure if sessions exist
            for i, session in ipairs(sessions) do
               if not session.name or not session.windows or not session.created then
                  return false, 'Session ' .. i .. ' missing required fields'
               end
            end

            return true, string.format('Found %d tmux sessions', #sessions)
         end
      },

      session_creation = {
         name = 'Session Creation',
         test = function()
            local test_session = TEST_CONFIG.session_name

            -- Clean up any existing test session
            local tmux_path = shell_integration.detect_shell('tmux')
            if tmux_path then
               os.execute(tmux_path .. ' kill-session -t "' .. test_session .. '" 2>/dev/null')
            end

            local success, result = shell_integration.create_tmux_session(test_session)

            if not success then
               return false, 'Session creation failed: ' .. (result or 'unknown error')
            end

            -- Verify session was created
            local sessions = shell_integration.get_tmux_sessions()
            local found = false
            for _, session in ipairs(sessions) do
               if session.name == test_session then
                  found = true
                  break
               end
            end

            -- Clean up test session
            if tmux_path then
               os.execute(tmux_path .. ' kill-session -t "' .. test_session .. '" 2>/dev/null')
            end

            if not found then
               return false, 'Created session not found in session list'
            end

            return true, 'Session created and verified successfully'
         end
      }
   }

   return M.run_test_suite('tmux Session Management', tests)
end

-- Integration validation tests
function M.test_integration_validation()
   local tests = {
      validation_comprehensive = {
         name = 'Comprehensive Validation',
         test = function()
            local validation = shell_integration.validate_shell_integration()

            if type(validation) ~= 'table' then
               return false, 'Validation returned non-table'
            end

            local required_fields = { 'zsh', 'tmux', 'environment', 'sessions', 'integration_score', 'status' }
            for _, field in ipairs(required_fields) do
               if validation[field] == nil then
                  return false, 'Validation missing field: ' .. field
               end
            end

            return true, string.format('Validation complete (score: %d, status: %s)',
               validation.integration_score, validation.status)
         end
      },

      integration_test_suite = {
         name = 'Integration Test Suite',
         test = function()
            local test_results = shell_integration.test_shell_integration()

            if type(test_results) ~= 'table' then
               return false, 'Test results returned non-table'
            end

            if not test_results.total or not test_results.passed or not test_results.status then
               return false, 'Test results missing required fields'
            end

            return test_results.status == 'pass',
               string.format('Tests: %d/%d passed (%.0f%%)',
                  test_results.passed, test_results.total, test_results.score)
         end
      }
   }

   return M.run_test_suite('Integration Validation', tests)
end

-- Test runner utility
function M.run_test_suite(suite_name, tests)
   wezterm.log_info('Shell validation: Running ' .. suite_name .. ' tests...')

   local results = {
      suite = suite_name,
      total = 0,
      passed = 0,
      failed = 0,
      tests = {},
      score = 0,
      status = 'unknown'
   }

   for test_id, test_config in pairs(tests) do
      results.total = results.total + 1
      local test_result = {
         id = test_id,
         name = test_config.name,
         passed = false,
         error = nil,
         result = nil,
         duration = 0
      }

      local start_time = os.clock()

      -- Run test with error handling
      local success, test_passed, test_output = pcall(test_config.test)

      test_result.duration = os.clock() - start_time

      if success and test_passed then
         test_result.passed = true
         test_result.result = test_output
         results.passed = results.passed + 1
         wezterm.log_info(string.format('%s: %s - PASS (%.2fs)',
            suite_name, test_config.name, test_result.duration))
      else
         test_result.passed = false
         test_result.error = test_output or (success and 'Test returned false' or 'Test threw exception')
         results.failed = results.failed + 1
         wezterm.log_error(string.format('%s: %s - FAIL: %s (%.2fs)',
            suite_name, test_config.name, test_result.error, test_result.duration))
      end

      results.tests[test_id] = test_result
   end

   -- Calculate score and status
   results.score = (results.passed / results.total) * 100
   results.status = results.score >= 80 and 'pass' or results.score >= 60 and 'warning' or 'fail'

   wezterm.log_info(string.format('%s: Complete (%d/%d passed, %.0f%%, %s)',
      suite_name, results.passed, results.total, results.score, results.status))

   return results
end

-- Comprehensive validation suite
function M.run_full_validation()
   wezterm.log_info('Shell validation: Starting comprehensive validation suite...')

   local suites = {
      { name = 'Shell Availability', func = M.test_shell_availability },
      { name = 'Shell Integration Functions', func = M.test_shell_integration_functions },
      { name = 'tmux Session Management', func = M.test_tmux_session_management },
      { name = 'Integration Validation', func = M.test_integration_validation },
   }

   local overall_results = {
      suites = {},
      total_tests = 0,
      total_passed = 0,
      total_failed = 0,
      overall_score = 0,
      status = 'unknown',
      start_time = os.time(),
      duration = 0
   }

   for _, suite in ipairs(suites) do
      local suite_results = suite.func()
      overall_results.suites[suite.name] = suite_results
      overall_results.total_tests = overall_results.total_tests + suite_results.total
      overall_results.total_passed = overall_results.total_passed + suite_results.passed
      overall_results.total_failed = overall_results.total_failed + suite_results.failed
   end

   overall_results.duration = os.time() - overall_results.start_time
   overall_results.overall_score = (overall_results.total_passed / overall_results.total_tests) * 100
   overall_results.status = overall_results.overall_score >= 85 and 'excellent' or
                            overall_results.overall_score >= 70 and 'good' or
                            overall_results.overall_score >= 50 and 'acceptable' or 'poor'

   wezterm.log_info(string.format(
      'Shell validation: Full validation complete - %s (%d/%d tests passed, %.0f%%, %ds)',
      overall_results.status,
      overall_results.total_passed,
      overall_results.total_tests,
      overall_results.overall_score,
      overall_results.duration
   ))

   return overall_results
end

-- Quick validation for startup
function M.quick_validation()
   local validation = shell_integration.validate_shell_integration()
   local score = validation.integration_score

   if score >= 90 then
      wezterm.log_info('Shell validation: Excellent integration (score: ' .. score .. '/100)')
   elseif score >= 70 then
      wezterm.log_info('Shell validation: Good integration (score: ' .. score .. '/100)')
   elseif score >= 50 then
      wezterm.log_warn('Shell validation: Acceptable integration (score: ' .. score .. '/100)')
   else
      wezterm.log_error('Shell validation: Poor integration (score: ' .. score .. '/100)')
      if #validation.recommendations > 0 then
         wezterm.log_warn('Shell validation: Recommendations:')
         for _, rec in ipairs(validation.recommendations) do
            wezterm.log_warn('  - ' .. rec)
         end
      end
   end

   return validation
end

return M