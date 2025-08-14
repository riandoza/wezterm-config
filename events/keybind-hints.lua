-- Key Binding Hints and Visual Feedback System
-- Advanced UI components for displaying key binding hints and mode indicators

local wezterm = require('wezterm')
local M = {}

-- Configuration for visual feedback
M.config = {
   hint_timeout = 5000,        -- 5 seconds
   toast_position = 'TopRight', -- TopLeft, TopCenter, TopRight, BottomLeft, BottomCenter, BottomRight
   mode_indicator_color = '#ff6b35',
   hint_text_color = '#ffffff',
   background_color = '#1a1a1a',
   border_color = '#444444',
   font_size = 12,
   opacity = 0.95,
}

-- Mode indicator styles
M.mode_styles = {
   normal = {
      color = '#4a9eff',
      icon = '',
      label = 'NORMAL',
   },
   leader = {
      color = '#f39c12',
      icon = '󰌌',
      label = 'LEADER',
   },
   window = {
      color = '#e74c3c',
      icon = '󰖲',
      label = 'WINDOW',
   },
   pane = {
      color = '#2ecc71',
      icon = '󰹑',
      label = 'PANE',
   },
   tab = {
      color = '#9b59b6',
      icon = '󰓩',
      label = 'TAB',
   },
   copy = {
      color = '#f1c40f',
      icon = '󰆏',
      label = 'COPY',
   },
   search = {
      color = '#1abc9c',
      icon = '󰍉',
      label = 'SEARCH',
   },
   tmux = {
      color = '#34495e',
      icon = '󰙀',
      label = 'TMUX',
   },
}

-- Key binding hint templates
M.hint_templates = {
   window_mode = {
      title = 'Window Management',
      hints = {
         { key = 'n', desc = 'New window', color = '#2ecc71' },
         { key = 'c', desc = 'Close window', color = '#e74c3c' },
         { key = 'z', desc = 'Toggle fullscreen', color = '#f39c12' },
         { key = 'r', desc = 'Resize mode', color = '#9b59b6' },
         { key = 'q', desc = 'Quit mode', color = '#95a5a6' },
      }
   },

   pane_mode = {
      title = 'Pane Management',
      hints = {
         { key = 'v', desc = 'Vertical split', color = '#2ecc71' },
         { key = 'h', desc = 'Horizontal split', color = '#2ecc71' },
         { key = 'z', desc = 'Toggle zoom', color = '#f39c12' },
         { key = 'x', desc = 'Close pane', color = '#e74c3c' },
         { key = 'r', desc = 'Resize mode', color = '#9b59b6' },
         { key = 'hjkl', desc = 'Navigate', color = '#3498db' },
         { key = 'q', desc = 'Quit mode', color = '#95a5a6' },
      }
   },

   tab_mode = {
      title = 'Tab Management',
      hints = {
         { key = 'n', desc = 'New tab', color = '#2ecc71' },
         { key = 'c', desc = 'Close tab', color = '#e74c3c' },
         { key = 'r', desc = 'Rename tab', color = '#f39c12' },
         { key = 'm', desc = 'Move mode', color = '#9b59b6' },
         { key = '[]', desc = 'Navigate', color = '#3498db' },
         { key = 'q', desc = 'Quit mode', color = '#95a5a6' },
      }
   },

   tmux_mode = {
      title = 'Tmux Integration',
      hints = {
         { key = 's', desc = 'Session list', color = '#2ecc71' },
         { key = 'w', desc = 'Window list', color = '#3498db' },
         { key = 'd', desc = 'Detach session', color = '#f39c12' },
         { key = 'c', desc = 'Command prompt', color = '#9b59b6' },
         { key = 'q', desc = 'Quit mode', color = '#95a5a6' },
      }
   },

   copy_mode = {
      title = 'Copy Mode',
      hints = {
         { key = 'hjkl', desc = 'Navigate', color = '#3498db' },
         { key = 'v', desc = 'Select', color = '#2ecc71' },
         { key = 'y', desc = 'Copy', color = '#f39c12' },
         { key = '/', desc = 'Search', color = '#1abc9c' },
         { key = 'q', desc = 'Quit', color = '#95a5a6' },
      }
   },

   resize_mode = {
      title = 'Resize Mode',
      hints = {
         { key = 'hjkl', desc = 'Resize', color = '#f39c12' },
         { key = 'q', desc = 'Quit mode', color = '#95a5a6' },
      }
   },
}

-- Create formatted hint display
function M.format_hints(template)
   if not template or not template.hints then
      return ''
   end

   local formatted_hints = {}
   for _, hint in ipairs(template.hints) do
      local colored_key = wezterm.format({
         { Foreground = { Color = hint.color } },
         { Text = hint.key },
         { Foreground = { Color = M.config.hint_text_color } },
         { Text = '=' .. hint.desc },
      })
      table.insert(formatted_hints, colored_key)
   end

   return table.concat(formatted_hints, ' | ')
end

-- Show mode indicator in window title or status
function M.show_mode_indicator(window, mode_name)
   local style = M.mode_styles[mode_name] or M.mode_styles.normal

   -- Create mode indicator text
   local indicator = wezterm.format({
      { Foreground = { Color = style.color } },
      { Text = style.icon .. ' ' .. style.label },
   })

   -- Show as toast notification
   window:toast_notification(
      'WezTerm Mode',
      indicator,
      nil,
      2000  -- 2 seconds
   )

   -- Also update window title if desired
   local overrides = window:get_config_overrides() or {}
   overrides.window_frame = overrides.window_frame or {}
   overrides.window_frame.inactive_titlebar_bg = style.color
   window:set_config_overrides(overrides)
