-- SSH Connection Management and Monitoring System
-- Advanced connection pooling, health checking, and session management

local wezterm = require('wezterm')
local security = require('utils.security')
local M = {}

-- Connection state management
M.connections = {}
M.connection_pool = {}
M.health_check_interval = 30  -- seconds

-- Connection states
M.CONNECTION_STATES = {
   DISCONNECTED = 'disconnected',
   CONNECTING = 'connecting',
   CONNECTED = 'connected',
   FAILED = 'failed',
   RECONNECTING = 'reconnecting',
}

-- Connection metrics and monitoring
M.metrics = {
   total_connections = 0,
   active_connections = 0,
   failed_connections = 0,
   reconnection_attempts = 0,
   avg_connection_time = 0,
   last_health_check = 0,
}

-- Connection configuration with retry logic
M.connection_config = {
   max_retry_attempts = 3,
   retry_delay = 5,  -- seconds
   connection_timeout = 30,
   health_check_timeout = 10,
   keepalive_interval = 60,
   max_idle_time = 300,  -- 5 minutes
}

-- Connection health checking
function M.check_connection_health(domain_name)
   local connection = M.connections[domain_name]
   if not connection then
      return false, 'Connection not found'
   end

   if connection.state ~= M.CONNECTION_STATES.CONNECTED then
      return false, 'Connection not in connected state'
   end

   -- Validate inputs before building command
   if not security.validate_username(connection.username) then
      wezterm.log_error('SSH Connection: Invalid username for ' .. domain_name)
      connection.state = M.CONNECTION_STATES.FAILED
      return false, 0
   end

   if not security.validate_host(connection.host) then
      wezterm.log_error('SSH Connection: Invalid host for ' .. domain_name)
      connection.state = M.CONNECTION_STATES.FAILED
      return false, 0
   end

   -- Build safe command with validated inputs
   local test_cmd = string.format(
      'timeout %d ssh -o ConnectTimeout=5 -o BatchMode=yes %s@%s "echo test" 2>/dev/null',
      M.connection_config.health_check_timeout,
      security.sanitize_shell_input(connection.username),
      security.sanitize_shell_input(connection.host)
   )

   local start_time = os.time()
   local stdout, err = security.safe_execute(test_cmd, M.connection_config.health_check_timeout * 1000)
   local success = stdout ~= nil
   local response_time = os.time() - start_time

   -- Update connection metrics
   connection.last_health_check = os.time()
   connection.response_time = response_time
   connection.consecutive_failures = success and 0 or (connection.consecutive_failures or 0) + 1

   if success then
      connection.state = M.CONNECTION_STATES.CONNECTED
      wezterm.log_info('SSH Connection: Health check passed for ' .. domain_name .. ' (' .. response_time .. 's)')
   else
      wezterm.log_warn('SSH Connection: Health check failed for ' .. domain_name)
      if connection.consecutive_failures >= 3 then
         connection.state = M.CONNECTION_STATES.FAILED
      end
   end

   return success, response_time
end

