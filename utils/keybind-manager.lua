-- Complex Key Binding Management System for WezTerm
-- Advanced modal key binding architecture with context awareness and visual feedback

local wezterm = require('wezterm')
local platform = require('utils.platform')
local act = wezterm.action

local M = {}

-- Key binding state management
M.state = {
   current_mode = 'normal',
   leader_active = false,
   hints_visible = false,
   context_stack = {},
   last_action_time = 0,
   repeat_count = 1,
}

-- Modal key binding system configuration
M.config = {
   leader_timeout = 2000,  -- 2 seconds
   hint_timeout = 5000,    -- 5 seconds
   mode_indicator = true,
   visual_feedback = true,
   repeat_actions = true,
}

-- Platform-specific modifier definitions
M.mod = {}
if platform.is_mac then
   M.mod.SUPER = 'SUPER'
   M.mod.SUPER_REV = 'SUPER|CTRL'
   M.mod.SUPER_CB = 'SUPER'
   M.mod.ALT = 'ALT'
   M.mod.CTRL = 'CTRL'
elseif platform.is_win or platform.is_linux then
   M.mod.SUPER = 'ALT'
   M.mod.SUPER_REV = 'ALT|CTRL'
   M.mod.SUPER_CB = 'CTRL|SHIFT'
   M.mod.ALT = 'ALT'
   M.mod.CTRL = 'CTRL'
end

-- Key binding modes and contexts
M.modes = {
   normal = {
      name = 'Normal',
      description = 'Default key binding mode',
      indicator = '',
      timeout = nil,
   },
   leader = {
      name = 'Leader',
      description = 'Leader key sequence mode',
      indicator = 'LEADER',
      timeout = M.config.leader_timeout,
   },
   window = {
      name = 'Window',
      description = 'Window management mode',
      indicator = 'WIN',
      timeout = M.config.hint_timeout,
   },
   pane = {
      name = 'Pane',
      description = 'Pane management mode',
      indicator = 'PANE',
      timeout = M.config.hint_timeout,
   },
   tab = {
      name = 'Tab',
      description = 'Tab management mode',
      indicator = 'TAB',
      timeout = M.config.hint_timeout,
   },
   copy = {
      name = 'Copy',
      description = 'Copy and selection mode',
      indicator = 'COPY',
      timeout = nil,
   },
   search = {
      name = 'Search',
      description = 'Search and navigation mode',
      indicator = 'SEARCH',
      timeout = nil,
   },
   tmux = {
      name = 'Tmux',
      description = 'Tmux integration mode',
      indicator = 'TMUX',
      timeout = M.config.hint_timeout,
   }
}

-- Context-sensitive key binding detection
function M.detect_context(window, pane)
   local context = {
      has_selection = window:get_selection_text_for_pane(pane) ~= '',
      pane_count = #window:mux_window():panes(),
      tab_count = #window:mux_window():tabs(),
      is_zoomed = pane:get_metadata().is_zoomed or false,
      domain_name = pane:get_domain_name(),
      current_working_dir = pane:get_current_working_dir(),
   }

   -- Detect tmux session
   local foreground_process = pane:get_foreground_process_name()
   context.in_tmux = foreground_process and foreground_process:match('tmux') ~= nil

   -- Detect shell type
   context.shell_type = 'unknown'
   if foreground_process then
      if foreground_process:match('zsh') then context.shell_type = 'zsh'
      elseif foreground_process:match('bash') then context.shell_type = 'bash'
      elseif foreground_process:match('fish') then context.shell_type = 'fish'
      end
   end

   return context
end

-- Visual feedback system
function M.show_mode_indicator(window, mode_name)
   if not M.config.mode_indicator then return end

   local mode = M.modes[mode_name] or M.modes.normal
   local indicator_text = mode.indicator ~= '' and ('[' .. mode.indicator .. ']') or ''

   if indicator_text ~= '' then
      window:toast_notification('WezTerm Key Mode', indicator_text, nil, 1000)
   end
end

function M.show_key_hints(window, hints)
   if not M.config.visual_feedback then return end

   local hint_text = table.concat(hints, ' | ')
   window:toast_notification('Key Bindings', hint_text, nil, M.config.hint_timeout)
end

-- Advanced key binding builders
function M.create_leader_binding(key, description, action, hints)
   return {
      key = key,
      mods = 'LEADER',
      action = wezterm.action_callback(function(window, pane)
         local context = M.detect_context(window, pane)

         -- Show hints if provided
         if hints and M.config.visual_feedback then
            M.show_key_hints(window, hints)
         end

         -- Execute action with context
         if type(action) == 'function' then
            return action(window, pane, context)
         else
            return action
         end
      end),
      description = description,
   }
end

