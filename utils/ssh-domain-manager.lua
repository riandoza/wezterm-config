-- SSH Domain Configuration Manager for WezTerm
-- Advanced SSH domain management with security best practices and connection validation

local wezterm = require('wezterm')
local M = {}

-- SSH configuration templates and best practices
M.config = {
   default_port = 22,
   connection_timeout = 30,
   keepalive_interval = 60,
   keepalive_count_max = 3,
   ssh_config_path = os.getenv('HOME') .. '/.ssh/config',
   known_hosts_path = os.getenv('HOME') .. '/.ssh/known_hosts',
}

-- Security-focused SSH options based on modern SSH best practices
M.secure_ssh_options = {
   -- Connection management
   ServerAliveInterval = '60',
   ServerAliveCountMax = '3',
   ConnectTimeout = '30',

   -- Security settings
   Protocol = '2',
   PubkeyAuthentication = 'yes',
   PasswordAuthentication = 'no',
   ChallengeResponseAuthentication = 'no',
   GSSAPIAuthentication = 'no',

   -- Key exchange and encryption (modern secure algorithms)
   KexAlgorithms = 'curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512',
   Ciphers = 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr',
   MACs = 'hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512',

   -- Host key verification
   StrictHostKeyChecking = 'ask',  -- More secure than 'no'
   HashKnownHosts = 'yes',

   -- Connection multiplexing (optional)
   ControlMaster = 'auto',
   ControlPath = '~/.ssh/control_%h_%p_%r',
   ControlPersist = '600',
}

-- Development/testing SSH options (less secure, more permissive)
M.dev_ssh_options = {
   ServerAliveInterval = '60',
   ServerAliveCountMax = '3',
   ConnectTimeout = '10',
   UserKnownHostsFile = '/dev/null',
   StrictHostKeyChecking = 'no',
   LogLevel = 'ERROR',
}

-- SSH key detection and management
function M.detect_ssh_keys()
   local ssh_dir = os.getenv('HOME') .. '/.ssh'
   local key_types = {
      { name = 'ed25519', private = 'id_ed25519', public = 'id_ed25519.pub' },
      { name = 'rsa', private = 'id_rsa', public = 'id_rsa.pub' },
      { name = 'ecdsa', private = 'id_ecdsa', public = 'id_ecdsa.pub' },
   }

   local detected_keys = {}

   for _, key_type in ipairs(key_types) do
      local private_path = ssh_dir .. '/' .. key_type.private
      local public_path = ssh_dir .. '/' .. key_type.public

      local private_exists = io.open(private_path, 'r')
      local public_exists = io.open(public_path, 'r')

      if private_exists and public_exists then
         private_exists:close()
         public_exists:close()

         -- Get key fingerprint
         local handle = io.popen('ssh-keygen -l -f "' .. public_path .. '" 2>/dev/null')
         local fingerprint = ''
         if handle then
            fingerprint = handle:read('*a'):gsub('%s+$', '')
            handle:close()
         end

         table.insert(detected_keys, {
            type = key_type.name,
            private_key = private_path,
            public_key = public_path,
            fingerprint = fingerprint,
         })

         wezterm.log_info('SSH Domain: Found ' .. key_type.name .. ' key: ' .. fingerprint)
      end
   end

   return detected_keys
end

-- Parse existing SSH config
function M.parse_ssh_config()
   local config_file = io.open(M.config.ssh_config_path, 'r')
   if not config_file then
      return {}
   end

   local hosts = {}
   local current_host = nil

   for line in config_file:lines() do
      line = line:gsub('^%s+', ''):gsub('%s+$', '')  -- Trim whitespace

      if line:match('^Host%s+') then
         current_host = line:match('^Host%s+(.+)')
         if current_host and current_host ~= '*' then
            hosts[current_host] = { name = current_host }
         end
      elseif current_host and hosts[current_host] then
         local key, value = line:match('^(%S+)%s+(.+)')
         if key and value then
            hosts[current_host][key:lower()] = value
         end
      end
   end

   config_file:close()
   return hosts
end