-- Connection establishment with retry logic
function M.establish_connection(domain_config)
   local domain_name = domain_config.name
   local connection = {
      name = domain_name,
      host = domain_config.remote_address:match('([^:]+)') or domain_config.remote_address,
      port = domain_config.remote_address:match(':(%d+)') or '22',
      username = domain_config.username,
      state = M.CONNECTION_STATES.CONNECTING,
      created_at = os.time(),
      last_used = os.time(),
      retry_count = 0,
      consecutive_failures = 0,
      metrics = {
         connection_attempts = 0,
         successful_connections = 0,
         total_uptime = 0,
      }
   }

   M.connections[domain_name] = connection

   -- Attempt connection with retry logic
   local function attempt_connection()
      connection.metrics.connection_attempts = connection.metrics.connection_attempts + 1
      connection.state = M.CONNECTION_STATES.CONNECTING

      wezterm.log_info('SSH Connection: Attempting to connect to ' .. domain_name .. ' (attempt ' .. connection.retry_count + 1 .. ')')

      local connect_cmd = string.format(
         'timeout %d ssh -o ConnectTimeout=%d -o BatchMode=yes %s@%s -p %s "echo connected" 2>/dev/null',
         M.connection_config.connection_timeout,
         M.connection_config.connection_timeout,
         connection.username,
         connection.host,
         connection.port
      )

      local start_time = os.time()
      local success = os.execute(connect_cmd) == 0
      local connection_time = os.time() - start_time

      if success then
         connection.state = M.CONNECTION_STATES.CONNECTED
         connection.connected_at = os.time()
         connection.connection_time = connection_time
         connection.metrics.successful_connections = connection.metrics.successful_connections + 1

         M.metrics.active_connections = M.metrics.active_connections + 1
         M.metrics.total_connections = M.metrics.total_connections + 1

         wezterm.log_info('SSH Connection: Successfully connected to ' .. domain_name .. ' (' .. connection_time .. 's)')
         return true
      else
         connection.retry_count = connection.retry_count + 1

         if connection.retry_count < M.connection_config.max_retry_attempts then
            connection.state = M.CONNECTION_STATES.RECONNECTING
            wezterm.log_warn('SSH Connection: Connection failed, retrying in ' .. M.connection_config.retry_delay .. 's...')

            -- Schedule retry
            wezterm.time.call_after(M.connection_config.retry_delay, attempt_connection)
            return false
         else
            connection.state = M.CONNECTION_STATES.FAILED
            M.metrics.failed_connections = M.metrics.failed_connections + 1
            wezterm.log_error('SSH Connection: Failed to connect to ' .. domain_name .. ' after ' .. connection.retry_count .. ' attempts')
            return false
         end
      end
   end

   return attempt_connection()
end

-- Connection cleanup and management
function M.cleanup_idle_connections()
   local current_time = os.time()
   local cleaned_count = 0

   for domain_name, connection in pairs(M.connections) do
      local idle_time = current_time - connection.last_used

      if idle_time > M.connection_config.max_idle_time and
         connection.state == M.CONNECTION_STATES.CONNECTED then

         wezterm.log_info('SSH Connection: Cleaning up idle connection: ' .. domain_name)
         connection.state = M.CONNECTION_STATES.DISCONNECTED
         M.metrics.active_connections = M.metrics.active_connections - 1
         cleaned_count = cleaned_count + 1
      end
   end

   if cleaned_count > 0 then
      wezterm.log_info('SSH Connection: Cleaned up ' .. cleaned_count .. ' idle connections')
   end

   return cleaned_count
end

-- Comprehensive health monitoring
function M.run_health_checks()
   local current_time = os.time()
   M.metrics.last_health_check = current_time

   local healthy_count = 0
   local unhealthy_count = 0

   for domain_name, connection in pairs(M.connections) do
      if connection.state == M.CONNECTION_STATES.CONNECTED then
         local is_healthy, response_time = M.check_connection_health(domain_name)

         if is_healthy then
            healthy_count = healthy_count + 1
            connection.last_used = current_time
         else
            unhealthy_count = unhealthy_count + 1

            -- Attempt reconnection for failed connections
            if connection.consecutive_failures >= 2 then
               wezterm.log_info('SSH Connection: Attempting reconnection for ' .. domain_name)
               M.metrics.reconnection_attempts = M.metrics.reconnection_attempts + 1

               -- Reset retry count for reconnection
               connection.retry_count = 0
               M.establish_connection({
                  name = domain_name,
                  remote_address = connection.host .. ':' .. connection.port,
                  username = connection.username,
               })
            end
         end
      end
   end

   wezterm.log_info(string.format(
      'SSH Connection: Health check complete - %d healthy, %d unhealthy connections',
      healthy_count, unhealthy_count
   ))

   return healthy_count, unhealthy_count
end

-- Connection statistics and reporting
function M.get_connection_stats()
   local stats = {
      total_domains = 0,
      connected_domains = 0,
      failed_domains = 0,
      connecting_domains = 0,
      connections = {},
      uptime_stats = {},
   }

   for domain_name, connection in pairs(M.connections) do
      stats.total_domains = stats.total_domains + 1

      if connection.state == M.CONNECTION_STATES.CONNECTED then
         stats.connected_domains = stats.connected_domains + 1

         -- Calculate uptime
         local uptime = os.time() - (connection.connected_at or connection.created_at)
         table.insert(stats.uptime_stats, uptime)

      elseif connection.state == M.CONNECTION_STATES.FAILED then
         stats.failed_domains = stats.failed_domains + 1
      elseif connection.state == M.CONNECTION_STATES.CONNECTING or
             connection.state == M.CONNECTION_STATES.RECONNECTING then
         stats.connecting_domains = stats.connecting_domains + 1
      end

      stats.connections[domain_name] = {
         state = connection.state,
         uptime = connection.connected_at and (os.time() - connection.connected_at) or 0,
         retry_count = connection.retry_count,
         last_health_check = connection.last_health_check,
         response_time = connection.response_time,
         consecutive_failures = connection.consecutive_failures,
         metrics = connection.metrics,
      }
   end

   -- Calculate average uptime
   if #stats.uptime_stats > 0 then
      local total_uptime = 0
      for _, uptime in ipairs(stats.uptime_stats) do
         total_uptime = total_uptime + uptime
      end
      stats.average_uptime = total_uptime / #stats.uptime_stats
   else
      stats.average_uptime = 0
   end

   return stats
