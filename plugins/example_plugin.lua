-- Example PixelUI Plugin
-- This demonstrates how to create a plugin for the PixelUI framework

-- Simple GradientBar widget class
local GradientBar = {}
GradientBar.__index = GradientBar

function GradientBar:new(props)
    local bar = setmetatable({}, self) -- Use 'self' instead of 'GradientBar'
    
    -- Basic widget properties
    bar.x = props.x or 1
    bar.y = props.y or 1
    bar.width = props.width or 20
    bar.height = props.height or 1
    bar.visible = props.visible ~= false
    bar.parent = props.parent
    
    -- GradientBar specific properties
    bar.value = props.value or 0
    bar.max = props.max or 100
    bar.colors = props.colors or {colors.red, colors.orange, colors.yellow, colors.lime}
    bar.direction = props.direction or "horizontal" -- "horizontal" or "vertical"
    bar.showValue = props.showValue ~= false
    
    if bar.direction == "vertical" and not props.height then
        bar.height = 10
    end
    
    return bar
end

function GradientBar:getAbsolutePos()
    local x, y = self.x, self.y
    if self.parent then
        local px, py = self.parent:getAbsolutePos()
        x = x + px - 1
        y = y + py - 1
    end
    return x, y
end

function GradientBar:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    local progress = math.min(self.value / self.max, 1)
    
    if self.direction == "horizontal" then
        -- Horizontal gradient bar
        for x = 0, self.width - 1 do
            local segmentProgress = x / (self.width - 1)
            local colorIndex = math.floor(segmentProgress * (#self.colors - 1)) + 1
            local color = self.colors[math.min(colorIndex, #self.colors)]
            
            term.setBackgroundColor(segmentProgress <= progress and color or colors.gray)
            term.setCursorPos(absX + x, absY)
            term.write(" ")
        end
        
        -- Show value if enabled
        if self.showValue then
            local valueText = tostring(math.floor(self.value))
            local textX = absX + math.floor((self.width - #valueText) / 2)
            term.setCursorPos(textX, absY)
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
            term.write(valueText)
        end
    else
        -- Vertical gradient bar
        for y = 0, self.height - 1 do
            local segmentProgress = (self.height - 1 - y) / (self.height - 1)
            local colorIndex = math.floor(segmentProgress * (#self.colors - 1)) + 1
            local color = self.colors[math.min(colorIndex, #self.colors)]
            
            term.setBackgroundColor(segmentProgress <= progress and color or colors.gray)
            term.setCursorPos(absX, absY + y)
            term.write(string.rep(" ", self.width))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function GradientBar:setValue(value)
    self.value = math.max(0, math.min(value, self.max))
end

function GradientBar:setMax(max)
    self.max = math.max(1, max)
    if self.value > self.max then
        self.value = self.max
    end
end

function GradientBar:draw()
    if not self.visible then return end
    self:render()
    -- Draw children if any (though GradientBar typically won't have children)
    if self.children then
        for _, child in ipairs(self.children) do
            if child.draw then
                child:draw()
            end
        end
    end
end

function GradientBar:invalidate()
    -- Simple implementation - could be enhanced
end

-- Define a custom theme: Cyberpunk
local cyberpunkTheme = {
    primary = colors.cyan,
    secondary = colors.magenta,
    success = colors.lime,
    warning = colors.orange,
    error = colors.red,
    background = colors.black,
    surface = colors.gray,
    text = colors.white,
    textSecondary = colors.lightGray,
    border = colors.cyan,
    
    button = {
        background = colors.purple,
        text = colors.white,
        hover = colors.magenta,
        pressed = colors.pink
    },
    
    textbox = {
        background = colors.black,
        text = colors.cyan,
        border = colors.magenta,
        focus = colors.pink
    },
    
    checkbox = {
        checked = colors.cyan,
        unchecked = colors.gray,
        border = colors.magenta
    },
    
    progressbar = {
        filled = colors.cyan,
        empty = colors.gray,
        border = colors.magenta
    }
}

-- Define plugin hooks
local function onWidgetRender(widget)
    -- Add a subtle glow effect to focused widgets
    if widget.focused and widget.border then
        -- This could add special rendering effects
    end
end

local function onButtonClick(button)
    -- Add click sound effect or animation - removed PixelUI dependency
    print("Plugin detected button click: " .. (button.text or "Unknown"))
end

-- Plugin API functions
local function createGradientButton(props)
    props = props or {}
    props.colors = props.colors or {colors.blue, colors.lightBlue, colors.white}
    -- Create a gradient bar that looks like a button
    return GradientBar:new(props)
end

local function applyCyberpunkTheme()
    print("Cyberpunk theme would be applied here")
end

-- Register the plugin
registerPlugin({
    id = "example_plugin",
    name = "Example PixelUI Plugin",
    version = "1.0.0",
    author = "PixelUI Team",
    description = "Demonstrates plugin capabilities with custom widgets, themes, and hooks",
    
    dependencies = {}, -- No dependencies
    
    -- Custom widgets provided by this plugin
    widgets = {
        gradientBar = GradientBar
    },
    
    -- Custom themes provided by this plugin
    themes = {
        cyberpunk = cyberpunkTheme
    },
    
    -- Event hooks
    hooks = {
        onWidgetRender = onWidgetRender,
        onButtonClick = onButtonClick
    },
    
    -- Plugin API functions
    api = {
        createGradientButton = createGradientButton,
        applyCyberpunkTheme = applyCyberpunkTheme
    },
    
    -- Lifecycle callbacks
    onLoad = function(plugin)
        --print("Loading plugin: " .. plugin.name)
    end,
    
    onEnable = function(plugin)
        --print("Enabling plugin: " .. plugin.name)
        --print("Plugin enable callback called successfully")
        -- No PixelUI access needed here to avoid errors
        return true -- Explicitly return true to indicate success
    end,
    
    onDisable = function(plugin)
        --print("Disabling plugin: " .. plugin.name)
    end,
    
    onUnload = function(plugin)
        --print("Unloading plugin: " .. plugin.name)
    end
})