-- Connection validation
function M.test_ssh_connection(host, port, username, timeout)
   timeout = timeout or M.config.connection_timeout
   port = port or M.config.default_port

   local test_cmd = string.format(
      'timeout %d ssh -o ConnectTimeout=%d -o BatchMode=yes -o StrictHostKeyChecking=no -p %d %s@%s exit 2>/dev/null',
      timeout, 10, port, username, host
   )

   local success = os.execute(test_cmd) == 0
   return success
end

-- Domain configuration builders
function M.create_ssh_domain(config)
   local domain = {
      name = config.name,
      remote_address = config.host,
      username = config.username,
      assume_shell = config.assume_shell or 'Posix',
      multiplexing = config.multiplexing or 'WezTerm',
   }

   -- Add port if not default
   if config.port and config.port ~= M.config.default_port then
      domain.remote_address = config.host .. ':' .. config.port
   end

   -- Set default program for SSH connection
   -- Try zsh first, fallback to bash if zsh not available
   domain.default_prog = config.default_prog or { '/bin/sh', '-c', 'command -v zsh >/dev/null 2>&1 && exec zsh -l || exec bash -l' }

   -- SSH options
   if config.secure then
      domain.ssh_option = M.secure_ssh_options
   elseif config.development then
      domain.ssh_option = M.dev_ssh_options
   else
      domain.ssh_option = config.ssh_options or {}
   end

   -- Add custom SSH options
   if config.extra_ssh_options then
      for key, value in pairs(config.extra_ssh_options) do
         domain.ssh_option[key] = value
      end
   end

   return domain
end

-- Predefined domain templates
function M.get_domain_templates()
   return {
      secure_server = {
         description = 'Secure production server configuration',
         template = {
            secure = true,
            multiplexing = 'WezTerm',
            shell_profile = 'default',
            assume_shell = 'Posix',
         }
      },

      development_server = {
         description = 'Development server with relaxed security',
         template = {
            development = true,
            multiplexing = 'None',
            shell_profile = 'development',
            assume_shell = 'Posix',
         }
      },

      cloud_instance = {
         description = 'Cloud instance (AWS/GCP/Azure) configuration',
         template = {
            secure = true,
            multiplexing = 'WezTerm',
            shell_profile = 'default',
            assume_shell = 'Posix',
            extra_ssh_options = {
               IdentitiesOnly = 'yes',
               PreferredAuthentications = 'publickey',
            },
         }
      },

      raspberry_pi = {
         description = 'Raspberry Pi/ARM device configuration',
         template = {
            port = 22,
            secure = false,  -- Often need more relaxed settings for Pi
            multiplexing = 'None',
            shell_profile = 'default',
            assume_shell = 'Posix',
            extra_ssh_options = {
               Ciphers = 'aes128-ctr,aes192-ctr,aes256-ctr',  -- Lighter encryption for ARM
            },
         }
      },
   }
end

-- Auto-discover SSH hosts from config
function M.discover_ssh_hosts()
   local ssh_hosts = M.parse_ssh_config()
   local discovered_domains = {}

   for host_name, host_config in pairs(ssh_hosts) do
      local domain_config = {
         name = 'ssh-' .. host_name,
         host = host_config.hostname or host_name,
         username = host_config.user or os.getenv('USER'),
         port = tonumber(host_config.port) or M.config.default_port,
         secure = true,  -- Default to secure
         shell_profile = 'default',
      }

      -- Test connection if requested
      local connection_ok = M.test_ssh_connection(
         domain_config.host,
         domain_config.port,
         domain_config.username,
         5  -- Quick test
      )

      if connection_ok then
         local domain = M.create_ssh_domain(domain_config)
         table.insert(discovered_domains, domain)
         wezterm.log_info('SSH Domain: Discovered and validated host: ' .. host_name)
      else
         wezterm.log_warn('SSH Domain: Host unreachable: ' .. host_name)
      end
   end

   return discovered_domains
end

