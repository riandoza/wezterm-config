-- SSH Connection Status Integration for WezTerm
-- Real-time SSH connection monitoring and status display

local wezterm = require('wezterm')
local ssh_connection_manager = require('utils.ssh-connection-manager')
local M = {}

-- Configuration for SSH status display
M.config = {
   show_connection_status = true,
   show_connection_count = true,
   update_interval = 5,  -- seconds
   status_timeout = 10,  -- seconds to show status messages
}

-- SSH status event handlers
function M.on_ssh_domain_connect(domain_name)
   ssh_connection_manager.on_domain_connect(domain_name)

   if M.config.show_connection_status then
      wezterm.gui.gui_windows()[1]:toast_notification(
         'SSH Connection',
         '✅ Connected to ' .. domain_name,
         nil,
         M.config.status_timeout * 1000
      )
   end
end

function M.on_ssh_domain_disconnect(domain_name)
   ssh_connection_manager.on_domain_disconnect(domain_name)

   if M.config.show_connection_status then
      wezterm.gui.gui_windows()[1]:toast_notification(
         'SSH Connection',
         '❌ Disconnected from ' .. domain_name,
         nil,
         M.config.status_timeout * 1000
      )
   end
end

-- Status line integration
function M.get_ssh_status_elements()
   local stats = ssh_connection_manager.get_connection_stats()
   local elements = {}

   if stats.connected_domains > 0 then
      table.insert(elements, {
         Background = { Color = '#2ecc71' },
         Foreground = { Color = '#ffffff' },
         Text = string.format(' 🔗 SSH:%d ', stats.connected_domains),
      })
   end

   if stats.failed_domains > 0 then
      table.insert(elements, {
         Background = { Color = '#e74c3c' },
         Foreground = { Color = '#ffffff' },
         Text = string.format(' ❌ FAIL:%d ', stats.failed_domains),
      })
   end

   if stats.connecting_domains > 0 then
      table.insert(elements, {
         Background = { Color = '#f39c12' },
         Foreground = { Color = '#ffffff' },
         Text = string.format(' ⏳ CONN:%d ', stats.connecting_domains),
      })
   end

   return elements
end

-- Detailed SSH status display
function M.show_detailed_status(window)
   local stats = ssh_connection_manager.get_connection_stats()

   local status_lines = {
      '📊 SSH Connection Status',
      '═══════════════════════',
      '',
      string.format('Total Domains: %d', stats.total_domains),
      string.format('Connected: %d', stats.connected_domains),
      string.format('Failed: %d', stats.failed_domains),
      string.format('Connecting: %d', stats.connecting_domains),
      '',
   }

   if stats.average_uptime > 0 then
      table.insert(status_lines, string.format('Average Uptime: %d minutes', math.floor(stats.average_uptime / 60)))
      table.insert(status_lines, '')
   end

   -- Individual connection details
   if stats.total_domains > 0 then
      table.insert(status_lines, 'Connection Details:')
      table.insert(status_lines, '─────────────────')

      for domain_name, connection in pairs(stats.connections) do
         local state_icon = '❓'
         if connection.state == 'connected' then state_icon = '✅'
         elseif connection.state == 'failed' then state_icon = '❌'
         elseif connection.state == 'connecting' or connection.state == 'reconnecting' then state_icon = '⏳'
         elseif connection.state == 'disconnected' then state_icon = '⭕'
         end

         local uptime_str = connection.uptime > 0 and
            string.format(' (up %dm)', math.floor(connection.uptime / 60)) or ''

         table.insert(status_lines, string.format('%s %s%s', state_icon, domain_name, uptime_str))

         if connection.response_time then
            table.insert(status_lines, string.format('   Response: %ds', connection.response_time))
         end

         if connection.consecutive_failures > 0 then
            table.insert(status_lines, string.format('   Failures: %d', connection.consecutive_failures))
         end
      end
   end

   local status_text = table.concat(status_lines, '\n')

   window:toast_notification(
      'SSH Status Report',
      status_text,
      nil,
      15000  -- 15 seconds for detailed status
   )
end

-- Connection diagnostics display
function M.show_connection_diagnostics(window, domain_name)
   local diagnostics = ssh_connection_manager.diagnose_connection_issues(domain_name)

   local diag_lines = {
      '🔧 SSH Diagnostics: ' .. domain_name,
      '═══════════════════════════════',
      '',
      'Status: ' .. diagnostics.status,
      '',
   }

   -- Test results
   if diagnostics.tests and #diagnostics.tests > 0 then
      table.insert(diag_lines, 'Tests:')
      for _, test in ipairs(diagnostics.tests) do
         local icon = test.success and '✅' or '❌'
         table.insert(diag_lines, string.format('  %s %s', icon, test.name))
      end
      table.insert(diag_lines, '')
   end

   -- Recommendations
   if diagnostics.recommendations and #diagnostics.recommendations > 0 then
      table.insert(diag_lines, 'Recommendations:')
      for _, rec in ipairs(diagnostics.recommendations) do
         table.insert(diag_lines, '  • ' .. rec)
      end
   end

   local diag_text = table.concat(diag_lines, '\n')

   window:toast_notification(
      'SSH Diagnostics',
      diag_text,
      nil,
      20000  -- 20 seconds for diagnostics
   )
end

-- Periodic status updates
function M.start_status_monitoring()
   local function update_status()
      -- Run health checks periodically
      ssh_connection_manager.run_health_checks()

      -- Schedule next update
      wezterm.time.call_after(M.config.update_interval, update_status)
   end

   -- Start monitoring
   wezterm.time.call_after(M.config.update_interval, update_status)

   wezterm.log_info('SSH Status: Started SSH status monitoring')
end

-- Event registration and setup
function M.setup()
   wezterm.log_info('SSH Status: Initializing SSH status monitoring...')

   -- Register SSH domain event handlers
   wezterm.on('ssh-domain-connected', M.on_ssh_domain_connect)
   wezterm.on('ssh-domain-disconnected', M.on_ssh_domain_disconnect)

   -- Integration with status line updates
   wezterm.on('update-status', function(window, pane)
      -- This could be used to update persistent status indicators
      -- if the status line is customized
   end)

   -- Start periodic status monitoring
   if M.config.show_connection_status then
      M.start_status_monitoring()
   end

   wezterm.log_info('SSH Status: SSH status monitoring initialized')
   return true
end

return M