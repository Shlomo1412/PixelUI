
-- PixelUI Framework for CC: Tweaked
-- A comprehensive UI framework with widgets and event handling

local PixelUI = {}

-- Global state
local widgets = {}
local rootContainer = nil
local eventQueue = {}
local running = false
local isDragging = false
local draggedWidget = nil
local focusedWidget = nil  -- Track globally focused widget

-- Advanced Animation System
local AnimationManager = {
    animations = {},
    time = 0
}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function easeLinear(t) return t end
local function easeInQuad(t) return t * t end
local function easeOutQuad(t) return t * (2 - t) end
local function easeInOutQuad(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end

local EASING = {
    linear = easeLinear,
    inQuad = easeInQuad,
    outQuad = easeOutQuad,
    inOutQuad = easeInOutQuad
}

function AnimationManager:add(anim)
    table.insert(self.animations, anim)
end

function AnimationManager:update(dt)
    self.time = self.time + dt
    local toRemove = {}
    for i, anim in ipairs(self.animations) do
        if not anim.startTime then anim.startTime = self.time end
        local t = (self.time - anim.startTime - (anim.delay or 0)) / anim.duration
        if t < 0 then goto continue end
        local ease = anim.easing and (EASING[anim.easing] or anim.easing) or easeLinear
        local progress = math.min(1, math.max(0, ease(t)))
        for k, v in pairs(anim.to) do
            local from = anim.from[k]
            if from ~= nil and anim.widget then
                anim.widget[k] = lerp(from, v, progress)
            end
        end
        if anim.onUpdate then anim.onUpdate(anim.widget, progress) end
        if t >= 1 then
            if anim.onComplete then anim.onComplete(anim.widget) end
            table.insert(toRemove, i)
        end
        ::continue::
    end
    -- Remove finished animations
    for i = #toRemove, 1, -1 do
        table.remove(self.animations, toRemove[i])
    end
end

function PixelUI.animate(widget, params)
    -- params: { to = {x=,y=,...}, duration=, delay=, easing=, onUpdate=, onComplete= }
    local from = {}
    for k, v in pairs(params.to) do
        from[k] = widget[k]
    end
    AnimationManager:add({
        widget = widget,
        from = from,
        to = params.to,
        duration = params.duration or 1,
        delay = params.delay or 0,
        easing = params.easing or "linear",
        onUpdate = params.onUpdate,
        onComplete = params.onComplete
    })
end

-- Internal: call AnimationManager:update(dt) every frame
local lastFrameTime = os.epoch and os.epoch("utc") or os.clock() * 1000
local function animationFrame()
    local now = os.epoch and os.epoch("utc") or os.clock() * 1000
    local dt = (now - lastFrameTime) / 1000
    lastFrameTime = now
    AnimationManager:update(dt)
end

-- Theming System
local Theme = {}
Theme.__index = Theme

local defaultTheme = {
    primary = colors.blue,
    secondary = colors.lightBlue,
    success = colors.green,
    warning = colors.orange,
    error = colors.red,
    background = colors.black,
    surface = colors.gray,
    text = colors.white,
    textSecondary = colors.lightGray,
    border = colors.gray,
    borderLight = colors.lightGray,
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
    },
    scrollbar = {
        track = colors.gray,
        thumb = colors.lightGray,
        thumbHover = colors.white
    },
    contextMenu = {
        background = colors.lightGray,
        text = colors.black,
        hover = colors.blue,
        hoverText = colors.white,
        border = colors.black
    }
}

local currentTheme = defaultTheme

function PixelUI.setTheme(theme)
    currentTheme = theme or defaultTheme
end

function PixelUI.getTheme()
    return currentTheme
end

function PixelUI.createTheme(props)
    local theme = {}
    for k, v in pairs(defaultTheme) do
        if type(v) == "table" then
            theme[k] = {}
            for k2, v2 in pairs(v) do
                theme[k][k2] = v2
            end
        else
            theme[k] = v
        end
    end
    
    if props then
        for k, v in pairs(props) do
            if type(v) == "table" and theme[k] and type(theme[k]) == "table" then
                for k2, v2 in pairs(v) do
                    theme[k][k2] = v2
                end
            else
                theme[k] = v
            end
        end
    end
    
    return theme
end

-- Utility functions
local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function round(x)
    return math.floor(x + 0.5)
end

local function isPointInBounds(x, y, widget)
    return x >= widget.x and x < widget.x + widget.width and
           y >= widget.y and y < widget.y + widget.height
end

-- Focus management functions
local function setFocusedWidget(widget)
    if focusedWidget and focusedWidget ~= widget and focusedWidget.focused then
        focusedWidget.focused = false
        if focusedWidget.onFocusLost then
            focusedWidget:onFocusLost()
        end
    end
    focusedWidget = widget
    if widget then
        widget.focused = true
        if widget.onFocusGained then
            widget:onFocusGained()
        end
    end
end

local function clearFocus()
    setFocusedWidget(nil)
end

local function getFocusedWidget()
    return focusedWidget
end

-- Border utilities for character-based borders (similar to Basalt)
local colorHex = {}
for i = 0, 15 do
    colorHex[2^i] = ("%x"):format(i)
    colorHex[("%x"):format(i)] = 2^i
end

-- Function to safely get hex color
local function getColorHex(color)
    return colorHex[color] or "f" -- Default to white if color not found
end

-- Draws a thin character-based border around a widget area
-- @param absX, absY: absolute position of the widget
-- @param width, height: dimensions of the widget
-- @param borderColor: color of the border
-- @param bgColor: background color of the widget
local function drawCharBorder(absX, absY, width, height, borderColor, bgColor)
    borderColor = borderColor or colors.lightGray
    bgColor = bgColor or colors.black
    
    -- Set up blit strings for the border with safe hex conversion
    local borderHex = getColorHex(borderColor)
    local bgHex = getColorHex(bgColor)
    
    -- Validate that we have valid hex strings
    if not borderHex or not bgHex then
        return -- Skip drawing if we can't get valid colors
    end
    
    -- Special case for single-pixel-high widgets: only draw side borders
    if height == 1 then
        -- Left border
        term.setCursorPos(absX, absY)
        term.blit("\149", borderHex, bgHex)
        
        -- Right border
        term.setCursorPos(absX + width - 1, absY)
        term.blit("\149", bgHex, borderHex)
        return
    end
    
    -- Normal border drawing for height > 1
    -- Top border (horizontal line)
    term.setCursorPos(absX, absY)
    term.blit(string.rep("\131", width), string.rep(borderHex, width), string.rep(bgHex, width))
    
    -- Bottom border (horizontal line)
    term.setCursorPos(absX, absY + height - 1)
    term.blit(string.rep("\143", width), string.rep(bgHex, width), string.rep(borderHex, width))
    
    -- Left and right borders (vertical lines)
    for i = 1, height - 2 do
        -- Left border
        term.setCursorPos(absX, absY + i)
        term.blit("\149", borderHex, bgHex)
        
        -- Right border
        term.setCursorPos(absX + width - 1, absY + i)
        term.blit("\149", bgHex, borderHex)
    end
    
    -- Corners
    term.setCursorPos(absX, absY)
    term.blit("\151", borderHex, bgHex) -- Top-left corner
    
    term.setCursorPos(absX + width - 1, absY)
    term.blit("\148", bgHex, borderHex) -- Top-right corner
    
    term.setCursorPos(absX, absY + height - 1)
    term.blit("\138", bgHex, borderHex) -- Bottom-left corner
    
    term.setCursorPos(absX + width - 1, absY + height - 1)
    term.blit("\133", bgHex, borderHex) -- Bottom-right corner
end

-- Base Widget class
local Widget = {}
Widget.__index = Widget

function Widget:new(props)
    local widget = {
        x = props.x or 1,
        y = props.y or 1,
        width = props.width or 1,
        height = props.height or 1,
        visible = props.visible ~= false,
        enabled = props.enabled ~= false,
        zIndex = props.zIndex or 1,
        onClick = props.onClick,
        parent = nil,
        children = {},
        draggable = props.draggable or false, -- enable dragging for this widget
        dragArea = props.dragArea, -- {x, y, width, height} relative to widget, or nil for full widget
        onDragStart = props.onDragStart,
        onDragEnd = props.onDragEnd,
        onDrag = props.onDrag
    }
    setmetatable(widget, self)
    return widget
end

function Widget:getAbsolutePos()
    local absX, absY = self.x, self.y
    if self.parent then
        local parentX, parentY = self.parent:getAbsolutePos()
        absX = absX + parentX - 1
        absY = absY + parentY - 1
    end
    return absX, absY
end

function Widget:addChild(child)
    child.parent = self
    table.insert(self.children, child)
    table.sort(self.children, function(a, b) return a.zIndex < b.zIndex end)
end

function Widget:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            break
        end
    end
end

function Widget:handleClick(x, y)
    if not self.enabled or not self.visible then return false end

    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1

    -- Check children first (reverse order for proper z-index handling)
    for i = #self.children, 1, -1 do
        if self.children[i]:handleClick(x, y) then
            return true
        end
    end

    -- Draggable support: check if click is in drag area
    if self.draggable then
        local area = self.dragArea or {x = 1, y = 1, width = self.width, height = self.height}
        if isPointInBounds(relX, relY, area) then
            isDragging = true
            draggedWidget = self
            self._dragStartOffset = {x = relX, y = relY}
            if self.onDragStart then self:onDragStart(relX, relY) end
            return true
        end
    end

    -- Check if click is within this widget
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        -- If this widget is not the currently focused widget and it's not focusable,
        -- clear focus from other widgets
        if not self.focused and not (self.handleKey or self.handleChar) then
            clearFocus()
        end
        
        if self.onClick then
            self:onClick(relX, relY)
        end
        return true
    end


    return false

end
-- Drag event handler for widgets
function Widget:handleDrag(x, y)
    if not self.enabled or not self.visible or not self.draggable then return false end
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    -- Move widget based on drag offset
    if self._dragStartOffset then
        local newX = x - self._dragStartOffset.x + 1
        local newY = y - self._dragStartOffset.y + 1
        self.x = newX
        self.y = newY
        if self.onDrag then self:onDrag(newX, newY) end
        return true
    end
    return false
end

function Widget:handleDragEnd()
    if self._dragStartOffset then
        self._dragStartOffset = nil
        if self.onDragEnd then self:onDragEnd(self.x, self.y) end
    end
end

function Widget:draw()
    if not self.visible then return end
    
    self:render()
    
    -- Draw children
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function Widget:render()
    -- Override in subclasses
end

-- Label Widget
local Label = setmetatable({}, {__index = Widget})
Label.__index = Label

function Label:new(props)
    local label = Widget.new(self, props)
    label.text = props.text or ""
    label.color = props.color or colors.white
    label.background = props.background
    label.align = props.align or "left"
    
    -- Auto-size if not specified
    if not props.width then
        label.width = #label.text
    end
    if not props.height then
        label.height = 1
    end
    
    return label
end

