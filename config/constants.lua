-- Central configuration constants for WezTerm
-- Eliminates magic numbers and provides single source of truth

local M = {}

-- Performance Settings
M.PERFORMANCE = {
    MAX_FPS = 60,  -- Reduced from 120 for better performance
    ANIMATION_FPS = 60,
    CURSOR_BLINK_RATE = 650,  -- milliseconds
    SCROLLBACK_LINES = 10000,  -- Default scrollback buffer
}

-- Timeouts (in milliseconds unless specified)
M.TIMEOUTS = {
    -- Shell and command timeouts
    SHELL_COMMAND = 5000,
    SHELL_VALIDATION = 3000,
    SHELL_STARTUP = 2000,

    -- SSH connection timeouts
    SSH_CONNECT = 30000,  -- 30 seconds
    SSH_HEALTH_CHECK = 10000,  -- 10 seconds
    SSH_BATCH_MODE = 5000,  -- 5 seconds

    -- UI timeouts
    LEADER_KEY = 2000,
    NOTIFICATION = 3000,
    LAUNCH_BACKDROP = 2000,

    -- Process timeouts
    PROCESS_CHECK = 120000,  -- 2 minutes default
    PROCESS_MAX = 600000,    -- 10 minutes maximum
}

-- Intervals (in milliseconds)
M.INTERVALS = {
    -- Background and UI
    BACKDROP_ROTATION = 30 * 60 * 1000,  -- 30 minutes
    BACKDROP_CACHE_SIZE = 5,  -- Number of images to keep in cache

    -- Health checks
    SSH_HEALTH_CHECK = 30 * 1000,  -- 30 seconds
    STATUS_UPDATE = 1000,  -- 1 second

    -- Performance monitoring
    PERFORMANCE_CHECK = 5000,  -- 5 seconds
}

-- Dimensions and Sizing
M.DIMENSIONS = {
    -- Window padding (lowercase keys required by WezTerm)
    PADDING = {
        left = 0,
        right = 0,
        top = 10,
        bottom = 7.5,
    },

    -- Tab settings
    TAB_MAX_WIDTH = 25,

    -- Window resizing
    WINDOW_RESIZE_STEP = 50,  -- pixels

    -- Background sizing
    BACKGROUND = {
        HEIGHT = '100%',
        WIDTH = '100%',
        OPACITY = 0.98,
        HSB_BRIGHTNESS = 0.3,
    },
}

-- File Patterns
M.PATTERNS = {
    -- Image file patterns
    BACKDROP_IMAGES = '*.{jpg,jpeg,png,gif,bmp,ico,tiff,pnm,dds,tga}',

    -- SSH patterns
    SSH_CONFIG = '~/.ssh/config',

    -- Shell patterns
    SHELL_RC = {
        ZSH = '~/.zshrc',
        BASH = '~/.bashrc',
        FISH = '~/.config/fish/config.fish',
    },
}

-- Limits and Thresholds
M.LIMITS = {
    -- Connection limits
    MAX_SSH_RETRIES = 3,
    MAX_CONSECUTIVE_FAILURES = 3,

    -- Process limits
    MAX_OUTPUT_CHARS = 30000,  -- Maximum characters in command output

    -- UI limits
    MAX_NOTIFICATION_LENGTH = 200,

    -- Performance thresholds
    CONTEXT_WARNING = 0.75,  -- 75% context usage warning
    CONTEXT_CRITICAL = 0.85,  -- 85% context usage critical
}

-- Colors and Themes
M.COLORS = {
    -- Status colors
    STATUS_CONNECTED = '#00ff00',
    STATUS_DISCONNECTED = '#ff0000',
    STATUS_WARNING = '#ffaa00',

    -- Background defaults
    DEFAULT_BACKGROUND = '#000000',
    FOCUS_BACKGROUND = '#090909',
}

-- Feature Flags
M.FEATURES = {
    -- Performance features
    ENABLE_GPU = true,
    ENABLE_SCROLL_BAR = true,
    ENABLE_TAB_BAR = true,

    -- Background features
    AUTO_BACKDROP_ROTATION = true,
    BACKDROP_LAZY_LOADING = true,

    -- Security features
    ENABLE_INPUT_VALIDATION = true,
    ENABLE_COMMAND_SANITIZATION = true,

    -- Debug features
    ENABLE_PERFORMANCE_MONITORING = false,
    ENABLE_DEBUG_LOGGING = false,
}

-- Shell Configuration
M.SHELLS = {
    DEFAULT = '/bin/zsh',
    FALLBACK = '/bin/bash',

    -- Shell flags
    FLAGS = {
        LOGIN = '-l',
        INTERACTIVE = '-i',
        NO_RC = '--no-rcs',
    },
}

-- Export the constants
return M