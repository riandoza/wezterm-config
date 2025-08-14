return {
   -- behaviours
   automatically_reload_config = true,
   exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status
   exit_behavior_messaging = 'Verbose',
   status_update_interval = 1000,

   scrollback_lines = 10000,  -- Reduced from 20000 for better memory usage

   -- Trackpad/Mouse settings for macOS - optimized for drag selection
   alternate_buffer_wheel_scroll_speed = 3,  -- Lines to scroll in alternate screen
   bypass_mouse_reporting_modifiers = "SHIFT",  -- Use Shift to bypass mouse reporting
   -- Enable proper mouse selection and drag behavior
   selection_word_boundary = " \t\n{}[]()\"'`,;",  -- Better word selection boundaries
   swallow_mouse_click_on_pane_focus = false,  -- Don't swallow clicks when focusing panes
   swallow_mouse_click_on_window_focus = false,  -- Don't swallow clicks when focusing windows

   -- macOS integration settings - optimized for tmux compatibility
   set_environment_variables = {
      TERM = 'xterm-256color',        -- Better tmux compatibility
      COLORTERM = 'truecolor',        -- Explicit truecolor support
      SHELL = '/bin/zsh',
      -- Performance optimizations for faster shell startup
      ZSH_DISABLE_COMPFIX = 'true',
      DISABLE_AUTO_UPDATE = 'true',
      DISABLE_UNTRACKED_FILES_DIRTY = 'true',
      ZSH_AUTOSUGGEST_MANUAL_REBIND = '1',
      HIST_STAMPS = 'yyyy-mm-dd',
      -- Terminal optimizations
      DISABLE_AUTO_TITLE = 'true',
   },

   hyperlink_rules = {
      -- Matches: a URL in parens: (URL)
      {
         regex = '\\((\\w+://\\S+)\\)',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in brackets: [URL]
      {
         regex = '\\[(\\w+://\\S+)\\]',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in curly braces: {URL}
      {
         regex = '\\{(\\w+://\\S+)\\}',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in angle brackets: <URL>
      {
         regex = '<(\\w+://\\S+)>',
         format = '$1',
         highlight = 1,
      },
      -- Then handle URLs not wrapped in brackets
      {
         regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
         format = '$0',
      },
      -- implicit mailto link
      {
         regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
         format = 'mailto:$0',
      },
   },
}
