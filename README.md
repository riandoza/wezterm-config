# WezTerm Configuration

A comprehensive, high-performance WezTerm configuration featuring modular architecture, dynamic backgrounds, sophisticated key bindings, and extensive customization options.

## ✨ Features

### Core Features

- **🎨 Dynamic Background System**: Rotating wallpaper collection with automatic cycling
- **⌨️ Advanced Key Bindings**: Modal key bindings with visual feedback and context awareness
- **🚀 Performance Optimization**: GPU-accelerated rendering with intelligent resource management
- **🎯 Modern UI**: Custom status bars, tab styling, and visual indicators
- **🐚 Shell Integration**: Enhanced support for ZSH and shell workflows
- **🍎 macOS Integration**: Native system integration and optimization

### Advanced Features

- **Launch Backdrop**: Visual startup sequence with configurable duration
- **Auto-Backdrop Rotation**: Automatic background changes every 5 minutes
- **Nano Scroll Fix**: Enhanced scrolling behavior for nano editor
- **Performance Monitoring**: Built-in performance tracking and reporting
- **Context-Aware Key Hints**: Smart key binding suggestions based on current context
- **SSH Status Integration**: Visual indicators for remote connections

## 🚀 Quick Start

### Requirements

- **WezTerm**: Minimum version `20240127-113634-bbcac864`
  - Recommended: [Nightly](https://github.com/wez/wezterm/releases/nightly)
- **Font**: JetBrainsMono Nerd Font (see [installation](#font-installation))

### Installation

1. **Clone the configuration:**

   ```bash
   git clone https://github.com/riandoza/wezterm-config.git ~/.config/wezterm
   ```

2. **Install required font:**

   ```bash
   # macOS
   brew tap homebrew/cask-fonts
   brew install font-jetbrains-mono-nerd-font

   # Windows (Scoop)
   scoop bucket add nerd-fonts
   scoop install JetBrainsMono-NF
   ```

3. **Start WezTerm** - Configuration loads automatically!

### Platform-Specific WezTerm Installation

<details>
<summary><b>macOS</b></summary>

**Stable:**

```bash
brew install --cask wezterm
```

**Nightly:**

```bash
brew install --cask wezterm@nightly
```

</details>

<details>
<summary><b>Windows</b></summary>

**Scoop:**

```bash
scoop bucket add extras
scoop install wezterm
```

**Winget:**

```bash
winget install wez.wezterm
```

**Chocolatey:**

```bash
choco install wezterm -y
```

</details>

<details>
<summary><b>Linux</b></summary>

See [WezTerm Linux Installation](https://wezfurlong.org/wezterm/install/linux.html)

</details>

## ⌨️ Key Bindings

### Modifier Keys

| Platform | SUPER | SUPER_REV | LEADER |
|----------|-------|-----------|--------|
| macOS | `Cmd` | `Cmd+Ctrl` | `Cmd+Ctrl+Space` |
| Windows/Linux | `Alt` | `Alt+Ctrl` | `Alt+Ctrl+Space` |

### Essential Bindings

| Key | Action | Description |
|-----|--------|-------------|
| `Cmd+?` | Show Help | Display key binding help overlay |
| `F1` | Copy Mode | Activate text selection mode |
| `F2` | Command Palette | Open WezTerm command palette |
| `F3` | Launcher | Show application launcher |
| `F12` | Debug Overlay | Toggle debug information |

### Window & Pane Management

| Key | Action | Description |
|-----|--------|-------------|
| `Cmd+n` | New Window | Spawn new WezTerm window |
| `Cmd+t` | New Tab | Create new tab |
| `Cmd+w` | Close | Close current pane/tab (context-aware) |
| `Cmd+Enter` | Zoom Pane | Toggle pane zoom state |
| `Cmd+\` | Split Vertical | Split pane vertically |
| `Cmd+Ctrl+\` | Split Horizontal | Split pane horizontally |

### Navigation

| Key | Action | Description |
|-----|--------|-------------|
| `Cmd+1-9` | Tab Access | Jump to tab by number |
| `Cmd+[/]` | Tab Navigation | Switch between tabs |
| `Cmd+Ctrl+hjkl` | Pane Navigation | Navigate panes vim-style |

### Background Controls

| Key | Action | Description |
|-----|--------|-------------|
| `Cmd+/` | Random Background | Select random wallpaper |
| `Cmd+,/.` | Cycle Background | Previous/next wallpaper |
| `Cmd+Ctrl+/` | Search Background | Fuzzy search wallpapers |
| `Cmd+b` | Focus Mode | Toggle solid color background |
| `Cmd+Ctrl+b` | Auto-Rotation | Toggle automatic wallpaper rotation |

### Leader Key Mode (`Cmd+Ctrl+Space`)

| Key | Action | Description |
|-----|--------|-------------|
| `Leader+w` | Window Mode | Window management operations |
| `Leader+p` | Pane Mode | Pane management operations |
| `Leader+t` | Tab Mode | Tab management operations |
| `Leader+f` | Font Resize | Enter font resizing mode |

### Copy & Search

| Key | Action | Description |
|-----|--------|-------------|
| `Cmd+c/v` | Copy/Paste | Standard clipboard operations |
| `Cmd+f` | Search | Search text in terminal |
| `Cmd+Ctrl+u` | Quick URL | Extract and open URLs |

## 🏗️ Architecture

### Project Structure

```
wezterm/
├── wezterm.lua                 # Main entry point
├── config/                     # Core configuration modules
│   ├── appearance.lua         # Visual settings and themes
│   ├── bindings.lua           # Key bindings and mouse controls
│   ├── constants.lua          # Configuration constants
│   ├── domains.lua            # SSH and WSL domain configurations
│   ├── fonts.lua              # Font configurations
│   ├── general.lua            # General terminal settings
│   └── launch.lua             # Launch profiles and shell configurations
├── utils/                      # Utility modules
│   ├── backdrops.lua          # Background image management
│   ├── gpu-adapter.lua        # GPU adapter selection
│   ├── keybind-manager.lua    # Advanced key binding system
│   ├── platform.lua           # Platform detection
│   └── ssh-*.lua              # SSH connection management
├── events/                     # Event handlers
│   ├── left-status.lua        # Left status bar configuration
│   ├── right-status.lua       # Right status bar with battery/time
│   ├── tab-title.lua          # Advanced tab title formatting
│   └── keybind-hints.lua      # Visual key binding feedback
├── colors/                     # Color schemes
│   └── custom.lua             # Custom color definitions
└── backdrops/                  # Background images
    └── *.{jpg,png,gif}        # Wallpaper collection
```

### Modular Design

The configuration uses a modular architecture where each component is isolated:

```lua
-- Main assembly pattern
return Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
```

## 🎨 Visual Features

### Dynamic Background System

- **Lazy Loading**: Images loaded on-demand with LRU cache
- **Performance Mode**: Minimal resource usage option
- **Focus Mode**: Solid color background for concentration
- **Auto-Rotation**: Automatic background changes every 5 minutes

### Status Bar System

- **Left Status**: Key mode indicators and leader key status
- **Right Status**: Battery status, date/time display
- **Tab Titles**: Process detection, admin indicators, unseen output badges

### Key Binding Hints

- **Context-Aware**: Shows relevant hints based on current state
- **Visual Feedback**: Toast notifications and mode indicators
- **Help System**: Comprehensive help overlay with `Cmd+?`

## 🚀 Performance Features

### GPU Acceleration

Intelligent GPU adapter selection for optimal performance:

- **Priority**: Discrete > Integrated > Other > CPU
- **APIs**: Metal (macOS), Dx12/Vulkan (Windows), Vulkan (Linux)
- **WebGPU**: High-performance rendering with intelligent fallbacks

### Resource Management

- **Lazy Loading**: Background images and modules loaded on-demand
- **LRU Caching**: Efficient memory usage with cache eviction
- **Performance Monitoring**: Built-in performance tracking (`Cmd+Ctrl+p`)

## ⚙️ Customization

### Configuration Files to Modify

| File | Purpose | Common Changes |
|------|---------|----------------|
| `config/domains.lua` | SSH/WSL domains | Add remote servers |
| `config/launch.lua` | Shell profiles | Preferred shells and paths |
| `colors/custom.lua` | Color scheme | Theme customization |
| `backdrops/` | Wallpapers | Add your images |

### Launch Profiles

Default shell configurations:

```lua
-- macOS default
options.default_prog = { '/bin/zsh', '-l' }

-- Available in launcher
options.launch_menu = {
  { label = 'ZSH (Default)', args = { '/bin/zsh', '-l' } },
  { label = 'Bash', args = { 'bash', '-l' } },
  { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
}
```

### SSH Domains

Add remote servers in `config/domains.lua`:

```lua
ssh_domains = {
  {
    name = 'myserver',
    remote_address = 'server.example.com',
    username = 'user',
  }
}
```

## 🛠️ Troubleshooting

### Performance Issues

1. **Check GPU Adapter**: Use `F12` debug overlay
2. **Monitor Performance**: `Cmd+Ctrl+p` for performance report
3. **Enable Performance Mode**: Set `performance_mode = true` in backdrop config

### Key Binding Issues

1. **Debug Bindings**: Run `wezterm show-keys --lua`
2. **Check Conflicts**: Review platform-specific modifiers
3. **Reset Hints**: Middle-click for contextual hints

### Background Issues

1. **Image Loading**: Check `backdrops/` directory permissions
2. **Performance Impact**: Use focus mode (`Cmd+b`) for better performance
3. **Auto-Rotation**: Toggle with `Cmd+Ctrl+b`

## 🔗 Integration

### Shell Integration

Enhanced shell support with tmux compatibility:

- **ZSH Integration**: Advanced prompt and completion support
- **Working Directory**: Intelligent CWD preservation across panes
- **Process Detection**: Application-aware tab titles
- **Tmux Support**: Available via manual integration when needed

### macOS Integration

- **Native Fullscreen**: Seamless macOS fullscreen support
- **Dock Integration**: Proper dock behavior and notifications
- **Notification Center**: System notification integration

## 🎯 Advanced Usage

### Custom Events

Trigger custom functionality:

```bash
# Manual performance report
wezterm.emit('show-performance-report')

# Control background system
wezterm.emit('toggle-auto-backdrop')
```

### Performance Constants

Key performance settings in `config/constants.lua`:

```lua
PERFORMANCE = {
   MAX_FPS = 60,
   ANIMATION_FPS = 60,
   CURSOR_BLINK_RATE = 650,
   CACHE_SIZE = 5,
}
```

## 📚 References

- [WezTerm Documentation](https://wezfurlong.org/wezterm/)
- [Lua API Reference](https://wezfurlong.org/wezterm/config/lua/)
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Configuration Examples](https://github.com/wez/wezterm/tree/main/docs/config/lua)
- [Inspired and Forked KevinSilvester/wezterm-config](https://github.com/KevinSilvester/wezterm-config)
- <https://github.com/rxi/lume>
- <https://github.com/catppuccin/wezterm>
- <https://github.com/wez/wezterm/discussions/628#discussioncomment-1874614>
- <https://github.com/wez/wezterm/discussions/628#discussioncomment-5942139>

---

*This configuration provides a comprehensive WezTerm setup optimized for productivity, aesthetics, and performance. Each component is designed to be modular and customizable while maintaining excellent user experience.*
