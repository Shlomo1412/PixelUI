# PixelUI Plugin System Documentation

The PixelUI framework includes a comprehensive plugin system that allows developers to extend the framework with custom widgets, themes, hooks, and functionality.

## Overview

The plugin system supports:
- **Custom Widgets**: Create new UI components with full integration
- **Custom Themes**: Define new color schemes and styling
- **Event Hooks**: Hook into framework events for custom behavior
- **API Extensions**: Add new functions to the PixelUI namespace
- **Dependency Management**: Plugins can depend on other plugins
- **Lifecycle Management**: Load, enable, disable, and unload plugins

## Quick Start

### 1. Create a Plugin Directory
Create a `plugins` folder in your PixelUI project directory:
```
project/
├── pixelui.lua
├── example.lua
└── plugins/
    └── my_plugin.lua
```

### 2. Basic Plugin Structure
```lua
-- my_plugin.lua
registerPlugin({
    id = "my_plugin",
    name = "My Awesome Plugin",
    version = "1.0.0",
    author = "Your Name",
    description = "A simple example plugin",
    
    onLoad = function(plugin)
        print("Plugin loaded: " .. plugin.name)
    end,
    
    onEnable = function(plugin)
        print("Plugin enabled!")
    end
})
```

### 3. Auto-Loading
Plugins in the `plugins` directory are automatically loaded when PixelUI initializes:
```lua
PixelUI.init() -- This will auto-load and enable all plugins
```

## Creating Custom Widgets

### Widget Class Definition
```lua
local MyWidget = setmetatable({}, {__index = PixelUI.Widget})
MyWidget.__index = MyWidget

function MyWidget:new(props)
    local widget = PixelUI.Widget.new(self, props)
    widget.customProperty = props.customProperty or "default"
    return widget
end

function MyWidget:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(absX, absY)
    term.write("My Widget: " .. self.customProperty)
    
    term.setBackgroundColor(colors.black)
end

-- Register in plugin
registerPlugin({
    id = "widget_plugin",
    widgets = {
        myWidget = MyWidget  -- This creates PixelUI.myWidget() function
    }
})
```

### Using Custom Widgets
```lua
-- After plugin is loaded, use like any other widget
local widget = PixelUI.myWidget({
    x = 5, y = 5,
    customProperty = "Hello World!"
})
```

## Creating Custom Themes

### Theme Definition
```lua
local darkTheme = {
    primary = colors.blue,
    secondary = colors.lightBlue,
    success = colors.green,
    warning = colors.orange,
    error = colors.red,
    background = colors.black,
    surface = colors.gray,
    text = colors.white,
    textSecondary = colors.lightGray,
    border = colors.lightGray,
    
    button = {
        background = colors.gray,
        text = colors.white,
        hover = colors.lightGray,
        pressed = colors.white
    },
    
    textbox = {
        background = colors.black,
        text = colors.white,
        border = colors.lightGray,
        focus = colors.blue
    }
}

registerPlugin({
    id = "theme_plugin",
    themes = {
        dark = darkTheme
    }
})
```

### Using Custom Themes
```lua
-- Apply plugin theme
local theme = PixelUI.getPluginTheme("dark")
if theme then
    PixelUI.setTheme(theme)
end

-- Or list all available plugin themes
local themes = PixelUI.listPluginThemes()
```

## Event Hooks

Hooks allow plugins to execute code when specific events occur:

### Available Hooks
- `onWidgetRender`: Called when any widget renders
- `onButtonClick`: Called when any button is clicked
- `onTextInput`: Called when text is entered
- `onFocusChange`: Called when focus changes between widgets
- `onThemeChange`: Called when theme is changed

### Hook Implementation
```lua
local function onButtonClick(button)
    print("Button clicked: " .. (button.text or "Unknown"))
    -- Add custom behavior like sounds, animations, logging, etc.
end

local function onWidgetRender(widget)
    -- Add global widget effects
    if widget.focused then
        -- Add glow effect, etc.
    end
end

registerPlugin({
    id = "hooks_plugin",
    hooks = {
        onButtonClick = onButtonClick,
        onWidgetRender = onWidgetRender
    }
})
```

### Running Hooks
The framework automatically runs hooks, but you can also manually trigger them:
```lua
PixelUI.runHook("onButtonClick", button)
```