function M.create_modal_binding(mode, key, description, action, one_shot)
   one_shot = one_shot or false

   return {
      key = key,
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
         local context = M.detect_context(window, pane)

         -- Execute action with context
         local result
         if type(action) == 'function' then
            result = action(window, pane, context)
         else
            result = action
         end

         -- Exit modal mode if one_shot
         if one_shot then
            window:perform_action(act.PopKeyTable, pane)
            M.state.current_mode = 'normal'
            M.show_mode_indicator(window, 'normal')
         end

         return result
      end),
      description = description,
   }
end

function M.create_conditional_binding(key, mods, conditions, actions, fallback)
   return {
      key = key,
      mods = mods,
      action = wezterm.action_callback(function(window, pane)
         local context = M.detect_context(window, pane)

         -- Check conditions and execute appropriate action
         for i, condition in ipairs(conditions) do
            if condition(context) then
               local action = actions[i]
               if type(action) == 'function' then
                  return action(window, pane, context)
               else
                  return action
               end
            end
         end

         -- Execute fallback action
         if fallback then
            if type(fallback) == 'function' then
               return fallback(window, pane, context)
            else
               return fallback
            end
         end
      end),
   }
end

-- Advanced window management bindings
function M.get_window_management_bindings()
   return {
      -- Window creation and management
      M.create_leader_binding('w', 'Window management', act.ActivateKeyTable({
         name = 'window_mode',
         one_shot = false,
         timeout_milliseconds = M.config.hint_timeout,
      }), {'n=new', 'c=close', 'z=zoom', 'r=resize', 'q=quit'}),

      -- Smart window navigation
      M.create_conditional_binding('h', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.pane_count > 1 end,  -- Multiple panes
            function(ctx) return ctx.tab_count > 1 end,   -- Multiple tabs
         },
         {
            act.ActivatePaneDirection('Left'),
            act.ActivateTabRelative(-1),
         },
         act.SendString('\u{1b}[1;5D')  -- Fallback: Ctrl+Left Arrow
      ),

      M.create_conditional_binding('l', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.pane_count > 1 end,
            function(ctx) return ctx.tab_count > 1 end,
         },
         {
            act.ActivatePaneDirection('Right'),
            act.ActivateTabRelative(1),
         },
         act.SendString('\u{1b}[1;5C')  -- Fallback: Ctrl+Right Arrow
      ),

      -- Context-aware close operation
      M.create_conditional_binding('w', M.mod.SUPER,
         {
            function(ctx) return ctx.pane_count > 1 end,  -- Close pane if multiple panes
            function(ctx) return ctx.tab_count > 1 end,   -- Close tab if multiple tabs
         },
         {
            act.CloseCurrentPane({ confirm = false }),
            act.CloseCurrentTab({ confirm = false }),
         },
         act.QuitApplication  -- Fallback: quit application
      ),
   }
end

-- Advanced pane management bindings
function M.get_pane_management_bindings()
   return {
      -- Pane mode activation
      M.create_leader_binding('p', 'Pane management', act.ActivateKeyTable({
         name = 'pane_mode',
         one_shot = false,
         timeout_milliseconds = M.config.hint_timeout,
      }), {'v=vsplit', 'h=hsplit', 'z=zoom', 'x=close', 'r=resize'}),

      -- Intelligent pane splitting
      M.create_conditional_binding('\\', M.mod.SUPER,
         {
            function(ctx) return ctx.current_working_dir ~= nil end,  -- Has CWD context
         },
         {
            function(window, pane, ctx)
               return act.SplitVertical({
                  domain = 'CurrentPaneDomain',
                  cwd = ctx.current_working_dir
               })
            end,
         },
         act.SplitVertical({ domain = 'CurrentPaneDomain' })
      ),

      M.create_conditional_binding('\\', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.current_working_dir ~= nil end,
         },
         {
            function(window, pane, ctx)
               return act.SplitHorizontal({
                  domain = 'CurrentPaneDomain',
                  cwd = ctx.current_working_dir
               })
            end,
         },
         act.SplitHorizontal({ domain = 'CurrentPaneDomain' })
      ),

      -- Smart pane navigation with vim-like bindings
      M.create_conditional_binding('k', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.pane_count > 1 end,
         },
         {
            act.ActivatePaneDirection('Up'),
         },
         act.ScrollByLine(-5)  -- Fallback: scroll up
      ),

      M.create_conditional_binding('j', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.pane_count > 1 end,
         },
         {
            act.ActivatePaneDirection('Down'),
         },
         act.ScrollByLine(5)  -- Fallback: scroll down
      ),
   }
end