end

-- Connection event handlers
function M.on_domain_connect(domain_name)
   local connection = M.connections[domain_name]
   if connection then
      connection.last_used = os.time()
      connection.state = M.CONNECTION_STATES.CONNECTED
      wezterm.log_info('SSH Connection: Domain connected: ' .. domain_name)
   end
end

function M.on_domain_disconnect(domain_name)
   local connection = M.connections[domain_name]
   if connection then
      connection.state = M.CONNECTION_STATES.DISCONNECTED
      if connection.connected_at then
         connection.metrics.total_uptime = connection.metrics.total_uptime +
            (os.time() - connection.connected_at)
      end
      M.metrics.active_connections = math.max(0, M.metrics.active_connections - 1)
      wezterm.log_info('SSH Connection: Domain disconnected: ' .. domain_name)
   end
end

-- Monitoring and maintenance tasks
function M.start_monitoring()
   -- Health check timer
   wezterm.time.call_after(M.health_check_interval, function()
      M.run_health_checks()
      M.cleanup_idle_connections()

      -- Schedule next health check
      M.start_monitoring()
   end)

   wezterm.log_info('SSH Connection: Started connection monitoring (interval: ' .. M.health_check_interval .. 's)')
end

-- Connection pool management for frequently used connections
function M.get_pooled_connection(domain_name)
   local connection = M.connections[domain_name]
   if connection and connection.state == M.CONNECTION_STATES.CONNECTED then
      connection.last_used = os.time()
      return connection
   end
   return nil
end

-- Diagnostic utilities
function M.diagnose_connection_issues(domain_name)
   local connection = M.connections[domain_name]
   if not connection then
      return {
         status = 'error',
         message = 'Connection not found',
         recommendations = { 'Verify domain name is correct' }
      }
   end

   local diagnostics = {
      status = connection.state,
      connection = connection,
      recommendations = {},
      tests = {},
   }

   -- Basic connectivity test
   local ping_cmd = 'ping -c 1 -W 5 ' .. connection.host .. ' >/dev/null 2>&1'
   local ping_success = os.execute(ping_cmd) == 0
   table.insert(diagnostics.tests, { name = 'ping', success = ping_success })

   if not ping_success then
      table.insert(diagnostics.recommendations, 'Host unreachable - check network connectivity')
   end

   -- Port connectivity test
   local port_cmd = string.format('nc -z -w5 %s %s >/dev/null 2>&1', connection.host, connection.port)
   local port_success = os.execute(port_cmd) == 0
   table.insert(diagnostics.tests, { name = 'port', success = port_success })

   if not port_success then
      table.insert(diagnostics.recommendations, 'SSH port ' .. connection.port .. ' not accessible')
   end

   -- SSH service test
   local ssh_cmd = string.format('timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes %s@%s -p %s "exit" 2>/dev/null',
      connection.username, connection.host, connection.port)
   local ssh_success = os.execute(ssh_cmd) == 0
   table.insert(diagnostics.tests, { name = 'ssh_auth', success = ssh_success })

   if not ssh_success then
      table.insert(diagnostics.recommendations, 'SSH authentication failed - check keys and credentials')
   end

   return diagnostics
end

-- Setup and initialization
function M.setup()
   wezterm.log_info('SSH Connection Manager: Initializing connection management...')

   -- Initialize metrics
   M.metrics.last_health_check = os.time()

   -- Start monitoring
   M.start_monitoring()

   wezterm.log_info('SSH Connection Manager: Connection management initialized')
   return true
end

return M