-- Generate comprehensive SSH domain configuration
function M.generate_ssh_domains()
   local domains = {}

   -- Add the existing Arch server with enhanced configuration
   local arch_server = M.create_ssh_domain({
      name = 'arch-server',
      host = '192.168.68.68',
      username = 'doza',
      secure = false,  -- Using dev settings for LAN
      development = true,
      shell_profile = 'default',
      multiplexing = 'None',  -- No multiplexing - arch-server doesn't have wezterm installed
      extra_ssh_options = {
         ServerAliveInterval = '60',
         ServerAliveCountMax = '3',
         -- Enable password authentication for arch-server
         PasswordAuthentication = 'yes',
         PreferredAuthentications = 'password,publickey',
         -- Relax host key checking for LAN
         StrictHostKeyChecking = 'no',
         UserKnownHostsFile = '/dev/null',
         -- Disable sending environment variables to avoid warnings
         SendEnv = '',
      },
   })
   table.insert(domains, arch_server)

   -- Add discovered hosts from SSH config
   local discovered = M.discover_ssh_hosts()
   for _, domain in ipairs(discovered) do
      table.insert(domains, domain)
   end

   -- Add localhost/WSL configuration
   local wsl_ssh = {
      name = 'wsl.ssh',
      remote_address = 'localhost',
      multiplexing = 'None',
      default_prog = { 'fish', '-l' },
      assume_shell = 'Posix',
      ssh_option = {
         StrictHostKeyChecking = 'no',
         UserKnownHostsFile = '/dev/null',
      },
   }
   table.insert(domains, wsl_ssh)

   return domains
end

-- SSH connection diagnostics
function M.diagnose_ssh_setup()
   local diagnostics = {
      ssh_keys = M.detect_ssh_keys(),
      ssh_config_exists = io.open(M.config.ssh_config_path, 'r') ~= nil,
      known_hosts_exists = io.open(M.config.known_hosts_path, 'r') ~= nil,
      ssh_agent_running = os.execute('ssh-add -l >/dev/null 2>&1') == 0,
      recommendations = {},
   }

   -- Check for SSH keys
   if #diagnostics.ssh_keys == 0 then
      table.insert(diagnostics.recommendations, 'Generate SSH keys: ssh-keygen -t ed25519 -C "your_email@example.com"')
   end

   -- Check SSH agent
   if not diagnostics.ssh_agent_running then
      table.insert(diagnostics.recommendations, 'Start SSH agent: eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519')
   end

   -- Check SSH config
   if not diagnostics.ssh_config_exists then
      table.insert(diagnostics.recommendations, 'Create SSH config file for better connection management')
   end

   return diagnostics
end

-- Validation and testing
function M.validate_domain_config(domain)
   local issues = {}

   -- Required fields
   if not domain.name then
      table.insert(issues, 'Domain name is required')
   end

   if not domain.remote_address then
      table.insert(issues, 'Remote address is required')
   end

   if not domain.username then
      table.insert(issues, 'Username is required')
   end

   -- Security checks
   if domain.ssh_option then
      if domain.ssh_option.StrictHostKeyChecking == 'no' and
         domain.ssh_option.UserKnownHostsFile ~= '/dev/null' then
         table.insert(issues, 'Warning: StrictHostKeyChecking disabled without disabling known_hosts')
      end

      if domain.ssh_option.PasswordAuthentication == 'yes' then
         table.insert(issues, 'Warning: Password authentication enabled (security risk)')
      end
   end

   return issues
end

-- Setup and initialization
function M.setup()
   wezterm.log_info('SSH Domain Manager: Initializing SSH domain configuration...')

   -- Run diagnostics
   local diagnostics = M.diagnose_ssh_setup()

   wezterm.log_info('SSH Domain Manager: Found ' .. #diagnostics.ssh_keys .. ' SSH keys')

   if diagnostics.ssh_agent_running then
      wezterm.log_info('SSH Domain Manager: SSH agent is running')
   else
      wezterm.log_warn('SSH Domain Manager: SSH agent not running')
   end

   -- Log recommendations
   if #diagnostics.recommendations > 0 then
      wezterm.log_warn('SSH Domain Manager: Recommendations:')
      for _, rec in ipairs(diagnostics.recommendations) do
         wezterm.log_warn('  - ' .. rec)
      end
   end

   wezterm.log_info('SSH Domain Manager: SSH domain configuration initialized')
   return true
end

return M