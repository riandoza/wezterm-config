local ssh_domain_manager = require('utils.ssh-domain-manager')
local ssh_connection_manager = require('utils.ssh-connection-manager')

-- Generate SSH domains using the advanced SSH domain manager
local ssh_domains = ssh_domain_manager.generate_ssh_domains()

return {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = ssh_domains,

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {
      {
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         username = 'doza',
         default_cwd = '/home/doza',
         default_prog = { 'fish', '-l' },
      },
   },
}