function Label:render()
    local absX, absY = self:getAbsolutePos()
    
    if self.background then
        term.setBackgroundColor(self.background)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(string.rep(" ", self.width))
        end
    end
    
    term.setTextColor(self.color)
    if self.background then
        term.setBackgroundColor(self.background)
    end
    
    local text = self.text:sub(1, self.width)
    local startX = absX
    
    if self.align == "center" then
        startX = absX + math.floor((self.width - #text) / 2)
    elseif self.align == "right" then
        startX = absX + self.width - #text
    end
    
    term.setCursorPos(startX, absY)
    term.write(text)
    
    term.setBackgroundColor(colors.black)
end

-- Button Widget
local Button = setmetatable({}, {__index = Widget})
Button.__index = Button

function Button:new(props)
    local button = Widget.new(self, props)
    button.text = props.text or "Button"
    button.color = props.color or colors.white
    button.background = props.background or colors.gray
    button.border = props.border ~= false
    button.clickEffect = props.clickEffect ~= false
    button.isPressed = false
    button.onClickCallback = props.onClick  -- Store the callback with a different name
    
    -- Auto-size if not specified
    if not props.width then
        button.width = #button.text + (button.border and 2 or 0)
    end
    if not props.height then
        button.height = button.border and 3 or 1
    end
    
    return button
end

function Button:render()
    local absX, absY = self:getAbsolutePos()
    local bgColor = self.enabled and self.background or colors.lightGray
    local textColor = self.color
    
    -- Apply click effect if enabled and pressed
    if self.clickEffect and self.isPressed and self.enabled then
        bgColor = self.color
        textColor = self.background
    end
    
    if self.border then
        -- Draw character-based border
        local borderColor = colors.gray
        drawCharBorder(absX, absY, self.width, self.height, borderColor, bgColor)
        
        -- Fill interior with button background (handle single-pixel height)
        if self.height == 1 then
            -- For single-pixel-high buttons, fill the space between the borders
            term.setBackgroundColor(bgColor)
            term.setCursorPos(absX + 1, absY)
            term.write(string.rep(" ", self.width - 2))
        else
            -- For multi-row buttons, fill each interior row
            term.setBackgroundColor(bgColor)
            for i = 1, self.height - 2 do
                term.setCursorPos(absX + 1, absY + i)
                term.write(string.rep(" ", self.width - 2))
            end
        end
        
        -- Draw text in center
        term.setTextColor(textColor)
        local textY = absY + math.floor(self.height / 2)
        local textX = absX + math.floor((self.width - #self.text) / 2)
        term.setCursorPos(textX, textY)
        term.write(self.text)
    else
        -- Simple button without border
        term.setBackgroundColor(bgColor)
        term.setTextColor(textColor)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(string.rep(" ", self.width))
        end
        
        local textX = absX + math.floor((self.width - #self.text) / 2)
        term.setCursorPos(textX, absY)
        term.write(self.text)
    end
    
    term.setBackgroundColor(colors.black)
end

function Button:onClick(relX, relY)
    if self.enabled then
        if self.clickEffect then
            self.isPressed = true
            -- The button will be re-rendered with inverted colors
            -- We'll reset this after a brief moment in the event loop
        end
        -- Call the provided onClick callback if it exists
        if self.onClickCallback then
            self.onClickCallback(relX, relY)
        end
    end
end

-- TextBox Widget
local TextBox = setmetatable({}, {__index = Widget})
TextBox.__index = TextBox

function TextBox:new(props)
    local textbox = Widget.new(self, props)
    textbox.text = props.text or ""
    textbox.placeholder = props.placeholder or ""
    textbox.color = props.color or colors.white
    textbox.background = props.background or colors.black
    textbox.border = props.border ~= false
    textbox.maxLength = props.maxLength or math.huge
    textbox.onChange = props.onChange
    textbox.onEnter = props.onEnter
    textbox.focused = false
    textbox.cursorPos = #textbox.text + 1
    textbox.scrollOffset = 0
    textbox.password = props.password or false -- password masking
    textbox.blink = false -- for blinking cursor
    textbox.lastBlink = os.clock()
    textbox.blinkInterval = 0.5
    textbox.selectAllOnFocus = props.selectAllOnFocus or false
    textbox.selection = nil -- {start, stop} or nil
    return textbox
end

function TextBox:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme and currentTheme.textbox or {border = colors.lightGray, focus = colors.blue}

    -- Border color feedback
    local borderColor = self.focused and (theme.focus or colors.blue) or (theme.border or colors.lightGray)
    local bgColor = self.background
    local textColor = self.color

    if self.border then
        term.setTextColor(borderColor)
        term.setCursorPos(absX, absY)
        term.write("[")
        term.setCursorPos(absX + self.width - 1, absY)
        term.write("]")
        term.setTextColor(textColor)
    end

    local contentX = absX + (self.border and 1 or 0)
    local contentWidth = self.width - (self.border and 2 or 0)
    term.setBackgroundColor(bgColor)
    term.setCursorPos(contentX, absY)

    local displayText = self.text
    if self.password and #displayText > 0 then
        displayText = string.rep("*", #displayText)
    end

    if #self.text == 0 and not self.focused then
        term.setTextColor(colors.gray)
        displayText = self.placeholder
        term.write(displayText:sub(1, contentWidth) .. string.rep(" ", math.max(0, contentWidth - #displayText)))
    else
        -- Handle text scrolling
        local visibleStart = self.scrollOffset + 1
        local visibleEnd = self.scrollOffset + contentWidth
        local visibleText = displayText:sub(visibleStart, visibleEnd)
        term.setTextColor(textColor)
        term.write(visibleText .. string.rep(" ", contentWidth - #visibleText))

        -- Draw selection highlight if any
        if self.focused and self.selection then
            local selStart = math.max(self.selection[1], visibleStart)
            local selEnd = math.min(self.selection[2], visibleEnd)
            if selStart <= selEnd then
                for i = selStart, selEnd do
                    local selX = contentX + i - visibleStart
                    term.setCursorPos(selX, absY)
                    term.setBackgroundColor(colors.lightBlue)
                    term.setTextColor(colors.white)
                    local c = displayText:sub(i, i)
                    if self.password then c = "*" end
                    term.write(c ~= "" and c or " ")
                    term.setBackgroundColor(bgColor)
                    term.setTextColor(textColor)
                end
            end
        end

        -- Blinking cursor
        if self.focused then
            local now = os.clock()
            if now - self.lastBlink > self.blinkInterval then
                self.blink = not self.blink
                self.lastBlink = now
            end
            local relativeCursorPos = self.cursorPos - self.scrollOffset
            if relativeCursorPos >= 1 and relativeCursorPos <= contentWidth then
                if self.blink then
                    local cursorX = contentX + relativeCursorPos - 1
                    term.setCursorPos(cursorX, absY)
                    term.setTextColor(colors.white)
                    term.setBackgroundColor(colors.gray)
                    term.write(" ")
                    term.setBackgroundColor(bgColor)
                end
            end
        end
    end
    term.setBackgroundColor(colors.black)
end

function TextBox:updateScrollOffset()
    local contentWidth = self.width - (self.border and 2 or 0)
    
    -- Ensure cursor is visible
    if self.cursorPos - self.scrollOffset > contentWidth then
        self.scrollOffset = self.cursorPos - contentWidth
    elseif self.cursorPos - self.scrollOffset < 1 then
        self.scrollOffset = math.max(0, self.cursorPos - 1)
    end
end

function TextBox:handleKey(key)
    if not self.focused or not self.enabled then return false end
    
    if key == keys.backspace then
        if self.cursorPos > 1 then
            self.text = self.text:sub(1, self.cursorPos - 2) .. self.text:sub(self.cursorPos)
            self.cursorPos = self.cursorPos - 1
            self:updateScrollOffset()
            if self.onChange then self:onChange(self.text) end
        end
        return true
    elseif key == keys.delete then
        if self.cursorPos <= #self.text then
            self.text = self.text:sub(1, self.cursorPos - 1) .. self.text:sub(self.cursorPos + 1)
            self:updateScrollOffset()
            if self.onChange then self:onChange(self.text) end
        end
        return true
    elseif key == keys.left then
        self.cursorPos = math.max(1, self.cursorPos - 1)
        self:updateScrollOffset()
        return true
    elseif key == keys.right then
        self.cursorPos = math.min(#self.text + 1, self.cursorPos + 1)
        self:updateScrollOffset()
        return true
    elseif key == keys.home then
        self.cursorPos = 1
        self:updateScrollOffset()
        return true
    elseif key == keys["end"] then
        self.cursorPos = #self.text + 1
        self:updateScrollOffset()
        return true
    elseif key == keys.enter then
        if self.onEnter then self:onEnter(self.text) end
        return true
    end
    
    return false
end

function TextBox:handleChar(char)
    if not self.focused or not self.enabled then return false end
    
    if #self.text < self.maxLength then
        self.text = self.text:sub(1, self.cursorPos - 1) .. char .. self.text:sub(self.cursorPos)
        self.cursorPos = self.cursorPos + 1
        self:updateScrollOffset()
        if self.onChange then self:onChange(self.text) end
    end
    
    return true
end

function TextBox:onClick(relX, relY)
    setFocusedWidget(self)
    -- Set cursor position based on click
    local pos = relX
    if self.border then pos = pos - 1 end
    pos = math.max(1, math.min(#self.text + 1, pos))
    self.cursorPos = pos
    self:updateScrollOffset()
    if self.selectAllOnFocus then
        self.selection = {1, #self.text}
    else
        self.selection = nil
    end
end

-- CheckBox Widget
local CheckBox = setmetatable({}, {__index = Widget})
CheckBox.__index = CheckBox

function CheckBox:new(props)
    local checkbox = Widget.new(self, props)
    checkbox.checked = props.checked or false
    checkbox.text = props.text or ""
    checkbox.color = props.color or colors.white
    checkbox.background = props.background
    checkbox.onToggle = props.onToggle
    
    -- Auto-size if not specified
    if not props.width then
        checkbox.width = 2 + #checkbox.text  -- 1 for checkbox + 1 space + text length
    end
    if not props.height then
        checkbox.height = 1
    end
    
    return checkbox
end

function CheckBox:render()
    local absX, absY = self:getAbsolutePos()
    
    if self.background then
        term.setBackgroundColor(self.background)
    end
    
    term.setCursorPos(absX, absY)
    
    -- Draw checkbox with pixel and * inside for checked, empty pixel for unchecked
    if self.checked then
        -- Draw checked: pixel background with * character
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.black)
        term.write("*")
    else
        -- Draw unchecked: empty pixel
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.black)
        term.write(" ")
    end
    
    -- Reset colors and draw text
    if self.background then
        term.setBackgroundColor(self.background)
    else
        term.setBackgroundColor(colors.black)
    end
    term.setTextColor(self.color)
    term.write(" " .. self.text)
    
    term.setBackgroundColor(colors.black)
end

function CheckBox:onClick()
    if self.enabled then
        self.checked = not self.checked
        if self.onToggle then
            self:onToggle(self.checked)
        end
    end
end

-- Slider Widget
local Slider = setmetatable({}, {__index = Widget})
Slider.__index = Slider

function Slider:new(props)
    local slider = Widget.new(self, props)
    slider.value = props.value or 0
    slider.min = props.min or 0
    slider.max = props.max or 100
    slider.step = props.step or 1
    slider.onChange = props.onChange
    slider.showValue = props.showValue ~= false  -- Show value by default
    slider.valueFormat = props.valueFormat or "%.0f"  -- Format for displaying value
    slider.trackColor = props.trackColor or currentTheme.border
    slider.fillColor = props.fillColor or currentTheme.primary
    slider.knobColor = props.knobColor or colors.white
    
    if not props.width then
        slider.width = 20
    end
    if not props.height then
        slider.height = 1
    end
    
    -- Clamp initial value to valid range
    slider.value = clamp(slider.value, slider.min, slider.max)
    
    return slider
end

function Slider:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Calculate progress and positions
    local progress = (self.value - self.min) / (self.max - self.min)
    local knobPos = math.floor(progress * (self.width - 1)) + 1
    local fillWidth = knobPos - 1
    
    -- Draw track background
    term.setBackgroundColor(self.trackColor or theme.border)
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    -- Draw filled portion (progress)
    if fillWidth > 0 then
        term.setBackgroundColor(self.fillColor or theme.primary)
        term.setCursorPos(absX, absY)
        term.write(string.rep(" ", fillWidth))
    end
    
    -- Draw slider knob/handle
    term.setBackgroundColor(self.knobColor or colors.white)
    term.setTextColor(theme.primary)
    term.setCursorPos(absX + knobPos - 1, absY)
    
    -- Use different knob styles based on state
    local knobChar = "O"  -- Capital O for normal state
    if not self.enabled then
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.gray)
        knobChar = "o"  -- Lowercase o for disabled
    elseif isDragging and draggedWidget == self then
        term.setBackgroundColor(theme.secondary)
        term.setTextColor(colors.white)
        knobChar = "O"  -- Capital O highlighted when dragging
    end
    
    term.write(knobChar)
    
    -- Draw value display if enabled
    if self.showValue then
        local valueText = string.format(self.valueFormat, self.value)
        local valueX = absX + self.width + 2
        
        term.setBackgroundColor(colors.black)
        term.setTextColor(theme.text)
        term.setCursorPos(valueX, absY)
        term.write(valueText)
    end
    
    -- Draw subtle track outline for better definition
    term.setBackgroundColor(colors.black)
    term.setTextColor(theme.borderLight)
    
    -- Optional: Add tick marks for major values (if there's space)
    if self.width >= 10 and (self.max - self.min) <= 10 then
        local stepWidth = (self.width - 1) / (self.max - self.min)
        if stepWidth >= 2 then  -- Only if ticks won't be too crowded
            for i = self.min, self.max, math.max(1, math.floor((self.max - self.min) / 5)) do
                local tickPos = math.floor((i - self.min) / (self.max - self.min) * (self.width - 1)) + 1
                if tickPos > 1 and tickPos < self.width then  -- Don't overlap with knob area
                    term.setCursorPos(absX + tickPos - 1, absY + 1)
                    term.write("|")
                end
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Slider:onClick(relX, relY)
    if self.enabled then
        -- Start dragging
        isDragging = true
        draggedWidget = self
        self:updateValue(relX)
    end
end

function Slider:updateValue(relX)
    local progress = (relX - 1) / (self.width - 1)
    progress = math.max(0, math.min(1, progress))
    self.value = self.min + progress * (self.max - self.min)
    self.value = math.floor(self.value / self.step) * self.step
    self.value = clamp(self.value, self.min, self.max)
    
    if self.onChange then
        self:onChange(self.value)
    end
end

function Slider:handleDrag(x, y)
    if self.enabled then
        local absX, absY = self:getAbsolutePos()
        local relX = x - absX + 1
        self:updateValue(relX)
    end
end

-- RangeSlider Widget
local RangeSlider = setmetatable({}, {__index = Widget})
RangeSlider.__index = RangeSlider

function RangeSlider:new(props)
    local rangeslider = Widget.new(self, props)
    rangeslider.minValue = props.minValue or 0
    rangeslider.maxValue = props.maxValue or 100
    rangeslider.rangeMin = props.rangeMin or 0
    rangeslider.rangeMax = props.rangeMax or 100
    rangeslider.step = props.step or 1
    rangeslider.onChange = props.onChange
    rangeslider.showValues = props.showValues ~= false
    rangeslider.valueFormat = props.valueFormat or "%.0f"
    rangeslider.trackColor = props.trackColor or currentTheme.border
    rangeslider.fillColor = props.fillColor or currentTheme.primary
    rangeslider.knobColor = props.knobColor or colors.white
    rangeslider.activeKnob = nil -- "min" or "max" for which knob is being dragged
    
    if not props.width then
        rangeslider.width = 20
    end
    if not props.height then
        rangeslider.height = 1
    end
    
    -- Clamp initial values to valid range
    rangeslider.minValue = clamp(rangeslider.minValue, rangeslider.rangeMin, rangeslider.rangeMax)
    rangeslider.maxValue = clamp(rangeslider.maxValue, rangeslider.rangeMin, rangeslider.rangeMax)
    
    -- Ensure min <= max
    if rangeslider.minValue > rangeslider.maxValue then
        local temp = rangeslider.minValue
        rangeslider.minValue = rangeslider.maxValue
        rangeslider.maxValue = temp
    end
    
    return rangeslider
end

function RangeSlider:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Calculate positions
    local range = self.rangeMax - self.rangeMin
    local minProgress = (self.minValue - self.rangeMin) / range
    local maxProgress = (self.maxValue - self.rangeMin) / range
    local minKnobPos = math.floor(minProgress * (self.width - 1)) + 1
    local maxKnobPos = math.floor(maxProgress * (self.width - 1)) + 1
    
    -- Draw track background
    term.setBackgroundColor(self.trackColor or theme.border)
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    -- Draw filled portion between knobs
    if maxKnobPos > minKnobPos then
        term.setBackgroundColor(self.fillColor or theme.primary)
        term.setCursorPos(absX + minKnobPos - 1, absY)
        term.write(string.rep(" ", maxKnobPos - minKnobPos + 1))
    end
    
    -- Draw min knob
    term.setBackgroundColor(self.knobColor or colors.white)
    term.setTextColor(theme.primary)
    term.setCursorPos(absX + minKnobPos - 1, absY)
    local minKnobChar = "[" 
    if not self.enabled then
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.gray)
        minKnobChar = "["
    elseif isDragging and draggedWidget == self and self.activeKnob == "min" then
        term.setBackgroundColor(theme.secondary)
        term.setTextColor(colors.white)
    end
    term.write(minKnobChar)
    
    -- Draw max knob
    term.setBackgroundColor(self.knobColor or colors.white)
    term.setTextColor(theme.primary)
    term.setCursorPos(absX + maxKnobPos - 1, absY)
    local maxKnobChar = "]"
    if not self.enabled then
        term.setBackgroundColor(colors.lightGray)
        term.setTextColor(colors.gray)
        maxKnobChar = "]"
    elseif isDragging and draggedWidget == self and self.activeKnob == "max" then
        term.setBackgroundColor(theme.secondary)
        term.setTextColor(colors.white)
    end
    term.write(maxKnobChar)
    
    -- Draw value display if enabled
    if self.showValues then
        local valueText = string.format(self.valueFormat .. " - " .. self.valueFormat, self.minValue, self.maxValue)
        local valueX = absX + self.width + 2
        
        term.setBackgroundColor(colors.black)
        term.setTextColor(theme.text)
        term.setCursorPos(valueX, absY)
        term.write(valueText)
    end
    
    term.setBackgroundColor(colors.black)
end

function RangeSlider:onClick(relX, relY)
    if self.enabled then
        -- Determine which knob is closer
        local range = self.rangeMax - self.rangeMin
        local minProgress = (self.minValue - self.rangeMin) / range
        local maxProgress = (self.maxValue - self.rangeMin) / range
        local minKnobPos = math.floor(minProgress * (self.width - 1)) + 1
        local maxKnobPos = math.floor(maxProgress * (self.width - 1)) + 1
        
        local distToMin = math.abs(relX - minKnobPos)
        local distToMax = math.abs(relX - maxKnobPos)
        
        if distToMin <= distToMax then
            self.activeKnob = "min"
        else
            self.activeKnob = "max"
        end
        
        -- Start dragging
        isDragging = true
        draggedWidget = self
        self:updateValue(relX)
    end
end

function RangeSlider:updateValue(relX)
    local progress = (relX - 1) / (self.width - 1)
    progress = math.max(0, math.min(1, progress))
    local newValue = self.rangeMin + progress * (self.rangeMax - self.rangeMin)
    newValue = math.floor(newValue / self.step) * self.step
    newValue = clamp(newValue, self.rangeMin, self.rangeMax)
    
    if self.activeKnob == "min" then
        self.minValue = math.min(newValue, self.maxValue)
    else
        self.maxValue = math.max(newValue, self.minValue)
    end
    
    if self.onChange then
        self:onChange(self.minValue, self.maxValue)
    end
end

function RangeSlider:handleDrag(x, y)
    if self.enabled then
        local absX, absY = self:getAbsolutePos()
        local relX = x - absX + 1
        self:updateValue(relX)
    end
end

-- ProgressBar Widget
local ProgressBar = setmetatable({}, {__index = Widget})
ProgressBar.__index = ProgressBar

function ProgressBar:new(props)
    local progressbar = Widget.new(self, props)
    progressbar.value = props.value or 0
    progressbar.max = props.max or 100
    progressbar.color = props.color or colors.green
    progressbar.background = props.background or colors.gray
    progressbar.intermediate = props.intermediate or false -- Enable intermediate/indeterminate mode
    progressbar.intermediateSpeed = props.intermediateSpeed or 2 -- Speed of intermediate animation
    progressbar.intermediateSize = props.intermediateSize or 3 -- Size of moving indicator
    progressbar.intermediatePosition = 0 -- Current position of intermediate indicator
    progressbar.intermediateDirection = 1 -- Direction: 1 for right, -1 for left
    progressbar.lastIntermediateUpdate = os.clock()
    
    if not props.width then
        progressbar.width = 20
    end
    if not props.height then
        progressbar.height = 1
    end
    
    return progressbar
end

function ProgressBar:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Draw background
    term.setBackgroundColor(self.background)
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    if self.intermediate then
        -- Intermediate/indeterminate mode - moving indicator
        self:updateIntermediateAnimation()
        
        -- Draw moving indicator
        local indicatorStart = math.floor(self.intermediatePosition)
        local indicatorEnd = math.min(self.width, indicatorStart + self.intermediateSize - 1)
        
        if indicatorStart >= 1 and indicatorStart <= self.width then
            term.setBackgroundColor(self.color)
            term.setCursorPos(absX + indicatorStart - 1, absY)
            local indicatorWidth = indicatorEnd - indicatorStart + 1
            term.write(string.rep(" ", indicatorWidth))
        end
    else
        -- Normal progress mode
        local progress = math.min(self.value / self.max, 1)
        local fillWidth = math.floor(progress * self.width)
        
        if fillWidth > 0 then
            term.setBackgroundColor(self.color)
            term.setCursorPos(absX, absY)
            term.write(string.rep(" ", fillWidth))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function ProgressBar:updateIntermediateAnimation()
    local now = os.clock()
    local deltaTime = now - self.lastIntermediateUpdate
    self.lastIntermediateUpdate = now
    
    -- Update position based on speed and direction
    self.intermediatePosition = self.intermediatePosition + (self.intermediateSpeed * deltaTime * self.intermediateDirection)
    
    -- Bounce off edges
    if self.intermediateDirection == 1 and self.intermediatePosition + self.intermediateSize > self.width then
        self.intermediateDirection = -1
        self.intermediatePosition = self.width - self.intermediateSize + 1
    elseif self.intermediateDirection == -1 and self.intermediatePosition < 1 then
        self.intermediateDirection = 1
        self.intermediatePosition = 1
    end
    
    -- Clamp position to valid range
    self.intermediatePosition = math.max(1, math.min(self.width - self.intermediateSize + 1, self.intermediatePosition))
end

function ProgressBar:setIntermediate(enabled)
    self.intermediate = enabled
    if enabled then
        -- Reset intermediate animation state
        self.intermediatePosition = 1
        self.intermediateDirection = 1
        self.lastIntermediateUpdate = os.clock()
    end
end

-- ProgressRing Widget
local ProgressRing = setmetatable({}, {__index = Widget})
ProgressRing.__index = ProgressRing

function ProgressRing:new(props)
    local progressring = Widget.new(self, props)
    progressring.value = props.value or 0
    progressring.max = props.max or 100
    progressring.color = props.color or colors.green
    progressring.background = props.background or colors.gray
    progressring.centerColor = props.centerColor or colors.black
    progressring.showValue = props.showValue ~= false
    progressring.valueFormat = props.valueFormat or "%.0f%%"
    progressring.thickness = props.thickness or 1
    progressring.startAngle = props.startAngle or 0 -- Starting angle in degrees (0 = top)
    progressring.clockwise = props.clockwise ~= false
    progressring.showMarkers = props.showMarkers or false
    progressring.markerColor = props.markerColor or colors.white
    
    -- Default size for ring
    if not props.width then
        progressring.width = 9
    end
    if not props.height then
        progressring.height = 9
    end
    
    -- Ensure odd dimensions for centered ring
    if progressring.width % 2 == 0 then progressring.width = progressring.width + 1 end
    if progressring.height % 2 == 0 then progressring.height = progressring.height + 1 end
    
    progressring.radius = math.min(progressring.width, progressring.height) / 2 - 1
    progressring.centerX = math.floor(progressring.width / 2) + 1
    progressring.centerY = math.floor(progressring.height / 2) + 1
    
    return progressring
end

function ProgressRing:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Clear background
    term.setBackgroundColor(self.centerColor)
    for y = 0, self.height - 1 do
        term.setCursorPos(absX, absY + y)
        term.write(string.rep(" ", self.width))
    end
    
    local progress = math.min(self.value / self.max, 1)
    local progressAngle = progress * 360
    
    -- Draw ring using thin border characters
    self:drawRingBorder(absX, absY, progressAngle)
    
    -- Draw center value if enabled
    if self.showValue then
        local valueText = string.format(self.valueFormat, (self.value / self.max) * 100)
        local textX = absX + self.centerX - math.floor(#valueText / 2) - 1
        local textY = absY + self.centerY - 1
        
        term.setBackgroundColor(self.centerColor)
        term.setTextColor(colors.white)
        term.setCursorPos(textX, textY)
        term.write(valueText)
    end
    
    term.setBackgroundColor(colors.black)
end

function ProgressRing:drawRingBorder(absX, absY, progressAngle)
    local radius = self.radius
    
    -- Define the ring points to draw (approximating a circle)
    local ringPoints = {}
    
    -- Top and bottom horizontal segments
    for x = -radius + 1, radius - 1 do
        table.insert(ringPoints, {x = x, y = -radius, char = "\131"}) -- Top horizontal
        table.insert(ringPoints, {x = x, y = radius, char = "\143"})   -- Bottom horizontal
    end
    
    -- Left and right vertical segments  
    for y = -radius + 1, radius - 1 do
        table.insert(ringPoints, {x = -radius, y = y, char = "\149"}) -- Left vertical
        table.insert(ringPoints, {x = radius, y = y, char = "\149"})  -- Right vertical
    end
    
    -- Corner pieces
    table.insert(ringPoints, {x = -radius, y = -radius, char = "\151"}) -- Top-left
    table.insert(ringPoints, {x = radius, y = -radius, char = "\148"})   -- Top-right
    table.insert(ringPoints, {x = -radius, y = radius, char = "\138"})   -- Bottom-left
    table.insert(ringPoints, {x = radius, y = radius, char = "\133"})    -- Bottom-right
    
    -- Draw each ring point
    for _, point in ipairs(ringPoints) do
        local screenX = absX + self.centerX + point.x - 1
        local screenY = absY + self.centerY + point.y - 1
        
        -- Check if point is within widget bounds
        if screenX >= absX and screenX < absX + self.width and 
           screenY >= absY and screenY < absY + self.height then
            
            -- Calculate angle for this point
            local angle = math.deg(math.atan2(point.y, point.x)) + 90
            if angle < 0 then angle = angle + 360 end
            
            -- Adjust for start angle and direction
            local adjustedAngle = self.clockwise and (angle - self.startAngle) or (self.startAngle - angle)
            if adjustedAngle < 0 then adjustedAngle = adjustedAngle + 360 end
            if adjustedAngle > 360 then adjustedAngle = adjustedAngle - 360 end
            
            -- Determine color based on progress
            local fgColor = self.background
            local bgColor = self.centerColor
            
            if adjustedAngle <= progressAngle then
                fgColor = self.color
            end
            
            -- Draw markers at quarters if enabled
            if self.showMarkers and (adjustedAngle % 90 < 15 or adjustedAngle % 90 > 345) then
                fgColor = self.markerColor
            end
            
            -- Use safe hex color conversion
            local fgHex = getColorHex(fgColor) or "f"
            local bgHex = getColorHex(bgColor) or "0"
            
            term.setCursorPos(screenX, screenY)
            term.blit(point.char, fgHex, bgHex)
        end
    end
end

-- CircularProgressBar Widget
local CircularProgressBar = setmetatable({}, {__index = Widget})
CircularProgressBar.__index = CircularProgressBar

function CircularProgressBar:new(props)
    local circularprogress = Widget.new(self, props)
    circularprogress.value = props.value or 0
    circularprogress.max = props.max or 100
    circularprogress.color = props.color or colors.cyan
    circularprogress.background = props.background or colors.gray
    circularprogress.centerColor = props.centerColor or colors.black
    circularprogress.showValue = props.showValue ~= false
    circularprogress.valueFormat = props.valueFormat or "%.0f%%"
    circularprogress.showTitle = props.showTitle or false
    circularprogress.title = props.title or "Progress"
    circularprogress.titleColor = props.titleColor or colors.white
    circularprogress.style = props.style or "filled" -- "filled", "segmented", "dots"
    circularprogress.segments = props.segments or 8
    circularprogress.animated = props.animated or false
    circularprogress.animationSpeed = props.animationSpeed or 1
    circularprogress.lastAnimationUpdate = os.clock()
    circularprogress.animationOffset = 0
    
    -- Default size for circular progress
    if not props.width then
        circularprogress.width = 11
    end
    if not props.height then
        circularprogress.height = 11
    end
    
    -- Ensure odd dimensions for centered circle
    if circularprogress.width % 2 == 0 then circularprogress.width = circularprogress.width + 1 end
    if circularprogress.height % 2 == 0 then circularprogress.height = circularprogress.height + 1 end
    
    circularprogress.radius = math.min(circularprogress.width, circularprogress.height) / 2 - 1
    circularprogress.centerX = math.floor(circularprogress.width / 2) + 1
    circularprogress.centerY = math.floor(circularprogress.height / 2) + 1
    
    return circularprogress
end

function CircularProgressBar:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Update animation if enabled
    if self.animated then
        local now = os.clock()
        local deltaTime = now - self.lastAnimationUpdate
        self.lastAnimationUpdate = now
        self.animationOffset = (self.animationOffset + deltaTime * self.animationSpeed * 360) % 360
    end
    
    -- Clear background
    term.setBackgroundColor(self.centerColor)
    for y = 0, self.height - 1 do
        term.setCursorPos(absX, absY + y)
        term.write(string.rep(" ", self.width))
    end
    
    local progress = math.min(self.value / self.max, 1)
    
    if self.style == "segmented" then
        self:drawSegmentedProgress(absX, absY, progress)
    elseif self.style == "dots" then
        self:drawDottedProgress(absX, absY, progress)
    else
        self:drawFilledProgress(absX, absY, progress)
    end
    
    -- Draw center content
    self:drawCenterContent(absX, absY)
    
    term.setBackgroundColor(colors.black)
end

function CircularProgressBar:drawFilledProgress(absX, absY, progress)
    local progressAngle = progress * 360
    
    -- Add animation offset if enabled
    if self.animated then
        progressAngle = progressAngle + self.animationOffset
    end
    
    -- Draw using thin border characters like ProgressRing
    self:drawCircularBorder(absX, absY, progressAngle)
end

function CircularProgressBar:drawSegmentedProgress(absX, absY, progress)
    local filledSegments = math.floor(progress * self.segments)
    local segmentAngle = 360 / self.segments
    
    -- Calculate which segments to fill
    for segment = 0, self.segments - 1 do
        local startAngle = segment * segmentAngle
        local endAngle = (segment + 1) * segmentAngle
        local shouldFill = segment < filledSegments
        
        -- Add animation effect
        if self.animated then
            local animSegment = (segment + math.floor(self.animationOffset / segmentAngle)) % self.segments
            shouldFill = animSegment < filledSegments
        end
        
        -- Draw this segment
        self:drawSegmentArc(absX, absY, startAngle, endAngle, shouldFill)
    end
end

function CircularProgressBar:drawDottedProgress(absX, absY, progress)
    local totalDots = self.segments
    local filledDots = math.floor(progress * totalDots)
    local dotAngle = 360 / totalDots
    
    for dot = 0, totalDots - 1 do
        local angle = dot * dotAngle
        local shouldFill = dot < filledDots
        
        -- Add animation effect
        if self.animated then
            local animDot = (dot + math.floor(self.animationOffset / dotAngle)) % totalDots
            shouldFill = animDot < filledDots
        end
        
        -- Calculate dot position on the circle
        local radians = math.rad(angle - 90) -- Adjust so 0° is at top
        local dotX = self.centerX + round(math.cos(radians) * self.radius)
        local dotY = self.centerY + round(math.sin(radians) * self.radius)
        
        -- Draw dot using appropriate character
        if dotX >= 1 and dotX <= self.width and dotY >= 1 and dotY <= self.height then
            local screenX = absX + dotX - 1
            local screenY = absY + dotY - 1
            
            local fgColor = shouldFill and self.color or self.background
            local bgColor = self.centerColor
            local fgHex = getColorHex(fgColor) or "f"
            local bgHex = getColorHex(bgColor) or "0"
            
            term.setCursorPos(screenX, screenY)
            term.blit("*", fgHex, bgHex) -- Use * for dots
        end
    end
end

function CircularProgressBar:drawSegmentArc(absX, absY, startAngle, endAngle, shouldFill)
    local radius = self.radius
    
    -- Simple approach: draw border characters in the segment range
    local circlePoints = {}
    
    -- Add points around the circle
    for angle = startAngle, endAngle, 5 do -- Sample every 5 degrees
        local radians = math.rad(angle - 90)
        local x = round(math.cos(radians) * radius)
        local y = round(math.sin(radians) * radius)
        
        -- Choose appropriate border character based on position
        local char = "\149" -- Default to vertical line
        if math.abs(x) > math.abs(y) then
            char = x < 0 and "\149" or "\149" -- Vertical for sides
        else
            char = y < 0 and "\131" or "\143" -- Horizontal for top/bottom
        end
        
        table.insert(circlePoints, {x = x, y = y, char = char})
    end
    
    -- Draw the segment points
    for _, point in ipairs(circlePoints) do
        local screenX = absX + self.centerX + point.x - 1
        local screenY = absY + self.centerY + point.y - 1
        
        if screenX >= absX and screenX < absX + self.width and 
           screenY >= absY and screenY < absY + self.height then
            
            local fgColor = shouldFill and self.color or self.background
            local bgColor = self.centerColor
            local fgHex = getColorHex(fgColor) or "f"
            local bgHex = getColorHex(bgColor) or "0"
            
            term.setCursorPos(screenX, screenY)
            term.blit(point.char, fgHex, bgHex)
        end
    end
end

function CircularProgressBar:drawCircularBorder(absX, absY, progressAngle)
    local radius = self.radius
    
    -- Define the circle points using border characters
    local circlePoints = {}
    
    -- Top and bottom horizontal segments
    for x = -radius + 1, radius - 1 do
        table.insert(circlePoints, {x = x, y = -radius, char = "\131"}) -- Top horizontal
        table.insert(circlePoints, {x = x, y = radius, char = "\143"})   -- Bottom horizontal
    end
    
    -- Left and right vertical segments  
    for y = -radius + 1, radius - 1 do
        table.insert(circlePoints, {x = -radius, y = y, char = "\149"}) -- Left vertical
        table.insert(circlePoints, {x = radius, y = y, char = "\149"})  -- Right vertical
    end
    
    -- Corner pieces for rounded appearance
    table.insert(circlePoints, {x = -radius, y = -radius, char = "\151"}) -- Top-left
    table.insert(circlePoints, {x = radius, y = -radius, char = "\148"})   -- Top-right
    table.insert(circlePoints, {x = -radius, y = radius, char = "\138"})   -- Bottom-left
    table.insert(circlePoints, {x = radius, y = radius, char = "\133"})    -- Bottom-right
    
    -- Draw each circle point
    for _, point in ipairs(circlePoints) do
        local screenX = absX + self.centerX + point.x - 1
        local screenY = absY + self.centerY + point.y - 1
        
        -- Check if point is within widget bounds
        if screenX >= absX and screenX < absX + self.width and 
           screenY >= absY and screenY < absY + self.height then
            
            -- Calculate angle for this point
            local angle = math.deg(math.atan2(point.y, point.x)) + 90
            if angle < 0 then angle = angle + 360 end
            
            -- Normalize angle to 0-360
            while angle >= 360 do angle = angle - 360 end
            while angle < 0 do angle = angle + 360 end
            
            -- Determine color based on progress
            local fgColor = self.background
            local bgColor = self.centerColor
            
            if angle <= progressAngle then
                fgColor = self.color
            end
            
            -- Use safe hex color conversion
            local fgHex = getColorHex(fgColor) or "f"
            local bgHex = getColorHex(bgColor) or "0"
            
            term.setCursorPos(screenX, screenY)
            term.blit(point.char, fgHex, bgHex)
        end
    end
end

function CircularProgressBar:drawCenterContent(absX, absY)
    -- Draw title if enabled
    if self.showTitle and self.title ~= "" then
        local titleX = absX + self.centerX - math.floor(#self.title / 2) - 1
        local titleY = absY + self.centerY - 2
        
        if titleY >= absY and titleY < absY + self.height then
            term.setBackgroundColor(self.centerColor)
            term.setTextColor(self.titleColor)
            term.setCursorPos(titleX, titleY)
            term.write(self.title)
        end
    end
    
    -- Draw value if enabled
    if self.showValue then
        local valueText = string.format(self.valueFormat, (self.value / self.max) * 100)
        local textX = absX + self.centerX - math.floor(#valueText / 2) - 1
        local textY = absY + self.centerY - 1
        
        if self.showTitle then
            textY = textY + 1 -- Move down if title is shown
        end
        
        if textY >= absY and textY < absY + self.height then
            term.setBackgroundColor(self.centerColor)
            term.setTextColor(colors.white)
            term.setCursorPos(textX, textY)
            term.write(valueText)
        end
    end
end

-- ListView Widget
local ListView = setmetatable({}, {__index = Widget})
ListView.__index = ListView

function ListView:new(props)
    local listview = Widget.new(self, props)
    listview.items = props.items or {}
    listview.selectedIndex = props.selectedIndex or 1
    listview.scrollable = props.scrollable ~= false
    listview.onSelect = props.onSelect
    listview.itemRenderer = props.itemRenderer
    listview.scrollOffset = 0
    
    return listview
end

function ListView:render()
    local absX, absY = self:getAbsolutePos()
    
    for i = 1, self.height do
        local itemIndex = i + self.scrollOffset
        if itemIndex <= #self.items then
            local item = self.items[itemIndex]
            local isSelected = itemIndex == self.selectedIndex
            
            term.setBackgroundColor(isSelected and colors.blue or colors.black)
            term.setTextColor(isSelected and colors.white or colors.lightGray)
            
            term.setCursorPos(absX, absY + i - 1)
            
            local text = ""
            if self.itemRenderer then
                text = self.itemRenderer(item, itemIndex, isSelected)
            else
                text = tostring(item)
            end
            
            text = text:sub(1, self.width)
            term.write(text .. string.rep(" ", self.width - #text))
        else
            term.setBackgroundColor(colors.black)
            term.setCursorPos(absX, absY + i - 1)
            term.write(string.rep(" ", self.width))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function ListView:onClick(relX, relY)
    if self.enabled then
        local clickedIndex = relY + self.scrollOffset
        if clickedIndex >= 1 and clickedIndex <= #self.items then
            self.selectedIndex = clickedIndex
            if self.onSelect then
                self:onSelect(self.items[clickedIndex], clickedIndex)
            end
        end
    end
end

-- Container Widget
local Container = setmetatable({}, {__index = Widget})
Container.__index = Container

function Container:new(props)
    local container = Widget.new(self, props)
    container.layout = props.layout or "absolute"
    container.padding = props.padding or 0
    container.background = props.background
    container.border = props.border or false
    container.isScrollable = props.isScrollable ~= false -- Default enabled
    container.scrollX = 0
    container.scrollY = 0
    container.contentWidth = 0
    container.contentHeight = 0
    container.verticalScrollBar = nil
    container.horizontalScrollBar = nil
    container.autoMargin = props.autoMargin or false
    
    return container
end

function Container:render()
    local absX, absY = self:getAbsolutePos()
    
    if self.background then
        term.setBackgroundColor(self.background)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(string.rep(" ", self.width))
        end
    end
    
    if self.border then
        local borderColor = currentTheme.border
        drawCharBorder(absX, absY, self.width, self.height, borderColor, self.background or colors.black)
        
        -- Restore interior background if specified
        if self.background then
            term.setBackgroundColor(self.background)
            for i = 1, self.height - 2 do
                term.setCursorPos(absX + 1, absY + i)
                term.write(string.rep(" ", self.width - 2))
            end
        end
    end
    
    -- Update content dimensions and create scrollbars if needed
    self:updateScrollBars()
    
    term.setBackgroundColor(colors.black)
end

function Container:updateScrollBars()
    if not self.isScrollable then return end
    
    -- Calculate content bounds
    self:calculateContentBounds()
    
    local viewWidth = self.width - (self.border and 2 or 0)
    local viewHeight = self.height - (self.border and 2 or 0)
    
    local needsVerticalScroll = self.contentHeight > viewHeight
    local needsHorizontalScroll = self.contentWidth > viewWidth
    
    -- Account for scrollbar space
    if needsVerticalScroll then
        viewWidth = viewWidth - 1
    end
    if needsHorizontalScroll then
        viewHeight = viewHeight - 1
    end
    
    -- Only create scrollbars if ScrollBar class is available (defined later in file)
    if not ScrollBar then return end
    
    -- Create vertical scrollbar if needed
    if needsVerticalScroll and not self.verticalScrollBar then
        self.verticalScrollBar = ScrollBar:new({
            x = self.width - (self.border and 1 or 0),
            y = (self.border and 2 or 1),
            width = 1,
            height = viewHeight,
            orientation = "vertical",
            min = 0,
            max = self.contentHeight - viewHeight,
            pageSize = viewHeight,
            onChange = function(value)
                self.scrollY = value
            end
        })
        self.verticalScrollBar.parent = self
    elseif not needsVerticalScroll and self.verticalScrollBar then
        self.verticalScrollBar = nil
        self.scrollY = 0
    end
    
    -- Create horizontal scrollbar if needed
    if needsHorizontalScroll and not self.horizontalScrollBar then
        self.horizontalScrollBar = ScrollBar:new({
            x = (self.border and 2 or 1),
            y = self.height - (self.border and 1 or 0),
            width = viewWidth,
            height = 1,
            orientation = "horizontal",
            min = 0,
            max = self.contentWidth - viewWidth,
            pageSize = viewWidth,
            onChange = function(value)
                self.scrollX = value
            end
        })
        self.horizontalScrollBar.parent = self
    elseif not needsHorizontalScroll and self.horizontalScrollBar then
        self.horizontalScrollBar = nil
        self.scrollX = 0
    end
end

function Container:calculateContentBounds()
    self.contentWidth = 0
    self.contentHeight = 0
    
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            local rightEdge = child.x + child.width - 1
            local bottomEdge = child.y + child.height - 1
            
            self.contentWidth = math.max(self.contentWidth, rightEdge)
            self.contentHeight = math.max(self.contentHeight, bottomEdge)
        end
    end
end

function Container:draw()
    if not self.visible then return end
    self:render()
    -- Set up clipping region for scrollable content
    local contentX = (self.border and 1 or 0) + 1
    local contentY = (self.border and 1 or 0) + 1
    local contentWidth = self.width - (self.border and 2 or 0) - (self.verticalScrollBar and 1 or 0)
    local contentHeight = self.height - (self.border and 2 or 0) - (self.horizontalScrollBar and 1 or 0)
    -- Draw children with scroll offset and strict clipping
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            -- Apply scroll offset (vertical only for now)
            local originalX, originalY = child.x, child.y
            child.x = child.x - (self.scrollX or 0)
            child.y = child.y - (self.scrollY or 0)
            -- Compute child's area relative to content area
            local childLeft = child.x
            local childTop = child.y
            local childRight = child.x + (child.width or 1) - 1
            local childBottom = child.y + (child.height or 1) - 1
            local clipLeft = contentX
            local clipTop = contentY
            local clipRight = contentX + contentWidth - 1
            local clipBottom = contentY + contentHeight - 1
            -- Only draw if child is fully or partially inside the viewport
            if childRight >= clipLeft and childLeft <= clipRight and childBottom >= clipTop and childTop <= clipBottom then
                child:draw()
            end
            -- Restore original position
            child.x, child.y = originalX, originalY
        end
    end
    -- Draw scrollbars
    if self.verticalScrollBar then self.verticalScrollBar:draw() end
    if self.horizontalScrollBar then self.horizontalScrollBar:draw() end
end

function Container:handleScroll(x, y, direction)
    if not self.enabled or not self.visible or not self.isScrollable then return false end
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        if self.verticalScrollBar then
            self.verticalScrollBar:scroll(direction * 3)
            return true
        else
            -- Fallback: update scrollY directly if no scrollbar
            self.scrollY = math.max(0, math.min((self.contentHeight or 0) - (self.height - (self.border and 2 or 0)), self.scrollY - direction * 3))
            return true
        end
    end
    return false
end
function Container:handleClick(x, y)
    if not self.enabled or not self.visible then return false end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    -- Check scrollbars first
    if self.verticalScrollBar and self.verticalScrollBar:handleClick(x, y) then
        return true
    end
    if self.horizontalScrollBar and self.horizontalScrollBar:handleClick(x, y) then
        return true
    end
    
    -- Check children with scroll offset and strict bounds
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.visible ~= false then
            -- Apply scroll offset for hit testing
            local absX, absY = self:getAbsolutePos()
            local relChildX = child.x - (self.scrollX or 0)
            local relChildY = child.y - (self.scrollY or 0)
            local childLeft = absX + relChildX - 1
            local childTop = absY + relChildY - 1
            local childRight = childLeft + (child.width or 1) - 1
            local childBottom = childTop + (child.height or 1) - 1
            local clipLeft = absX + (self.border and 1 or 0)
            local clipTop = absY + (self.border and 1 or 0)
            local clipRight = clipLeft + (self.width - (self.border and 2 or 0) - (self.verticalScrollBar and 1 or 0)) - 1
            local clipBottom = clipTop + (self.height - (self.border and 2 or 0) - (self.horizontalScrollBar and 1 or 0)) - 1

            -- Only allow click if child is at least partially inside the viewport
            if childRight >= clipLeft and childLeft <= clipRight and childBottom >= clipTop and childTop <= clipBottom then
                -- Adjust event coordinates for child
                local adjustedX = x + (self.scrollX or 0)
                local adjustedY = y + (self.scrollY or 0)
                if child:handleClick(adjustedX, adjustedY) then
                    return true
                end
            end
        end
    end
    
    -- Check if click is within this container
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        if self.onClick then
            self:onClick(relX, relY)
        end
        return true
    end
    
    return false
end

function Container:handleScroll(x, y, direction)
    if not self.enabled or not self.visible or not self.isScrollable then return false end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        if self.verticalScrollBar then
            self.verticalScrollBar:scroll(direction * 3) -- Scroll 3 lines at a time
            return true
        end
    end
    
    return false
end

function Container:addChild(child)
    Widget.addChild(self, child)
    self:layoutChildren()
end

function Container:layoutChildren()
    if self.layout == "vertical" then
        local currentY = self.padding + (self.border and 1 or 0) + 1
        for _, child in ipairs(self.children) do
            child.x = self.padding + (self.border and 1 or 0) + 1
            child.y = currentY
            currentY = currentY + child.height
        end
    elseif self.layout == "horizontal" then
        local currentX = self.padding + (self.border and 1 or 0) + 1
        for _, child in ipairs(self.children) do
            child.x = currentX
            child.y = self.padding + (self.border and 1 or 0) + 1
            currentX = currentX + child.width
        end
    end
    -- "absolute" layout doesn't change positions
    
    -- Apply auto margin if enabled
    if self.autoMargin then
        self:applySmartMargins()
    end
end

-- Smart Margin System
function Container:applySmartMargins()
    if #self.children == 0 then return end
    
    local availableWidth = self.width - (self.border and 2 or 0)
    local availableHeight = self.height - (self.border and 2 or 0)
    
    if self.layout == "vertical" then
        self:applyVerticalSmartMargins(availableWidth, availableHeight)
    elseif self.layout == "horizontal" then
        self:applyHorizontalSmartMargins(availableWidth, availableHeight)
    else
        self:applyAbsoluteSmartMargins(availableWidth, availableHeight)
    end
end

function Container:applyVerticalSmartMargins(availableWidth, availableHeight)
    -- Calculate total content height
    local totalContentHeight = 0
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            totalContentHeight = totalContentHeight + child.height
        end
    end
    
    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            table.insert(visibleChildren, child)
        end
    end
    
    -- Calculate optimal spacing
    local remainingHeight = availableHeight - totalContentHeight
    local spacing = math.max(0, math.floor(remainingHeight / (#visibleChildren + 1)))
    
    -- Apply margins
    local currentY = spacing + (self.border and 1 or 0) + 1
    for _, child in ipairs(visibleChildren) do
        child.y = currentY
        child.x = (self.border and 1 or 0) + 1 + math.floor((availableWidth - child.width) / 2) -- Center horizontally
        currentY = currentY + child.height + spacing
    end
end

function Container:applyHorizontalSmartMargins(availableWidth, availableHeight)
    -- Calculate total content width
    local totalContentWidth = 0
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            totalContentWidth = totalContentWidth + child.width
        end
    end
    
    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            table.insert(visibleChildren, child)
        end
    end
    
    -- Calculate optimal spacing
    local remainingWidth = availableWidth - totalContentWidth
    local spacing = math.max(0, math.floor(remainingWidth / (#visibleChildren + 1)))
    
    -- Apply margins
    local currentX = spacing + (self.border and 1 or 0) + 1
    for _, child in ipairs(visibleChildren) do
        child.x = currentX
        child.y = (self.border and 1 or 0) + 1 + math.floor((availableHeight - child.height) / 2) -- Center vertically
        currentX = currentX + child.width + spacing
    end
end

function Container:applyAbsoluteSmartMargins(availableWidth, availableHeight)
    -- For absolute layout, apply smart padding to optimize space usage
    local children = {}
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            table.insert(children, child)
        end
    end
    
    if #children == 0 then return end
    
    -- Use a grid-based approach for absolute positioning
    local cols = math.ceil(math.sqrt(#children))
    local rows = math.ceil(#children / cols)
    
    local cellWidth = math.floor(availableWidth / cols)
    local cellHeight = math.floor(availableHeight / rows)
    
    for i, child in ipairs(children) do
        local col = ((i - 1) % cols) + 1
        local row = math.ceil(i / cols)
        
        local cellX = (col - 1) * cellWidth + (self.border and 1 or 0) + 1
        local cellY = (row - 1) * cellHeight + (self.border and 1 or 0) + 1
        
        -- Center child within cell
        child.x = cellX + math.floor((cellWidth - child.width) / 2)
        child.y = cellY + math.floor((cellHeight - child.height) / 2)
        
        -- Ensure child stays within bounds
        child.x = math.max((self.border and 1 or 0) + 1, math.min(child.x, availableWidth - child.width + 1))
        child.y = math.max((self.border and 1 or 0) + 1, math.min(child.y, availableHeight - child.height + 1))
    end
end

function Container:optimizeLayout()
    -- Advanced layout optimization algorithm
    if #self.children == 0 then return end
    
    local availableWidth = self.width - (self.border and 2 or 0)
    local availableHeight = self.height - (self.border and 2 or 0)
    
    -- Collect visible children
    local visibleChildren = {}
    for _, child in ipairs(self.children) do
        if child.visible ~= false then
            table.insert(visibleChildren, child)
        end
    end
    
    -- Calculate aspect ratios and priority scores
    local childData = {}
    for i, child in ipairs(visibleChildren) do
        local aspectRatio = child.width / child.height
        local area = child.width * child.height
        local priority = child.layoutPriority or 1
        
        table.insert(childData, {
            child = child,
            index = i,
            aspectRatio = aspectRatio,
            area = area,
            priority = priority,
            originalWidth = child.width,
            originalHeight = child.height
        })
    end
    
    -- Sort by priority (higher priority first)
    table.sort(childData, function(a, b) return a.priority > b.priority end)
    
    -- Apply optimal positioning using a bin-packing algorithm
    local usedAreas = {}
    
    for _, data in ipairs(childData) do
        local bestX, bestY = self:findBestPosition(data.child, usedAreas, availableWidth, availableHeight)
        
        data.child.x = bestX + (self.border and 1 or 0) + 1
        data.child.y = bestY + (self.border and 1 or 0) + 1
        
        -- Record used area
        table.insert(usedAreas, {
            x = bestX,
            y = bestY,
            width = data.child.width,
            height = data.child.height
        })
    end
end

function Container:findBestPosition(child, usedAreas, availableWidth, availableHeight)
    local bestX, bestY = 0, 0
    local bestScore = -1
    
    -- Try different positions and score them
    for y = 0, availableHeight - child.height do
        for x = 0, availableWidth - child.width do
            if not self:overlapsWithUsedAreas(x, y, child.width, child.height, usedAreas) then
                local score = self:calculatePositionScore(x, y, child, availableWidth, availableHeight)
                if score > bestScore then
                    bestScore = score
                    bestX, bestY = x, y
                end
            end
        end
    end
    
    return bestX, bestY
end

function Container:overlapsWithUsedAreas(x, y, width, height, usedAreas)
    for _, area in ipairs(usedAreas) do
        if not (x >= area.x + area.width or 
                x + width <= area.x or 
                y >= area.y + area.height or 
                y + height <= area.y) then
            return true
        end
    end
    return false
end

function Container:calculatePositionScore(x, y, child, availableWidth, availableHeight)
    -- Score based on multiple factors
    local score = 0
    
    -- Prefer positions closer to top-left (reading order)
    score = score - (x + y) * 0.1
    
    -- Prefer positions that don't waste space at edges
    local rightWaste = availableWidth - (x + child.width)
    local bottomWaste = availableHeight - (y + child.height)
    score = score - (rightWaste + bottomWaste) * 0.05
    
    -- Prefer positions that align with existing elements
    -- (simplified - could be expanded with more sophisticated alignment detection)
    score = score + (x == 0 and 10 or 0) -- Left alignment bonus
    score = score + (y == 0 and 10 or 0) -- Top alignment bonus
    
    return score
end

-- ToggleSwitch Widget
local ToggleSwitch = setmetatable({}, {__index = Widget})
ToggleSwitch.__index = ToggleSwitch

function ToggleSwitch:new(props)
    local toggleswitch = Widget.new(self, props)
    toggleswitch.checked = props.checked or false
    toggleswitch.text = props.text or ""
    toggleswitch.color = props.color or colors.white
    toggleswitch.onToggle = props.onToggle
    
    -- Theme support for colors
    toggleswitch.trackColorOn = props.trackColorOn or colors.lime
    toggleswitch.trackColorOff = props.trackColorOff or colors.lightGray
    toggleswitch.borderColorOn = props.borderColorOn or colors.green
    toggleswitch.borderColorOff = props.borderColorOff or colors.gray
    toggleswitch.knobColor = props.knobColor or colors.white
    toggleswitch.statusColor = props.statusColor or toggleswitch.color
    
    -- Auto-size if not specified - account for new modern design
    -- Track (5) + knob overlap (0) + label space (2) + text + status ([ON/OFF] = 6)
    if not props.width then
        local baseWidth = 5 -- track width
        local labelWidth = (#toggleswitch.text > 0) and (#toggleswitch.text + 2) or 0
        local statusWidth = 7 -- " [OFF]" or " [ON]"
        toggleswitch.width = baseWidth + labelWidth + statusWidth
    end
    if not props.height then
        toggleswitch.height = 1
    end
    
    return toggleswitch
end

function ToggleSwitch:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Modern switch design with rounded track appearance and theme support
    local trackWidth = 5
    local trackColor = self.checked and self.trackColorOn or self.trackColorOff
    local trackBorderColor = self.checked and self.borderColorOn or self.borderColorOff
    local knobColor = self.knobColor
    local knobChar = "O"
    local knobPos = self.checked and (trackWidth - 1) or 1
    
    -- Draw track background with borders
    term.setBackgroundColor(trackBorderColor)
    term.setTextColor(trackBorderColor)
    term.setCursorPos(absX, absY)
    term.write("[")
    
    -- Draw track interior
    term.setBackgroundColor(trackColor)
    term.setTextColor(trackColor)
    for i = 1, trackWidth - 2 do
        term.write(" ")
    end
    
    term.setBackgroundColor(trackBorderColor)
    term.setTextColor(trackBorderColor)
    term.write("]")
    
    -- Draw knob
    term.setBackgroundColor(knobColor)
    term.setTextColor(colors.black)
    term.setCursorPos(absX + knobPos, absY)
    term.write(knobChar)
    
    -- Draw label with better spacing
    if #self.text > 0 then
        term.setBackgroundColor(colors.black)
        term.setTextColor(self.enabled and self.color or colors.gray)
        term.setCursorPos(absX + trackWidth + 2, absY)
        term.write(self.text)
    end
    
    -- Draw status indicator (ON/OFF) for clarity
    local statusText = self.checked and "ON" or "OFF"
    local statusColor = self.checked and self.trackColorOn or self.statusColor
    term.setTextColor(statusColor)
    term.setCursorPos(absX + trackWidth + (#self.text > 0 and #self.text + 3 or 2), absY)
    term.write(" [" .. statusText .. "]")
    
    term.setBackgroundColor(colors.black)
end

function ToggleSwitch:onClick()
    if self.enabled then
        self.checked = not self.checked
        if self.onToggle then
            self:onToggle(self.checked)
        end
    end
end

-- RadioButton Widget
local RadioButton = setmetatable({}, {__index = Widget})
RadioButton.__index = RadioButton

function RadioButton:new(props)
    local radiobutton = Widget.new(self, props)
    radiobutton.checked = props.checked or false
    radiobutton.text = props.text or ""
    radiobutton.group = props.group or "default"
    radiobutton.color = props.color or colors.white
    radiobutton.onSelect = props.onSelect
    
    -- Auto-size if not specified
    if not props.width then
        radiobutton.width = 2 + #radiobutton.text  -- 1 for radio + 1 space + text length
    end
    if not props.height then
        radiobutton.height = 1
    end
    
    return radiobutton
end

function RadioButton:render()
    local absX, absY = self:getAbsolutePos()
    
    term.setTextColor(self.color)
    term.setCursorPos(absX, absY)
    
    local radioChar = self.checked and "-" or "o"  -- Dash for selected, o for unselected
    term.write(radioChar .. " " .. self.text)
    
    term.setBackgroundColor(colors.black)
end

function RadioButton:onClick()
    if self.enabled then
        -- Uncheck other radio buttons in the same group
        for _, widget in ipairs(widgets) do
            if widget ~= self and widget.group == self.group and widget.checked then
                widget.checked = false
            end
        end
        
        self.checked = true
        if self.onSelect then
            self:onSelect()
        end
    end
end

-- ComboBox Widget
local ComboBox = setmetatable({}, {__index = Widget})
ComboBox.__index = ComboBox

function ComboBox:new(props)
    local combobox = Widget.new(self, props)
    combobox.items = props.items or {}
    combobox.selectedIndex = props.selectedIndex or 1
    combobox.color = props.color or colors.white
    combobox.background = props.background or colors.black
    combobox.onSelect = props.onSelect
    combobox.isOpen = false
    combobox.baseHeight = props.height or 1
    
    if not props.width then
        combobox.width = 20
    end
    combobox.height = combobox.baseHeight
    
    return combobox
end

function ComboBox:render()
    local absX, absY = self:getAbsolutePos()
    
    term.setBackgroundColor(self.background)
    term.setTextColor(self.color)
    
    -- Draw main box
    term.setCursorPos(absX, absY)
    local selectedText = self.items[self.selectedIndex] or ""
    local displayText = selectedText:sub(1, self.width - 2)
    term.write(displayText .. string.rep(" ", self.width - 2 - #displayText) .. "v")
    
    -- Draw dropdown if open
    if self.isOpen then
        for i = 1, #self.items do
            local item = self.items[i]
            if item then
                term.setCursorPos(absX, absY + i)
                local isSelected = i == self.selectedIndex
                term.setBackgroundColor(isSelected and colors.blue or colors.lightGray)
                term.setTextColor(isSelected and colors.white or colors.black)
                local itemText = tostring(item):sub(1, self.width)
                term.write(itemText .. string.rep(" ", self.width - #itemText))
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function ComboBox:onClick(relX, relY)
    if self.enabled then
        if not self.isOpen then
            -- Open the dropdown
            self.isOpen = true
            self.height = self.baseHeight + #self.items
        else
            -- If clicking on the main box area, close dropdown
            if relY == 1 then
                self.isOpen = false
                self.height = self.baseHeight
            -- If clicking on dropdown items
            elseif relY > 1 then
                local selectedIndex = relY - 1
                if selectedIndex >= 1 and selectedIndex <= #self.items then
                    self.selectedIndex = selectedIndex
                    if self.onSelect then
                        self:onSelect(self.items[selectedIndex], selectedIndex)
                    end
                    self.isOpen = false
                    self.height = self.baseHeight
                end
            end
        end
    end
end

-- TabControl Widget
local TabControl = setmetatable({}, {__index = Widget})
TabControl.__index = TabControl

function TabControl:new(props)
    local tabcontrol = Widget.new(self, props)
    tabcontrol.tabs = props.tabs or {}
    tabcontrol.selectedIndex = props.selectedIndex or 1
    tabcontrol.color = props.color or colors.white
    tabcontrol.background = props.background or colors.black
    tabcontrol.onChange = props.onChange
    
    return tabcontrol
end

function TabControl:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Draw tab headers
    local currentX = absX
    for i, tab in ipairs(self.tabs) do
        local isSelected = i == self.selectedIndex
        term.setBackgroundColor(isSelected and colors.lightGray or colors.gray)
        term.setTextColor(isSelected and colors.black or colors.white)
        
        term.setCursorPos(currentX, absY)
        local tabText = " " .. tab.text .. " "
        term.write(tabText)
        currentX = currentX + #tabText
    end
    
    -- Draw content area
    term.setBackgroundColor(self.background)
    for i = 1, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw selected tab content
    if self.tabs[self.selectedIndex] and self.tabs[self.selectedIndex].content then
        local content = self.tabs[self.selectedIndex].content
        content.x = 1
        content.y = 2
        content:draw()
    end
    
    term.setBackgroundColor(colors.black)
end

function TabControl:onClick(relX, relY)
    if self.enabled and relY == 1 then
        -- Calculate which tab was clicked
        local currentX = 1
        for i, tab in ipairs(self.tabs) do
            local tabWidth = #tab.text + 2
            if relX >= currentX and relX < currentX + tabWidth then
                self.selectedIndex = i
                if self.onChange then
                    self:onChange(i)
                end
                break
            end
            currentX = currentX + tabWidth
        end
    end
end

-- Grid Widget
local Grid = setmetatable({}, {__index = Widget})
Grid.__index = Grid

function Grid:new(props)
    local grid = Widget.new(self, props)
    grid.rows = props.rows or 1
    grid.columns = props.columns or 1
    grid.background = props.background
    grid.cellWidth = math.floor(grid.width / grid.columns)
    grid.cellHeight = math.floor(grid.height / grid.rows)
    
    return grid
end

function Grid:render()
    local absX, absY = self:getAbsolutePos()
    
    if self.background then
        term.setBackgroundColor(self.background)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(string.rep(" ", self.width))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Grid:addChildAt(child, row, column)
    child.x = (column - 1) * self.cellWidth + 1
    child.y = (row - 1) * self.cellHeight + 1
    child.gridRow = row
    child.gridColumn = column
    self:addChild(child)
end

-- Canvas Widget
local Canvas = setmetatable({}, {__index = Widget})
Canvas.__index = Canvas

function Canvas:new(props)
    local canvas = Widget.new(self, props)
    canvas.pixels = {}
    canvas.background = props.background or colors.black
    canvas.border = props.border or false
    canvas.borderColor = props.borderColor or colors.white
    canvas.onDraw = props.onDraw
    
    -- Initialize pixel array
    for y = 1, canvas.height do
        canvas.pixels[y] = {}
    end
    
    return canvas
end

function Canvas:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Call onDraw callback if provided
    if self.onDraw then
        self.onDraw(self, self)
    end
    
    -- Draw border if enabled
    if self.border then
        drawCharBorder(absX, absY, self.width, self.height, self.borderColor, self.background)
    end
    
    -- Draw canvas content
    local startX = self.border and 1 or 0
    local startY = self.border and 1 or 0
    local endX = self.width - (self.border and 1 or 0)
    local endY = self.height - (self.border and 1 or 0)
    
    for y = startY + 1, endY do
        for x = startX + 1, endX do
            local canvasX = x - startX
            local canvasY = y - startY
            local pixel = self.pixels[canvasY] and self.pixels[canvasY][canvasX]
            
            if pixel then
                if pixel.bg then term.setBackgroundColor(pixel.bg) end
                if pixel.fg then term.setTextColor(pixel.fg) end
                term.setCursorPos(absX + x - 1, absY + y - 1)
                term.write(pixel.char or " ")
            else
                term.setBackgroundColor(self.background)
                term.setCursorPos(absX + x - 1, absY + y - 1)
                term.write(" ")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Canvas:setPixel(x, y, color)
    if not self.pixels[y] then
        self.pixels[y] = {}
    end
    self.pixels[y][x] = {bg = color}
end

function Canvas:clear(color)
    color = color or self.background
    for y = 1, self.height do
        if not self.pixels[y] then
            self.pixels[y] = {}
        end
        for x = 1, self.width do
            self.pixels[y][x] = {bg = color}
        end
    end
end

-- Chart Widget
local Chart = setmetatable({}, {__index = Widget})
Chart.__index = Chart

function Chart:new(props)
    local chart = Widget.new(self, props)
    chart.data = props.data or {}
    chart.chartType = props.chartType or "line" -- "line", "bar", "scatter"
    chart.renderMode = props.renderMode or "lines" -- "lines", "pixels"
    chart.title = props.title or ""
    chart.xLabel = props.xLabel or ""
    chart.yLabel = props.yLabel or ""
    chart.background = props.background or colors.black
    chart.axisColor = props.axisColor or colors.lightGray
    chart.dataColor = props.dataColor or colors.cyan
    chart.titleColor = props.titleColor or colors.white
    chart.labelColor = props.labelColor or colors.lightGray
    chart.showGrid = props.showGrid ~= false
    chart.gridColor = props.gridColor or colors.gray
    chart.autoScale = props.autoScale ~= false
    chart.minY = props.minY
    chart.maxY = props.maxY
    chart.minX = props.minX
    chart.maxX = props.maxX
    
    if not props.width then
        chart.width = 20
    end
    if not props.height then
        chart.height = 10
    end
    
    return chart
end

function Chart:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Clear background
    term.setBackgroundColor(self.background)
    for y = 0, self.height - 1 do
        term.setCursorPos(absX, absY + y)
        term.write(string.rep(" ", self.width))
    end
    
    if #self.data == 0 then
        -- Show "No Data" message
        term.setTextColor(self.labelColor)
        term.setCursorPos(absX + math.floor(self.width / 2) - 3, absY + math.floor(self.height / 2))
        term.write("No Data")
        return
    end
    
    -- Calculate data bounds
    local minX, maxX, minY, maxY = self:calculateBounds()
    
    -- Chart area (leave space for axes and labels)
    local chartX = absX + 3
    local chartY = absY + 1
    local chartWidth = self.width - 4
    local chartHeight = self.height - 3
    
    -- Draw title
    if self.title ~= "" then
        term.setTextColor(self.titleColor)
        term.setCursorPos(absX + math.floor((self.width - #self.title) / 2), absY)
        term.write(self.title)
        chartY = chartY + 1
        chartHeight = chartHeight - 1
    end
    
    -- Draw grid
    if self.showGrid then
        term.setTextColor(self.gridColor)
        for x = 0, chartWidth - 1, math.max(1, math.floor(chartWidth / 5)) do
            for y = 0, chartHeight - 1 do
                term.setCursorPos(chartX + x, chartY + y)
                term.write(".")
            end
        end
        for y = 0, chartHeight - 1, math.max(1, math.floor(chartHeight / 4)) do
            for x = 0, chartWidth - 1 do
                term.setCursorPos(chartX + x, chartY + y)
                term.write(".")
            end
        end
    end
    
    -- Draw axes
    term.setTextColor(self.axisColor)
    -- Y axis
    for y = 0, chartHeight - 1 do
        term.setCursorPos(chartX - 1, chartY + y)
        term.write("|")
    end
    -- X axis
    for x = 0, chartWidth - 1 do
        term.setCursorPos(chartX + x, chartY + chartHeight)
        term.write("-")
    end
    -- Origin
    term.setCursorPos(chartX - 1, chartY + chartHeight)
    term.write("+")
    
    -- Draw data based on chart type
    if self.chartType == "line" then
        self:drawLineChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    elseif self.chartType == "bar" then
        self:drawBarChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    elseif self.chartType == "scatter" then
        self:drawScatterChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    end
    
    -- Draw labels
    if self.xLabel ~= "" then
        term.setTextColor(self.labelColor)
        term.setCursorPos(absX + math.floor((self.width - #self.xLabel) / 2), absY + self.height - 1)
        term.write(self.xLabel)
    end
    
    if self.yLabel ~= "" then
        term.setTextColor(self.labelColor)
        -- Render y-label vertically
        local labelY = absY + math.floor((self.height - #self.yLabel) / 2)
        for i = 1, #self.yLabel do
            term.setCursorPos(absX, labelY + i - 1)
            term.write(self.yLabel:sub(i, i))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Chart:calculateBounds()
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    
    for _, point in ipairs(self.data) do
        local x, y = point.x or point[1] or 0, point.y or point[2] or 0
        if x < minX then minX = x end
        if x > maxX then maxX = x end
        if y < minY then minY = y end
        if y > maxY then maxY = y end
    end
    
    -- Use provided bounds if not auto-scaling
    if not self.autoScale then
        minX = self.minX or minX
        maxX = self.maxX or maxX
        minY = self.minY or minY
        maxY = self.maxY or maxY
    end
    
    -- Add padding if range is too small
    if maxX - minX < 0.1 then
        maxX = maxX + 0.5
        minX = minX - 0.5
    end
    if maxY - minY < 0.1 then
        maxY = maxY + 0.5
        minY = minY - 0.5
    end
    
    return minX, maxX, minY, maxY
end

function Chart:drawLineChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    term.setTextColor(self.dataColor)
    
    if self.renderMode == "pixels" then
        -- Pixels mode: draw only individual points
        for i, point in ipairs(self.data) do
            local x, y = point.x or point[1] or 0, point.y or point[2] or 0
            
            -- Convert to screen coordinates
            local screenX = chartX + math.floor((x - minX) / (maxX - minX) * (chartWidth - 1))
            local screenY = chartY + chartHeight - 1 - math.floor((y - minY) / (maxY - minY) * (chartHeight - 1))
            
            if screenX >= chartX and screenX < chartX + chartWidth and
               screenY >= chartY and screenY < chartY + chartHeight then
                term.setCursorPos(screenX, screenY)
                term.write("*")
            end
        end
    else
        -- Lines mode: draw points connected with lines
        local lastScreenX, lastScreenY = nil, nil
        
        for i, point in ipairs(self.data) do
            local x, y = point.x or point[1] or 0, point.y or point[2] or 0
            
            -- Convert to screen coordinates
            local screenX = chartX + math.floor((x - minX) / (maxX - minX) * (chartWidth - 1))
            local screenY = chartY + chartHeight - 1 - math.floor((y - minY) / (maxY - minY) * (chartHeight - 1))
            
            if screenX >= chartX and screenX < chartX + chartWidth and
               screenY >= chartY and screenY < chartY + chartHeight then
                
                -- Draw point
                term.setCursorPos(screenX, screenY)
                term.write("*")
                
                -- Draw line to previous point
                if lastScreenX and lastScreenY then
                    self:drawLine(lastScreenX, lastScreenY, screenX, screenY)
                end
                
                lastScreenX, lastScreenY = screenX, screenY
            end
        end
    end
end

function Chart:drawBarChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    term.setTextColor(self.dataColor)
    
    local barWidth = math.max(1, math.floor(chartWidth / #self.data))
    
    for i, point in ipairs(self.data) do
        local x, y = point.x or point[1] or i, point.y or point[2] or 0
        
        local barX = chartX + (i - 1) * barWidth
        local barHeight = math.floor((y - minY) / (maxY - minY) * chartHeight)
        local barTop = chartY + chartHeight - barHeight
        
        -- Draw bar
        for bx = 0, barWidth - 1 do
            for by = 0, barHeight - 1 do
                if barX + bx < chartX + chartWidth then
                    term.setCursorPos(barX + bx, barTop + by)
                    term.write("#")
                end
            end
        end
    end
end

function Chart:drawScatterChart(chartX, chartY, chartWidth, chartHeight, minX, maxX, minY, maxY)
    term.setTextColor(self.dataColor)
    
    for i, point in ipairs(self.data) do
        local x, y = point.x or point[1] or 0, point.y or point[2] or 0
        
        -- Convert to screen coordinates
        local screenX = chartX + math.floor((x - minX) / (maxX - minX) * (chartWidth - 1))
        local screenY = chartY + chartHeight - 1 - math.floor((y - minY) / (maxY - minY) * (chartHeight - 1))
        
        if screenX >= chartX and screenX < chartX + chartWidth and
           screenY >= chartY and screenY < chartY + chartHeight then
            term.setCursorPos(screenX, screenY)
            term.write("o")
        end
    end
end

function Chart:drawLine(x1, y1, x2, y2)
    -- Simple line drawing using Bresenham's algorithm (simplified)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local x, y = x1, y1
    local n = 1 + dx + dy
    local x_inc = (x2 > x1) and 1 or -1
    local y_inc = (y2 > y1) and 1 or -1
    local error = dx - dy
    
    dx = dx * 2
    dy = dy * 2
    
    for _ = 1, n do
        term.setCursorPos(x, y)
        term.write("-")
        
        if error > 0 then
            x = x + x_inc
            error = error - dy
        else
            y = y + y_inc
            error = error + dx
        end
    end
end

-- Spacer Widget
local Spacer = setmetatable({}, {__index = Widget})
Spacer.__index = Spacer

function Spacer:new(props)
    local spacer = Widget.new(self, props)
    -- Spacer is invisible, just takes up space
    return spacer
end

function Spacer:render()
    -- Spacer renders nothing
end

-- ScrollBar Widget
local ScrollBar = setmetatable({}, {__index = Widget})
ScrollBar.__index = ScrollBar

function ScrollBar:new(props)
    local scrollbar = Widget.new(self, props)
    scrollbar.orientation = props.orientation or "vertical" -- "vertical" or "horizontal"
    scrollbar.min = props.min or 0
    scrollbar.max = props.max or 100
    scrollbar.value = props.value or 0
    scrollbar.step = props.step or 1
    scrollbar.pageSize = props.pageSize or 10
    scrollbar.onChange = props.onChange
    scrollbar.thumbSize = math.max(1, math.floor((scrollbar.pageSize / (scrollbar.max - scrollbar.min + scrollbar.pageSize)) * (scrollbar.orientation == "vertical" and scrollbar.height or scrollbar.width)))
    scrollbar.isDragging = false
    scrollbar.dragOffset = 0
    
    -- Auto-size if not specified
    if scrollbar.orientation == "vertical" then
        if not props.width then scrollbar.width = 1 end
        if not props.height then scrollbar.height = 10 end
    else
        if not props.width then scrollbar.width = 10 end
        if not props.height then scrollbar.height = 1 end
    end
    
    return scrollbar
end

function ScrollBar:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    if self.orientation == "vertical" then
        -- Draw track
        term.setBackgroundColor(theme.scrollbar.track)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(" ")
        end
        
        -- Calculate thumb position
        local trackSize = self.height
        local thumbPos = math.floor((self.value - self.min) / (self.max - self.min) * (trackSize - self.thumbSize))
        thumbPos = math.max(0, math.min(trackSize - self.thumbSize, thumbPos))
        
        -- Draw thumb
        term.setBackgroundColor(theme.scrollbar.thumb)
        for i = 0, self.thumbSize - 1 do
            term.setCursorPos(absX, absY + thumbPos + i)
            term.write(" ")
        end
    else
        -- Horizontal scrollbar
        term.setBackgroundColor(theme.scrollbar.track)
        term.setCursorPos(absX, absY)
        term.write(string.rep(" ", self.width))
        
        -- Calculate thumb position
        local trackSize = self.width
        local thumbPos = math.floor((self.value - self.min) / (self.max - self.min) * (trackSize - self.thumbSize))
        thumbPos = math.max(0, math.min(trackSize - self.thumbSize, thumbPos))
        
        -- Draw thumb
        term.setBackgroundColor(theme.scrollbar.thumb)
        term.setCursorPos(absX + thumbPos, absY)
        term.write(string.rep(" ", self.thumbSize))
    end
    
    term.setBackgroundColor(colors.black)
end

function ScrollBar:onClick(relX, relY)
    if not self.enabled then return end
    
    local trackSize = self.orientation == "vertical" and self.height or self.width
    local clickPos = self.orientation == "vertical" and relY or relX
    
    -- Calculate thumb position
    local thumbPos = math.floor((self.value - self.min) / (self.max - self.min) * (trackSize - self.thumbSize))
    
    if clickPos >= thumbPos + 1 and clickPos <= thumbPos + self.thumbSize then
        -- Start dragging thumb
        self.isDragging = true
        self.dragOffset = clickPos - thumbPos - 1
        isDragging = true
        draggedWidget = self
    else
        -- Jump to position
        local newThumbPos = clickPos - math.floor(self.thumbSize / 2)
        local newValue = self.min + (newThumbPos / (trackSize - self.thumbSize)) * (self.max - self.min)
        self.value = math.max(self.min, math.min(self.max, newValue))
        if self.onChange then
            self:onChange(self.value)
        end
    end
end

function ScrollBar:handleDrag(x, y)
    if not self.enabled or not self.isDragging then return end
    
    local absX, absY = self:getAbsolutePos()
    local relPos = (self.orientation == "vertical" and (y - absY + 1) or (x - absX + 1)) - self.dragOffset
    local trackSize = self.orientation == "vertical" and self.height or self.width
    
    local newValue = self.min + (relPos / (trackSize - self.thumbSize)) * (self.max - self.min)
    self.value = math.max(self.min, math.min(self.max, newValue))
    
    if self.onChange then
        self:onChange(self.value)
    end
end

function ScrollBar:scroll(delta)
    self.value = math.max(self.min, math.min(self.max, self.value + delta * self.step))
    if self.onChange then
        self:onChange(self.value)
    end
end

-- ContextMenu Widget
local ContextMenu = setmetatable({}, {__index = Widget})
ContextMenu.__index = ContextMenu

function ContextMenu:new(props)
    local contextmenu = Widget.new(self, props)
    contextmenu.items = props.items or {}
    contextmenu.visible = false
    contextmenu.onClose = props.onClose
    contextmenu.targetWidget = props.targetWidget
    
    -- Auto-size based on content
    local maxWidth = 0
    for _, item in ipairs(contextmenu.items) do
        if item.text then
            maxWidth = math.max(maxWidth, #item.text + 2) -- +2 for padding
        end
    end
    
    contextmenu.width = props.width or math.max(10, maxWidth)
    contextmenu.height = props.height or (#contextmenu.items + 2) -- +2 for borders
    
    return contextmenu
end

function ContextMenu:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Draw background
    term.setBackgroundColor(theme.contextMenu.background)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw character-based border
    drawCharBorder(absX, absY, self.width, self.height, theme.contextMenu.border, theme.contextMenu.background)
    
    -- Draw menu items
    for i, item in ipairs(self.items) do
        local itemY = absY + i
        term.setCursorPos(absX + 1, itemY)
        
        if item.separator then
            -- Draw separator
            term.setTextColor(theme.contextMenu.border)
            term.write(string.rep("-", self.width - 2))
        else
            -- Draw menu item
            local isHovered = self.hoveredIndex == i
            term.setBackgroundColor(isHovered and theme.contextMenu.hover or theme.contextMenu.background)
            term.setTextColor(isHovered and theme.contextMenu.hoverText or theme.contextMenu.text)
            
            local text = item.text or ""
            if item.enabled == false then
                term.setTextColor(theme.textSecondary)
            end
            
            local displayText = text:sub(1, self.width - 2)
            term.write(displayText .. string.rep(" ", self.width - 2 - #displayText))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function ContextMenu:show(x, y)
    -- Ensure the menu fits on screen
    local termWidth, termHeight = term.getSize()
    
    self.x = math.min(x, termWidth - self.width + 1)
    self.y = math.min(y, termHeight - self.height + 1)
    self.visible = true
    self.hoveredIndex = nil
    
    -- Add to widgets list temporarily
    table.insert(widgets, self)
end

function ContextMenu:hide()
    self.visible = false
    
    -- Remove from widgets list
    for i, widget in ipairs(widgets) do
        if widget == self then
            table.remove(widgets, i)
            break
        end
    end
    
    if self.onClose then
        self:onClose()
    end
end

function ContextMenu:onClick(relX, relY)
    if not self.visible then return false end
    
    -- Check if click is within menu
    if relX >= 1 and relX <= self.width and relY >= 1 and relY <= self.height then
        local itemIndex = relY - 1 -- Adjust for border
        if itemIndex >= 1 and itemIndex <= #self.items then
            local item = self.items[itemIndex]
            if item and not item.separator and item.enabled ~= false then
                if item.onClick then
                    item:onClick()
                end
                self:hide()
            end
        end
        return true
    else
        -- Click outside menu - close it
        self:hide()
        return false
    end
end

function ContextMenu:handleMouseMove(relX, relY)
    if not self.visible then return end
    
    if relX >= 2 and relX < self.width and relY >= 2 and relY < self.height then
        local itemIndex = relY - 1
        if itemIndex >= 1 and itemIndex <= #self.items then
            local item = self.items[itemIndex]
            if item and not item.separator and item.enabled ~= false then
                self.hoveredIndex = itemIndex
            else
                self.hoveredIndex = nil
            end
        end
    else
        self.hoveredIndex = nil
    end
end

-- GroupBox Widget
local GroupBox = setmetatable({}, {__index = Widget})
GroupBox.__index = GroupBox

function GroupBox:new(props)
    local groupbox = Widget.new(self, props)
    groupbox.title = props.title or props.text or ""
    groupbox.titleColor = props.titleColor or colors.white
    groupbox.background = props.background
    groupbox.border = props.border ~= false
    groupbox.borderColor = props.borderColor or colors.lightGray
    
    return groupbox
end

function GroupBox:render()
    local absX, absY = self:getAbsolutePos()
    
    if self.background then
        term.setBackgroundColor(self.background)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(string.rep(" ", self.width))
        end
    end
    
    if self.border then
        -- Draw character-based border
        drawCharBorder(absX, absY, self.width, self.height, self.borderColor, self.background or colors.black)
        
        -- Draw title on top of the border
        if #self.title > 0 then
            term.setCursorPos(absX + 2, absY)
            term.setTextColor(self.titleColor)
            term.setBackgroundColor(self.background or colors.black)
            term.write(" " .. self.title .. " ")
        end
    end
    
    term.setBackgroundColor(colors.black)
end

-- PasswordBox Widget
local PasswordBox = setmetatable({}, {__index = TextBox})
PasswordBox.__index = PasswordBox

function PasswordBox:new(props)
    local passwordbox = TextBox.new(self, props)
    passwordbox.maskChar = props.maskChar or "*"
    return passwordbox
end

function PasswordBox:render()
    -- Temporarily replace text with mask characters
    local originalText = self.text
    self.text = string.rep(self.maskChar, #originalText)
    
    -- Call parent render
    TextBox.render(self)
    
    -- Restore original text
    self.text = originalText
end

-- NumericUpDown Widget
local NumericUpDown = setmetatable({}, {__index = Widget})
NumericUpDown.__index = NumericUpDown

function NumericUpDown:new(props)
    local numericupdown = Widget.new(self, props)
    numericupdown.value = props.value or 0
    numericupdown.min = props.min or -math.huge
    numericupdown.max = props.max or math.huge
    numericupdown.step = props.step or 1
    numericupdown.color = props.color or colors.white
    numericupdown.background = props.background or colors.black
    numericupdown.onChange = props.onChange
    
    if not props.width then
        numericupdown.width = 10
    end
    if not props.height then
        numericupdown.height = 1
    end
    
    return numericupdown
end

function NumericUpDown:render()
    local absX, absY = self:getAbsolutePos()
    
    term.setBackgroundColor(self.background)
    term.setTextColor(self.color)
    term.setCursorPos(absX, absY)
    
    local valueStr = tostring(self.value)
    local displayWidth = self.width - 2
    term.write(valueStr:sub(1, displayWidth) .. string.rep(" ", displayWidth - #valueStr))
    
    -- Draw up/down buttons
    term.setBackgroundColor(colors.gray)
    term.write("^v")
    
    term.setBackgroundColor(colors.black)
end

function NumericUpDown:onClick(relX, relY)
    if self.enabled then
        if relX == self.width - 1 then -- Up button
            self.value = math.min(self.max, self.value + self.step)
            if self.onChange then self:onChange(self.value) end
        elseif relX == self.width then -- Down button
            self.value = math.max(self.min, self.value - self.step)
            if self.onChange then self:onChange(self.value) end
        end
    end
end

-- Modal Widget
local Modal = setmetatable({}, {__index = Widget})
Modal.__index = Modal

function Modal:new(props)
    local modal = Widget.new(self, props)
    modal.content = props.content
    modal.background = props.background or colors.lightGray
    modal.onClose = props.onClose
    modal.visible = props.visible ~= false
    
    -- Center the modal
    local termWidth, termHeight = term.getSize()
    modal.x = math.floor((termWidth - modal.width) / 2) + 1
    modal.y = math.floor((termHeight - modal.height) / 2) + 1
    
    return modal
end

function Modal:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Draw modal background
    term.setBackgroundColor(self.background)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw character-based border
    drawCharBorder(absX, absY, self.width, self.height, colors.black, self.background)
    
    -- Draw content
    if self.content then
        self.content.x = 2
        self.content.y = 2
        self.content:draw()
    end
    
    -- Draw children (for ColorPickerDialog compatibility)
    for _, child in ipairs(self.children or {}) do
        if child.draw then
            child:draw()
        elseif child.render then
            child:render()
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Modal:close()
    self.visible = false
    if self.onClose then
        self:onClose()
    end
end

-- Window Widget
local Window = setmetatable({}, {__index = Widget})
Window.__index = Window

function Window:new(props)
    local window = Widget.new(self, props)
    window.title = props.title or "Window"
    window.content = props.content
    window.draggable = props.draggable ~= false
    window.resizable = props.resizable or false
    window.onClose = props.onClose
    window.isDragging = false
    window.dragOffsetX = 0
    window.dragOffsetY = 0
    
    return window
end

function Window:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Draw title bar
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(absX, absY)
    local titleText = " " .. self.title .. string.rep(" ", self.width - #self.title - 3) .. "X"
    term.write(titleText)
    
    -- Draw window content area
    term.setBackgroundColor(colors.lightGray)
    for i = 1, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw content
    if self.content then
        self.content.x = 1
        self.content.y = 2
        self.content:draw()
    end
    
    term.setBackgroundColor(colors.black)
end

function Window:onClick(relX, relY)
    if relY == 1 then -- Title bar clicked
        if relX == self.width then -- Close button
            if self.onClose then
                self:onClose()
            end
        elseif self.draggable then -- Start dragging
            self.isDragging = true
            self.dragOffsetX = relX
            self.dragOffsetY = relY
        end
    end
end

-- Breadcrumb Widget
local Breadcrumb = setmetatable({}, {__index = Widget})
Breadcrumb.__index = Breadcrumb

function Breadcrumb:new(props)
    local breadcrumb = Widget.new(self, props)
    breadcrumb.items = props.items or {}
    breadcrumb.color = props.color or colors.white
    breadcrumb.separator = props.separator or " > "
    
    if not props.height then
        breadcrumb.height = 1
    end
    
    return breadcrumb
end

function Breadcrumb:render()
    local absX, absY = self:getAbsolutePos()
    
    term.setTextColor(self.color)
    term.setCursorPos(absX, absY)
    
    local text = ""
    for i, item in ipairs(self.items) do
        if i > 1 then
            text = text .. self.separator
        end
        text = text .. item.text
    end
    
    text = text:sub(1, self.width)
    term.write(text .. string.rep(" ", self.width - #text))
    
    term.setBackgroundColor(colors.black)
end

function Breadcrumb:onClick(relX, relY)
    if self.enabled then
        -- Calculate which breadcrumb item was clicked
        local currentX = 1
        for i, item in ipairs(self.items) do
            local itemWidth = #item.text
            if relX >= currentX and relX < currentX + itemWidth then
                if item.onClick then
                    item:onClick()
                end
                break
            end
            currentX = currentX + itemWidth + #self.separator
        end
    end
end

-- TreeView Widget
local TreeView = setmetatable({}, {__index = Widget})
TreeView.__index = TreeView

function TreeView:new(props)
    local treeview = Widget.new(self, props)
    treeview.items = props.items or {}
    treeview.selectedItem = nil
    treeview.color = props.color or colors.white
    treeview.onExpand = props.onExpand
    treeview.onCollapse = props.onCollapse
    treeview.onSelect = props.onSelect
    treeview.scrollOffset = 0
    
    return treeview
end

function TreeView:render()
    local absX, absY = self:getAbsolutePos()
    
    local function renderNode(node, depth, y)
        if y > self.height then return y end
        if y <= self.scrollOffset then return y + 1 end
        
        local displayY = absY + y - self.scrollOffset - 1
        if displayY >= absY and displayY < absY + self.height then
            term.setCursorPos(absX, displayY)
            
            local indent = string.rep("  ", depth)
            local expandChar = ""
            if node.children and #node.children > 0 then
                expandChar = node.expanded and "- " or "+ "
            else
                expandChar = "  "
            end
            
            local isSelected = self.selectedItem == node
            term.setBackgroundColor(isSelected and colors.blue or colors.black)
            term.setTextColor(isSelected and colors.white or self.color)
            
            local text = indent .. expandChar .. node.text
            text = text:sub(1, self.width)
            term.write(text .. string.rep(" ", self.width - #text))
        end
        
        y = y + 1
        
        if node.expanded and node.children then
            for _, child in ipairs(node.children) do
                y = renderNode(child, depth + 1, y)
            end
        end
        
        return y
    end
    
    local y = 1
    for _, item in ipairs(self.items) do
        y = renderNode(item, 0, y)
    end
    
    term.setBackgroundColor(colors.black)
end

function TreeView:onClick(relX, relY)
    if not self.enabled then return end
    
    local function countNodesBeforeY(items, depth, targetY)
        local currentY = 1
        
        local function traverse(nodes, currentDepth)
            for _, node in ipairs(nodes) do
                if currentY == targetY then
                    -- Check if expand/collapse button was clicked
                    local buttonX = currentDepth * 2 + 1
                    if relX >= buttonX and relX < buttonX + 2 and node.children and #node.children > 0 then
                        node.expanded = not node.expanded
                        if node.expanded and self.onExpand then
                            self:onExpand(node)
                        elseif not node.expanded and self.onCollapse then
                            self:onCollapse(node)
                        end
                    else
                        self.selectedItem = node
                        if self.onSelect then
                            self:onSelect(node)
                        end
                    end
                    return true
                end
                
                currentY = currentY + 1
                
                if node.expanded and node.children then
                    if traverse(node.children, currentDepth + 1) then
                        return true
                    end
                end
            end
            return false
        end
        
        return traverse(items, depth)
    end
    
    countNodesBeforeY(self.items, 0, relY + self.scrollOffset)
end

-- ColorPicker Widget
local ColorPicker = setmetatable({}, {__index = Widget})
ColorPicker.__index = ColorPicker

function ColorPicker:new(props)
    local colorpicker = Widget.new(self, props)
    colorpicker.selectedColor = props.selectedColor or colors.white
    colorpicker.colors = props.colors or {
        colors.white, colors.orange, colors.magenta, colors.lightBlue,
        colors.yellow, colors.lime, colors.pink, colors.gray,
        colors.lightGray, colors.cyan, colors.purple, colors.blue,
        colors.brown, colors.green, colors.red, colors.black
    }
    colorpicker.colorNames = props.colorNames or {
        "White", "Orange", "Magenta", "Light Blue",
        "Yellow", "Lime", "Pink", "Gray",
        "Light Gray", "Cyan", "Purple", "Blue",
        "Brown", "Green", "Red", "Black"
    }
    colorpicker.onChange = props.onChange
    colorpicker.showPreview = props.showPreview ~= false
    colorpicker.showName = props.showName ~= false
    colorpicker.gridColumns = props.gridColumns or 4
    colorpicker.colorSize = props.colorSize or 2
    colorpicker.hoveredIndex = nil
    colorpicker.selectedIndex = 1
    
    -- Find initial selected index
    for i, color in ipairs(colorpicker.colors) do
        if color == colorpicker.selectedColor then
            colorpicker.selectedIndex = i
            break
        end
    end
    
    -- Auto-size if not specified
    if not props.width then
        colorpicker.width = colorpicker.gridColumns * (colorpicker.colorSize + 1) - 1
    end
    if not props.height then
        local rows = math.ceil(#colorpicker.colors / colorpicker.gridColumns)
        colorpicker.height = rows * (colorpicker.colorSize + 1) - 1
        if colorpicker.showPreview then
            colorpicker.height = colorpicker.height + 3
        end
        if colorpicker.showName then
            colorpicker.height = colorpicker.height + 1
        end
    end
    
    return colorpicker
end

function ColorPicker:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Draw color grid
    local gridRows = math.ceil(#self.colors / self.gridColumns)
    local startY = absY
    
    for row = 1, gridRows do
        for col = 1, self.gridColumns do
            local index = (row - 1) * self.gridColumns + col
            if index <= #self.colors then
                local color = self.colors[index]
                local isSelected = index == self.selectedIndex
                local isHovered = index == self.hoveredIndex
                local colorX = absX + (col - 1) * (self.colorSize + 1)
                local colorY = startY + (row - 1) * (self.colorSize + 1)
                
                -- Draw color swatch
                term.setBackgroundColor(color)
                for dy = 0, self.colorSize - 1 do
                    term.setCursorPos(colorX, colorY + dy)
                    term.write(string.rep(" ", self.colorSize))
                end
                
                -- Draw selection border
                if isSelected then
                    term.setBackgroundColor(colors.white)
                    term.setTextColor(colors.black)
                    term.setCursorPos(colorX, colorY)
                    term.write("[")
                    term.setCursorPos(colorX + self.colorSize - 1, colorY)
                    term.write("]")
                end
            end
        end
    end
    
    -- Draw preview if enabled
    if self.showPreview then
        local previewY = startY + gridRows * (self.colorSize + 1)
        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.setCursorPos(absX, previewY)
        term.write("Preview:")
        
        term.setBackgroundColor(self.selectedColor)
        term.setCursorPos(absX + 9, previewY)
        term.write(string.rep(" ", 6))
        
        term.setCursorPos(absX + 9, previewY + 1)
        term.write(string.rep(" ", 6))
    end
    
    -- Draw color name if enabled
    if self.showName then
        local nameY = absY + self.height - 1
        term.setBackgroundColor(theme.background)
        term.setTextColor(theme.text)
        term.setCursorPos(absX, nameY)
        local colorName = self.colorNames[self.selectedIndex] or "Unknown"
        term.write(colorName .. string.rep(" ", self.width - #colorName))
    end
    
    term.setBackgroundColor(colors.black)
end

function ColorPicker:onClick(relX, relY)
    if not self.enabled then return end
    
    local gridRows = math.ceil(#self.colors / self.gridColumns)
    local gridHeight = gridRows * (self.colorSize + 1) - 1
    
    -- Check if click is in the color grid area
    if relY <= gridHeight then
        local col = math.floor((relX - 1) / (self.colorSize + 1)) + 1
        local row = math.floor((relY - 1) / (self.colorSize + 1)) + 1
        local index = (row - 1) * self.gridColumns + col
        
        if index >= 1 and index <= #self.colors and col >= 1 and col <= self.gridColumns then
            self.selectedIndex = index
            self.selectedColor = self.colors[index]
            if self.onChange then
                self:onChange(self.selectedColor, index, self.colorNames[index])
            end
        end
    end
end

function ColorPicker:handleMouseMove(x, y)
    if not self.enabled then return end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    local gridRows = math.ceil(#self.colors / self.gridColumns)
    local gridHeight = gridRows * (self.colorSize + 1) - 1
    
    -- Check if hover is in the color grid area
    if relX >= 1 and relX <= self.width and relY >= 1 and relY <= gridHeight then
        local col = math.floor((relX - 1) / (self.colorSize + 1)) + 1
        local row = math.floor((relY - 1) / (self.colorSize + 1)) + 1
        local index = (row - 1) * self.gridColumns + col
        
        if index >= 1 and index <= #self.colors and col >= 1 and col <= self.gridColumns then
            self.hoveredIndex = index
        else
            self.hoveredIndex = nil
        end
    else
        self.hoveredIndex = nil
    end
end

-- ColorPickerDialog Widget (Modal Color Picker)
local ColorPickerDialog = setmetatable({}, {__index = Widget})
ColorPickerDialog.__index = ColorPickerDialog

function ColorPickerDialog:new(props)
    local dialog = Widget.new(self, props)
    dialog.title = props.title or "Select Color"
    dialog.selectedColor = props.selectedColor or colors.white
    dialog.onColorSelected = props.onColorSelected
    dialog.onCancel = props.onCancel
    dialog.visible = false
    dialog.modal = nil
    dialog.colorPicker = nil
    dialog.previewColor = dialog.selectedColor
    dialog.border = props.border ~= false  -- Border enabled by default, can be disabled
    
    -- Dialog dimensions - wider to accommodate more columns, shorter height
    dialog.width = 36
    dialog.height = 16  -- Increased height to accommodate better spacing
    
    return dialog
end

function ColorPickerDialog:show()
    self.visible = true
    self.previewColor = self.selectedColor
    
    -- Create modal background
    local termWidth, termHeight = term.getSize()
    self.modal = Modal:new({
        width = self.width,
        height = self.height,
        background = colors.lightGray,
        border = self.border,  -- Use the border property
        onClose = function()
            self:hide()
        end
    })
    
    -- Create title label
    local titleLabel = Label:new({
        x = 2, y = 2,
        text = self.title,
        color = colors.black,
        background = colors.lightGray,  -- Explicitly set background
        align = "center",
        width = self.width - 2
    })
    
    -- Create color picker
    self.colorPicker = ColorPicker:new({
        x = 2, y = 4,
        selectedColor = self.selectedColor,
        gridColumns = 8,  -- More columns to spread horizontally
        colorSize = 2,
        showPreview = false,
        showName = false,
        onChange = function(colorpicker, color, index, name)
            self.previewColor = color
            -- Update preview swatch color
            if self.previewSwatch then
                self.previewSwatch.background = color
            end
        end
    })
    
    -- Create preview area
    local previewLabel = Label:new({
        x = 2, y = 10,  -- Moved further down to avoid overlap with color grid
        text = "Preview:",
        color = colors.black,
        background = colors.lightGray,  -- Explicitly set background
        width = 8
    })
    
    -- Create a larger preview swatch
    local previewSwatch = Label:new({
        x = 11, y = 10,  -- Moved down to match preview label
        text = "      ",  -- 6 spaces for preview color
        color = colors.white,
        background = self.previewColor,
        width = 6
    })
    
    -- Create color name display
    local colorNames = {
        [colors.white] = "White", [colors.orange] = "Orange", [colors.magenta] = "Magenta",
        [colors.lightBlue] = "Light Blue", [colors.yellow] = "Yellow", [colors.lime] = "Lime",
        [colors.pink] = "Pink", [colors.gray] = "Gray", [colors.lightGray] = "Light Gray",
        [colors.cyan] = "Cyan", [colors.purple] = "Purple", [colors.blue] = "Blue",
        [colors.brown] = "Brown", [colors.green] = "Green", [colors.red] = "Red",
        [colors.black] = "Black"
    }
    
    local nameLabel = Label:new({
        x = 2, y = 12,  -- Moved down to provide more space
        text = ("Current: " .. (colorNames[self.previewColor] or "Unknown")),
        color = colors.black,
        background = colors.lightGray,  -- Explicitly set background
        width = self.width - 2
    })
    
    -- Create buttons
    local okButton = Button:new({
        x = 2, y = 14,  -- Moved down to accommodate new spacing
        text = "OK",
        width = 6,
        height = 1,
        background = colors.green,
        color = colors.white,
        onClick = function()
            self.selectedColor = self.previewColor
            if self.onColorSelected then
                self.onColorSelected(self.selectedColor)
            end
            self:hide()
        end
    })
    
    local cancelButton = Button:new({
        x = 10, y = 14,  -- Moved down to accommodate new spacing
        text = "Cancel",
        width = 8,
        height = 1,
        background = colors.red,
        color = colors.white,
        onClick = function()
            if self.onCancel then
                self.onCancel()
            end
            self:hide()
        end
    })
    
    local resetButton = Button:new({
        x = 20, y = 14,  -- Moved down to accommodate new spacing
        text = "Reset",
        width = 8,
        height = 1,
        background = colors.orange,
        color = colors.white,
        onClick = function()
            self.previewColor = colors.white
            self.colorPicker.selectedColor = colors.white
            self.colorPicker.selectedIndex = 1
            nameLabel.text = "White"
            -- Update preview swatch
            if previewSwatch then
                previewSwatch.background = colors.white
            end
        end
    })
    
    -- Add all widgets to modal
    self.modal:addChild(titleLabel)
    self.modal:addChild(self.colorPicker)
    self.modal:addChild(previewLabel)
    self.modal:addChild(previewSwatch)
    self.modal:addChild(nameLabel)
    self.modal:addChild(okButton)
    self.modal:addChild(cancelButton)
    self.modal:addChild(resetButton)
    
    -- Add modal to widgets list
    table.insert(widgets, self.modal)
    
    -- Store references for updates
    self.nameLabel = nameLabel
    self.previewSwatch = previewSwatch
end

function ColorPickerDialog:hide()
    self.visible = false
    if self.modal then
        -- Remove modal from widgets list
        for i, widget in ipairs(widgets) do
            if widget == self.modal then
                table.remove(widgets, i)
                break
            end
        end
        self.modal = nil
    end
end

function ColorPickerDialog:render()
    if not self.visible or not self.modal then return end
    
    -- Update preview area and color name
    if self.nameLabel then
        local colorNames = {
            [colors.white] = "White", [colors.orange] = "Orange", [colors.magenta] = "Magenta",
            [colors.lightBlue] = "Light Blue", [colors.yellow] = "Yellow", [colors.lime] = "Lime",
            [colors.pink] = "Pink", [colors.gray] = "Gray", [colors.lightGray] = "Light Gray",
            [colors.cyan] = "Cyan", [colors.purple] = "Purple", [colors.blue] = "Blue",
            [colors.brown] = "Brown", [colors.green] = "Green", [colors.red] = "Red",
            [colors.black] = "Black"
        }
        self.nameLabel.text = colorNames[self.previewColor] or "Unknown"
    end
    
    -- Update preview swatch color
    if self.previewSwatch then
        self.previewSwatch.background = self.previewColor
    end
    
    -- Draw preview color swatch (legacy method, now handled by previewSwatch widget)
    if self.modal then
        term.setBackgroundColor(colors.black)
    end
end

-- LoadingIndicator Widget (Simple Loading Bar)
local LoadingIndicator = setmetatable({}, {__index = Widget})
LoadingIndicator.__index = LoadingIndicator

function LoadingIndicator:new(props)
    local loading = Widget.new(self, props)
    loading.progress = props.progress or 0  -- 0-100
    loading.style = props.style or "bar"  -- "bar", "dots", "pulse"
    loading.color = props.color or colors.cyan
    loading.background = props.background or colors.gray
    loading.text = props.text or ""
    loading.showPercent = props.showPercent ~= false
    loading.animated = props.animated ~= false
    loading.animationFrame = 0
    loading.animationSpeed = props.animationSpeed or 10  -- frames per second
    loading.lastUpdate = os.epoch("utc")
    
    if not props.width then
        loading.width = 20
    end
    if not props.height then
        loading.height = 1
    end
    
    return loading
end

function LoadingIndicator:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Update animation if enabled
    if self.animated then
        local now = os.epoch("utc")
        if now - self.lastUpdate > (1000 / self.animationSpeed) then
            self.animationFrame = (self.animationFrame + 1) % 20
            self.lastUpdate = now
        end
    end
    
    if self.style == "bar" then
        self:renderBar(absX, absY)
    elseif self.style == "dots" then
        self:renderDots(absX, absY)
    elseif self.style == "pulse" then
        self:renderPulse(absX, absY)
    end
    
    -- Draw text if provided
    if #self.text > 0 then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(absX, absY + 1)
        term.write(self.text)
    end
    
    -- Draw percentage if enabled
    if self.showPercent then
        local percentText = string.format("%.0f%%", self.progress)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.setCursorPos(absX + self.width + 2, absY)
        term.write(percentText)
    end
    
    term.setBackgroundColor(colors.black)
end

function LoadingIndicator:renderBar(absX, absY)
    -- Draw background
    term.setBackgroundColor(self.background)
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    -- Draw progress fill
    local fillWidth = math.floor((self.progress / 100) * self.width)
    if fillWidth > 0 then
        term.setBackgroundColor(self.color)
        term.setCursorPos(absX, absY)
        term.write(string.rep(" ", fillWidth))
    end
    
    -- Add animated shimmer effect if animated
    if self.animated and fillWidth > 2 then
        local shimmerPos = (self.animationFrame % (fillWidth * 2)) - fillWidth
        if shimmerPos >= 0 and shimmerPos < fillWidth then
            term.setBackgroundColor(colors.white)
            term.setCursorPos(absX + shimmerPos, absY)
            term.write(" ")
        end
    end
end

function LoadingIndicator:renderDots(absX, absY)
    local dots = {".", "o", "O", "o"}
    local numDots = math.min(self.width, 10)
    
    term.setBackgroundColor(colors.black)
    term.setCursorPos(absX, absY)
    
    for i = 1, numDots do
        local dotIndex = ((self.animationFrame + i) % #dots) + 1
        local dot = dots[dotIndex]
        
        -- Color based on progress
        local dotProgress = (i - 1) / (numDots - 1) * 100
        if dotProgress <= self.progress then
            term.setTextColor(self.color)
        else
            term.setTextColor(self.background)
        end
        
        term.write(dot .. " ")
    end
end

function LoadingIndicator:renderPulse(absX, absY)
    local pulseChar = "O"
    local pulseSize = math.floor(math.sin(self.animationFrame * 0.3) * 3) + 4
    
    term.setBackgroundColor(colors.black)
    term.setCursorPos(absX, absY)
    
    -- Center the pulse
    local startPos = math.floor((self.width - pulseSize) / 2)
    
    for i = 1, self.width do
        if i >= startPos and i < startPos + pulseSize then
            local intensity = 1 - math.abs(i - (startPos + pulseSize / 2)) / (pulseSize / 2)
            if intensity > 0.5 then
                term.setTextColor(self.color)
            else
                term.setTextColor(self.background)
            end
            term.write(pulseChar)
        else
            term.write(" ")
        end
    end
end

function LoadingIndicator:setProgress(progress)
    self.progress = math.max(0, math.min(100, progress))
end

-- Spinner Widget (Advanced Loading Spinner)
local Spinner = setmetatable({}, {__index = Widget})
Spinner.__index = Spinner

function Spinner:new(props)
    local spinner = Widget.new(self, props)
    spinner.style = props.style or "classic"  -- "classic", "dots", "arrow", "clock", "bar"
    spinner.color = props.color or colors.cyan
    spinner.speed = props.speed or 8  -- frames per second
    spinner.text = props.text or ""
    spinner.textPosition = props.textPosition or "right"  -- "right", "bottom", "left", "top"
    spinner.frame = 0
    spinner.lastUpdate = os.epoch("utc")
    spinner.active = props.active ~= false
    
    if not props.width then
        spinner.width = spinner.style == "bar" and 10 or 3
    end
    if not props.height then
        spinner.height = (#spinner.text > 0 and spinner.textPosition == "bottom") and 2 or 1
    end
    
    return spinner
end

function Spinner:render()
    if not self.active then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Update animation frame
    local now = os.epoch("utc")
    if now - self.lastUpdate > (1000 / self.speed) then
        self.frame = self.frame + 1
        self.lastUpdate = now
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(self.color)
    
    if self.style == "classic" then
        self:renderClassic(absX, absY)
    elseif self.style == "dots" then
        self:renderDots(absX, absY)
    elseif self.style == "arrow" then
        self:renderArrow(absX, absY)
    elseif self.style == "clock" then
        self:renderClock(absX, absY)
    elseif self.style == "bar" then
        self:renderBar(absX, absY)
    end
    
    -- Draw text if provided
    if #self.text > 0 then
        term.setTextColor(colors.white)
        
        if self.textPosition == "right" then
            term.setCursorPos(absX + self.width + 1, absY)
        elseif self.textPosition == "bottom" then
            term.setCursorPos(absX, absY + 1)
        elseif self.textPosition == "left" then
            term.setCursorPos(absX - #self.text - 1, absY)
        elseif self.textPosition == "top" then
            term.setCursorPos(absX, absY - 1)
        end
        
        term.write(self.text)
    end
    
    term.setBackgroundColor(colors.black)
end

function Spinner:renderClassic(absX, absY)
    local chars = {"|", "/", "-", "\\"}
    local char = chars[(self.frame % #chars) + 1]
    
    term.setCursorPos(absX, absY)
    term.write(char)
end

function Spinner:renderDots(absX, absY)
    local patterns = {"   ", ".  ", ".. ", "...", " ..", "  .", "   "}
    local pattern = patterns[(self.frame % #patterns) + 1]
    
    term.setCursorPos(absX, absY)
    term.write(pattern)
end

function Spinner:renderArrow(absX, absY)
    local arrows = {">  ", ">> ", ">>>", " >>", "  >", "   "}
    local arrow = arrows[(self.frame % #arrows) + 1]
    
    term.setCursorPos(absX, absY)
    term.write(arrow)
end

function Spinner:renderClock(absX, absY)
    local clocks = {"12", "1 ", "3 ", "6 ", "9 "}
    local clock = clocks[(self.frame % #clocks) + 1]
    
    term.setCursorPos(absX, absY)
    term.write("[" .. clock .. "]")
end

function Spinner:renderBar(absX, absY)
    local barChars = {"[=    ]", "[==   ]", "[===  ]", "[==== ]", "[=====]", "[====]", "[===]", "[==]", "[=]", "[    ]"}
    local bar = barChars[(self.frame % #barChars) + 1]
    
    term.setCursorPos(absX, absY)
    term.write(bar)
end

function Spinner:start()
    self.active = true
    self.frame = 0
    self.lastUpdate = os.epoch("utc")
end

function Spinner:stop()
    self.active = false
end

-- MsgBox Widget (Message Box Dialog)
local MsgBox = setmetatable({}, {__index = Widget})
MsgBox.__index = MsgBox

function MsgBox:new(props)
    local msgbox = Widget.new(self, props)
    msgbox.title = props.title or "Message"
    msgbox.message = props.message or ""
    msgbox.buttons = props.buttons or {"OK"}
    msgbox.icon = props.icon or "info" -- "info", "warning", "error", "question"
    msgbox.color = props.color or colors.white
    msgbox.background = props.background or colors.lightGray
    msgbox.titleColor = props.titleColor or colors.black
    msgbox.buttonColor = props.buttonColor or colors.white
    msgbox.buttonBackground = props.buttonBackground or colors.blue
    msgbox.onClose = props.onClose
    msgbox.onButton = props.onButton
    msgbox.visible = props.visible ~= false
    msgbox.result = nil
    msgbox.selectedButton = 1
    
    -- Auto-size if not specified
    if not props.width then
        local termWidth, termHeight = term.getSize()
        local maxWidth = termWidth - 2  -- Maximum width is screen width minus 2
        
        local minWidth = math.max(#msgbox.title + 4, 30)  -- Minimum reasonable width
        local buttonWidth = 0
        for _, button in ipairs(msgbox.buttons) do
            buttonWidth = buttonWidth + #button + 4  -- button text + padding + spacing
        end
        
        msgbox.width = math.min(maxWidth, math.max(minWidth, buttonWidth + 2))
    end
    if not props.height then
        -- Calculate the actual number of lines needed after word wrapping
        local maxLineWidth = msgbox.width - 3  -- Account for icon and padding
        local totalLines = 0
        
        -- Split message by explicit newlines first
        local paragraphs = {}
        for paragraph in msgbox.message:gmatch("[^\n]*") do
            if paragraph ~= "" then
                table.insert(paragraphs, paragraph)
            else
                table.insert(paragraphs, "")
            end
        end
        
        -- Count lines needed for each paragraph
        for _, paragraph in ipairs(paragraphs) do
            if paragraph == "" then
                totalLines = totalLines + 1  -- Empty line
            else
                -- Word wrap this paragraph and count lines
                local currentLine = ""
                local linesInParagraph = 0
                local words = {}
                for word in paragraph:gmatch("%S+") do
                    table.insert(words, word)
                end
                
                for _, word in ipairs(words) do
                    if #currentLine + #word + 1 <= maxLineWidth then
                        if #currentLine > 0 then
                            currentLine = currentLine .. " " .. word
                        else
                            currentLine = word
                        end
                    else
                        if #currentLine > 0 then
                            linesInParagraph = linesInParagraph + 1
                        end
                        currentLine = word
                    end
                end
                if #currentLine > 0 then
                    linesInParagraph = linesInParagraph + 1
                end
                
                totalLines = totalLines + math.max(1, linesInParagraph)
            end
        end
        
        msgbox.height = 7 + totalLines  -- title + border + message + buttons + spacing
    end
    
    -- Center the msgbox
    local termWidth, termHeight = term.getSize()
    msgbox.x = math.floor((termWidth - msgbox.width) / 2) + 1
    msgbox.y = math.floor((termHeight - msgbox.height) / 2) + 1
    
    return msgbox
end

function MsgBox:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Draw modal background
    term.setBackgroundColor(self.background)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw character-based border
    drawCharBorder(absX, absY, self.width, self.height, colors.black, self.background)
    
    -- Draw title bar
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(absX + 1, absY + 1)
    
    -- Word wrap title if needed
    local maxTitleWidth = self.width - 3  -- Account for padding and borders
    local titleText = self.title
    if #titleText > maxTitleWidth then
        titleText = titleText:sub(1, maxTitleWidth - 3) .. "..."  -- Truncate with ellipsis
    end
    titleText = " " .. titleText .. string.rep(" ", self.width - #titleText - 3)
    term.write(titleText)
    
    -- Draw icon and message
    term.setBackgroundColor(self.background)
    term.setTextColor(self.color)
    
    local iconChar = "i"
    local iconColor = colors.blue
    if self.icon == "warning" then
        iconChar = "!"
        iconColor = colors.orange
    elseif self.icon == "error" then
        iconChar = "X"
        iconColor = colors.red
    elseif self.icon == "question" then
        iconChar = "?"
        iconColor = colors.cyan
    end
    
    -- Draw icon
    term.setTextColor(iconColor)
    term.setCursorPos(absX + 2, absY + 3)
    term.write("[" .. iconChar .. "]")
    
    -- Draw message (word wrap)
    term.setTextColor(self.color)
    local messageLines = {}
    
    -- First, split message by explicit newlines
    local paragraphs = {}
    for paragraph in self.message:gmatch("[^\n]*") do
        if paragraph ~= "" then
            table.insert(paragraphs, paragraph)
        else
            -- Empty line represents a paragraph break
            table.insert(paragraphs, "")
        end
    end
    
    local maxLineWidth = self.width - 8  -- Account for icon and padding
    
    -- Process each paragraph for word wrapping
    for _, paragraph in ipairs(paragraphs) do
        if paragraph == "" then
            -- Empty paragraph creates a blank line
            table.insert(messageLines, "")
        else
            -- Word wrap this paragraph
            local currentLine = ""
            local words = {}
            for word in paragraph:gmatch("%S+") do
                table.insert(words, word)
            end
            
            for _, word in ipairs(words) do
                if #currentLine + #word + 1 <= maxLineWidth then
                    if #currentLine > 0 then
                        currentLine = currentLine .. " " .. word
                    else
                        currentLine = word
                    end
                else
                    if #currentLine > 0 then
                        table.insert(messageLines, currentLine)
                    end
                    currentLine = word
                end
            end
            if #currentLine > 0 then
                table.insert(messageLines, currentLine)
            end
        end
    end
    
    for i, line in ipairs(messageLines) do
        term.setCursorPos(absX + 6, absY + 2 + i)
        term.write(line)
    end
    
    -- Draw buttons
    local buttonY = absY + self.height - 3
    local totalButtonWidth = 0
    for _, button in ipairs(self.buttons) do
        totalButtonWidth = totalButtonWidth + #button + 4
    end
    
    local startX = absX + math.floor((self.width - totalButtonWidth) / 2)
    local currentX = startX
    
    for i, button in ipairs(self.buttons) do
        local isSelected = i == self.selectedButton
        local bgColor = isSelected and colors.white or self.buttonBackground
        local textColor = isSelected and colors.black or self.buttonColor
        
        term.setBackgroundColor(bgColor)
        term.setTextColor(textColor)
        term.setCursorPos(currentX, buttonY)
        term.write(" " .. button .. " ")
        
        currentX = currentX + #button + 4
    end
    
    term.setBackgroundColor(colors.black)
end

function MsgBox:onClick(relX, relY)
    if not self.visible then return end
    
    local buttonY = self.height - 2  -- Fixed: was self.height - 3, now matches actual button position
    if relY == buttonY then
        -- Calculate which button was clicked
        local totalButtonWidth = 0
        for _, button in ipairs(self.buttons) do
            totalButtonWidth = totalButtonWidth + #button + 4  -- match rendering calculation
        end
        
        local startX = math.floor((self.width - totalButtonWidth) / 2) + 1  -- +1 because widget coordinates are 1-based
        local currentX = startX
        
        for i, button in ipairs(self.buttons) do
            local buttonWidth = #button + 2  -- " " + button + " " = +2 characters
            if relX >= currentX and relX < currentX + buttonWidth then
                self.result = i
                self.visible = false
                if self.onButton then
                    self:onButton(i, button)
                end
                if self.onClose then
                    self:onClose(i)
                end
                break
            end
            currentX = currentX + #button + 4  -- match rendering spacing
        end
    end
    return false
end

function MsgBox:close(result)
    self.result = result or 1
    self.visible = false
    if self.onClose then
        self:onClose(self.result)
    end
end

-- Main PixelUI functions

function PixelUI.init()
    rootContainer = Container:new({
        x = 1, y = 1,
        width = term.getSize(),
        height = select(2, term.getSize()),
        visible = true,
        enabled = true
    })
    widgets = {}
    eventQueue = {}
    running = false
end

-- Developer-friendly: PixelUI handles the event loop and animation internally
function PixelUI.run(userConfig)
    -- userConfig: { onKey, onEvent, onQuit, ... } (optional)
    local animationInterval = 0.05 -- 20 FPS
    local timerId = os.startTimer(animationInterval)
    local running = true
    if userConfig and userConfig.onStart then userConfig.onStart() end
    while running do
        animationFrame() -- update all animations
        PixelUI.render()
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        if event == "timer" and p1 == timerId then
            timerId = os.startTimer(animationInterval)
        else
            PixelUI.handleEvent(event, p1, p2, p3, p4, p5)
            if userConfig and userConfig.onEvent then
                userConfig.onEvent(event, p1, p2, p3, p4, p5)
            end
            if event == "key" then
                if userConfig and userConfig.onKey then
                    if userConfig.onKey(p1) == false then
                        running = false
                    end
                elseif p1 == keys.q then
                    running = false
                end
            end
        end
    end
    if userConfig and userConfig.onQuit then userConfig.onQuit() end
    term.clear()
    term.setCursorPos(1, 1)
end

function PixelUI.label(props)
    local label = Label:new(props)
    table.insert(widgets, label)
    if rootContainer then
        rootContainer:addChild(label)
    end
    return label
end

function PixelUI.button(props)
    local button = Button:new(props)
    table.insert(widgets, button)
    if rootContainer then
        rootContainer:addChild(button)
    end
    return button
end

function PixelUI.textBox(props)
    local textbox = TextBox:new(props)
    table.insert(widgets, textbox)
    if rootContainer then
        rootContainer:addChild(textbox)
    end
    return textbox
end

function PixelUI.checkBox(props)
    local checkbox = CheckBox:new(props)
    table.insert(widgets, checkbox)
    if rootContainer then
        rootContainer:addChild(checkbox)
    end
    return checkbox
end

function PixelUI.slider(props)
    local slider = Slider:new(props)
    table.insert(widgets, slider)
    if rootContainer then
        rootContainer:addChild(slider)
    end
    return slider
end

function PixelUI.rangeSlider(props)
    local rangeslider = RangeSlider:new(props)
    table.insert(widgets, rangeslider)
    if rootContainer then
        rootContainer:addChild(rangeslider)
    end
    return rangeslider
end

function PixelUI.progressBar(props)
    local progressbar = ProgressBar:new(props)
    table.insert(widgets, progressbar)
    if rootContainer then
        rootContainer:addChild(progressbar)
    end
    return progressbar
end

function PixelUI.progressRing(props)
    local progressring = ProgressRing:new(props)
    table.insert(widgets, progressring)
    if rootContainer then
        rootContainer:addChild(progressring)
    end
    return progressring
end

function PixelUI.circularProgressBar(props)
    local circularprogress = CircularProgressBar:new(props)
    table.insert(widgets, circularprogress)
    if rootContainer then
        rootContainer:addChild(circularprogress)
    end
    return circularprogress
end

function PixelUI.listView(props)
    local listview = ListView:new(props)
    table.insert(widgets, listview)
    if rootContainer then
        rootContainer:addChild(listview)
    end
    return listview
end

function PixelUI.container(props)
    local container = Container:new(props)
    table.insert(widgets, container)
    if rootContainer then
        rootContainer:addChild(container)
    end
    return container
end

function PixelUI.toggleSwitch(props)
    local toggleswitch = ToggleSwitch:new(props)
    table.insert(widgets, toggleswitch)
    if rootContainer then
        rootContainer:addChild(toggleswitch)
    end
    return toggleswitch
end

function PixelUI.radioButton(props)
    local radiobutton = RadioButton:new(props)
    table.insert(widgets, radiobutton)
    if rootContainer then
        rootContainer:addChild(radiobutton)
    end
    return radiobutton
end

function PixelUI.comboBox(props)
    local combobox = ComboBox:new(props)
    table.insert(widgets, combobox)
    if rootContainer then
        rootContainer:addChild(combobox)
    end
    return combobox
end

function PixelUI.tabControl(props)
    local tabcontrol = TabControl:new(props)
    table.insert(widgets, tabcontrol)
    if rootContainer then
        rootContainer:addChild(tabcontrol)
    end
    return tabcontrol
end

function PixelUI.grid(props)
    local grid = Grid:new(props)
    table.insert(widgets, grid)
    if rootContainer then
        rootContainer:addChild(grid)
    end
    return grid
end

function PixelUI.canvas(props)
    local canvas = Canvas:new(props)
    table.insert(widgets, canvas)
    if rootContainer then
        rootContainer:addChild(canvas)
    end
    return canvas
end

function PixelUI.chart(props)
    local chart = Chart:new(props)
    table.insert(widgets, chart)
    if rootContainer then
        rootContainer:addChild(chart)
    end
    return chart
end

function PixelUI.spacer(props)
    local spacer = Spacer:new(props)
    table.insert(widgets, spacer)
    if rootContainer then
        rootContainer:addChild(spacer)
    end
    return spacer
end

function PixelUI.scrollBar(props)
    local scrollbar = ScrollBar:new(props)
    table.insert(widgets, scrollbar)
    if rootContainer then
        rootContainer:addChild(scrollbar)
    end
    return scrollbar
end

function PixelUI.contextMenu(props)
    local contextmenu = ContextMenu:new(props)
    -- Context menus are not added to widgets list by default
    -- They are shown/hidden dynamically
    return contextmenu
end

function PixelUI.groupBox(props)
    local groupbox = GroupBox:new(props)
    table.insert(widgets, groupbox)
    if rootContainer then
        rootContainer:addChild(groupbox)
    end
    return groupbox
end

function PixelUI.passwordBox(props)
    local passwordbox = PasswordBox:new(props)
    table.insert(widgets, passwordbox)
    if rootContainer then
        rootContainer:addChild(passwordbox)
    end
    return passwordbox
end

function PixelUI.numericUpDown(props)
    local numericupdown = NumericUpDown:new(props)
    table.insert(widgets, numericupdown)
    if rootContainer then
        rootContainer:addChild(numericupdown)
    end
    return numericupdown
end

function PixelUI.modal(props)
    local modal = Modal:new(props)
    table.insert(widgets, modal)
    if rootContainer then
        rootContainer:addChild(modal)
    end
    return modal
end

function PixelUI.window(props)
    local window = Window:new(props)
    table.insert(widgets, window)
    if rootContainer then
        rootContainer:addChild(window)
    end
    return window
end

function PixelUI.breadcrumb(props)
    local breadcrumb = Breadcrumb:new(props)
    table.insert(widgets, breadcrumb)
    if rootContainer then
        rootContainer:addChild(breadcrumb)
    end
    return breadcrumb
end

function PixelUI.treeView(props)
    local treeview = TreeView:new(props)
    table.insert(widgets, treeview)
    if rootContainer then
        rootContainer:addChild(treeview)
    end
    return treeview
end

function PixelUI.msgBox(props)
    local msgbox = MsgBox:new(props)
    table.insert(widgets, msgbox)
    if rootContainer then
        rootContainer:addChild(msgbox)
    end
    return msgbox
end

function PixelUI.colorPicker(props)
    local colorpicker = ColorPicker:new(props)
    table.insert(widgets, colorpicker)
    if rootContainer then
        rootContainer:addChild(colorpicker)
    end
    return colorpicker
end

function PixelUI.colorPickerDialog(props)
    local dialog = ColorPickerDialog:new(props)
    return dialog
end

function PixelUI.loadingIndicator(props)
    local loading = LoadingIndicator:new(props)
    table.insert(widgets, loading)
    if rootContainer then
        rootContainer:addChild(loading)
    end
    return loading
end

function PixelUI.spinner(props)
    local spinner = Spinner:new(props)
    table.insert(widgets, spinner)
    if rootContainer then
        rootContainer:addChild(spinner)
    end
    return spinner
end

-- Core rendering and event handling functions
function PixelUI.render()
    -- Clear the screen first
    term.setBackgroundColor(colors.black)
    term.clear()

    -- Check for visible modal MsgBox (or Modal) and render only it if present
    local activeModal = nil
    for _, widget in ipairs(widgets) do
        if widget.__index == MsgBox and widget.visible then
            activeModal = widget
            break
        end
    end
    if not activeModal then
        for _, widget in ipairs(widgets) do
            if widget.__index == Modal and widget.visible then
                activeModal = widget
                break
            end
        end
    end

    if activeModal then
        activeModal:draw()
    else
        -- Render root container if it exists
        if rootContainer then
            rootContainer:draw()
        else
            -- Render all widgets directly if no container
            for _, widget in ipairs(widgets) do
                if widget.visible ~= false then
                    widget:draw()
                end
            end
        end
    end
end

function PixelUI.clear()
    -- Clear all widgets
    widgets = {}
    if rootContainer then
        rootContainer.children = {}
    end
    
    -- Clear the screen
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
end

function PixelUI.handleEvent(event, ...)
    local args = {...}
    
    if event == "mouse_click" then
        local button, x, y = args[1], args[2], args[3]

        -- Recursively traverse all widgets and their children (depth-first, z-order)
        local function traverse(list, fn)
            for i = #list, 1, -1 do
                local widget = list[i]
                if fn(widget) then return true end
                if widget.children then
                    if traverse(widget.children, fn) then return true end
                end
            end
            return false
        end

        -- Handle right-click for context menus
        if button == 2 then
            traverse(widgets, function(widget)
                if widget.visible ~= false and widget.contextMenu then
                    local absX, absY = widget.getAbsolutePos and widget:getAbsolutePos() or 0, 0
                    local relX, relY = x - absX + 1, y - absY + 1
                    if isPointInBounds and isPointInBounds(relX, relY, {x = 1, y = 1, width = widget.width, height = widget.height}) then
                        widget.contextMenu:show(x, y)
                        return true
                    end
                end
                return false
            end)
        end

        -- Handle click events for all widgets first (reverse order for proper z-index)
        local clickHandled = false
        traverse(widgets, function(widget)
            if widget.visible ~= false and widget.handleClick and widget:handleClick(x, y) then
                clickHandled = true
                return true
            end
            return false
        end)

        -- Close any open dropdowns when clicking outside them (only if no widget handled the click)
        if not clickHandled then
            traverse(widgets, function(widget)
                if widget.isOpen ~= nil and widget.isOpen then
                    local absX, absY = widget.getAbsolutePos and widget:getAbsolutePos() or 0, 0
                    local relX, relY = x - absX + 1, y - absY + 1
                    -- For ComboBox widgets, don't close if clicking within the expanded dropdown area
                    local isComboBox = widget.items ~= nil and widget.baseHeight ~= nil
                    local actualHeight = widget.height
                    if not (relX >= 1 and relX <= widget.width and relY >= 1 and relY <= actualHeight) then
                        widget.isOpen = false
                        if widget.baseHeight then
                            widget.height = widget.baseHeight
                        end
                    end
                end
                return false
            end)
        end
        
        -- If no widget handled the click, clear focus
        if not clickHandled then
            clearFocus()
        end
        
    elseif event == "mouse_scroll" then
        local direction, x, y = args[1], args[2], args[3]
        local function traverse(list, fn)
            for i = #list, 1, -1 do
                local widget = list[i]
                if fn(widget) then return true end
                if widget.children then
                    if traverse(widget.children, fn) then return true end
                end
            end
            return false
        end
        traverse(widgets, function(widget)
            if widget.visible ~= false and widget.handleScroll and widget:handleScroll(x, y, direction) then
                return true
            end
            return false
        end)
        
    elseif event == "mouse_drag" then
        local button, x, y = args[1], args[2], args[3]
        
        -- Handle drag events for widgets that support it
        if draggedWidget then
            if draggedWidget.handleDrag then
                draggedWidget:handleDrag(x, y)
            end
        end
        
    elseif event == "mouse_up" then
        -- Reset dragging state
        isDragging = false
        if draggedWidget then
            if draggedWidget.isDragging ~= nil then
                draggedWidget.isDragging = false
            end
            draggedWidget = nil
        end
        -- Reset button press effects
        local function traverse(list, fn)
            for i = #list, 1, -1 do
                local widget = list[i]
                fn(widget)
                if widget.children then
                    traverse(widget.children, fn)
                end
            end
        end
        traverse(widgets, function(widget)
            if widget.isPressed then widget.isPressed = false end
        end)
        
    elseif event == "key" then
        local key = args[1]
        local function traverse(list, fn)
            for i = #list, 1, -1 do
                local widget = list[i]
                if fn(widget) then return true end
                if widget.children then
                    if traverse(widget.children, fn) then return true end
                end
            end
            return false
        end
        traverse(widgets, function(widget)
            if widget == focusedWidget and widget.handleKey then
                if widget:handleKey(key) then
                    return true
                end
            end
            return false
        end)
    elseif event == "char" then
        local char = args[1]
        local function traverse(list, fn)
            for i = #list, 1, -1 do
                local widget = list[i]
                if fn(widget) then return true end
                if widget.children then
                    if traverse(widget.children, fn) then return true end
                end
            end
            return false
        end
        traverse(widgets, function(widget)
            if widget == focusedWidget and widget.handleChar then
                if widget:handleChar(char) then
                    return true
                end
            end
            return false
        end)
    end
end

function PixelUI.setRootContainer(container)
    rootContainer = container
end

function PixelUI.getRootContainer()
    return rootContainer
end

function PixelUI.getWidgets()
    return widgets
end

-- Focus management API
function PixelUI.setFocus(widget)
    setFocusedWidget(widget)
end

function PixelUI.clearFocus()
    clearFocus()
end

function PixelUI.getFocusedWidget()
    return getFocusedWidget()
end

-- Export all widget classes for advanced usage
PixelUI.Widget = Widget
PixelUI.Label = Label
PixelUI.Button = Button
PixelUI.TextBox = TextBox
PixelUI.CheckBox = CheckBox
PixelUI.Slider = Slider
PixelUI.RangeSlider = RangeSlider
PixelUI.ProgressBar = ProgressBar
PixelUI.ProgressRing = ProgressRing
PixelUI.CircularProgressBar = CircularProgressBar
PixelUI.ListView = ListView
PixelUI.Container = Container
PixelUI.ToggleSwitch = ToggleSwitch
PixelUI.RadioButton = RadioButton
PixelUI.ComboBox = ComboBox
PixelUI.TabControl = TabControl
PixelUI.Grid = Grid
PixelUI.Canvas = Canvas
PixelUI.Chart = Chart
PixelUI.Spacer = Spacer
PixelUI.ScrollBar = ScrollBar
PixelUI.ContextMenu = ContextMenu
PixelUI.GroupBox = GroupBox
PixelUI.PasswordBox = PasswordBox
PixelUI.NumericUpDown = NumericUpDown
PixelUI.Modal = Modal
PixelUI.Window = Window
PixelUI.Breadcrumb = Breadcrumb
PixelUI.TreeView = TreeView
PixelUI.MsgBox = MsgBox
PixelUI.ColorPicker = ColorPicker
PixelUI.ColorPickerDialog = ColorPickerDialog
PixelUI.LoadingIndicator = LoadingIndicator
PixelUI.Spinner = Spinner

return PixelUI