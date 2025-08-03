-- Base Plugin - Provides utility functions for other plugins
-- This demonstrates how to create a plugin that other plugins can depend on

-- Create a utility service that other plugins can use
local UtilityService = {
    formatText = function(text, maxWidth)
        local lines = {}
        local currentLine = ""
        
        for word in text:gmatch("%S+") do
            if #currentLine + #word + 1 <= maxWidth then
                currentLine = currentLine .. (currentLine ~= "" and " " or "") .. word
            else
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                end
                currentLine = word
            end
        end
        
        if currentLine ~= "" then
            table.insert(lines, currentLine)
        end
        
        return lines
    end,
    
    calculateCenter = function(containerWidth, contentWidth)
        return math.floor((containerWidth - contentWidth) / 2) + 1
    end,
    
    hexToColor = function(hex)
        -- Convert hex color to CC color (simplified)
        local colorMap = {
            ["#FFFFFF"] = colors.white,
            ["#FFA500"] = colors.orange,
            ["#FF00FF"] = colors.magenta,
            ["#ADD8E6"] = colors.lightBlue,
            ["#FFFF00"] = colors.yellow,
            ["#00FF00"] = colors.lime,
            ["#FFC0CB"] = colors.pink,
            ["#808080"] = colors.gray,
            ["#D3D3D3"] = colors.lightGray,
            ["#00FFFF"] = colors.cyan,
            ["#800080"] = colors.purple,
            ["#0000FF"] = colors.blue,
            ["#A52A2A"] = colors.brown,
            ["#008000"] = colors.green,
            ["#FF0000"] = colors.red,
            ["#000000"] = colors.black
        }
        return colorMap[hex:upper()] or colors.white
    end
}

-- Register the base plugin
registerPlugin({
    id = "base_utility",
    name = "Base Utility Plugin",
    version = "1.0.0",
    author = "PixelUI Team",
    description = "Provides utility functions for other plugins",
    
    onLoad = function(plugin)
        print("Base Utility Plugin loaded - providing utility services")
        
        -- Register the utility service for other plugins to use
        registerService("textUtils", UtilityService)
        
        -- Emit an event that other plugins can listen for
        emit("baseUtilityLoaded", {
            plugin = plugin,
            service = UtilityService
        })
    end,
    
    onUnload = function(plugin)
        print("Base Utility Plugin unloaded")
        
        -- Clean up service registration
        -- Note: Service will be automatically unregistered when plugin unloads
    end,
    
    onEnable = function(plugin)
        print("Base Utility Plugin enabled")
    end,
    
    onDisable = function(plugin)
        print("Base Utility Plugin disabled")
    end,
    
    -- Provide API functions directly on PixelUI
    api = {
        formatTextLines = UtilityService.formatText,
        centerContent = UtilityService.calculateCenter,
        parseHexColor = UtilityService.hexToColor
    }
})
