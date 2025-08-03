-- PixelUI Plugin System Demo
-- This demo shows how to use plugins with the PixelUI framework

-- ComputerCraft/CC:Tweaked environment setup
if not colors then
    colors = {
        white = 1, orange = 2, magenta = 4, lightBlue = 8,
        yellow = 16, lime = 32, pink = 64, gray = 128,
        lightGray = 256, cyan = 512, purple = 1024, blue = 2048,
        brown = 4096, green = 8192, red = 16384, black = 32768
    }
end

if not term then
    term = {
        clear = function() end,
        setCursorPos = function() end,
        write = function() end
    }
end

if not keys then
    keys = {
        q = 16, left = 203, right = 205
    }
end

if not os then
    os = {
        pullEvent = function(event) 
            return event or "key", 0
        end
    }
end

-- Load the PixelUI framework (with plugin system)
local PixelUI = require("pixelui")

-- Initialize the UI framework (this auto-loads plugins from the plugins directory)
PixelUI.init()

-- Demo state
local demo = {
    currentPage = 1,
    totalPages = 3,
    running = true
}

function demo:createPage1()
    PixelUI.clear()
    
    PixelUI.label({
        x = 2, y = 2,
        text = "PixelUI Plugin System Demo - Page 1/3",
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 2, y = 4,
        text = "This demo shows loaded plugins and their features.",
        color = colors.white
    })
    
    -- Show loaded plugins
    local plugins = PixelUI.listPlugins()
    local yPos = 6
    
    if #plugins > 0 then
        PixelUI.label({
            x = 2, y = yPos,
            text = "Loaded Plugins:",
            color = colors.lime
        })
        yPos = yPos + 1
        
        for _, plugin in ipairs(plugins) do
            local status = plugin.enabled and "Enabled" or "Disabled"
            local statusColor = plugin.enabled and colors.green or colors.red
            
            PixelUI.label({
                x = 4, y = yPos,
                text = "• " .. plugin.name .. " v" .. plugin.version,
                color = colors.white
            })
            
            PixelUI.label({
                x = 4, y = yPos + 1,
                text = "  " .. plugin.description,
                color = colors.lightGray
            })
            
            PixelUI.label({
                x = 4, y = yPos + 2,
                text = "  Status: " .. status,
                color = statusColor
            })
            
            -- Add enable/disable button
            if plugin.enabled then
                PixelUI.button({
                    x = 4, y = yPos + 3,
                    text = "Disable",
                    width = 8,
                    height = 1,
                    background = colors.red,
                    color = colors.white,
                    onClick = function()
                        PixelUI.disablePlugin(plugin.id)
                        PixelUI.showToast("Plugin disabled: " .. plugin.name, "Plugin", "info", 2000)
                        demo:createPage1() -- Refresh page
                    end
                })
            else
                PixelUI.button({
                    x = 4, y = yPos + 3,
                    text = "Enable",
                    width = 8,
                    height = 1,
                    background = colors.green,
                    color = colors.white,
                    onClick = function()
                        print("Attempting to enable plugin: " .. plugin.id)
                        local success = PixelUI.enablePlugin(plugin.id)
                        print("Enable result: " .. tostring(success))
                        if success then
                            PixelUI.showToast("Plugin enabled: " .. plugin.name, "Plugin", "success", 2000)
                        else
                            PixelUI.showToast("Failed to enable plugin: " .. plugin.name, "Plugin", "error", 2000)
                            print("Plugin error: " .. tostring(plugin.error))
                        end
                        demo:createPage1() -- Refresh page
                    end
                })
            end
            
            yPos = yPos + 5
        end
    else
        PixelUI.label({
            x = 2, y = yPos,
            text = "No plugins loaded. Try placing plugins in the 'plugins' directory.",
            color = colors.orange
        })
    end
    
    self:createNavigation()
end