-- Advanced tab management bindings
function M.get_tab_management_bindings()
   return {
      -- Tab mode activation
      M.create_leader_binding('t', 'Tab management', act.ActivateKeyTable({
         name = 'tab_mode',
         one_shot = false,
         timeout_milliseconds = M.config.hint_timeout,
      }), {'n=new', 'c=close', 'r=rename', 'm=move', '[/]=nav'}),

      -- Intelligent tab creation
      -- Cmd+T removed - handled by default-bindings.lua for simplicity
      -- M.create_conditional_binding('t', M.mod.SUPER, ...) -- Commented out to prevent conflicts

      -- Tab navigation with number keys
      { key = '1', mods = M.mod.SUPER, action = act.ActivateTab(0) },
      { key = '2', mods = M.mod.SUPER, action = act.ActivateTab(1) },
      { key = '3', mods = M.mod.SUPER, action = act.ActivateTab(2) },
      { key = '4', mods = M.mod.SUPER, action = act.ActivateTab(3) },
      { key = '5', mods = M.mod.SUPER, action = act.ActivateTab(4) },
      { key = '6', mods = M.mod.SUPER, action = act.ActivateTab(5) },
      { key = '7', mods = M.mod.SUPER, action = act.ActivateTab(6) },
      { key = '8', mods = M.mod.SUPER, action = act.ActivateTab(7) },
      { key = '9', mods = M.mod.SUPER, action = act.ActivateTab(-1) },
   }
end

-- tmux integration bindings
function M.get_tmux_integration_bindings()
   return {
      -- tmux mode activation
      M.create_leader_binding('m', 'Tmux integration', act.ActivateKeyTable({
         name = 'tmux_mode',
         one_shot = false,
         timeout_milliseconds = M.config.hint_timeout,
      }), {'s=sessions', 'w=windows', 'd=detach', 'c=command'}),

      -- Pass-through tmux prefix (Ctrl+Space)
      {
         key = 'Space',
         mods = 'CTRL',
         action = wezterm.action_callback(function(window, pane)
            local context = M.detect_context(window, pane)
            if context.in_tmux then
               -- Send tmux prefix key
               return act.SendKey({ key = 'Space', mods = 'CTRL' })
            else
               -- Start tmux session
               return act.SendString('tmux attach || tmux new\n')
            end
         end),
      },

      -- Smart tmux session management
      M.create_conditional_binding('s', M.mod.SUPER_REV,
         {
            function(ctx) return ctx.in_tmux end,
         },
         {
            act.SendKey({ key = 's', mods = 'CTRL' }),  -- tmux session list
         },
         act.ShowLauncherArgs({ flags = 'FUZZY|DOMAINS' })  -- WezTerm domain launcher
      ),
   }
end

-- Copy mode and search enhancements
function M.get_copy_search_bindings()
   return {
      -- Enhanced copy mode activation
      M.create_leader_binding('c', 'Copy mode', act.ActivateCopyMode,
         {'hjkl=nav', 'v=select', 'y=copy', 'q=quit'}),

      -- Intelligent search
      M.create_conditional_binding('f', M.mod.SUPER,
         {
            function(ctx) return ctx.has_selection end,
         },
         {
            function(window, pane, ctx)
               local selection = window:get_selection_text_for_pane(pane)
               return act.Search({ CaseInSensitiveString = selection })
            end,
         },
         act.Search({ CaseInSensitiveString = '' })
      ),

      -- Quick URL opening
      {
         key = 'u',
         mods = M.mod.SUPER_REV,
         action = act.QuickSelectArgs({
            label = 'Open URL',
            patterns = {
               '\\((https?://\\S+)\\)',
               '\\[(https?://\\S+)\\]',
               '\\{(https?://\\S+)\\}',
               '<(https?://\\S+)>',
               '\\bhttps?://\\S+[)/a-zA-Z0-9-]+'
            },
            action = wezterm.action_callback(function(window, pane)
               local url = window:get_selection_text_for_pane(pane)
               wezterm.log_info('Opening URL: ' .. url)
               wezterm.open_with(url)
            end),
         }),
      },
   }
end

-- Generate comprehensive key binding configuration
function M.generate_bindings()
   local bindings = {}

   -- Add all binding categories
   local binding_categories = {
      M.get_window_management_bindings(),
      M.get_pane_management_bindings(),
      M.get_tab_management_bindings(),
      M.get_tmux_integration_bindings(),
      M.get_copy_search_bindings(),
   }

   for _, category in ipairs(binding_categories) do
      for _, binding in ipairs(category) do
         table.insert(bindings, binding)
      end
   end

   return bindings
end

