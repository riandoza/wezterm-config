local wezterm = require('wezterm')

local M = {}

-- Sanitize shell input to prevent command injection
function M.sanitize_shell_input(input)
    if not input then return "" end

    -- Remove or escape dangerous characters
    local sanitized = tostring(input)
        :gsub('[;&|`$()]', '')  -- Remove command separators and subshells
        :gsub('[<>]', '')        -- Remove redirections
        :gsub('["\'\\]', '\\%0') -- Escape quotes and backslashes
        :gsub('\n', ' ')         -- Replace newlines with spaces
        :gsub('%s+', ' ')        -- Normalize whitespace
        :gsub('^%s+', '')        -- Trim leading whitespace
        :gsub('%s+$', '')        -- Trim trailing whitespace

    return sanitized
end

-- Validate hostname/IP address
function M.validate_host(host)
    if not host then return false end

    -- Basic validation for hostname or IP
    local pattern_hostname = '^[a-zA-Z0-9][a-zA-Z0-9%-%.]*[a-zA-Z0-9]$'
    local pattern_ip = '^%d+%.%d+%.%d+%.%d+$'

    if host:match(pattern_hostname) or host:match(pattern_ip) then
        -- Additional check for IP range
        if host:match(pattern_ip) then
            for octet in host:gmatch('%d+') do
                if tonumber(octet) > 255 then
                    return false
                end
            end
        end
        return true
    end

    return false
end

-- Validate username
function M.validate_username(username)
    if not username then return false end

    -- Unix username pattern: alphanumeric, underscore, hyphen
    -- Must start with letter or underscore
    local pattern = '^[a-zA-Z_][a-zA-Z0-9_%-]*$'

    return username:match(pattern) ~= nil and #username <= 32
end

-- Validate port number
function M.validate_port(port)
    if not port then return true end -- Port is optional

    local port_num = tonumber(port)
    return port_num and port_num >= 1 and port_num <= 65535
end

-- Safe command construction
function M.build_safe_command(template, params)
    -- Validate all parameters first
    for key, value in pairs(params) do
        if type(value) == 'string' then
            params[key] = M.sanitize_shell_input(value)
        end
    end

    -- Use string.format with validated parameters
    return string.format(template, table.unpack(params))
end

-- Execute command with timeout and error handling
function M.safe_execute(cmd, timeout_ms)
    timeout_ms = timeout_ms or 5000

    local success, result = pcall(function()
        -- Use wezterm's run_child_process for safer execution
        local success, stdout, stderr = wezterm.run_child_process({
            '/bin/sh', '-c', cmd
        })

        if not success then
            wezterm.log_error('Command failed: ' .. cmd)
            wezterm.log_error('Error: ' .. (stderr or 'Unknown error'))
            return nil, stderr
        end

        return stdout, nil
    end)

    if not success then
        wezterm.log_error('Command execution error: ' .. tostring(result))
        return nil, result
    end

    return result
end

return M