end

-- Show contextual key hints
function M.show_key_hints(window, template_name, custom_hints)
   local template = template_name and M.hint_templates[template_name] or nil

   if custom_hints then
      template = {
         title = custom_hints.title or 'Key Bindings',
         hints = custom_hints.hints or {}
      }
   end

   if not template then
      return
   end

   local hint_text = M.format_hints(template)

   if hint_text ~= '' then
      window:toast_notification(
         template.title,
         hint_text,
         nil,
         M.config.hint_timeout
      )
   end
end

-- Context-aware hint display
function M.show_contextual_hints(window, pane, context)
   context = context or {}

   local hints = {}

   -- Add context-specific hints
   if context.pane_count and context.pane_count > 1 then
      table.insert(hints, { key = 'hjkl', desc = 'Navigate panes', color = '#3498db' })
   end

   if context.tab_count and context.tab_count > 1 then
      table.insert(hints, { key = '[]', desc = 'Switch tabs', color = '#9b59b6' })
   end

   if context.has_selection then
      table.insert(hints, { key = 'y', desc = 'Copy selection', color = '#f39c12' })
   end

   if context.in_tmux then
      table.insert(hints, { key = 'C-Space', desc = 'Tmux prefix', color = '#34495e' })
   end

   -- Show Leader key hint if not in tmux
   if not context.in_tmux then
      table.insert(hints, { key = 'Leader', desc = 'C-Cmd+Space', color = '#f39c12' })
   end

   if #hints > 0 then
      M.show_key_hints(window, nil, {
         title = 'Context Hints',
         hints = hints
      })
   end
end

-- Create help overlay for all key bindings
function M.show_help_overlay(window)
   local help_sections = {
      {
         title = 'Navigation',
         bindings = {
            'Cmd+[/] - Switch tabs',
            'Cmd+Ctrl+hjkl - Navigate panes',
            'Cmd+1-9 - Go to tab N',
         }
      },
      {
         title = 'Management',
         bindings = {
            'Leader+w - Window mode',
            'Leader+p - Pane mode',
            'Leader+t - Tab mode',
            'Leader+m - Tmux mode',
         }
      },
      {
         title = 'Actions',
         bindings = {
            'Cmd+\\ - Split vertical',
            'Cmd+Ctrl+\\ - Split horizontal',
            'Cmd+w - Close pane/tab',
            'Cmd+Enter - Zoom pane',
         }
      },
      {
         title = 'Copy & Search',
         bindings = {
            'Leader+c - Copy mode',
            'Cmd+f - Search',
            'Cmd+Ctrl+u - Quick URL',
         }
      }
   }

   local help_text = {}
   for _, section in ipairs(help_sections) do
      table.insert(help_text, wezterm.format({
         { Attribute = { Underline = 'Single' } },
         { Foreground = { Color = '#f39c12' } },
         { Text = section.title },
         { Attribute = { Underline = 'None' } },
         { Foreground = { Color = M.config.hint_text_color } },
         { Text = '\n' .. table.concat(section.bindings, '\n') .. '\n\n' },
      }))
   end

   window:toast_notification(
      'WezTerm Key Bindings Help',
      table.concat(help_text, ''),
      nil,
      10000  -- 10 seconds for help
   )
end

-- Enhanced status line integration
function M.create_status_elements(mode_name, context)
   local elements = {}

   -- Mode indicator element
   if mode_name and mode_name ~= 'normal' then
      local style = M.mode_styles[mode_name] or M.mode_styles.normal
      table.insert(elements, {
         Background = { Color = style.color },
         Foreground = { Color = '#ffffff' },
         Text = ' ' .. style.icon .. ' ' .. style.label .. ' ',
      })
   end

   -- Context indicators
   if context then
      if context.in_tmux then
         table.insert(elements, {
            Background = { Color = '#34495e' },
            Foreground = { Color = '#ffffff' },
            Text = ' 󰙀 TMUX ',
         })
      end

      if context.has_selection then
         table.insert(elements, {
            Background = { Color = '#f1c40f' },
            Foreground = { Color = '#000000' },
            Text = ' 󰆏 SEL ',
         })
      end

      if context.pane_count and context.pane_count > 1 then
         table.insert(elements, {
            Background = { Color = '#2ecc71' },
            Foreground = { Color = '#ffffff' },
            Text = ' 󰹑 ' .. context.pane_count .. ' ',
         })
      end
   end

   return elements
end

-- Event handlers for mode changes
function M.on_mode_change(window, old_mode, new_mode, context)
   -- Show mode indicator
   M.show_mode_indicator(window, new_mode)

   -- Show relevant hints for new mode
   if new_mode ~= 'normal' and M.hint_templates[new_mode .. '_mode'] then
      M.show_key_hints(window, new_mode .. '_mode')
   end

   wezterm.log_info('Key binding hints: Mode changed from ' .. old_mode .. ' to ' .. new_mode)
end

-- Setup event listeners
function M.setup()
   wezterm.log_info('Key binding hints: Initializing visual feedback system...')

   -- Register for key table events
   wezterm.on('update-status', function(window, pane)
      -- This could be enhanced to show persistent mode indicators
      -- in the status line if desired
   end)

   wezterm.log_info('Key binding hints: Visual feedback system initialized')
   return true
end

return M