-- Generate modal key tables
function M.generate_key_tables()
   return {
      -- Window management mode
      window_mode = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         M.create_modal_binding('window', 'n', 'New window', act.SpawnWindow, true),
         M.create_modal_binding('window', 'c', 'Close window', act.QuitApplication, true),
         M.create_modal_binding('window', 'z', 'Toggle zoom', act.ToggleFullScreen, true),
         M.create_modal_binding('window', 'r', 'Resize mode', act.ActivateKeyTable({
            name = 'resize_window',
            one_shot = false,
            timeout_milliseconds = M.config.hint_timeout,
         }), false),
      },

      -- Pane management mode
      pane_mode = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         M.create_modal_binding('pane', 'v', 'Vertical split', act.SplitVertical({ domain = 'CurrentPaneDomain' }), true),
         M.create_modal_binding('pane', 'h', 'Horizontal split', act.SplitHorizontal({ domain = 'CurrentPaneDomain' }), true),
         M.create_modal_binding('pane', 'z', 'Toggle zoom', act.TogglePaneZoomState, true),
         M.create_modal_binding('pane', 'x', 'Close pane', act.CloseCurrentPane({ confirm = false }), true),
         M.create_modal_binding('pane', 'r', 'Resize mode', act.ActivateKeyTable({
            name = 'resize_pane',
            one_shot = false,
            timeout_milliseconds = M.config.hint_timeout,
         }), false),
         -- Navigation within pane mode
         { key = 'h', mods = 'NONE', action = act.ActivatePaneDirection('Left') },
         { key = 'j', mods = 'NONE', action = act.ActivatePaneDirection('Down') },
         { key = 'k', mods = 'NONE', action = act.ActivatePaneDirection('Up') },
         { key = 'l', mods = 'NONE', action = act.ActivatePaneDirection('Right') },
      },

      -- Tab management mode
      tab_mode = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         M.create_modal_binding('tab', 'n', 'New tab', act.SpawnTab('DefaultDomain'), true),
         M.create_modal_binding('tab', 'c', 'Close tab', act.CloseCurrentTab({ confirm = false }), true),
         M.create_modal_binding('tab', 'r', 'Rename tab', act.EmitEvent('tabs.manual-update-tab-title'), true),
         M.create_modal_binding('tab', 'm', 'Move tab', act.ActivateKeyTable({
            name = 'move_tab',
            one_shot = false,
            timeout_milliseconds = M.config.hint_timeout,
         }), false),
         -- Navigation within tab mode
         { key = '[', mods = 'NONE', action = act.ActivateTabRelative(-1) },
         { key = ']', mods = 'NONE', action = act.ActivateTabRelative(1) },
         { key = 'h', mods = 'NONE', action = act.ActivateTabRelative(-1) },
         { key = 'l', mods = 'NONE', action = act.ActivateTabRelative(1) },
      },

      -- tmux integration mode
      tmux_mode = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         M.create_modal_binding('tmux', 's', 'Session list', act.SendKey({ key = 's', mods = 'CTRL' }), true),
         M.create_modal_binding('tmux', 'w', 'Window list', act.SendKey({ key = 'w', mods = 'CTRL' }), true),
         M.create_modal_binding('tmux', 'd', 'Detach session', act.SendKey({ key = 'd', mods = 'CTRL' }), true),
         M.create_modal_binding('tmux', 'c', 'Command prompt', act.SendKey({ key = ':', mods = 'SHIFT' }), true),
      },

      -- Window resize mode
      resize_window = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         { key = 'h', mods = 'NONE', action = wezterm.action_callback(function(window, pane)
            local dims = window:get_dimensions()
            window:set_inner_size(dims.pixel_width - 50, dims.pixel_height)
         end) },
         { key = 'l', mods = 'NONE', action = wezterm.action_callback(function(window, pane)
            local dims = window:get_dimensions()
            window:set_inner_size(dims.pixel_width + 50, dims.pixel_height)
         end) },
         { key = 'k', mods = 'NONE', action = wezterm.action_callback(function(window, pane)
            local dims = window:get_dimensions()
            window:set_inner_size(dims.pixel_width, dims.pixel_height - 30)
         end) },
         { key = 'j', mods = 'NONE', action = wezterm.action_callback(function(window, pane)
            local dims = window:get_dimensions()
            window:set_inner_size(dims.pixel_width, dims.pixel_height + 30)
         end) },
      },

      -- Tab move mode
      move_tab = {
         { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
         { key = 'q', mods = 'NONE', action = act.PopKeyTable },
         { key = 'h', mods = 'NONE', action = act.MoveTabRelative(-1) },
         { key = 'l', mods = 'NONE', action = act.MoveTabRelative(1) },
         { key = '[', mods = 'NONE', action = act.MoveTabRelative(-1) },
         { key = ']', mods = 'NONE', action = act.MoveTabRelative(1) },
      },
   }
end

-- Initialize key binding system
function M.setup()
   wezterm.log_info('Key binding manager: Initializing complex key binding system...')

   -- Reset state
   M.state.current_mode = 'normal'
   M.state.leader_active = false
   M.state.hints_visible = false
   M.state.context_stack = {}
   M.state.last_action_time = os.time()

   wezterm.log_info('Key binding manager: Complex key binding system initialized')
   return true
end

return M