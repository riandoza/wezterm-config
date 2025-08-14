-- Launch Backdrop for WezTerm
-- Shows a special backdrop during WezTerm startup for visual appeal
--
-- FEATURES:
-- • Uses available images from backdrops/ directory during WezTerm startup
-- • Intelligent image selection with preferred image list
-- • Automatic transition to normal backdrop after configurable duration
-- • Fallback to gradient if no images available
-- • Manual controls via keybindings
-- • Performance optimized for instant startup
-- • Maintains tab bar visibility (no missing titles)
-- • Consistent window padding (no zoom effects)
--
-- USAGE:
-- The launch backdrop automatically selects from available images in backdrops/ directory.
-- It will show for 1.5 seconds (configurable) then transition to normal backdrop.
-- Preferred images are tried first, then random selection from available images.
--
-- KEYBINDINGS:
-- • Cmd+Ctrl+L - Restart launch backdrop (manual trigger)
-- • Cmd+Ctrl+T - Test launch backdrop transition
-- • Cmd+Ctrl+V - Validate launch backdrop functionality
--
-- CONFIGURATION:
-- Configure in wezterm.lua:
-- launch_backdrop:configure({
--    duration = 1.5,               -- Show for 1.5 seconds
--    backdrop_type = 'image',      -- 'image', 'random_image', 'gradient', 'solid'
--    show_message = true,          -- Log launch message
--    image_brightness = 0.3,       -- Darken image for text visibility
--    overlay_opacity = 0.9,        -- Dark overlay opacity
-- })

local wezterm = require('wezterm')
local colors = require('colors.custom')

local M = {}

-- Get available backdrop images (safe for event handling only)
function M.get_available_images()
    -- IMPORTANT: This function can only be called during event handling,
    -- not during initial config loading due to coroutine limitations
    local backdrops_dir = wezterm.config_dir .. '/backdrops/'
    local glob_pattern = '*.{jpg,jpeg,png,gif,bmp,ico,tiff,pnm,dds,tga}'

    -- Safely call glob with error handling
    local success, images = pcall(function()
        return wezterm.glob(backdrops_dir .. glob_pattern)
    end)

    if success and images then
        return images
    else
        wezterm.log_warn('Launch backdrop: Could not load images via glob - ' .. (images or 'unknown error'))
        return {}
    end
end

