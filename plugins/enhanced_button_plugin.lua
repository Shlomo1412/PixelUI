-- Enhanced Button Plugin - Depends on base_utility plugin
-- This demonstrates dependency usage with version constraints

-- Custom Enhanced Button Widget
local EnhancedButton = setmetatable({}, {__index = PixelUI.Widget})
EnhancedButton.__index = EnhancedButton

function EnhancedButton:new(props)
    props = props or {}
    local button = setmetatable({}, EnhancedButton)
    
    -- Initialize base widget properties
    for k, v in pairs(props) do
        button[k] = v
    end
    
    button.x = props.x or 1
    button.y = props.y or 1
    button.width = props.width or 10
    button.height = props.height or 3
    button.text = props.text or "Button"
    button.enabled = props.enabled ~= false
    button.visible = props.visible ~= false
    button.bgColor = props.bgColor or colors.blue
    button.textColor = props.textColor or colors.white
    button.hoverColor = props.hoverColor or colors.lightBlue
    button.gradient = props.gradient or false
    button.icon = props.icon or nil
    button.onClick = props.onClick or function() end
    
    -- Enhanced properties
    button.isHovered = false
    button.isPressed = false
    button.animation = props.animation or "none" -- "none", "bounce", "fade"
    button.tooltip = props.tooltip or nil
    
    return button
end

function EnhancedButton:draw()
    if not self.visible then return end
    
    -- Get utility service from base plugin
    local textUtils = getService("textUtils")
    if not textUtils then
        error("EnhancedButton requires base_utility plugin")
    end
    
    -- Determine current color based on state
    local currentBgColor = self.bgColor
    if self.isPressed then
        currentBgColor = colors.gray
    elseif self.isHovered then
        currentBgColor = self.hoverColor
    end
    
    -- Draw button background
    if self.gradient then
        -- Use drawing utilities for gradient effect
        draw.drawGradient(self.x, self.y, self.width, self.height, 
                         currentBgColor, colors.black, "vertical")
    else
        draw.drawFilledRect(self.x, self.y, self.width, self.height, currentBgColor)
    end
    
    -- Draw border
    draw.drawBorder(self.x, self.y, self.width, self.height, colors.white)
    
    -- Format and center text using utility service
    local textLines = textUtils.formatText(self.text, self.width - 2)
    local startY = self.y + textUtils.calculateCenter(self.height, #textLines) - 1
    
    for i, line in ipairs(textLines) do
        local textX = self.x + textUtils.calculateCenter(self.width, #line) - 1
        draw.drawText(textX, startY + i - 1, line, self.textColor)
    end
    
    -- Draw icon if present
    if self.icon then
        draw.drawText(self.x + 1, self.y + 1, self.icon, self.textColor)
    end
end

function EnhancedButton:onClick(relX, relY)
    if not self.enabled then return false end
    
    self.isPressed = true
    
    -- Trigger animation based on type
    if self.animation == "bounce" then
        -- Simple bounce effect
        emit("buttonBounce", { button = self })
    end
    
    -- Call the click handler
    if self.onClick then
        self:onClick(relX, relY)
    end
    
    return true
end

function EnhancedButton:onMouseEnter()
    self.isHovered = true
    if self.tooltip then
        emit("showTooltip", { text = self.tooltip, x = self.x, y = self.y - 1 })
    end
end

function EnhancedButton:onMouseLeave()
    self.isHovered = false
    self.isPressed = false
    if self.tooltip then
        emit("hideTooltip", {})
    end
end

-- Register the enhanced button plugin
registerPlugin({
    id = "enhanced_button",
    name = "Enhanced Button Plugin",
    version = "2.1.0",
    author = "PixelUI Community",
    description = "Provides enhanced button widgets with animations and tooltips",
    
    -- Declare dependency on base utility plugin with version constraint
    dependencies = {
        "base_utility@1.0.0"  -- Requires exactly version 1.0.0
    },
    
    widgets = {
        enhancedButton = EnhancedButton
    },
    
    onLoad = function(plugin)
        print("Enhanced Button Plugin loaded")
        
        -- Listen for base utility events
        on("baseUtilityLoaded", function(data)
            print("Enhanced Button: Base utility service is now available")
        end)
        
        -- Register event handlers for button animations
        on("buttonBounce", function(data)
            print("Button bounce animation triggered for:", data.button.text)
        end)
    end,
    
    onUnload = function(plugin)
        print("Enhanced Button Plugin unloaded")
    end,
    
    onEnable = function(plugin)
        print("Enhanced Button Plugin enabled - enhanced buttons available")
    end,
    
    onDisable = function(plugin)
        print("Enhanced Button Plugin disabled")
    end,
    
    -- Configuration with validation schema
    config = {
        defaultAnimation = "bounce",
        enableTooltips = true,
        gradientButtons = false
    },
    
    configSchema = {
        defaultAnimation = {
            type = "string",
            required = false
        },
        enableTooltips = {
            type = "boolean",
            required = false
        },
        gradientButtons = {
            type = "boolean",
            required = false
        }
    }
})