## API Extensions

Add new functions to the PixelUI namespace:

```lua
local function createSpecialButton(text, x, y)
    return PixelUI.button({
        x = x, y = y,
        text = text,
        background = colors.purple,
        color = colors.white,
        border = true
    })
end

local function showNotification(message)
    PixelUI.showToast(message, "Notification", "info", 3000)
end

registerPlugin({
    id = "api_plugin",
    api = {
        createSpecialButton = createSpecialButton,
        showNotification = showNotification
    }
})
```

### Using API Extensions
```lua
-- After plugin is loaded
local button = PixelUI.createSpecialButton("Click Me!", 10, 5)
PixelUI.showNotification("Plugin API is working!")
```

## Plugin Management

### Manual Plugin Management
```lua
-- Register a plugin
local plugin = PixelUI.registerPlugin({
    id = "test_plugin",
    name = "Test Plugin"
})

-- Load and enable
PixelUI.loadPlugin("test_plugin")
PixelUI.enablePlugin("test_plugin")

-- Disable and unload
PixelUI.disablePlugin("test_plugin")
PixelUI.unloadPlugin("test_plugin")
```

### Loading from Files
```lua
-- Load single plugin file
PixelUI.loadPluginFromFile("path/to/plugin.lua")

-- Load all plugins from directory
local loadedPlugins = PixelUI.loadPluginsFromDirectory("plugins")
```

### Plugin Information
```lua
-- List all plugins
local plugins = PixelUI.listPlugins()
for _, plugin in ipairs(plugins) do
    print(plugin.name .. " v" .. plugin.version .. " by " .. plugin.author)
    print("  Loaded: " .. tostring(plugin.loaded))
    print("  Enabled: " .. tostring(plugin.enabled))
end

-- Get specific plugin
local plugin = PixelUI.getPlugin("my_plugin")
if plugin then
    print("Plugin found: " .. plugin.name)
end

-- Check plugin status
if PixelUI.isPluginLoaded("my_plugin") then
    print("Plugin is loaded")
end

if PixelUI.isPluginEnabled("my_plugin") then
    print("Plugin is enabled")
end
```

## Advanced Features

### Plugin Dependencies
```lua
registerPlugin({
    id = "dependent_plugin",
    dependencies = {"base_plugin", "utils_plugin"},
    -- This plugin will only load if base_plugin and utils_plugin are loaded
})
```

### Lifecycle Callbacks
```lua
registerPlugin({
    id = "lifecycle_plugin",
    
    onLoad = function(plugin)
        -- Called when plugin is loaded
        print("Loading: " .. plugin.name)
    end,
    
    onUnload = function(plugin)
        -- Called when plugin is unloaded
        print("Unloading: " .. plugin.name)
    end,
    
    onEnable = function(plugin)
        -- Called when plugin is enabled
        print("Enabling: " .. plugin.name)
        return true -- Return false to prevent enabling
    end,
    
    onDisable = function(plugin)
        -- Called when plugin is disabled
        print("Disabling: " .. plugin.name)
    end
})
```

### Error Handling
The plugin system includes automatic error handling:
- Plugin loading errors are captured and stored
- Failed plugins don't crash the entire framework
- Error information is available for debugging

```lua
local plugins = PixelUI.listPlugins()
for _, plugin in ipairs(plugins) do
    if plugin.error then
        print("Plugin error in " .. plugin.id .. ": " .. plugin.error)
    end
end
```

## Best Practices

1. **Use Unique IDs**: Choose unique plugin IDs to avoid conflicts
2. **Handle Errors**: Use pcall() for risky operations in plugins
3. **Clean Up**: Properly clean up resources in onUnload callbacks
4. **Document APIs**: Document any API functions your plugin provides
5. **Version Compatibility**: Specify compatible PixelUI versions
6. **Minimal Dependencies**: Keep dependencies minimal to improve compatibility

## Example: Complete Plugin

See `plugins/example_plugin.lua` for a complete example that demonstrates:
- Custom widget (GradientBar)
- Custom theme (Cyberpunk)
- Event hooks
- API extensions
- Lifecycle management

## Security Considerations

Plugins run with the same permissions as the main application. Only load trusted plugins from reliable sources. The plugin system provides a sandboxed environment, but plugins can still access ComputerCraft APIs.