function demo:createPage2()
    PixelUI.clear()
    
    PixelUI.label({
        x = 2, y = 2,
        text = "PixelUI Plugin System Demo - Page 2/3",
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 2, y = 4,
        text = "Plugin Widget Demo",
        color = colors.white
    })
    
    -- Try to use plugin widgets if available
    if PixelUI.gradientBar then
        PixelUI.label({
            x = 2, y = 6,
            text = "GradientBar widget (from example plugin):",
            color = colors.lime
        })
        
        PixelUI.gradientBar({
            x = 2, y = 8,
            width = 30,
            value = 75,
            max = 100,
            colors = {colors.red, colors.orange, colors.yellow, colors.lime},
            showValue = true
        })
        
        PixelUI.gradientBar({
            x = 2, y = 10,
            width = 4,
            height = 8,
            value = 60,
            max = 100,
            direction = "vertical",
            colors = {colors.blue, colors.lightBlue, colors.white},
            showValue = false
        })
        
        PixelUI.label({
            x = 8, y = 12,
            text = "Vertical gradient bar",
            color = colors.lightGray
        })
    else
        PixelUI.label({
            x = 2, y = 6,
            text = "No plugin widgets available.",
            color = colors.orange
        })
        
        PixelUI.label({
            x = 2, y = 7,
            text = "Install the example plugin to see custom widgets.",
            color = colors.lightGray
        })
    end
    
    -- Available plugin themes
    local themes = PixelUI.listPluginThemes()
    if #themes > 0 then
        PixelUI.label({
            x = 2, y = 14,
            text = "Available Plugin Themes:",
            color = colors.lime
        })
        
        local xPos = 2
        for _, themeName in ipairs(themes) do
            PixelUI.button({
                x = xPos, y = 16,
                text = themeName,
                width = 12,
                height = 1,
                background = colors.blue,
                color = colors.white,
                onClick = function()
                    local theme = PixelUI.getPluginTheme(themeName)
                    if theme then
                        PixelUI.setTheme(theme)
                        PixelUI.showToast("Applied theme: " .. themeName, "Theme", "success", 2000)
                        -- Refresh the page to show new theme
                        demo:createPage2()
                    end
                end
            })
            xPos = xPos + 14
        end
    end
    
    self:createNavigation()
end

function demo:createPage3()
    PixelUI.clear()
    
    PixelUI.label({
        x = 2, y = 2,
        text = "PixelUI Plugin System Demo - Page 3/3",
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 2, y = 4,
        text = "Plugin Management",
        color = colors.white
    })
    
    -- Manual plugin loading demo
    PixelUI.button({
        x = 2, y = 6,
        text = "Reload Plugins",
        width = 15,
        height = 2,
        background = colors.green,
        color = colors.white,
        onClick = function()
            local loadedPlugins = PixelUI.loadPluginsFromDirectory("plugins")
            local message = "Loaded " .. #loadedPlugins .. " plugins"
            PixelUI.showToast(message, "Plugin System", "info", 2000)
            
            -- Enable all loaded plugins
            for _, pluginInfo in ipairs(loadedPlugins) do
                if pluginInfo.plugin and pluginInfo.plugin.id then
                    local success = PixelUI.enablePlugin(pluginInfo.plugin.id)
                    if success then
                        print("Enabled plugin: " .. pluginInfo.plugin.id)
                    else
                        print("Failed to enable plugin: " .. pluginInfo.plugin.id)
                    end
                end
            end
            
            demo:createPage1() -- Refresh to show updated plugin list
        end
    })
    
    -- Enable all plugins button
    PixelUI.button({
        x = 20, y = 6,
        text = "Enable All",
        width = 12,
        height = 2,
        background = colors.blue,
        color = colors.white,
        onClick = function()
            local plugins = PixelUI.listPlugins()
            local enabledCount = 0
            for _, plugin in ipairs(plugins) do
                if not plugin.enabled then
                    local success = PixelUI.enablePlugin(plugin.id)
                    if success then
                        enabledCount = enabledCount + 1
                    end
                end
            end
            PixelUI.showToast("Enabled " .. enabledCount .. " plugins", "Plugin System", "success", 2000)
            demo:createPage1() -- Refresh to show updated plugin list
        end
    })
    
    -- Plugin API demo
    if PixelUI.createGradientButton then
        PixelUI.label({
            x = 2, y = 9,
            text = "Plugin API Demo:",
            color = colors.lime
        })
        
        local gradientBtn = PixelUI.createGradientButton({
            x = 2, y = 11,
            width = 20,
            value = 50,
            colors = {colors.purple, colors.magenta, colors.pink}
        })
    end
    
    if PixelUI.applyCyberpunkTheme then
        PixelUI.button({
            x = 2, y = 13,
            text = "Apply Cyberpunk Theme",
            width = 22,
            height = 1,
            background = colors.magenta,
            color = colors.white,
            onClick = function()
                PixelUI.applyCyberpunkTheme()
                demo:createPage3() -- Refresh page with new theme
            end
        })
    end
    
    -- Reset theme button
    PixelUI.button({
        x = 2, y = 15,
        text = "Reset to Default Theme",
        width = 22,
        height = 1,
        background = colors.gray,
        color = colors.white,
        onClick = function()
            PixelUI.setTheme(nil) -- Reset to default
            PixelUI.showToast("Reset to default theme", "Theme", "info", 2000)
            demo:createPage3() -- Refresh page
        end
    })
    
    self:createNavigation()