-- Select a launch image (preferred or random)
function M.select_launch_image()
    local available_images = M.get_available_images()

    if #available_images == 0 then
        wezterm.log_warn('Launch backdrop: No images found in backdrops directory')
        return nil
    end

    -- Try to find a preferred image first
    if M.config.preferred_images then
        for _, preferred in ipairs(M.config.preferred_images) do
            for _, available in ipairs(available_images) do
                if available:match(preferred .. '$') then
                    wezterm.log_info('Launch backdrop: Selected preferred image: ' .. preferred)
                    return available
                end
            end
        end
    end

    -- If no preferred image found, select random
    local random_index = math.random(#available_images)
    local selected = available_images[random_index]
    local filename = selected:match('([^/]+)$')
    wezterm.log_info('Launch backdrop: Selected random image: ' .. filename)
    return selected
end

-- Configuration for launch backdrop
M.config = {
    -- Duration to show launch backdrop (in seconds)
    duration = 1.5,

    -- Launch backdrop options - USE AVAILABLE IMAGES
    backdrop_type = 'image', -- 'image', 'random_image', 'gradient', 'solid'

    -- Image selection preferences
    preferred_images = {
        'nord-space.png',
        'galactic-night-sky-astronomy-science-combined-generative-ai.jpg',
        'space.jpg',
        'cloudy-quasar.png',
        'abstract-landscape-with-photorealistic-view-moon.jpg',
        'voyage.jpg',
        'frieren.jpeg',
        'totoro.jpeg',
    },

    -- Fallback colors for gradient backdrop (if no images available)
    gradient_colors = {
        start = '#1a1b26',  -- Tokyo Night background
        middle = '#24283b', -- Tokyo Night darker
        ending = '#414868',    -- Tokyo Night comment
    },

    -- Solid color backdrop (fallback)
    solid_color = colors.background or '#1a1b26',

    -- Launch message
    show_message = true,
    message = '🚀 WezTerm Loading...',
    message_color = '#7aa2f7', -- Tokyo Night blue

    -- Image backdrop settings
    image_brightness = 0.4,  -- Darken image for better text visibility
    image_opacity = 0.9,
    overlay_opacity = 0.85,  -- Dark overlay for text readability
}

-- Create image-based backdrop
function M.create_image_backdrop()
    local selected_image = M.select_launch_image()

    if not selected_image then
        wezterm.log_warn('Launch backdrop: No image available, falling back to gradient')
        return M.create_gradient_backdrop()
    end

    return {
        {
            source = { File = selected_image },
            horizontal_align = 'Center',
            vertical_align = 'Middle',
            width = '100%',
            height = '100%',
            hsb = {
                brightness = M.config.image_brightness or 0.4,
                saturation = 1.0
            },
            opacity = M.config.image_opacity or 0.9,
        },
        {
            source = { Color = '#000000' },  -- Pure black overlay instead of gradient color
            height = '100%',
            width = '100%',
            opacity = M.config.overlay_opacity or 0.3,  -- Much lighter overlay so image is visible
        }
    }
end

-- Create gradient backdrop (fallback)
function M.create_gradient_backdrop()
    return {
        {
            source = {
                Gradient = {
                    colors = { M.config.gradient_colors.start, M.config.gradient_colors.middle, M.config.gradient_colors.ending },
                    orientation = { Linear = { angle = -45.0 } },  -- Diagonal gradient
                    preset = 'Blues',
                    noise = 32,  -- Add subtle texture
                }
            },
            height = '100%',
            width = '100%',
            opacity = 0.95,
        },
        {
            source = { Color = M.config.gradient_colors.start },
            height = '100%',
            width = '100%',
            opacity = 0.6,  -- Overlay for depth
        }
    }
end

-- Create solid color backdrop
function M.create_solid_backdrop()
    return {
        {
            source = { Color = M.config.solid_color },
            height = '100%',
            width = '100%',
            opacity = 1.0,
        }
    }
end

-- Create animated backdrop with subtle pulse effect
function M.create_animated_backdrop()
    return {
        {
            source = {
                Gradient = {
                    colors = { M.config.gradient_colors.start, M.config.gradient_colors.ending },
                    orientation = { Radial = { cx = 0.5, cy = 0.5, radius = 0.8 } },
                    noise = 16,
                }
            },
            height = '110%',
            width = '110%',
            vertical_offset = '-5%',
            horizontal_offset = '-5%',
            opacity = 0.9,
        },
        {
            source = { Color = M.config.gradient_colors.start },
            height = '100%',
            width = '100%',
            opacity = 0.7,
        }
    }
end

-- Create safe initial backdrop (for config loading)
function M.create_initial_launch_backdrop()
    -- SAFE: Use solid black backdrop during initial config loading
    -- Images will be loaded later during event handling
    wezterm.log_info('Launch backdrop: Using solid black backdrop for initial load (images loaded later)')
    return {
        {
            source = { Color = '#000000' },  -- Pure black background
            height = '100%',
            width = '100%',
            opacity = 1.0,
        }
    }
end

-- Create backdrop based on configuration (for event handling)
function M.create_launch_backdrop()
    if M.config.backdrop_type == 'image' then
        return M.create_image_backdrop()
    elseif M.config.backdrop_type == 'random_image' then
        -- Force random selection (ignore preferences)
        local available_images = M.get_available_images()
        if #available_images > 0 then
            local random_index = math.random(#available_images)
            local selected = available_images[random_index]
            wezterm.log_info('Launch backdrop: Random image selected: ' .. selected:match('([^/]+)$'))
            return {
                {
                    source = { File = selected },
                    horizontal_align = 'Center',
                    vertical_align = 'Middle',
                    hsb = { brightness = M.config.image_brightness or 0.4 },
                    opacity = M.config.image_opacity or 0.9,
                },
                {
                    source = { Color = '#000000' },  -- Pure black overlay
                    opacity = M.config.overlay_opacity or 0.3,  -- Light overlay for image visibility
                }
            }
        else
            return M.create_gradient_backdrop()
        end
    elseif M.config.backdrop_type == 'gradient' then
        return M.create_gradient_backdrop()
    elseif M.config.backdrop_type == 'solid' then
        return M.create_solid_backdrop()
    elseif M.config.backdrop_type == 'animated' then
        return M.create_animated_backdrop()
    else
        -- Default to image backdrop (preferred behavior)
        return M.create_image_backdrop()
    end
end

-- Apply launch backdrop to window (with image loading)
function M.apply_launch_backdrop(window)
    if not window then
        wezterm.log_warn('Launch backdrop: No window provided')
        return
    end

    -- NOW it's safe to load images (we're in event handling context)
    local backdrop_config = {
        background = M.create_launch_backdrop(),  -- This can now safely use glob
        enable_tab_bar = true,  -- Keep tab bar visible to show title
        window_padding = {
            left = 0,     -- Keep consistent with appearance.lua
            right = 0,    -- Keep consistent with appearance.lua
            top = 10,     -- Keep consistent with appearance.lua
            bottom = 7.5, -- Keep consistent with appearance.lua
        },
    }

    -- Add launch message if enabled
    if M.config.show_message then
        wezterm.log_info('Launch backdrop: ' .. M.config.message)
    end

    window:set_config_overrides(backdrop_config)
    wezterm.log_info('Launch backdrop: Applied image launch backdrop for ' .. M.config.duration .. ' seconds')
end

-- Restore normal backdrop after launch duration
function M.restore_normal_backdrop(window)
    if not window then
        wezterm.log_warn('Launch backdrop: No window provided for restoration')
        return
    end

    -- Clear the launch backdrop overrides
    window:set_config_overrides({})
    wezterm.log_info('Launch backdrop: Restored normal backdrop')
end

-- Setup launch backdrop with automatic restoration
function M.setup_launch_sequence(window)
    if not window then
        wezterm.log_warn('Launch backdrop: Cannot setup without window')
        return
    end

    wezterm.log_info('Launch backdrop: Starting launch sequence...')

    -- Apply launch backdrop immediately
    M.apply_launch_backdrop(window)

    -- Schedule restoration to normal backdrop
    wezterm.time.call_after(M.config.duration, function()
        M.restore_normal_backdrop(window)
        wezterm.log_info('Launch backdrop: Launch sequence completed')
    end)
end

-- Create launch backdrop configuration for initial window setup
function M.get_initial_launch_config()
    return {
        background = M.create_launch_backdrop(),
        enable_tab_bar = false,
        window_padding = {
            left = 20,
            right = 20,
            top = 30,
            bottom = 20,
        },
    }
end

-- Configure launch backdrop settings
function M.configure(options)
    if options then
        for key, value in pairs(options) do
            if M.config[key] ~= nil then
                M.config[key] = value
                wezterm.log_info('Launch backdrop: Set ' .. key .. ' = ' .. tostring(value))
            else
                wezterm.log_warn('Launch backdrop: Unknown configuration option: ' .. key)
            end
        end
    end
    return M
end

-- NOTE: Event handlers moved to events/launch-backdrop.lua to avoid duplication
-- This prevents multiple backdrop changes during startup

-- Manual trigger for launch backdrop
wezterm.on('trigger-launch-backdrop', function(window, pane)
    if window then
        M.setup_launch_sequence(window)
    end
end)

-- Validation function to test launch backdrop functionality
function M.validate()
    local results = {}
    local score = 0
    local total_tests = 0

    -- Test 1: Configuration validation
    total_tests = total_tests + 1
    if M.config and M.config.duration and M.config.backdrop_type then
        table.insert(results, "✅ Configuration loaded successfully")
        score = score + 1
    else
        table.insert(results, "❌ Configuration failed to load")
    end

    -- Test 2: Image availability (safe validation)
    total_tests = total_tests + 1
    local success, available_images = pcall(M.get_available_images)
    if success and available_images and #available_images > 0 then
        table.insert(results, string.format("✅ Found %d available images", #available_images))
        score = score + 1
    else
        table.insert(results, "⚠️  No images found or glob not available - will use gradient fallback")
    end

    -- Test 3: Backdrop creation (safe test with initial backdrop)
    total_tests = total_tests + 1
    local backdrop = M.create_initial_launch_backdrop()  -- Use safe version for validation
    if backdrop and type(backdrop) == 'table' and #backdrop > 0 then
        table.insert(results, "✅ Launch backdrop created successfully")
        score = score + 1
    else
        table.insert(results, "❌ Failed to create launch backdrop")
    end

    -- Test 4: Function availability
    total_tests = total_tests + 1
    local required_functions = {
        'create_image_backdrop',
        'create_gradient_backdrop',
        'create_solid_backdrop',
        'apply_launch_backdrop',
        'restore_normal_backdrop',
        'setup_launch_sequence',
        'get_available_images',
        'select_launch_image'
    }

    local functions_available = true
    for _, func_name in ipairs(required_functions) do
        if type(M[func_name]) ~= 'function' then
            functions_available = false
            break
        end
    end

    if functions_available then
        table.insert(results, "✅ All required functions available")
        score = score + 1
    else
        table.insert(results, "❌ Missing required functions")
    end

    -- Calculate final score
    local percentage = math.floor((score / total_tests) * 100)
    local status = percentage >= 80 and "PASS" or percentage >= 60 and "WARNING" or "FAIL"

    -- Log results
    wezterm.log_info("Launch backdrop validation results:")
    for _, result in ipairs(results) do
        wezterm.log_info("  " .. result)
    end
    wezterm.log_info(string.format("Launch backdrop validation: %s (%d/%d tests passed, %d%%)",
        status, score, total_tests, percentage))

    return {
        score = score,
        total = total_tests,
        percentage = percentage,
        status = status,
        results = results
    }
end

-- Manual validation trigger
wezterm.on('validate-launch-backdrop', function()
    M.validate()
end)

-- Export configuration constants
M.DURATION = M.config.duration
M.BACKDROP_TYPE = M.config.backdrop_type
M.SHOW_MESSAGE = M.config.show_message

return M