end

function demo:createNavigation()
    -- Previous button
    if self.currentPage > 1 then
        PixelUI.button({
            x = 2, y = 18,
            text = "< Previous",
            width = 12,
            height = 1,
            background = colors.blue,
            color = colors.white,
            onClick = function()
                self.currentPage = self.currentPage - 1
                self:refreshPage()
            end
        })
    end
    
    -- Next button
    if self.currentPage < self.totalPages then
        PixelUI.button({
            x = 16, y = 18,
            text = "Next >",
            width = 12,
            height = 1,
            background = colors.blue,
            color = colors.white,
            onClick = function()
                self.currentPage = self.currentPage + 1
                self:refreshPage()
            end
        })
    end
    
    -- Quit button
    PixelUI.button({
        x = 45, y = 18,
        text = "Quit",
        width = 6,
        height = 1,
        background = colors.red,
        color = colors.white,
        onClick = function()
            self.running = false
        end
    })
end

function demo:refreshPage()
    if self.currentPage == 1 then
        self:createPage1()
    elseif self.currentPage == 2 then
        self:createPage2()
    elseif self.currentPage == 3 then
        self:createPage3()
    end
end

-- Welcome message
print("PixelUI Plugin System Demo")
print("========================")
print("This demo showcases the plugin system capabilities.")
print("Check the 'plugins' directory for example plugins.")
print()
print("Press any key to start...")
os.pullEvent("key")

-- Initialize demo
term.clear()
demo:refreshPage()

-- Main loop
PixelUI.run({
    onKey = function(key)
        if key == keys.q then
            return false -- Quit
        elseif key == keys.left and demo.currentPage > 1 then
            demo.currentPage = demo.currentPage - 1
            demo:refreshPage()
        elseif key == keys.right and demo.currentPage < demo.totalPages then
            demo.currentPage = demo.currentPage + 1
            demo:refreshPage()
        end
    end
})

print("Thanks for trying the PixelUI Plugin System!")
print()
print("To create your own plugins:")
print("1. Create a .lua file in the 'plugins' directory")
print("2. Use registerPlugin() to define your plugin")
print("3. Add custom widgets, themes, hooks, or API functions")
print("4. Restart the demo to see your plugin loaded")
print()
print("See PLUGIN_SYSTEM.md for detailed documentation.")
