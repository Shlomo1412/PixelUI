
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

-- Thread Management System
local ThreadManager = {
    threads = {},
    nextId = 1,
    running = false,
    mainUICoroutine = nil
}

function ThreadManager:create(func, name)
    local id = self.nextId
    self.nextId = self.nextId + 1
    
    local thread = {
        id = id,
        name = name or ("Thread_" .. id),
        coroutine = coroutine.create(func),
        status = "created",
        lastError = nil,
        startTime = os.clock(),
        onError = nil,
        onComplete = nil
    }
    
    self.threads[id] = thread
    return id, thread
end

function ThreadManager:remove(id)
    if self.threads[id] then
        self.threads[id] = nil
        return true
    end
    return false
end

function ThreadManager:get(id)
    return self.threads[id]
end

function ThreadManager:getAll()
    local result = {}
    for id, thread in pairs(self.threads) do
        table.insert(result, thread)
    end
    return result
end

function ThreadManager:isAlive(id)
    local thread = self.threads[id]
    return thread and (thread.status == "running" or thread.status == "suspended")
end

function ThreadManager:kill(id)
    if self.threads[id] then
        self.threads[id].status = "killed"
        return true
    end
    return false
end

function ThreadManager:resumeThread(thread, ...)
    if not thread or thread.status == "dead" or thread.status == "killed" then
        return false
    end
    
    local success, result = coroutine.resume(thread.coroutine, ...)
    
    if not success then
        thread.status = "error"
        thread.lastError = result
        if thread.onError then
            thread.onError(result, thread)
        else
            -- Default error handling - show as toast if available
            if PixelUI.showToast then
                PixelUI.showToast("Thread Error: " .. tostring(result), thread.name, "error")
            end
        end
        return false
    end
    
    if coroutine.status(thread.coroutine) == "dead" then
        thread.status = "completed"
        if thread.onComplete then
            thread.onComplete(thread)
        end
        return false
    else
        thread.status = "suspended"
        return true
    end
end

function ThreadManager:step()
    -- Resume all threads
    local toRemove = {}
    
    for id, thread in pairs(self.threads) do
        if thread.status == "created" or thread.status == "suspended" then
            thread.status = "running"
            local stillRunning = self:resumeThread(thread)
            
            if not stillRunning then
                table.insert(toRemove, id)
            end
        elseif thread.status == "error" or thread.status == "completed" or thread.status == "killed" then
            table.insert(toRemove, id)
        end
    end
    
    -- Clean up finished threads
    for _, id in ipairs(toRemove) do
        self:remove(id)
    end
end

function ThreadManager:stopAll()
    for id, thread in pairs(self.threads) do
        thread.status = "killed"
    end
    self.threads = {}
end

function ThreadManager:getStats()
    local stats = {
        total = 0,
        running = 0,
        suspended = 0,
        error = 0,
        completed = 0
    }
    
    for _, thread in pairs(self.threads) do
        stats.total = stats.total + 1
        if thread.status == "running" or thread.status == "created" then
            stats.running = stats.running + 1
        elseif thread.status == "suspended" then
            stats.suspended = stats.suspended + 1
        elseif thread.status == "error" then
            stats.error = stats.error + 1
        elseif thread.status == "completed" then
            stats.completed = stats.completed + 1
        end
    end
    
    return stats
end

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

-- Timer system for delayed callbacks
local TimerManager = {
    timers = {}
}

function TimerManager:add(callback, delay)
    table.insert(self.timers, {
        callback = callback,
        startTime = os.clock(),
        delay = delay / 1000 -- Convert ms to seconds
    })
end

function TimerManager:update()
    local now = os.clock()
    local toRemove = {}
    
    for i, timer in ipairs(self.timers) do
        if now - timer.startTime >= timer.delay then
            timer.callback()
            table.insert(toRemove, i)
        end
    end
    
    -- Remove completed timers
    for i = #toRemove, 1, -1 do
        table.remove(self.timers, toRemove[i])
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

-- Timer system
function PixelUI.setTimeout(callback, delay)
    TimerManager:add(callback, delay)
end

-- Internal: call AnimationManager:update(dt) every frame
local lastFrameTime = os.epoch and os.epoch("utc") or os.clock() * 1000
local function animationFrame()
    local now = os.epoch and os.epoch("utc") or os.clock() * 1000
    local dt = (now - lastFrameTime) / 1000
    lastFrameTime = now
    AnimationManager:update(dt)
    TimerManager:update()
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
    table.sort(self.children, function(a, b) 
        local aZ = a.zIndex or 0
        local bZ = b.zIndex or 0
        return aZ < bZ 
    end)
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
    if not self.enabled or not self:isEffectivelyVisible() then return false end

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
    if not self.enabled or not self:isEffectivelyVisible() or not self.draggable then return false end
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
    if not self:isEffectivelyVisible() then return end
    
    self:render()
    
    -- Draw children
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- Check if widget is effectively visible (considering parent visibility)
function Widget:isEffectivelyVisible()
    if not self.visible then return false end
    
    -- Check parent visibility recursively
    local parent = self.parent
    while parent do
        if not parent.visible then return false end
        parent = parent.parent
    end
    
    return true
end

function Widget:render()
    -- Override in subclasses
end

function Widget:setFocus()
    setFocusedWidget(self)
end

function Widget:clearFocus()
    if focusedWidget == self then
        setFocusedWidget(nil)
    end
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
    
    local text = (self.text or ""):sub(1, self.width)
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
    progressbar.backgroundPattern = props.backgroundPattern or "\127" -- Light shade character for incomplete part
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
    
    -- Draw background with pattern
    term.setBackgroundColor(self.background)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(absX, absY)
    term.write(string.rep(self.backgroundPattern, self.width))
    
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

function ListView:handleScroll(x, y, direction)
    if not self.enabled or not self.visible or not self.scrollable then return false end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    -- Check if scroll is within ListView bounds
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        if #self.items > self.height then
            local scrollAmount = direction * 1 -- Scroll 1 item at a time for precision
            local maxScroll = math.max(0, #self.items - self.height)
            self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset + scrollAmount)) -- Flip direction for natural scrolling
            
            -- Ensure selected item stays visible
            self:ensureSelectedVisible()
            return true
        end
    end
    
    return false
end

function ListView:ensureSelectedVisible()
    if self.selectedIndex <= self.scrollOffset then
        -- Selected item is above visible area
        self.scrollOffset = math.max(0, self.selectedIndex - 1)
    elseif self.selectedIndex > self.scrollOffset + self.height then
        -- Selected item is below visible area
        self.scrollOffset = self.selectedIndex - self.height
    end
end

function ListView:setSelectedIndex(index)
    if index >= 1 and index <= #self.items then
        self.selectedIndex = index
        self:ensureSelectedVisible()
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
        -- Re-check vertical scroll need after horizontal scrollbar takes space
        needsVerticalScroll = self.contentHeight > viewHeight
        if needsVerticalScroll and not needsHorizontalScroll then
            viewWidth = viewWidth - 1 -- Account for vertical scrollbar
        end
    end
    
    -- Only create scrollbars if ScrollBar class is available
    -- (ScrollBar is defined later in the file, so we need to check if it exists)
    if not ScrollBar then
        -- ScrollBar not yet defined, skip scrollbar creation for now
        return
    end
    
    -- Create vertical scrollbar if needed
    if needsVerticalScroll and not self.verticalScrollBar then
        self.verticalScrollBar = ScrollBar:new({
            x = self.width - (self.border and 1 or 0),
            y = (self.border and 2 or 1),
            width = 1,
            height = viewHeight,
            orientation = "vertical",
            min = 0,
            max = math.max(0, self.contentHeight - viewHeight),
            value = self.scrollY or 0,
            pageSize = viewHeight,
            step = 1,
            onChange = function(value)
                self.scrollY = value
            end
        })
        self.verticalScrollBar.parent = self
    elseif not needsVerticalScroll and self.verticalScrollBar then
        self.verticalScrollBar = nil
        self.scrollY = 0
    elseif self.verticalScrollBar then
        -- Update existing scrollbar properties
        self.verticalScrollBar.max = math.max(0, self.contentHeight - viewHeight)
        self.verticalScrollBar.pageSize = viewHeight
        self.verticalScrollBar.value = math.min(self.verticalScrollBar.value, self.verticalScrollBar.max)
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
            max = math.max(0, self.contentWidth - viewWidth),
            value = self.scrollX or 0,
            pageSize = viewWidth,
            step = 1,
            onChange = function(value)
                self.scrollX = value
            end
        })
        self.horizontalScrollBar.parent = self
    elseif not needsHorizontalScroll and self.horizontalScrollBar then
        self.horizontalScrollBar = nil
        self.scrollX = 0
    elseif self.horizontalScrollBar then
        -- Update existing scrollbar properties
        self.horizontalScrollBar.max = math.max(0, self.contentWidth - viewWidth)
        self.horizontalScrollBar.pageSize = viewWidth
        self.horizontalScrollBar.value = math.min(self.horizontalScrollBar.value, self.horizontalScrollBar.max)
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
    
    -- Ensure minimum content size to match viewport
    local viewWidth = self.width - (self.border and 2 or 0)
    local viewHeight = self.height - (self.border and 2 or 0)
    self.contentWidth = math.max(self.contentWidth, viewWidth)
    self.contentHeight = math.max(self.contentHeight, viewHeight)
end

function Container:draw()
    if not self:isEffectivelyVisible() then return end
    self:render()
    
    -- Calculate content and viewport dimensions
    local contentX = self.x + (self.border and 1 or 0)
    local contentY = self.y + (self.border and 1 or 0)
    local contentWidth = self.width - (self.border and 2 or 0) - (self.verticalScrollBar and 1 or 0)
    local contentHeight = self.height - (self.border and 2 or 0) - (self.horizontalScrollBar and 1 or 0)
    
    -- Draw children with scroll offset and clipping
    for _, child in ipairs(self.children) do
        if child.visible ~= false then -- Only check child's own visibility since parent visibility is checked by child:draw()
            -- Store original position
            local originalX, originalY = child.x, child.y
            
            -- Apply scroll offset
            child.x = child.x - (self.scrollX or 0)
            child.y = child.y - (self.scrollY or 0)
            
            -- Check if child is within viewport bounds
            local childLeft = contentX + child.x - 1
            local childTop = contentY + child.y - 1
            local childRight = childLeft + child.width - 1
            local childBottom = childTop + child.height - 1
            
            local viewportLeft = contentX
            local viewportTop = contentY
            local viewportRight = contentX + contentWidth - 1
            local viewportBottom = contentY + contentHeight - 1
            
            -- Only draw if child overlaps with viewport
            if childRight >= viewportLeft and childLeft <= viewportRight and 
               childBottom >= viewportTop and childTop <= viewportBottom then
                child:draw()
            end
            
            -- Restore original position
            child.x, child.y = originalX, originalY
        end
    end
    
    -- Draw scrollbars last
    if self.verticalScrollBar then self.verticalScrollBar:draw() end
    if self.horizontalScrollBar then self.horizontalScrollBar:draw() end
end

function Container:handleScroll(x, y, direction)
    if not self.enabled or not self:isEffectivelyVisible() or not self.isScrollable then return false end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    -- Check if scroll is within container bounds
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        local scrollAmount = direction * 3 -- Scroll 3 lines at a time
        
        if self.verticalScrollBar and self.verticalScrollBar.scroll then
            -- Use scrollbar if available
            self.verticalScrollBar:scroll(-scrollAmount) -- Flip direction for natural scrolling
            return true
        else
            -- Direct scroll handling when no scrollbar is available
            local maxScrollY = math.max(0, self.contentHeight - (self.height - (self.border and 2 or 0)))
            self.scrollY = math.max(0, math.min(maxScrollY, (self.scrollY or 0) + scrollAmount)) -- Flip direction
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
    
    local radioChar = self.checked and "\7" or "o"  -- Dash for selected, o for unselected
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
    
    -- Draw main box only (dropdown is rendered separately to appear on top)
    term.setCursorPos(absX, absY)
    local selectedText = self.items[self.selectedIndex] or ""
    local displayText = selectedText:sub(1, self.width - 2)
    local arrowChar = self.isOpen and "\30" or "\31"  -- Up arrow when open, down arrow when closed
    term.write(displayText .. string.rep(" ", self.width - 2 - #displayText) .. arrowChar)
    
    term.setBackgroundColor(colors.black)
end

function ComboBox:renderDropdown()
    -- Render dropdown on top of everything else
    if self.isOpen then
        local absX, absY = self:getAbsolutePos()
        
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
        
        term.setBackgroundColor(colors.black)
    end
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

-- Image Widget
local Image = setmetatable({}, {__index = Widget})
Image.__index = Image

function Image:new(props)
    local image = Widget.new(self, props)
    image.path = props.path or ""
    image.background = props.background or colors.black
    image.border = props.border or false
    image.borderColor = props.borderColor or colors.white
    image.scale = props.scale or 1
    image.imageData = nil
    image.loadError = nil
    
    -- Load the image on creation
    image:loadImage()
    
    return image
end

function Image:loadImage()
    if not self.path or self.path == "" then
        self.loadError = "No image path specified"
        return
    end
    
    -- Check if file exists
    if not fs.exists(self.path) then
        self.loadError = "Image file not found: " .. self.path
        return
    end
    
    -- Detect file format based on extension
    local extension = self.path:match("%.([^%.]+)$")
    if extension then
        extension = extension:lower()
    end
    
    local success, result
    
    if extension == "nfp" then
        -- Load NFP (ComputerCraft Pictures) format
        success, result = pcall(function()
            return self:loadNFP()
        end)
    elseif extension == "bimg" then
        -- Load BIMG format
        success, result = pcall(function()
            return self:loadBIMG()
        end)
    else
        -- Try to auto-detect format by attempting to load as NFP first, then BIMG
        success, result = pcall(function()
            -- First try NFP (text-based format)
            local nfpResult = self:loadNFP()
            if nfpResult then
                return nfpResult
            end
            
            -- If NFP fails, try BIMG (binary format)
            return self:loadBIMG()
        end)
    end
    
    if success then
        self.imageData = result
        self.loadError = nil
        
        -- Auto-size widget to image if no size specified
        if result and ((not self.width or self.width == 0) or (not self.height or self.height == 0)) then
            if not self.width or self.width == 0 then
                self.width = math.min(result.width * self.scale, 50) -- Cap at 50 for safety
            end
            if not self.height or self.height == 0 then
                self.height = math.min(result.height * self.scale, 50) -- Cap at 50 for safety
            end
        end
    else
        self.loadError = "Error loading image: " .. tostring(result)
        self.imageData = nil
    end
end

function Image:loadNFP()
    local file = fs.open(self.path, "r")
    if not file then
        error("Could not open NFP file: " .. self.path)
    end
    
    local pixels = {}
    local width = 0
    local height = 0
    local y = 1
    
    -- Color character mappings for NFP format
    local colorMap = {
        ["0"] = colors.white,
        ["1"] = colors.orange,
        ["2"] = colors.magenta,
        ["3"] = colors.lightBlue,
        ["4"] = colors.yellow,
        ["5"] = colors.lime,
        ["6"] = colors.pink,
        ["7"] = colors.gray,
        ["8"] = colors.lightGray,
        ["9"] = colors.cyan,
        ["a"] = colors.purple,
        ["b"] = colors.blue,
        ["c"] = colors.brown,
        ["d"] = colors.green,
        ["e"] = colors.red,
        ["f"] = colors.black,
        [" "] = nil -- Transparent/background
    }
    
    local line = file.readLine()
    while line do
        pixels[y] = {}
        width = math.max(width, #line)
        
        for x = 1, #line do
            local char = line:sub(x, x):lower()
            pixels[y][x] = colorMap[char]
        end
        
        y = y + 1
        line = file.readLine()
    end
    
    height = y - 1
    file.close()
    
    if height == 0 or width == 0 then
        error("Invalid NFP file format")
    end
    
    -- Fill in missing pixels with nil (transparent)
    for row = 1, height do
        if not pixels[row] then
            pixels[row] = {}
        end
        for col = 1, width do
            if pixels[row][col] == nil then
                pixels[row][col] = nil -- Keep transparent
            end
        end
    end
    
    return {
        width = width,
        height = height,
        pixels = pixels
    }
end

function Image:loadBIMG()
    local file = fs.open(self.path, "rb")
    if not file then
        error("Could not open BIMG file: " .. self.path)
    end
    
    -- Read BIMG header (basic implementation)
    -- BIMG format: width(2 bytes), height(2 bytes), then pixel data
    local widthLow = file.read()
    local widthHigh = file.read()
    local heightLow = file.read()
    local heightHigh = file.read()
    
    if not widthLow or not widthHigh or not heightLow or not heightHigh then
        file.close()
        error("Invalid BIMG file format")
    end
    
    local imgWidth = widthLow + widthHigh * 256
    local imgHeight = heightLow + heightHigh * 256
    
    -- Read pixel data
    local pixels = {}
    for y = 1, imgHeight do
        pixels[y] = {}
        for x = 1, imgWidth do
            local colorByte = file.read()
            if colorByte then
                -- Convert byte to ComputerCraft color
                -- Simple mapping: 0-15 maps to colors.white to colors.black
                local color = math.pow(2, colorByte % 16)
                pixels[y][x] = color
            else
                pixels[y][x] = colors.black
            end
        end
    end
    
    file.close()
    
    return {
        width = imgWidth,
        height = imgHeight,
        pixels = pixels
    }
end

function Image:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Draw border if enabled
    if self.border then
        drawCharBorder(absX, absY, self.width, self.height, self.borderColor, self.background)
    end
    
    local startX = self.border and 1 or 0
    local startY = self.border and 1 or 0
    local endX = self.width - (self.border and 1 or 0)
    local endY = self.height - (self.border and 1 or 0)
    
    -- Fill background first
    term.setBackgroundColor(self.background)
    for y = startY + 1, endY do
        term.setCursorPos(absX + startX, absY + y - 1)
        term.write(string.rep(" ", endX - startX))
    end
    
    -- Render image or error message
    if self.loadError then
        -- Display error message
        term.setTextColor(colors.red)
        term.setBackgroundColor(self.background)
        local errorLines = {}
        local words = {}
        for word in self.loadError:gmatch("%S+") do
            table.insert(words, word)
        end
        
        local currentLine = ""
        local maxWidth = endX - startX
        for _, word in ipairs(words) do
            if #currentLine + #word + 1 <= maxWidth then
                currentLine = currentLine .. (currentLine == "" and "" or " ") .. word
            else
                if currentLine ~= "" then
                    table.insert(errorLines, currentLine)
                end
                currentLine = word
            end
        end
        if currentLine ~= "" then
            table.insert(errorLines, currentLine)
        end
        
        for i, line in ipairs(errorLines) do
            if i <= endY - startY then
                term.setCursorPos(absX + startX, absY + startY + i - 1)
                term.write(line:sub(1, maxWidth))
            end
        end
        
    elseif self.imageData then
        -- Render the image
        local imgData = self.imageData
        local scaleX = (endX - startX) / imgData.width
        local scaleY = (endY - startY) / imgData.height
        
        for y = 1, endY - startY do
            for x = 1, endX - startX do
                -- Map screen coordinates to image coordinates
                local imgX = math.floor(x / scaleX) + 1
                local imgY = math.floor(y / scaleY) + 1
                
                if imgX <= imgData.width and imgY <= imgData.height then
                    local pixel = imgData.pixels[imgY] and imgData.pixels[imgY][imgX]
                    if pixel then
                        term.setBackgroundColor(pixel)
                        term.setCursorPos(absX + startX + x - 1, absY + startY + y - 1)
                        term.write(" ")
                    end
                    -- If pixel is nil (transparent), don't draw anything - keep background
                end
            end
        end
    else
        -- Display placeholder
        term.setTextColor(colors.lightGray)
        term.setBackgroundColor(self.background)
        local placeholder = "No Image"
        local midY = math.floor((endY - startY) / 2) + startY
        local midX = math.floor((endX - startX - #placeholder) / 2) + startX
        term.setCursorPos(absX + midX, absY + midY)
        term.write(placeholder)
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function Image:setPath(newPath)
    self.path = newPath
    self:loadImage()
end

function Image:reload()
    self:loadImage()
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
    
    -- Get theme colors with fallbacks
    local trackColor = (theme.scrollbar and theme.scrollbar.track) or colors.gray
    local thumbColor = (theme.scrollbar and theme.scrollbar.thumb) or colors.lightGray
    
    if self.orientation == "vertical" then
        -- Draw track
        term.setBackgroundColor(trackColor)
        for i = 0, self.height - 1 do
            term.setCursorPos(absX, absY + i)
            term.write(" ")
        end
        
        -- Calculate thumb position and size
        local trackSize = self.height
        local range = self.max - self.min
        if range > 0 then
            local thumbSize = math.max(1, math.floor((self.pageSize / (range + self.pageSize)) * trackSize))
            local thumbPos = math.floor(((self.value - self.min) / range) * (trackSize - thumbSize))
            thumbPos = math.max(0, math.min(trackSize - thumbSize, thumbPos))
            
            -- Draw thumb
            term.setBackgroundColor(thumbColor)
            for i = 0, thumbSize - 1 do
                if thumbPos + i < trackSize then
                    term.setCursorPos(absX, absY + thumbPos + i)
                    term.write(" ")
                end
            end
        end
    else
        -- Horizontal scrollbar
        term.setBackgroundColor(trackColor)
        term.setCursorPos(absX, absY)
        term.write(string.rep(" ", self.width))
        
        -- Calculate thumb position and size
        local trackSize = self.width
        local range = self.max - self.min
        if range > 0 then
            local thumbSize = math.max(1, math.floor((self.pageSize / (range + self.pageSize)) * trackSize))
            local thumbPos = math.floor(((self.value - self.min) / range) * (trackSize - thumbSize))
            thumbPos = math.max(0, math.min(trackSize - thumbSize, thumbPos))
            
            -- Draw thumb
            term.setBackgroundColor(thumbColor)
            term.setCursorPos(absX + thumbPos, absY)
            term.write(string.rep(" ", thumbSize))
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function ScrollBar:onClick(relX, relY)
    if not self.enabled then return end
    
    local trackSize = self.orientation == "vertical" and self.height or self.width
    local clickPos = self.orientation == "vertical" and relY or relX
    local range = self.max - self.min
    
    if range <= 0 then return end
    
    -- Calculate current thumb position and size
    local thumbSize = math.max(1, math.floor((self.pageSize / (range + self.pageSize)) * trackSize))
    local thumbPos = math.floor(((self.value - self.min) / range) * (trackSize - thumbSize))
    thumbPos = math.max(0, math.min(trackSize - thumbSize, thumbPos))
    
    if clickPos >= thumbPos + 1 and clickPos <= thumbPos + thumbSize then
        -- Start dragging thumb
        self.isDragging = true
        self.dragOffset = clickPos - thumbPos - 1
        isDragging = true
        draggedWidget = self
    else
        -- Jump to position (page up/down behavior)
        local newThumbPos = clickPos - math.floor(thumbSize / 2)
        newThumbPos = math.max(0, math.min(trackSize - thumbSize, newThumbPos))
        
        if trackSize > thumbSize then
            local newValue = self.min + (newThumbPos / (trackSize - thumbSize)) * range
            self.value = math.max(self.min, math.min(self.max, newValue))
            if self.onChange then
                self:onChange(self.value)
            end
        end
    end
end

function ScrollBar:handleDrag(x, y)
    if not self.enabled or not self.isDragging then return end
    
    local absX, absY = self:getAbsolutePos()
    local relPos = (self.orientation == "vertical" and (y - absY + 1) or (x - absX + 1)) - self.dragOffset
    local trackSize = self.orientation == "vertical" and self.height or self.width
    local range = self.max - self.min
    
    if range <= 0 then return end
    
    -- Calculate thumb size
    local thumbSize = math.max(1, math.floor((self.pageSize / (range + self.pageSize)) * trackSize))
    
    if trackSize > thumbSize then
        local newValue = self.min + (relPos / (trackSize - thumbSize)) * range
        self.value = math.max(self.min, math.min(self.max, newValue))
        
        if self.onChange then
            self:onChange(self.value)
        end
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
    
    -- Remove all children from the global widgets list
    if self.children then
        for _, child in ipairs(self.children) do
            PixelUI.removeWidgetAndChildren(child)
        end
        -- Clear the children array
        self.children = {}
    end
    
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

-- NotificationToast Widget
local NotificationToast = setmetatable({}, {__index = Widget})
NotificationToast.__index = NotificationToast

function NotificationToast:new(props)
    local toast = Widget.new(self, props)
    toast.message = props.message or "Notification"
    toast.title = props.title or ""
    toast.type = props.type or "info" -- "info", "success", "warning", "error"
    toast.duration = props.duration or 3000 -- Duration in milliseconds
    toast.color = props.color or colors.white
    toast.titleColor = props.titleColor or colors.white
    toast.closeable = props.closeable ~= false
    toast.autoHide = props.autoHide ~= false
    toast.onShow = props.onShow
    toast.onHide = props.onHide
    toast.onToastClick = props.onClick  -- Rename to avoid conflict with method name
    toast.fadeSpeed = props.fadeSpeed or 20
    toast.slideSpeed = props.slideSpeed or 10
    toast.animateIn = props.animateIn ~= false  -- Enable slide-in animation
    toast.animateOut = props.animateOut ~= false  -- Enable slide-out animation
    toast.animationType = props.animationType or "slide"  -- "slide", "fade", "both"
    
    -- Animation properties
    toast.opacity = props.animateIn and (props.animationType == "fade" or props.animationType == "both") and 0 or 1
    toast.slideOffset = props.animateIn and (props.animationType == "slide" or props.animationType == "both") and -(props.height or 3) or 0
    toast.isShowing = false
    toast.isHiding = false
    toast.showTime = 0
    toast.lastUpdate = os.clock()
    
    -- Auto-size based on content FIRST
    if not props.width then
        local messageLength = #toast.message
        local titleLength = toast.title ~= "" and #toast.title or 0
        toast.width = math.max(math.min(math.max(messageLength, titleLength) + 4, 40), 20)
    end
    if not props.height then
        toast.height = toast.title ~= "" and 3 or 2
    end
    
    -- Update slide offset after height is determined
    if props.animateIn and (props.animationType == "slide" or props.animationType == "both") then
        toast.slideOffset = -toast.height
    end
    
    -- Position at top-right by default AFTER sizing
    local termWidth, termHeight = term.getSize()
    if not props.x then
        toast.x = termWidth - toast.width + 1
    end
    if not props.y then
        toast.y = 1
    end
    
    -- Set background color after getting type color
    toast.background = props.background or toast:getTypeColor()
    
    return toast
end

function NotificationToast:getTypeColor()
    local typeColors = {
        info = colors.blue,
        success = colors.green,
        warning = colors.orange,
        error = colors.red
    }
    return typeColors[self.type] or colors.blue
end

function NotificationToast:render()
    if not self.visible or self.opacity <= 0 then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Apply slide animation
    absY = absY + self.slideOffset
    
    -- Draw background with opacity simulation
    local bgColor = self.background
    if self.opacity < 1 then
        -- Simulate opacity by blending with black background
        local opacityColors = {
            [colors.blue] = {colors.black, colors.blue, colors.lightBlue},
            [colors.green] = {colors.black, colors.green, colors.lime},
            [colors.orange] = {colors.black, colors.orange, colors.yellow},
            [colors.red] = {colors.black, colors.red, colors.pink}
        }
        local colorSteps = opacityColors[bgColor] or {colors.black, bgColor, colors.white}
        local stepIndex = math.floor(self.opacity * (#colorSteps - 1)) + 1
        bgColor = colorSteps[math.min(stepIndex, #colorSteps)]
    end
    
    term.setBackgroundColor(bgColor)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw type indicator (left border)
    local typeChar = self:getTypeIndicator()
    term.setBackgroundColor(self:getTypeColor())
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(" ")
    end
    
    -- Draw title if present
    local contentY = 0
    if self.title ~= "" then
        term.setBackgroundColor(bgColor)
        term.setTextColor(self.titleColor)
        term.setCursorPos(absX + 2, absY + contentY)
        local titleText = self.title:sub(1, self.width - 4)
        term.write(titleText)
        contentY = contentY + 1
    end
    
    -- Draw message
    term.setBackgroundColor(bgColor)
    term.setTextColor(self.color)
    term.setCursorPos(absX + 2, absY + contentY)
    local messageText = self.message:sub(1, self.width - 4)
    term.write(messageText)
    
    -- Draw close button if closeable
    if self.closeable then
        term.setBackgroundColor(bgColor)
        term.setTextColor(colors.lightGray)
        term.setCursorPos(absX + self.width - 1, absY)
        term.write("X")
    end
    
    term.setBackgroundColor(colors.black)
end

-- Alias draw to render for compatibility with the widget system
function NotificationToast:draw()
    if not self:isEffectivelyVisible() then return end
    self:render()
end

function NotificationToast:getTypeIndicator()
    local indicators = {
        info = "i",
        success = "+",
        warning = "!",
        error = "X"
    }
    return indicators[self.type] or "i"
end

function NotificationToast:show()
    self.visible = true
    self.showTime = os.clock()
    self.lastUpdate = os.clock()
    
    -- Set initial animation state based on animation settings
    if self.animateIn then
        self.isShowing = true
        self.isHiding = false
        if self.animationType == "fade" then
            self.opacity = 0
            self.slideOffset = 0
        elseif self.animationType == "slide" then
            self.opacity = 1
            self.slideOffset = -self.height
        else -- "both"
            self.opacity = 0
            self.slideOffset = -self.height
        end
    else
        -- No animation - show immediately
        self.isShowing = false
        self.isHiding = false
        self.opacity = 1
        self.slideOffset = 0
        
        -- Start auto-hide timer immediately if enabled
        if self.autoHide then
            PixelUI.setTimeout(function()
                self:hide()
            end, self.duration)
        end
    end
    
    if self.onShow then
        self:onShow()
    end
    
    -- Add to widgets if not already added
    local found = false
    for _, widget in ipairs(widgets) do
        if widget == self then
            found = true
            break
        end
    end
    if not found then
        table.insert(widgets, self)
    end
end

function NotificationToast:hide()
    if not self.isHiding then
        if self.animateOut then
            self.isHiding = true
            self.isShowing = false
        else
            -- No animation - hide immediately
            self.visible = false
            self.isHiding = false
            self.isShowing = false
            
            -- Remove from widgets immediately
            for i, widget in ipairs(widgets) do
                if widget == self then
                    table.remove(widgets, i)
                    break
                end
            end
        end
        
        if self.onHide then
            self:onHide()
        end
    end
end

function NotificationToast:update()
    if not self.visible then return end
    
    local now = os.clock()
    local deltaTime = now - self.lastUpdate
    self.lastUpdate = now
    
    if self.isShowing then
        -- Animate in based on animation type
        if self.animationType == "fade" then
            self.opacity = math.min(1, self.opacity + deltaTime * self.fadeSpeed)
            if self.opacity >= 1 then
                self.isShowing = false
            end
        elseif self.animationType == "slide" then
            self.slideOffset = math.min(0, self.slideOffset + deltaTime * self.slideSpeed * self.height)
            if self.slideOffset >= 0 then
                self.isShowing = false
            end
        else -- "both"
            self.opacity = math.min(1, self.opacity + deltaTime * self.fadeSpeed)
            self.slideOffset = math.min(0, self.slideOffset + deltaTime * self.slideSpeed * self.height)
            if self.opacity >= 1 and self.slideOffset >= 0 then
                self.isShowing = false
            end
        end
        
        -- Start auto-hide timer when animation finishes
        if not self.isShowing and self.autoHide then
            PixelUI.setTimeout(function()
                self:hide()
            end, self.duration)
        end
        
    elseif self.isHiding then
        -- Animate out based on animation type
        if self.animationType == "fade" then
            self.opacity = math.max(0, self.opacity - deltaTime * self.fadeSpeed)
            if self.opacity <= 0 then
                self.visible = false
                self.isHiding = false
            end
        elseif self.animationType == "slide" then
            self.slideOffset = math.max(-self.height, self.slideOffset - deltaTime * self.slideSpeed * self.height)
            if self.slideOffset <= -self.height then
                self.visible = false
                self.isHiding = false
            end
        else -- "both"
            self.opacity = math.max(0, self.opacity - deltaTime * self.fadeSpeed)
            self.slideOffset = math.max(-self.height, self.slideOffset - deltaTime * self.slideSpeed * self.height)
            if self.opacity <= 0 then
                self.visible = false
                self.isHiding = false
            end
        end
        
        -- Remove from widgets when animation completes
        if not self.visible then
            for i, widget in ipairs(widgets) do
                if widget == self then
                    table.remove(widgets, i)
                    break
                end
            end
        end
    end
end

function NotificationToast:onClick(relX, relY)
    if self.closeable and relX == self.width and relY == 1 then
        -- Close button clicked
        self:hide()
    elseif self.onToastClick then
        -- Call user-provided click handler
        self:onToastClick(relX, relY)
    end
end

-- DataGrid Widget (Table)
local DataGrid = setmetatable({}, {__index = Widget})
DataGrid.__index = DataGrid

function DataGrid:new(props)
    local grid = Widget.new(self, props)
    grid.columns = props.columns or {}
    grid.data = props.data or {}
    grid.headers = props.headers or {}
    grid.showHeaders = props.showHeaders ~= false
    grid.headerHeight = grid.showHeaders and 1 or 0
    grid.rowHeight = props.rowHeight or 1
    grid.alternatingRows = props.alternatingRows ~= false
    grid.gridLines = props.gridLines ~= false
    grid.sortable = props.sortable ~= false
    grid.selectable = props.selectable ~= false
    grid.multiSelect = props.multiSelect or false
    grid.selectedRows = {}
    grid.sortColumn = nil
    grid.sortDirection = "asc" -- "asc" or "desc"
    grid.scrollOffsetX = 0
    grid.scrollOffsetY = 0
    grid.cellPadding = props.cellPadding or 1
    
    -- Colors
    grid.headerColor = props.headerColor or colors.lightGray
    grid.headerBackground = props.headerBackground or colors.gray
    grid.color = props.color or colors.white
    grid.background = props.background or colors.black
    grid.selectedColor = props.selectedColor or colors.black
    grid.selectedBackground = props.selectedBackground or colors.lightBlue
    grid.alternateBackground = props.alternateBackground or colors.gray
    grid.gridLineColor = props.gridLineColor or colors.lightGray
    
    -- Events
    grid.onRowSelect = props.onRowSelect
    grid.onRowDoubleClick = props.onRowDoubleClick
    grid.onSort = props.onSort
    grid.onCellClick = props.onCellClick
    
    -- Calculate column widths if not specified
    grid:calculateColumnWidths()
    
    return grid
end

function DataGrid:calculateColumnWidths()
    if #self.columns == 0 then
        -- Auto-generate columns from first data row
        if #self.data > 0 then
            local firstRow = self.data[1]
            if type(firstRow) == "table" then
                for key, value in pairs(firstRow) do
                    table.insert(self.columns, {
                        field = key,
                        title = key:sub(1,1):upper() .. key:sub(2),
                        width = math.max(#tostring(value), #key) + 2
                    })
                end
            end
        end
    end
    
    -- Auto-calculate widths if not specified
    for i, col in ipairs(self.columns) do
        if not col.width then
            local maxWidth = #(col.title or col.field or "")
            
            -- Check data for max width
            for _, row in ipairs(self.data) do
                local value = ""
                if type(row) == "table" then
                    value = tostring(row[col.field] or "")
                else
                    value = tostring(row[i] or "")
                end
                maxWidth = math.max(maxWidth, #value)
            end
            
            col.width = math.min(maxWidth + self.cellPadding * 2, 20)
        end
    end
end

function DataGrid:render()
    local absX, absY = self:getAbsolutePos()
    
    -- Draw headers
    if self.showHeaders then
        self:renderHeaders(absX, absY)
    end
    
    -- Draw data rows
    self:renderRows(absX, absY + self.headerHeight)
    
    -- Draw grid lines if enabled
    if self.gridLines then
        self:renderGridLines(absX, absY)
    end
    
    term.setBackgroundColor(colors.black)
end

function DataGrid:renderHeaders(absX, absY)
    local currentX = absX - self.scrollOffsetX
    
    term.setBackgroundColor(self.headerBackground)
    term.setTextColor(self.headerColor)
    
    -- Clear header row
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    for i, col in ipairs(self.columns) do
        if currentX + col.width > absX and currentX < absX + self.width then
            term.setCursorPos(math.max(currentX, absX), absY)
            
            local title = col.title or col.field or ""
            local displayWidth = math.min(col.width, absX + self.width - math.max(currentX, absX))
            
            -- Add sort indicator if this column is sorted
            if self.sortColumn == i then
                title = title .. (self.sortDirection == "asc" and "↑" or "↓")
            end
            
            local text = title:sub(1, displayWidth - self.cellPadding)
            text = text .. string.rep(" ", displayWidth - #text)
            term.write(text:sub(1, displayWidth))
        end
        currentX = currentX + col.width
    end
end

function DataGrid:renderRows(absX, absY)
    local visibleRows = self.height - self.headerHeight
    local startRow = self.scrollOffsetY + 1
    
    for row = 1, visibleRows do
        local dataIndex = startRow + row - 1
        if dataIndex <= #self.data then
            local rowY = absY + row - 1
            local isSelected = self:isRowSelected(dataIndex)
            local isAlternate = self.alternatingRows and (dataIndex % 2 == 0)
            
            -- Determine row background
            local rowBg = self.background
            if isSelected then
                rowBg = self.selectedBackground
            elseif isAlternate then
                rowBg = self.alternateBackground
            end
            
            -- Clear row
            term.setBackgroundColor(rowBg)
            term.setCursorPos(absX, rowY)
            term.write(string.rep(" ", self.width))
            
            -- Render cells
            self:renderRowCells(absX, rowY, dataIndex, isSelected)
        end
    end
end

function DataGrid:renderRowCells(absX, rowY, dataIndex, isSelected)
    local currentX = absX - self.scrollOffsetX
    local rowData = self.data[dataIndex]
    
    local textColor = isSelected and self.selectedColor or self.color
    term.setTextColor(textColor)
    
    for i, col in ipairs(self.columns) do
        if currentX + col.width > absX and currentX < absX + self.width then
            term.setCursorPos(math.max(currentX + self.cellPadding, absX), rowY)
            
            local value = ""
            if type(rowData) == "table" then
                value = tostring(rowData[col.field] or "")
            else
                value = tostring(rowData[i] or "")
            end
            
            local displayWidth = math.min(col.width - self.cellPadding * 2, 
                                        absX + self.width - math.max(currentX + self.cellPadding, absX))
            
            if displayWidth > 0 then
                local text = value:sub(1, displayWidth)
                term.write(text)
            end
        end
        currentX = currentX + col.width
    end
end

function DataGrid:renderGridLines(absX, absY)
    term.setTextColor(self.gridLineColor)
    
    -- Vertical lines
    local currentX = absX - self.scrollOffsetX
    for i, col in ipairs(self.columns) do
        currentX = currentX + col.width
        if currentX >= absX and currentX < absX + self.width then
            for y = 0, self.height - 1 do
                term.setCursorPos(currentX, absY + y)
                term.write("|")
            end
        end
    end
    
    -- Horizontal lines
    if self.showHeaders then
        -- Header separator
        term.setCursorPos(absX, absY + self.headerHeight)
        term.write(string.rep("-", self.width))
    end
end

function DataGrid:onClick(relX, relY)
    if not self.enabled then return end
    
    if self.showHeaders and relY == 1 then
        -- Header clicked - handle sorting
        self:handleHeaderClick(relX)
    elseif relY > self.headerHeight then
        -- Data row clicked
        self:handleRowClick(relX, relY)
    end
end

function DataGrid:handleHeaderClick(relX)
    if not self.sortable then return end
    
    local currentX = 1 - self.scrollOffsetX
    for i, col in ipairs(self.columns) do
        if relX >= currentX and relX < currentX + col.width then
            -- Toggle sort direction if same column, otherwise set to ascending
            if self.sortColumn == i then
                self.sortDirection = self.sortDirection == "asc" and "desc" or "asc"
            else
                self.sortColumn = i
                self.sortDirection = "asc"
            end
            
            self:sortData()
            break
        end
        currentX = currentX + col.width
    end
end

function DataGrid:handleRowClick(relX, relY)
    if not self.selectable then return end
    
    local rowIndex = self.scrollOffsetY + relY - self.headerHeight
    if rowIndex >= 1 and rowIndex <= #self.data then
        if self.multiSelect then
            -- Toggle selection
            if self:isRowSelected(rowIndex) then
                self:deselectRow(rowIndex)
            else
                self:selectRow(rowIndex)
            end
        else
            -- Single selection
            self.selectedRows = {rowIndex}
        end
        
        if self.onRowSelect then
            self:onRowSelect(rowIndex, self.data[rowIndex])
        end
    end
end

function DataGrid:sortData()
    if not self.sortColumn or not self.columns[self.sortColumn] then return end
    
    local field = self.columns[self.sortColumn].field
    local direction = self.sortDirection
    
    table.sort(self.data, function(a, b)
        local valueA, valueB
        
        if type(a) == "table" then
            valueA = a[field] or ""
        else
            valueA = a[self.sortColumn] or ""
        end
        
        if type(b) == "table" then
            valueB = b[field] or ""
        else
            valueB = b[self.sortColumn] or ""
        end
        
        -- Convert to strings for comparison
        valueA = tostring(valueA):lower()
        valueB = tostring(valueB):lower()
        
        if direction == "asc" then
            return valueA < valueB
        else
            return valueA > valueB
        end
    end)
    
    -- Clear selection after sort
    self.selectedRows = {}
    
    if self.onSort then
        self:onSort(self.sortColumn, direction)
    end
end

function DataGrid:isRowSelected(rowIndex)
    for _, selectedIndex in ipairs(self.selectedRows) do
        if selectedIndex == rowIndex then
            return true
        end
    end
    return false
end

function DataGrid:selectRow(rowIndex)
    if not self:isRowSelected(rowIndex) then
        table.insert(self.selectedRows, rowIndex)
    end
end

function DataGrid:deselectRow(rowIndex)
    for i, selectedIndex in ipairs(self.selectedRows) do
        if selectedIndex == rowIndex then
            table.remove(self.selectedRows, i)
            break
        end
    end
end

function DataGrid:handleScroll(x, y, direction)
    if not self.enabled or not self.visible then return false end
    
    local absX, absY = self:getAbsolutePos()
    local relX, relY = x - absX + 1, y - absY + 1
    
    if isPointInBounds(relX, relY, {x = 1, y = 1, width = self.width, height = self.height}) then
        local maxScrollY = math.max(0, #self.data - (self.height - self.headerHeight))
        
        if direction > 0 then
            self.scrollOffsetY = math.max(0, self.scrollOffsetY - 1)
        else
            self.scrollOffsetY = math.min(maxScrollY, self.scrollOffsetY + 1)
        end
        
        return true
    end
    
    return false
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

-- RichTextBox Widget (Multi-line text editing with formatting)
local RichTextBox = setmetatable({}, {__index = Widget})
RichTextBox.__index = RichTextBox

function RichTextBox:new(props)
    local richtext = Widget.new(self, props)
    richtext.lines = props.lines or {""}
    richtext.cursorX = props.cursorX or 1
    richtext.cursorY = props.cursorY or 1
    richtext.scrollX = 0
    richtext.scrollY = 0
    richtext.maxLines = props.maxLines or 1000
    richtext.wordWrap = props.wordWrap ~= false
    richtext.showLineNumbers = props.showLineNumbers or false
    richtext.tabSize = props.tabSize or 4
    richtext.onChange = props.onChange
    richtext.onCursorMove = props.onCursorMove
    richtext.readonly = props.readonly or false
    
    -- Formatting support
    richtext.formatting = props.formatting or {}
    richtext.allowFormatting = props.allowFormatting or false
    richtext.formatCodes = {
        ["&0"] = colors.white, ["&1"] = colors.orange, ["&2"] = colors.magenta,
        ["&3"] = colors.lightBlue, ["&4"] = colors.yellow, ["&5"] = colors.lime,
        ["&6"] = colors.pink, ["&7"] = colors.gray, ["&8"] = colors.lightGray,
        ["&9"] = colors.cyan, ["&a"] = colors.purple, ["&b"] = colors.blue,
        ["&c"] = colors.brown, ["&d"] = colors.green, ["&e"] = colors.red,
        ["&f"] = colors.black
    }
    
    -- Selection
    richtext.hasSelection = false
    richtext.selStartX = 1
    richtext.selStartY = 1
    richtext.selEndX = 1
    richtext.selEndY = 1
    
    return richtext
end

function RichTextBox:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Draw background
    term.setBackgroundColor(self.background or theme.textbox.background or colors.black)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw border if enabled
    if self.border then
        drawCharBorder(absX, absY, self.width, self.height, self.borderColor or theme.border or colors.gray, self.background or theme.textbox.background or colors.black)
    end
    
    -- Calculate content area
    local contentX = absX + (self.border and 1 or 0) + (self.showLineNumbers and 4 or 0)
    local contentY = absY + (self.border and 1 or 0)
    local contentWidth = self.width - (self.border and 2 or 0) - (self.showLineNumbers and 4 or 0)
    local contentHeight = self.height - (self.border and 2 or 0)
    
    -- Draw line numbers if enabled
    if self.showLineNumbers then
        term.setBackgroundColor(theme.surface or colors.gray)
        term.setTextColor(theme.textSecondary or colors.lightGray)
        for i = 1, contentHeight do
            local lineNum = i + self.scrollY
            term.setCursorPos(absX + (self.border and 1 or 0), contentY + i - 1)
            if lineNum <= #self.lines then
                local numStr = tostring(lineNum)
                term.write(string.rep(" ", 3 - #numStr) .. numStr)
            else
                term.write("   ")
            end
        end
    end
    
    -- Draw text content
    term.setBackgroundColor(self.background or theme.textbox.background or colors.black)
    term.setTextColor(self.color or theme.text or colors.white)
    
    for i = 1, contentHeight do
        local lineIndex = i + self.scrollY
        term.setCursorPos(contentX, contentY + i - 1)
        
        if lineIndex <= #self.lines then
            local line = self.lines[lineIndex] or ""
            local displayLine = line:sub(self.scrollX + 1, self.scrollX + contentWidth)
            
            if self.allowFormatting then
                self:renderFormattedLine(displayLine, contentX, contentY + i - 1)
            else
                term.write(displayLine .. string.rep(" ", math.max(0, contentWidth - #displayLine)))
            end
        else
            term.write(string.rep(" ", contentWidth))
        end
    end
    
    -- Draw cursor if focused
    if self.focused and not self.readonly then
        local cursorScreenX = contentX + self.cursorX - self.scrollX - 1
        local cursorScreenY = contentY + self.cursorY - self.scrollY - 1
        
        if cursorScreenX >= contentX and cursorScreenX < contentX + contentWidth and
           cursorScreenY >= contentY and cursorScreenY < contentY + contentHeight then
            term.setCursorPos(cursorScreenX, cursorScreenY)
            term.setBackgroundColor(self.color or theme.text or colors.white)
            term.setTextColor(self.background or theme.textbox.background or colors.black)
            
            local currentLine = self.lines[self.cursorY] or ""
            local cursorChar = currentLine:sub(self.cursorX, self.cursorX)
            term.write(cursorChar ~= "" and cursorChar or " ")
        end
    end
    
    -- Draw scrollbar if content is larger than visible area
    if #self.lines > contentHeight then
        local scrollbarX = absX + self.width - 1
        local scrollbarHeight = contentHeight
        local maxScrollY = math.max(0, #self.lines - contentHeight)
        
        -- Draw scrollbar background
        term.setBackgroundColor(colors.lightGray)
        for i = 0, scrollbarHeight - 1 do
            term.setCursorPos(scrollbarX, contentY + i)
            term.write(" ")
        end
        
        -- Draw scrollbar thumb
        if maxScrollY > 0 then
            local thumbHeight = math.max(1, math.floor(scrollbarHeight * contentHeight / #self.lines))
            local thumbPos = math.floor(scrollbarHeight * self.scrollY / maxScrollY)
            thumbPos = math.min(thumbPos, scrollbarHeight - thumbHeight)
            
            term.setBackgroundColor(colors.gray)
            for i = 0, thumbHeight - 1 do
                term.setCursorPos(scrollbarX, contentY + thumbPos + i)
                term.write(" ")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function RichTextBox:renderFormattedLine(line, x, y)
    local currentX = x
    local currentColor = self.color or colors.white
    local i = 1
    
    while i <= #line do
        local char = line:sub(i, i)
        
        if char == "&" and i < #line then
            local formatCode = line:sub(i, i + 1)
            if self.formatCodes[formatCode] then
                currentColor = self.formatCodes[formatCode]
                term.setTextColor(currentColor)
                i = i + 2
                goto continue
            end
        end
        
        term.setCursorPos(currentX, y)
        term.write(char)
        currentX = currentX + 1
        i = i + 1
        
        ::continue::
    end
end

function RichTextBox:insertText(text)
    if self.readonly then return end
    
    local currentLine = self.lines[self.cursorY] or ""
    local before = currentLine:sub(1, self.cursorX - 1)
    local after = currentLine:sub(self.cursorX)
    
    -- Handle newlines
    if text == "\n" then
        -- Simple newline insertion
        self.lines[self.cursorY] = before
        table.insert(self.lines, self.cursorY + 1, after)
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
    elseif text:find("\n") then
        -- Handle multiple lines (paste)
        local lines = {}
        for line in text:gmatch("[^\n]*") do
            table.insert(lines, line)
        end
        
        self.lines[self.cursorY] = before .. lines[1]
        for i = 2, #lines do
            table.insert(self.lines, self.cursorY + i - 1, lines[i] .. (i == #lines and after or ""))
        end
        
        self.cursorY = self.cursorY + #lines - 1
        self.cursorX = #lines[#lines] + 1
        if #lines == 1 then
            self.cursorX = self.cursorX + #before
        end
    else
        -- Regular text insertion
        self.lines[self.cursorY] = before .. text .. after
        self.cursorX = self.cursorX + #text
    end
    
    self:ensureCursorVisible()
    if self.onChange then
        self:onChange(self.lines, self.cursorX, self.cursorY)
    end
end

function RichTextBox:ensureCursorVisible()
    local contentWidth = self.width - (self.border and 2 or 0) - (self.showLineNumbers and 4 or 0)
    local contentHeight = self.height - (self.border and 2 or 0)
    
    -- Horizontal scrolling
    if self.cursorX <= self.scrollX then
        self.scrollX = math.max(0, self.cursorX - 1)
    elseif self.cursorX > self.scrollX + contentWidth then
        self.scrollX = self.cursorX - contentWidth
    end
    
    -- Vertical scrolling
    if self.cursorY <= self.scrollY then
        self.scrollY = math.max(0, self.cursorY - 1)
    elseif self.cursorY > self.scrollY + contentHeight then
        self.scrollY = self.cursorY - contentHeight
    end
end

function RichTextBox:onClick(relX, relY)
    if not self.enabled then return false end
    
    self:setFocus()
    
    local contentX = (self.border and 1 or 0) + (self.showLineNumbers and 4 or 0)
    local contentY = (self.border and 1 or 0)
    local contentHeight = self.height - (self.border and 2 or 0)
    local scrollbarX = self.width - 1
    
    -- Check if clicked on scrollbar
    if relX == scrollbarX and #self.lines > contentHeight then
        local maxScrollY = math.max(0, #self.lines - contentHeight)
        local clickPosY = relY - contentY
        
        if clickPosY >= 0 and clickPosY < contentHeight then
            -- Calculate scroll position based on click position
            local scrollRatio = clickPosY / contentHeight
            self.scrollY = math.floor(scrollRatio * maxScrollY)
            self.scrollY = math.max(0, math.min(maxScrollY, self.scrollY))
        end
        
        return true
    end
    
    -- Handle content area click
    if relX > contentX and relY > contentY then
        local clickX = relX - contentX + self.scrollX
        local clickY = relY - contentY + self.scrollY
        
        if clickY >= 1 and clickY <= #self.lines then
            self.cursorY = clickY
            local line = self.lines[clickY] or ""
            self.cursorX = math.min(clickX, #line + 1)
            
            if self.onCursorMove then
                self:onCursorMove(self.cursorX, self.cursorY)
            end
        end
    end
    
    return true
end

function RichTextBox:handleKey(key)
    if not self.enabled or not self.focused or self.readonly then return false end
    
    local contentHeight = self.height - (self.border and 2 or 0)
    local contentWidth = self.width - (self.border and 2 or 0) - (self.showLineNumbers and 4 or 0)
    
    -- Check for Ctrl key combinations
    local isCtrlHeld = false
    -- Note: In CC:Tweaked, we can't easily detect Ctrl state, so we'll use different key combinations
    
    if key == keys.up then
        if self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            local line = self.lines[self.cursorY] or ""
            self.cursorX = math.min(self.cursorX, #line + 1)
            self:ensureCursorVisible()
        end
        return true
    elseif key == keys.down then
        if self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            local line = self.lines[self.cursorY] or ""
            self.cursorX = math.min(self.cursorX, #line + 1)
            self:ensureCursorVisible()
        end
        return true
    elseif key == keys.left then
        if self.cursorX > 1 then
            self.cursorX = self.cursorX - 1
            self:ensureCursorVisible()
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            local line = self.lines[self.cursorY] or ""
            self.cursorX = #line + 1
            self:ensureCursorVisible()
        end
        return true
    elseif key == keys.right then
        local line = self.lines[self.cursorY] or ""
        if self.cursorX <= #line then
            self.cursorX = self.cursorX + 1
            self:ensureCursorVisible()
        elseif self.cursorY < #self.lines then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
            self:ensureCursorVisible()
        end
        return true
    elseif key == keys.pageUp then
        self.cursorY = math.max(1, self.cursorY - contentHeight)
        local line = self.lines[self.cursorY] or ""
        self.cursorX = math.min(self.cursorX, #line + 1)
        self:ensureCursorVisible()
        return true
    elseif key == keys.pageDown then
        self.cursorY = math.min(#self.lines, self.cursorY + contentHeight)
        local line = self.lines[self.cursorY] or ""
        self.cursorX = math.min(self.cursorX, #line + 1)
        self:ensureCursorVisible()
        return true
    elseif key == keys.home then
        self.cursorX = 1
        self:ensureCursorVisible()
        return true
    elseif key == keys["end"] then
        local line = self.lines[self.cursorY] or ""
        self.cursorX = #line + 1
        self:ensureCursorVisible()
        return true
    elseif key == keys.leftCtrl or key == keys.rightCtrl then
        -- Store ctrl state for next key press combinations
        -- Since CC:Tweaked doesn't have easy multi-key detection, we'll add alternative shortcuts
        return false -- Let other handlers process this
    elseif key == keys.f2 then
        -- F2: Go to top of document
        self.cursorY = 1
        self.cursorX = 1
        self:ensureCursorVisible()
        return true
    elseif key == keys.f3 then
        -- F3: Go to bottom of document
        self.cursorY = #self.lines
        local line = self.lines[self.cursorY] or ""
        self.cursorX = #line + 1
        self:ensureCursorVisible()
        return true
    elseif key == keys.f4 then
        -- F4: Scroll left (horizontal)
        self.scrollX = math.max(0, self.scrollX - 5)
        return true
    elseif key == keys.f5 then
        -- F5: Scroll right (horizontal)
        local maxScrollX = math.max(0, self:getMaxLineLength() - contentWidth)
        self.scrollX = math.min(maxScrollX, self.scrollX + 5)
        return true
    elseif key == keys.enter then
        self:insertText("\n")
        return true
    elseif key == keys.backspace then
        if self.cursorX > 1 then
            local line = self.lines[self.cursorY] or ""
            self.lines[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            local currentLine = self.lines[self.cursorY] or ""
            local prevLine = self.lines[self.cursorY - 1] or ""
            self.lines[self.cursorY - 1] = prevLine .. currentLine
            table.remove(self.lines, self.cursorY)
            self.cursorY = self.cursorY - 1
            self.cursorX = #prevLine + 1
        end
        self:ensureCursorVisible()
        if self.onChange then
            self:onChange(self.lines, self.cursorX, self.cursorY)
        end
        return true
    elseif key == keys.tab then
        self:insertText(string.rep(" ", self.tabSize))
        return true
    end
    
    return false
end

function RichTextBox:handleScroll(x, y, direction)
    if not self.enabled or not self.visible then return false end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Check if scroll event is within widget bounds
    if x >= absX and x < absX + self.width and y >= absY and y < absY + self.height then
        local scrollAmount = 3 -- Number of lines to scroll per wheel tick
        local contentHeight = self.height - (self.border and 2 or 0)
        local maxScrollY = math.max(0, #self.lines - contentHeight)
        
        if direction == -1 then -- Scroll up
            self.scrollY = math.max(0, self.scrollY - scrollAmount)
        elseif direction == 1 then -- Scroll down
            self.scrollY = math.min(maxScrollY, self.scrollY + scrollAmount)
        end
        
        return true
    end
    
    return false
end

function RichTextBox:scrollToLine(lineNumber)
    if lineNumber < 1 then lineNumber = 1 end
    if lineNumber > #self.lines then lineNumber = #self.lines end
    
    local contentHeight = self.height - (self.border and 2 or 0)
    self.scrollY = math.max(0, lineNumber - math.floor(contentHeight / 2))
    
    local maxScrollY = math.max(0, #self.lines - contentHeight)
    self.scrollY = math.min(self.scrollY, maxScrollY)
end

function RichTextBox:scrollBy(lines)
    local contentHeight = self.height - (self.border and 2 or 0)
    local maxScrollY = math.max(0, #self.lines - contentHeight)
    
    self.scrollY = math.max(0, math.min(maxScrollY, self.scrollY + lines))
end

function RichTextBox:scrollToTop()
    self.scrollY = 0
end

function RichTextBox:scrollToBottom()
    local contentHeight = self.height - (self.border and 2 or 0)
    self.scrollY = math.max(0, #self.lines - contentHeight)
end

function RichTextBox:getMaxLineLength()
    local maxLength = 0
    for i = 1, #self.lines do
        local line = self.lines[i] or ""
        maxLength = math.max(maxLength, #line)
    end
    return maxLength
end

function RichTextBox:handleChar(char)
    if not self.enabled or not self.focused or self.readonly then return false end
    
    self:insertText(char)
    return true
end

function RichTextBox:getText()
    return table.concat(self.lines, "\n")
end

function RichTextBox:setText(text)
    self.lines = {}
    for line in text:gmatch("[^\n]*") do
        table.insert(self.lines, line)
    end
    if #self.lines == 0 then
        self.lines = {""}
    end
    self.cursorX = 1
    self.cursorY = 1
    self.scrollX = 0
    self.scrollY = 0
end

-- CodeEditor Widget (Syntax-highlighted code editing)
local CodeEditor = setmetatable({}, {__index = RichTextBox})
CodeEditor.__index = CodeEditor

function CodeEditor:new(props)
    local editor = RichTextBox.new(self, props)
    editor.language = props.language or "lua"
    editor.showLineNumbers = true
    editor.syntaxHighlight = props.syntaxHighlight ~= false
    editor.autoIndent = props.autoIndent ~= false
    editor.matchBrackets = props.matchBrackets ~= false
    editor.autoComplete = props.autoComplete ~= false
    editor.autoPairing = props.autoPairing ~= false  -- Auto-pairing enabled by default
    
    -- Auto-completion state
    editor.completionVisible = false
    editor.completionPrefix = ""
    editor.completionOptions = {}
    editor.completionSelected = 1
    editor.completionScroll = 1  -- Index of first option displayed in popup
    editor.completionScroll = 1  -- First visible option index in popup
    editor.completionStartX = 0
    editor.completionStartY = 0
    editor.maxCompletionHeight = props.maxCompletionHeight or 8
    editor.maxCompletionWidth = props.maxCompletionWidth or 30
    editor.completionBorder = props.completionBorder ~= false  -- Border enabled by default
    editor.completionBorderColor = props.completionBorderColor or colors.gray
    editor.completionBgColor = props.completionBgColor or colors.lightGray
    editor.completionSelectedBgColor = props.completionSelectedBgColor or colors.blue
    editor.completionTextColor = props.completionTextColor or colors.black
    editor.completionSelectedTextColor = props.completionSelectedTextColor or colors.white
    
    -- Lua syntax highlighting
    editor.keywords = {
        ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
        ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
        ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
        ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
        ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
        ["while"] = true
    }
    
    -- Auto-completion dictionaries
    editor.completionSources = {
        keywords = {
            "and", "break", "do", "else", "elseif", "end", "false", "for",
            "function", "if", "in", "local", "nil", "not", "or", "repeat",
            "return", "then", "true", "until", "while"
        },
        builtins = {
            "print", "error", "assert", "type", "tostring", "tonumber",
            "pairs", "ipairs", "next", "pcall", "xpcall", "getmetatable", "setmetatable",
            "rawget", "rawset", "rawlen", "select", "unpack", "pack"
        },
        string_methods = {
            "byte", "char", "dump", "find", "format", "gmatch", "gsub",
            "len", "lower", "match", "rep", "reverse", "sub", "upper"
        },
        table_methods = {
            "concat", "insert", "maxn", "remove", "sort", "unpack"
        },
        math_methods = {
            "abs", "acos", "asin", "atan", "atan2", "ceil", "cos", "cosh",
            "deg", "exp", "floor", "fmod", "frexp", "huge", "ldexp", "log",
            "log10", "max", "min", "modf", "pi", "pow", "rad", "random",
            "randomseed", "sin", "sinh", "sqrt", "tan", "tanh"
        },
        cc_apis = {
            "term", "colors", "fs", "os", "redstone", "peripheral", "turtle",
            "http", "textutils", "vector", "bit", "bit32", "coroutine",
            "paintutils", "parallel", "keys", "window", "multishell", "gps"
        }
    }
    
    return editor
end

function CodeEditor:render()
    -- Use parent render but with syntax highlighting
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Draw background
    term.setBackgroundColor(colors.black)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw border
    if self.border then
        drawCharBorder(absX, absY, self.width, self.height, colors.gray, colors.black)
    end
    
    -- Calculate content area (account for scrollbar if needed)
    local needsScrollbar = #self.lines > (self.height - (self.border and 2 or 0))
    local contentX = absX + (self.border and 1 or 0) + 4 -- Always show line numbers
    local contentY = absY + (self.border and 1 or 0)
    local contentWidth = self.width - (self.border and 2 or 0) - 4 - (needsScrollbar and 1 or 0)
    local contentHeight = self.height - (self.border and 2 or 0)
    
    -- Draw line numbers
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    for i = 1, contentHeight do
        local lineNum = i + self.scrollY
        term.setCursorPos(absX + (self.border and 1 or 0), contentY + i - 1)
        if lineNum <= #self.lines then
            local numStr = tostring(lineNum)
            term.write(string.rep(" ", 3 - #numStr) .. numStr)
        else
            term.write("   ")
        end
    end
    
    -- Draw code with syntax highlighting
    for i = 1, contentHeight do
        local lineIndex = i + self.scrollY
        if lineIndex <= #self.lines then
            local line = self.lines[lineIndex] or ""
            local displayLine = line:sub(self.scrollX + 1, self.scrollX + contentWidth)
            self:renderSyntaxHighlightedLine(displayLine, contentX, contentY + i - 1)
        end
    end
    
    -- Draw cursor
    if self.focused and not self.readonly then
        local cursorScreenX = contentX + self.cursorX - self.scrollX - 1
        local cursorScreenY = contentY + self.cursorY - self.scrollY - 1
        
        if cursorScreenX >= contentX and cursorScreenX < contentX + contentWidth and
           cursorScreenY >= contentY and cursorScreenY < contentY + contentHeight then
            term.setCursorPos(cursorScreenX, cursorScreenY)
            term.setBackgroundColor(colors.white)
            term.setTextColor(colors.black)
            
            local currentLine = self.lines[self.cursorY] or ""
            local cursorChar = currentLine:sub(self.cursorX, self.cursorX)
            term.write(cursorChar ~= "" and cursorChar or " ")
        end
    end
    
    -- Draw vertical scrollbar if content is larger than visible area
    if needsScrollbar then
        local scrollbarX = absX + self.width - 1
        local scrollbarHeight = contentHeight
        local maxScrollY = math.max(0, #self.lines - contentHeight)
        
        -- Draw scrollbar background
        term.setBackgroundColor(colors.lightGray)
        for i = 0, scrollbarHeight - 1 do
            term.setCursorPos(scrollbarX, contentY + i)
            term.write(" ")
        end
        
        -- Draw scrollbar thumb
        if maxScrollY > 0 then
            local thumbHeight = math.max(1, math.floor(scrollbarHeight * contentHeight / #self.lines))
            local thumbPos = math.floor(scrollbarHeight * self.scrollY / maxScrollY)
            thumbPos = math.min(thumbPos, scrollbarHeight - thumbHeight)
            
            term.setBackgroundColor(colors.gray)
            for i = 0, thumbHeight - 1 do
                term.setCursorPos(scrollbarX, contentY + thumbPos + i)
                term.write(" ")
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function CodeEditor:renderSyntaxHighlightedLine(line, x, y)
    term.setCursorPos(x, y)
    term.setBackgroundColor(colors.black)
    
    if not self.syntaxHighlight then
        term.setTextColor(colors.white)
        term.write(line)
        return
    end
    
    -- Simple Lua syntax highlighting
    local i = 1
    while i <= #line do
        local char = line:sub(i, i)
        
        -- Comments
        if line:sub(i, i + 1) == "--" then
            term.setTextColor(colors.green)
            term.write(line:sub(i))
            break
        end
        
        -- Strings
        if char == '"' or char == "'" then
            local quote = char
            term.setTextColor(colors.yellow)
            term.write(char)
            i = i + 1
            
            while i <= #line do
                char = line:sub(i, i)
                term.write(char)
                if char == quote then
                    i = i + 1
                    break
                end
                i = i + 1
            end
            goto continue
        end
        
        -- Numbers
        if char:match("%d") then
            term.setTextColor(colors.cyan)
            while i <= #line and line:sub(i, i):match("[%d%.]") do
                term.write(line:sub(i, i))
                i = i + 1
            end
            goto continue
        end
        
        -- Keywords and identifiers
        if char:match("[%a_]") then
            local word = ""
            local startI = i
            while i <= #line and line:sub(i, i):match("[%w_]") do
                word = word .. line:sub(i, i)
                i = i + 1
            end
            
            if self.keywords[word] then
                term.setTextColor(colors.purple)
            else
                term.setTextColor(colors.white)
            end
            
            term.write(word)
            goto continue
        end
        
        -- Default color for symbols
        term.setTextColor(colors.lightGray)
        term.write(char)
        i = i + 1
        
        ::continue::
    end
end

-- Auto-completion methods for CodeEditor
function CodeEditor:showAutoCompletion()
    if not self.autoComplete then return end
    
    
    local currentLine = self.lines[self.cursorY] or ""
    local beforeCursor = currentLine:sub(1, self.cursorX - 1)
    
    -- Find the current word being typed
    local wordStart = 1
    for i = self.cursorX - 1, 1, -1 do
        local char = beforeCursor:sub(i, i)
        if not char:match("[%w_]") then
            wordStart = i + 1
            break
        end
    end
    
    self.completionPrefix = beforeCursor:sub(wordStart)
    
    -- Always show at least some basic completions for testing
    self.completionOptions = {}
    
    -- Add some basic test completions
    local testCompletions = {"function", "local", "if", "then", "end", "for", "while", "do"}
    for _, item in ipairs(testCompletions) do
        if #self.completionPrefix == 0 or item:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
            table.insert(self.completionOptions, {
                text = item,
                category = "test",
                display = item .. " (test)"
            })
        end
    end
    
    -- Safely add completion options with nil checks
    if self.completionSources then
        if self.completionSources.keywords then
            self:addCompletionOptions(self.completionSources.keywords, "keyword")
        end
        if self.completionSources.builtins then
            self:addCompletionOptions(self.completionSources.builtins, "builtin")
        end
        
        -- Context-aware completions
        if beforeCursor:match("string%.%w*$") and self.completionSources.string_methods then
            self:addCompletionOptions(self.completionSources.string_methods, "method")
        elseif beforeCursor:match("table%.%w*$") and self.completionSources.table_methods then
            self:addCompletionOptions(self.completionSources.table_methods, "method")
        elseif beforeCursor:match("math%.%w*$") and self.completionSources.math_methods then
            self:addCompletionOptions(self.completionSources.math_methods, "method")
        elseif self.completionSources.cc_apis then
            self:addCompletionOptions(self.completionSources.cc_apis, "api")
        end
    end
    
    -- Add variables from current scope
    self:addVariableCompletions()
    
    -- Sort by relevance (exact prefix match first, then alphabetical)
    table.sort(self.completionOptions, function(a, b)
        local aExact = a.text:sub(1, #self.completionPrefix):lower() == self.completionPrefix:lower()
        local bExact = b.text:sub(1, #self.completionPrefix):lower() == self.completionPrefix:lower()
        
        if aExact ~= bExact then
            return aExact
        end
        return a.text < b.text
    end)
    
    if #self.completionOptions > 0 then
        self.completionVisible = true
        self.completionSelected = 1
        self.completionScroll = 1
        self.completionStartX = wordStart
        self.completionStartY = self.cursorY
    else
        self:hideAutoCompletion()
    end
end

function CodeEditor:addCompletionOptions(source, category)
    if not source then return end
    
    for _, item in ipairs(source) do
        if item and item:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
            table.insert(self.completionOptions, {
                text = item,
                category = category,
                display = item .. " (" .. category .. ")"
            })
        end
    end
end

function CodeEditor:addVariableCompletions()
    -- Extract variable names from current file
    local variables = {}
    
    for lineNum, line in ipairs(self.lines) do
        -- Find local variable declarations
        for var in line:gmatch("local%s+([%w_]+)") do
            if var:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
                variables[var] = true
            end
        end
        
        -- Find function parameters
        for params in line:gmatch("function[^%(]*%(([^%)]*)%)") do
            for param in params:gmatch("([%w_]+)") do
                if param:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
                    variables[param] = true
                end
            end
        end
        
        -- Find assignments
        for var in line:gmatch("([%w_]+)%s*=") do
            if var:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
                variables[var] = true
            end
        end
    end
    
    for var, _ in pairs(variables) do
        table.insert(self.completionOptions, {
            text = var,
            category = "variable",
            display = var .. " (variable)"
        })
    end
end

function CodeEditor:hideAutoCompletion()
    self.completionVisible = false
    self.completionOptions = {}
    self.completionSelected = 1
end

function CodeEditor:selectCompletion(direction)
    if not self.completionVisible or #self.completionOptions == 0 then return end
    
    self.completionSelected = self.completionSelected + direction
    local total = #self.completionOptions
    if self.completionSelected < 1 then
        self.completionSelected = total
    elseif self.completionSelected > total then
        self.completionSelected = 1
    end
    -- Adjust scroll so selected is visible
    local maxHeight = math.min(total, self.maxCompletionHeight)
    if self.completionSelected < self.completionScroll then
        self.completionScroll = self.completionSelected
    elseif self.completionSelected >= self.completionScroll + maxHeight then
        self.completionScroll = self.completionSelected - maxHeight + 1
    end
end

function CodeEditor:insertCompletion()
    if not self.completionVisible or #self.completionOptions == 0 then return false end
    
    local completion = self.completionOptions[self.completionSelected]
    local currentLine = self.lines[self.cursorY] or ""
    
    -- Replace the prefix with the completion
    local beforePrefix = currentLine:sub(1, self.completionStartX - 1)
    local afterCursor = currentLine:sub(self.cursorX)
    local newLine = beforePrefix .. completion.text .. afterCursor
    
    self.lines[self.cursorY] = newLine
    self.cursorX = self.completionStartX + #completion.text
    
    self:hideAutoCompletion()
    return true
end

function CodeEditor:renderAutoCompletion()
    if not self.completionVisible or #self.completionOptions == 0 then return end
    
    local absX, absY = self:getAbsolutePos()
    local contentX = absX + (self.border and 1 or 0) + 4 -- Account for line numbers
    local contentY = absY + (self.border and 1 or 0)
    
    -- Calculate completion popup position
    local popupX = contentX + self.completionStartX - self.scrollX - 1
    local popupY = contentY + self.completionStartY - self.scrollY
    
    -- Calculate popup dimensions
    local maxWidth = math.min(self.maxCompletionWidth, 40)
    local total = #self.completionOptions
    local maxHeight = math.min(total, self.maxCompletionHeight)
    
    -- Calculate actual content width based on longest option
    local contentWidth = 0
    for i = 1, #self.completionOptions do
        contentWidth = math.max(contentWidth, #self.completionOptions[i].text)
    end
    contentWidth = math.min(contentWidth + 2, maxWidth) -- Add padding
    
    -- Calculate total dimensions including border
    local totalWidth = self.completionBorder and (contentWidth + 2) or contentWidth
    local totalHeight = self.completionBorder and (maxHeight + 2) or maxHeight
    
    -- Adjust if popup would go off screen
    local termWidth, termHeight = term.getSize()
    
    if popupX + totalWidth > termWidth then
        popupX = termWidth - totalWidth
    end
    if popupY + totalHeight > termHeight then
        popupY = popupY - totalHeight - 1
    end
    
    -- Ensure popup is within bounds
    popupX = math.max(1, popupX)
    popupY = math.max(1, popupY)
    
    if self.completionBorder then
        -- Draw border using drawCharBorder
        drawCharBorder(
            popupX, popupY,
            totalWidth, totalHeight,
            self.completionBorderColor or colors.gray,
            self.completionBgColor or colors.lightGray
        )
        
        -- Draw completion options inside border
        local innerX = popupX + 1
        local innerY = popupY + 1
        
        for i = 1, maxHeight do
            local idx = self.completionScroll + i - 1
            if idx <= total then
                local option = self.completionOptions[idx]
                local isSelected = (idx == self.completionSelected)
                
                term.setCursorPos(innerX, innerY + i - 1)
                
                if isSelected then
                    term.setBackgroundColor(self.completionSelectedBgColor or colors.blue)
                    term.setTextColor(self.completionSelectedTextColor or colors.white)
                else
                    term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                    term.setTextColor(self.completionTextColor or colors.black)
                end
                
                -- Truncate text if too long and fully pad to fill interior width
                local displayText = option.text
                local availableWidth = contentWidth - 2
                if #displayText > availableWidth then
                    displayText = displayText:sub(1, availableWidth - 3) .. "..."
                end
                -- Build padded text with one space margin on both sides to match contentWidth
                -- Pad with one space on the left and fill the rest
                local paddedText = " " .. displayText .. string.rep(" ", availableWidth - #displayText)
                term.write(paddedText)
                -- Draw scrollbar cell at the right interior column
                local scrollbarX = popupX + totalWidth - 2
                local rowY = innerY + i - 1
                term.setCursorPos(scrollbarX, rowY)
                if total > maxHeight then
                    local maxScroll = total - maxHeight
                    local thumbHeight = math.max(1, math.floor(maxHeight * maxHeight / total))
                    local thumbPos = math.floor(((self.completionScroll - 1) / maxScroll) * (maxHeight - thumbHeight))
                    local isThumb = (i - 1 >= thumbPos and i - 1 < thumbPos + thumbHeight)
                    term.setBackgroundColor(isThumb and (self.completionSelectedBgColor or colors.blue)
                        or (self.completionBgColor or colors.lightGray))
                else
                    term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                end
                term.write(" ")
            else
                -- Fill empty rows completely within the interior
                term.setCursorPos(innerX, innerY + i - 1)
                term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                term.write(string.rep(" ", contentWidth))
                -- Draw empty scrollbar cell
                local scrollbarX = popupX + totalWidth - 2
                local rowY = innerY + i - 1
                term.setCursorPos(scrollbarX, rowY)
                term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                term.write(" ")
            end
        end
    else
        -- Draw without border
        for i = 1, maxHeight do
            if i <= #self.completionOptions then
                local option = self.completionOptions[i]
                local isSelected = (i == self.completionSelected)
                
                term.setCursorPos(popupX, popupY + i - 1)
                
                if isSelected then
                    term.setBackgroundColor(self.completionSelectedBgColor or colors.blue)
                    term.setTextColor(self.completionSelectedTextColor or colors.white)
                else
                    term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                    term.setTextColor(self.completionTextColor or colors.black)
                end
                
                -- Truncate text if too long
                local displayText = option.text
                if #displayText > contentWidth - 2 then
                    displayText = displayText:sub(1, contentWidth - 5) .. "..."
                end
                
                -- Write text with proper spacing
                local paddedText = " " .. displayText
                local remainingSpace = contentWidth - #displayText - 1
                if remainingSpace > 0 then
                    paddedText = paddedText .. string.rep(" ", remainingSpace)
                end
                
                term.write(paddedText)
            else
                -- Fill empty rows
                term.setCursorPos(popupX, popupY + i - 1)
                term.setBackgroundColor(self.completionBgColor or colors.lightGray)
                term.write(string.rep(" ", contentWidth))
            end
        end
    end
end

-- Key handling for auto-completion
function CodeEditor:handleKey(key)
    -- Handle auto-completion navigation
    if self.completionVisible then
        if key == keys.up then
            self:selectCompletion(-1)
            return true
        elseif key == keys.down then
            self:selectCompletion(1)
            return true
        elseif key == keys.enter or key == keys.tab then
            return self:insertCompletion()
        elseif key == keys.escape then
            self:hideAutoCompletion()
            return true
        end
    end
    
    -- Handle special auto-completion triggers
    -- Try both space+ctrl and just F1 as alternative trigger
    if (key == keys.space and term.current().isColor and term.current().isColor()) or key == keys.f1 then
        self:showAutoCompletion()
        return true
    end
    
    -- Handle smart deletion for auto-paired characters
    if key == keys.backspace and self:handleSmartDeletion() then
        return true
    end
    
    -- Call parent handler
    local result = RichTextBox.handleKey(self, key)
    
    -- Hide completion on navigation keys (but not if we just handled completion)
    if not self.completionVisible and (key == keys.left or key == keys.right or 
                                     key == keys.up or key == keys.down or
                                     key == keys.home or key == keys["end"] or
                                     key == keys.pageUp or key == keys.pageDown) then
        self:hideAutoCompletion()
    -- Disable auto-completion trigger on backspace/delete to avoid unwanted popups
    -- elseif key == keys.backspace or key == keys.delete then
    --     if self.autoComplete then
    --         self:showAutoCompletion()
    --     end
    end
    
    return result
end

function CodeEditor:handleSmartDeletion()
    -- Check if smart deletion is enabled
    if not self.autoPairing then
        return false
    end
    
    -- Only handle if cursor is not at start of line
    if self.cursorX <= 1 then
        return false
    end
    
    local currentLine = self.lines[self.cursorY] or ""
    local charBeforeCursor = currentLine:sub(self.cursorX - 1, self.cursorX - 1)
    local charAtCursor = currentLine:sub(self.cursorX, self.cursorX)
    
    -- Define pairs for smart deletion
    local pairs = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        ['"'] = '"',
        ["'"] = "'"
    }
    
    -- Check if we have a pair that should be deleted together
    if pairs[charBeforeCursor] and charAtCursor == pairs[charBeforeCursor] then
        -- Delete both the opening and closing characters
        local before = currentLine:sub(1, self.cursorX - 2)
        local after = currentLine:sub(self.cursorX + 1)
        
        self.lines[self.cursorY] = before .. after
        self.cursorX = self.cursorX - 1
        
        self:ensureCursorVisible()
        if self.onChange then
            self:onChange(self.lines, self.cursorX, self.cursorY)
        end
        
        return true
    end
    
    return false
end

-- Mouse-wheel scroll for both main editor and autocomplete popup
function CodeEditor:handleScroll(x, y, direction)
    if not self.enabled or not self.visible then return false end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Check if scroll event is within widget bounds
    if x >= absX and x < absX + self.width and y >= absY and y < absY + self.height then
        -- First check if we're scrolling in auto-completion popup
        if self.completionVisible and #self.completionOptions > 0 then
            -- Compute popup position and size (same logic as renderAutoCompletion)
            local contentX = absX + (self.border and 1 or 0) + 4
            local contentY = absY + (self.border and 1 or 0)
            local maxHeight = math.min(#self.completionOptions, self.maxCompletionHeight)
            local contentWidth = 0
            for i, opt in ipairs(self.completionOptions) do 
                contentWidth = math.max(contentWidth, #opt.text) 
            end
            local totalWidth = self.completionBorder and (math.min(contentWidth + 2, self.maxCompletionWidth) + 2)
                or math.min(contentWidth + 2, self.maxCompletionWidth)
            local totalHeight = self.completionBorder and (maxHeight + 2) or maxHeight
            local popupX = contentX + self.completionStartX - self.scrollX - 1
            local popupY = contentY + self.completionStartY - self.scrollY
            
            -- Adjust bounds
            local termW, termH = term.getSize()
            if popupX + totalWidth > termW then popupX = termW - totalWidth end
            if popupY + totalHeight > termH then popupY = popupY - totalHeight - 1 end
            popupX = math.max(1, popupX); popupY = math.max(1, popupY)
            
            -- Check if within popup
            if x >= popupX and x < popupX + totalWidth and y >= popupY and y < popupY + totalHeight then
                -- Scroll the auto-completion list
                local total = #self.completionOptions
                local maxScroll = total - maxHeight
                if direction == -1 then -- wheel up
                    self.completionScroll = math.max(1, self.completionScroll - 1)
                elseif direction == 1 then -- wheel down
                    self.completionScroll = math.min(math.max(1, maxScroll + 1), self.completionScroll + 1)
                end
                return true
            end
        end
        
        -- Otherwise, scroll the main editor content
        local scrollAmount = 3 -- Number of lines to scroll per wheel tick
        local contentHeight = self.height - (self.border and 2 or 0)
        local maxScrollY = math.max(0, #self.lines - contentHeight)
        
        if direction == -1 then -- Scroll up
            self.scrollY = math.max(0, self.scrollY - scrollAmount)
        elseif direction == 1 then -- Scroll down
            self.scrollY = math.min(maxScrollY, self.scrollY + scrollAmount)
        end
        
        return true
    end
    
    return false
end

function CodeEditor:handleChar(char)
    if not self.enabled or not self.focused or self.readonly then return false end
    
    -- Handle auto-pairing for brackets and quotes
    if self:handleAutoPairing(char) then
        -- Auto-pairing handled the character
        return true
    end
    
    -- Call parent handler for regular characters
    local result = RichTextBox.handleChar(self, char)
    
    -- Show auto-completion for word characters
    if self.autoComplete and char:match("[%w_]") then
        -- Trigger completion immediately after character insertion
        self:showAutoCompletion()
    elseif char == "." then
        -- Show completion for method calls
        self:showAutoCompletion()
    else
        -- Hide completion for non-word characters (except dot)
        self:hideAutoCompletion()
    end
    
    return result
end

function CodeEditor:handleAutoPairing(char)
    -- Check if auto-pairing is enabled
    if not self.autoPairing then
        return false
    end
    
    -- Define pairs for auto-completion
    local pairs = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        ['"'] = '"',
        ["'"] = "'"
    }
    
    local closingChars = {
        [")"] = "(",
        ["]"] = "[", 
        ["}"] = "{",
        ['"'] = '"',
        ["'"] = "'"
    }
    
    local currentLine = self.lines[self.cursorY] or ""
    local charAtCursor = currentLine:sub(self.cursorX, self.cursorX)
    
    -- Handle closing characters - skip if we're at the matching closing char
    if closingChars[char] and charAtCursor == char then
        -- Move cursor past the existing closing character
        self.cursorX = self.cursorX + 1
        self:ensureCursorVisible()
        return true
    end
    
    -- Handle opening characters - insert both opening and closing
    if pairs[char] then
        local closingChar = pairs[char]
        
        -- For quotes, check if we should close an existing quote instead of opening a new pair
        if (char == '"' or char == "'") then
            -- Count quotes of this type before cursor to determine if we're opening or closing
            local beforeCursor = currentLine:sub(1, self.cursorX - 1)
            local quoteCount = 0
            for i = 1, #beforeCursor do
                if beforeCursor:sub(i, i) == char then
                    quoteCount = quoteCount + 1
                end
            end
            
            -- If odd number of quotes, we're closing; if even, we're opening
            if quoteCount % 2 == 1 then
                -- We're closing a quote - just insert the closing quote
                self:insertText(char)
                return true
            end
        end
        
        -- Insert opening character and closing character
        local before = currentLine:sub(1, self.cursorX - 1)
        local after = currentLine:sub(self.cursorX)
        
        self.lines[self.cursorY] = before .. char .. closingChar .. after
        self.cursorX = self.cursorX + 1  -- Position cursor between the pair
        
        self:ensureCursorVisible()
        if self.onChange then
            self:onChange(self.lines, self.cursorX, self.cursorY)
        end
        
        return true
    end
    
    return false  -- Character not handled by auto-pairing
end

function CodeEditor:handleEvent(event, ...)
    -- Handle our custom completion event (removed for simplicity)
    -- Call parent handler if it exists
    if RichTextBox.handleEvent then
        return RichTextBox.handleEvent(self, event, ...)
    end
    
    return false
end

-- API for adding custom completion sources
function CodeEditor:addCompletionSource(sourceName, items)
    if not self.completionSources then
        self.completionSources = {}
    end
    self.completionSources[sourceName] = items
end

function CodeEditor:removeCompletionSource(sourceName)
    if self.completionSources then
        self.completionSources[sourceName] = nil
    end
end

function CodeEditor:getCompletionSources()
    return self.completionSources or {}
end

-- Method to manually trigger auto-completion
function CodeEditor:triggerAutoCompletion()
    self:showAutoCompletion()
end

-- Method to check if auto-completion is currently visible
function CodeEditor:isAutoCompletionVisible()
    return self.completionVisible or false
end

-- Scrolling utility methods
function CodeEditor:scrollToLine(lineNumber)
    if lineNumber < 1 then lineNumber = 1 end
    if lineNumber > #self.lines then lineNumber = #self.lines end
    
    local contentHeight = self.height - (self.border and 2 or 0)
    self.scrollY = math.max(0, lineNumber - math.floor(contentHeight / 2))
    
    local maxScrollY = math.max(0, #self.lines - contentHeight)
    self.scrollY = math.min(self.scrollY, maxScrollY)
end

function CodeEditor:scrollBy(lines)
    local contentHeight = self.height - (self.border and 2 or 0)
    local maxScrollY = math.max(0, #self.lines - contentHeight)
    
    self.scrollY = math.max(0, math.min(maxScrollY, self.scrollY + lines))
end

function CodeEditor:scrollToTop()
    self.scrollY = 0
end

function CodeEditor:scrollToBottom()
    local contentHeight = self.height - (self.border and 2 or 0)
    self.scrollY = math.max(0, #self.lines - contentHeight)
end

function CodeEditor:getMaxLineLength()
    local maxLength = 0
    for i = 1, #self.lines do
        local line = self.lines[i] or ""
        maxLength = math.max(maxLength, #line)
    end
    return maxLength
end

-- Accordion Widget (Collapsible sections)
local Accordion = setmetatable({}, {__index = Widget})
Accordion.__index = Accordion

function Accordion:new(props)
    local accordion = Widget.new(self, props)
    accordion.sections = props.sections or {}
    accordion.allowMultiple = props.allowMultiple or false
    accordion.expandedSections = props.expandedSections or {}
    accordion.sectionHeight = props.sectionHeight or 1
    accordion.headerHeight = props.headerHeight or 1
    accordion.onSectionToggle = props.onSectionToggle
    accordion.headerColor = props.headerColor or colors.white
    accordion.headerBackground = props.headerBackground or colors.gray
    accordion.contentColor = props.contentColor or colors.white
    accordion.contentBackground = props.contentBackground or colors.black
    accordion.borderColor = props.borderColor or colors.lightGray
    
    -- Initialize first section as expanded if none specified
    if #accordion.expandedSections == 0 and #accordion.sections > 0 then
        accordion.expandedSections[1] = true
    end
    
    return accordion
end

function Accordion:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    local currentY = absY
    
    for i, section in ipairs(self.sections) do
        local isExpanded = self.expandedSections[i]
        
        -- Draw section header
        term.setBackgroundColor(self.headerBackground)
        term.setTextColor(self.headerColor)
        term.setCursorPos(absX, currentY)
        
        local expandIcon = isExpanded and "v" or ">"
        local headerText = expandIcon .. " " .. (section.title or ("Section " .. i))
        headerText = headerText:sub(1, self.width - 1)
        headerText = headerText .. string.rep(" ", self.width - #headerText)
        term.write(headerText)
        
        currentY = currentY + self.headerHeight
        
        -- Draw section content if expanded
        if isExpanded then
            local content = section.content or {}
            local contentHeight = type(content) == "table" and #content or self.sectionHeight
            
            term.setBackgroundColor(self.contentBackground)
            term.setTextColor(self.contentColor)
            
            if type(content) == "table" then
                for j, line in ipairs(content) do
                    if currentY - absY < self.height then
                        term.setCursorPos(absX, currentY)
                        local displayLine = tostring(line):sub(1, self.width)
                        displayLine = displayLine .. string.rep(" ", self.width - #displayLine)
                        term.write(displayLine)
                        currentY = currentY + 1
                    end
                end
            elseif type(content) == "string" then
                -- Word wrap the content
                local words = {}
                for word in content:gmatch("%S+") do
                    table.insert(words, word)
                end
                
                local line = ""
                for _, word in ipairs(words) do
                    if #line + #word + 1 <= self.width then
                        line = line .. (line ~= "" and " " or "") .. word
                    else
                        if currentY - absY < self.height then
                            term.setCursorPos(absX, currentY)
                            local displayLine = line .. string.rep(" ", self.width - #line)
                            term.write(displayLine)
                            currentY = currentY + 1
                        end
                        line = word
                    end
                end
                
                if line ~= "" and currentY - absY < self.height then
                    term.setCursorPos(absX, currentY)
                    local displayLine = line .. string.rep(" ", self.width - #line)
                    term.write(displayLine)
                    currentY = currentY + 1
                end
            end
        end
        
        -- Draw separator line
        if i < #self.sections then
            term.setBackgroundColor(self.borderColor)
            term.setCursorPos(absX, currentY)
            term.write(string.rep(" ", self.width))
            currentY = currentY + 1
        end
        
        -- Stop if we've exceeded the widget height
        if currentY - absY >= self.height then
            break
        end
    end
    
    -- Fill remaining space
    term.setBackgroundColor(self.background or colors.black)
    while currentY - absY < self.height do
        term.setCursorPos(absX, currentY)
        term.write(string.rep(" ", self.width))
        currentY = currentY + 1
    end
    
    term.setBackgroundColor(colors.black)
end

function Accordion:onClick(relX, relY)
    if not self.enabled then return false end
    
    local currentY = 1
    
    for i, section in ipairs(self.sections) do
        -- Check if click is on header
        if relY >= currentY and relY < currentY + self.headerHeight then
            self:toggleSection(i)
            return true
        end
        
        currentY = currentY + self.headerHeight
        
        -- Skip content area if expanded
        if self.expandedSections[i] then
            local content = section.content or {}
            local contentHeight = type(content) == "table" and #content or self.sectionHeight
            currentY = currentY + contentHeight
        end
        
        -- Skip separator
        if i < #self.sections then
            currentY = currentY + 1
        end
        
        if currentY > self.height then
            break
        end
    end
    
    return false
end

function Accordion:toggleSection(index)
    if not self.allowMultiple then
        -- Close all other sections
        self.expandedSections = {}
    end
    
    self.expandedSections[index] = not self.expandedSections[index]
    
    if self.onSectionToggle then
        self:onSectionToggle(index, self.expandedSections[index])
    end
end

function Accordion:expandSection(index)
    if not self.allowMultiple then
        self.expandedSections = {}
    end
    self.expandedSections[index] = true
end

function Accordion:collapseSection(index)
    self.expandedSections[index] = false
end

-- Minimap Widget (Overview of large content)
local Minimap = setmetatable({}, {__index = Widget})
Minimap.__index = Minimap

function Minimap:new(props)
    local minimap = Widget.new(self, props)
    minimap.sourceWidget = props.sourceWidget
    minimap.scale = props.scale or 4 -- How many source pixels per minimap pixel
    minimap.viewportColor = props.viewportColor or colors.red
    minimap.contentColor = props.contentColor or colors.white
    minimap.backgroundColor = props.backgroundColor or colors.gray
    minimap.showViewport = props.showViewport ~= false
    minimap.onClick = props.onClick
    minimap.interactive = props.interactive ~= false
    
    return minimap
end

function Minimap:render()
    if not self.visible or not self.sourceWidget then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Draw background
    term.setBackgroundColor(self.backgroundColor)
    for i = 0, self.height - 1 do
        term.setCursorPos(absX, absY + i)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw border
    drawCharBorder(absX, absY, self.width, self.height, colors.lightGray, self.backgroundColor)
    
    local contentX = absX + 1
    local contentY = absY + 1
    local contentWidth = self.width - 2
    local contentHeight = self.height - 2
    
    -- Simplified representation of source content
    if self.sourceWidget then
        -- Draw content representation
        term.setTextColor(self.contentColor)
        
        -- If source is a text widget, show text density
        if self.sourceWidget.lines then
            local sourceLines = self.sourceWidget.lines or {}
            local linesPerPixel = math.max(1, #sourceLines / contentHeight)
            
            for y = 0, contentHeight - 1 do
                term.setCursorPos(contentX, contentY + y)
                local sourceLineStart = math.floor(y * linesPerPixel) + 1
                local sourceLineEnd = math.floor((y + 1) * linesPerPixel)
                
                -- Calculate content density for this row
                local density = 0
                for lineIdx = sourceLineStart, math.min(sourceLineEnd, #sourceLines) do
                    local line = sourceLines[lineIdx] or ""
                    density = density + #line
                end
                density = density / ((sourceLineEnd - sourceLineStart + 1) * contentWidth)
                
                -- Draw density representation
                local char = " "
                if density > 0.7 then char = "#"
                elseif density > 0.4 then char = "="
                elseif density > 0.1 then char = "-"
                end
                
                term.write(string.rep(char, contentWidth))
            end
        else
            -- Generic content representation
            term.setCursorPos(contentX, contentY)
            for i = 1, contentHeight do
                term.setCursorPos(contentX, contentY + i - 1)
                term.write(string.rep(".", contentWidth))
            end
        end
        
        -- Draw viewport indicator
        if self.showViewport and self.sourceWidget.scrollX ~= nil and self.sourceWidget.scrollY ~= nil then
            local sourceWidth = self.sourceWidget.width or 80
            local sourceHeight = self.sourceWidget.height or 24
            local sourceContentWidth = sourceWidth
            local sourceContentHeight = #(self.sourceWidget.lines or {})
            
            if sourceContentHeight > 0 then
                local viewportX = math.floor((self.sourceWidget.scrollX or 0) / self.scale)
                local viewportY = math.floor((self.sourceWidget.scrollY or 0) * contentHeight / sourceContentHeight)
                local viewportWidth = math.max(1, math.floor(sourceWidth / self.scale))
                local viewportHeight = math.max(1, math.floor(sourceHeight * contentHeight / sourceContentHeight))
                
                -- Ensure viewport stays within bounds
                viewportX = math.max(0, math.min(viewportX, contentWidth - viewportWidth))
                viewportY = math.max(0, math.min(viewportY, contentHeight - viewportHeight))
                
                -- Draw viewport rectangle
                term.setTextColor(self.viewportColor)
                term.setBackgroundColor(self.viewportColor)
                
                -- Top and bottom borders
                for x = 0, viewportWidth - 1 do
                    if contentX + viewportX + x < absX + self.width - 1 then
                        term.setCursorPos(contentX + viewportX + x, contentY + viewportY)
                        term.write(" ")
                        if viewportHeight > 1 then
                            term.setCursorPos(contentX + viewportX + x, contentY + viewportY + viewportHeight - 1)
                            term.write(" ")
                        end
                    end
                end
                
                -- Left and right borders
                for y = 1, viewportHeight - 2 do
                    if contentY + viewportY + y < absY + self.height - 1 then
                        term.setCursorPos(contentX + viewportX, contentY + viewportY + y)
                        term.write(" ")
                        if viewportWidth > 1 then
                            term.setCursorPos(contentX + viewportX + viewportWidth - 1, contentY + viewportY + y)
                            term.write(" ")
                        end
                    end
                end
            end
        end
    end
    
    term.setBackgroundColor(colors.black)
end

function Minimap:onClick(relX, relY)
    if not self.enabled or not self.interactive or not self.sourceWidget then return false end
    
    -- Calculate click position in source coordinates
    local contentX = relX - 1 -- Adjust for border
    local contentY = relY - 1
    local contentWidth = self.width - 2
    local contentHeight = self.height - 2
    
    if contentX >= 0 and contentX < contentWidth and contentY >= 0 and contentY < contentHeight then
        if self.sourceWidget.scrollX ~= nil and self.sourceWidget.scrollY ~= nil then
            -- Calculate new scroll position
            local sourceContentHeight = #(self.sourceWidget.lines or {})
            
            if sourceContentHeight > 0 then
                local newScrollY = math.floor((contentY / contentHeight) * sourceContentHeight)
                local newScrollX = contentX * self.scale
                
                -- Update source widget scroll position
                self.sourceWidget.scrollY = math.max(0, math.min(newScrollY, sourceContentHeight - self.sourceWidget.height))
                self.sourceWidget.scrollX = math.max(0, newScrollX)
                
                if self.sourceWidget.ensureCursorVisible then
                    self.sourceWidget:ensureCursorVisible()
                end
            end
        end
        
        if self.onClick then
            self:onClick(contentX, contentY)
        end
        
        return true
    end
    
    return false
end

-- StatusBar Widget (Bottom status information)
local StatusBar = setmetatable({}, {__index = Widget})
StatusBar.__index = StatusBar

function StatusBar:new(props)
    local statusbar = Widget.new(self, props)
    statusbar.sections = props.sections or {}
    statusbar.separator = props.separator or " | "
    statusbar.align = props.align or "left" -- "left", "right", "center"
    statusbar.showTime = props.showTime or false
    statusbar.timeFormat = props.timeFormat or "%H:%M"
    statusbar.color = props.color or colors.white
    statusbar.background = props.background or colors.gray
    statusbar.height = 1 -- Status bars are always 1 line tall
    
    return statusbar
end

function StatusBar:render()
    if not self.visible then return end
    
    local absX, absY = self:getAbsolutePos()
    
    -- Draw background
    term.setBackgroundColor(self.background)
    term.setTextColor(self.color)
    term.setCursorPos(absX, absY)
    term.write(string.rep(" ", self.width))
    
    -- Collect all sections
    local allSections = {}
    
    -- Add custom sections
    for _, section in ipairs(self.sections) do
        if type(section) == "string" then
            table.insert(allSections, section)
        elseif type(section) == "function" then
            local result = section()
            if result then
                table.insert(allSections, tostring(result))
            end
        elseif type(section) == "table" and section.text then
            table.insert(allSections, section.text)
        end
    end
    
    -- Add time if enabled
    if self.showTime then
        local timeStr = os.date(self.timeFormat)
        table.insert(allSections, timeStr)
    end
    
    -- Combine sections with separator
    local statusText = table.concat(allSections, self.separator)
    
    -- Truncate if too long
    if #statusText > self.width then
        statusText = statusText:sub(1, self.width - 3) .. "..."
    end
    
    -- Position text based on alignment
    local textX = absX
    if self.align == "center" then
        textX = absX + math.floor((self.width - #statusText) / 2)
    elseif self.align == "right" then
        textX = absX + self.width - #statusText
    end
    
    term.setCursorPos(textX, absY)
    term.write(statusText)
    
    term.setBackgroundColor(colors.black)
end

function StatusBar:addSection(section)
    table.insert(self.sections, section)
end

function StatusBar:removeSection(index)
    if index >= 1 and index <= #self.sections then
        table.remove(self.sections, index)
    end
end

function StatusBar:updateSection(index, newSection)
    if index >= 1 and index <= #self.sections then
        self.sections[index] = newSection
    end
end

function StatusBar:clearSections()
    self.sections = {}
end

-- Program Widget (Runs external programs in a contained window)
local Program = setmetatable({}, {__index = Widget})
Program.__index = Program

function Program:new(props)
    local program = Widget.new(self, props)
    program.path = props.path or ""
    program.running = false
    program.programInstance = nil
    program.programWindow = nil
    program.programCoroutine = nil
    program.programFilter = nil
    program.environmentVars = props.environment or {}
    program.addEnvironment = props.addEnvironment ~= false -- default true
    program.args = props.args or {}
    
    -- Callbacks
    program.onError = props.onError -- function(program, error, traceback)
    program.onDone = props.onDone -- function(program, success, result)
    program.onOutput = props.onOutput -- function(program, text)
    
    -- Display properties
    program.showOutput = props.showOutput ~= false -- default true
    program.captureOutput = props.captureOutput ~= false -- default true
    program.outputBuffer = {}
    program.maxOutputLines = props.maxOutputLines or 1000
    
    -- Execution state
    program.exitCode = nil
    program.lastError = nil
    program.startTime = nil
    program.endTime = nil
    
    return program
end

-- Internal program management class
local ProgramRunner = {}
ProgramRunner.__index = ProgramRunner

function ProgramRunner.new(programWidget, env, addEnvironment)
    local self = setmetatable({}, ProgramRunner)
    self.programWidget = programWidget
    self.env = env or {}
    self.args = {}
    self.addEnvironment = addEnvironment == nil and true or addEnvironment
    self.window = nil
    self.coroutine = nil
    self.filter = nil
    return self
end

function ProgramRunner:setArgs(...)
    self.args = {...}
end

function ProgramRunner:createShellEnv(dir)
    local env = { shell = shell, multishell = multishell }
    if package and require then
        local newPackage = require("cc.require").make
        env.require, env.package = newPackage(env, dir)
    end
    return env
end

function ProgramRunner:run(path, width, height)
    -- Create window for the program
    self.window = window.create(term.current(), 1, 1, width, height, false)
    
    -- Resolve program path
    local resolvedPath = shell.resolveProgram(path) or (fs.exists(path) and path) or nil
    if not resolvedPath then
        if self.programWidget.onError then
            self.programWidget.onError(self.programWidget, "Program not found: " .. path, "")
        end
        return false, "Program not found: " .. path
    end
    
    if not fs.exists(resolvedPath) then
        if self.programWidget.onError then
            self.programWidget.onError(self.programWidget, "File not found: " .. resolvedPath, "")
        end
        return false, "File not found: " .. resolvedPath
    end
    
    -- Read program content
    local file = fs.open(resolvedPath, "r")
    if not file then
        if self.programWidget.onError then
            self.programWidget.onError(self.programWidget, "Cannot read file: " .. resolvedPath, "")
        end
        return false, "Cannot read file: " .. resolvedPath
    end
    
    local content = file.readAll()
    file.close()
    
    if not content then
        if self.programWidget.onError then
            self.programWidget.onError(self.programWidget, "Empty or invalid file: " .. resolvedPath, "")
        end
        return false, "Empty or invalid file: " .. resolvedPath
    end
    
    -- Set up environment
    local env = setmetatable(self:createShellEnv(fs.getDir(resolvedPath)), { __index = _ENV })
    env.term = self.window
    env.term.current = term.current
    env.term.redirect = term.redirect
    env.term.native = function()
        return self.window
    end
    
    if self.addEnvironment then
        for k, v in pairs(self.env) do
            env[k] = v
        end
    else
        env = self.env
    end
    
    -- Create and start coroutine
    self.coroutine = coroutine.create(function()
        local program = load(content, "@/" .. resolvedPath, nil, env)
        if program then
            local result = program(table.unpack(self.args))
            return result
        else
            error("Failed to load program")
        end
    end)
    
    local current = term.current()
    term.redirect(self.window)
    local ok, result = coroutine.resume(self.coroutine)
    term.redirect(current)
    
    if not ok then
        local doneCallback = self.programWidget.onDone
        if doneCallback then
            doneCallback(self.programWidget, ok, result)
        end
        
        local errorCallback = self.programWidget.onError
        if errorCallback then
            local trace = debug.traceback(self.coroutine, result)
            local suppressError = errorCallback(self.programWidget, result, trace:gsub(result, ""))
            if suppressError == false then
                self.filter = nil
                return ok, result
            end
        end
        
        self.programWidget.lastError = result
        self.programWidget.exitCode = -1
    end
    
    if coroutine.status(self.coroutine) == "dead" then
        self.programWidget.running = false
        self.programWidget.programInstance = nil
        local doneCallback = self.programWidget.onDone
        if doneCallback then
            doneCallback(self.programWidget, ok, result)
        end
    end
    
    return ok, result
end

function ProgramRunner:resize(width, height)
    if self.window then
        self.window.reposition(1, 1, width, height)
        self:resume("term_resize", width, height)
    end
end

function ProgramRunner:resume(event, ...)
    local args = {...}
    
    -- Adjust mouse coordinates to be relative to the program window
    if event:find("mouse_") then
        args[2], args[3] = args[2] - self.programWidget.x + 1, args[3] - self.programWidget.y + 1
    end
    
    if self.coroutine == nil or coroutine.status(self.coroutine) == "dead" then
        self.programWidget.running = false
        return
    end
    
    if self.filter ~= nil then
        if event ~= self.filter then
            return
        end
        self.filter = nil
    end
    
    local current = term.current()
    term.redirect(self.window)
    local ok, result = coroutine.resume(self.coroutine, event, table.unpack(args))
    term.redirect(current)
    
    if ok then
        self.filter = result
        if coroutine.status(self.coroutine) == "dead" then
            self.programWidget.running = false
            self.programWidget.programInstance = nil
            local doneCallback = self.programWidget.onDone
            if doneCallback then
                doneCallback(self.programWidget, ok, result)
            end
        end
    else
        local doneCallback = self.programWidget.onDone
        if doneCallback then
            doneCallback(self.programWidget, ok, result)
        end
        
        local errorCallback = self.programWidget.onError
        if errorCallback then
            local trace = debug.traceback(self.coroutine, result)
            trace = trace == nil and "" or trace
            result = result or "Unknown error"
            local suppressError = errorCallback(self.programWidget, result, trace:gsub(result, ""))
            if suppressError == false then
                self.filter = nil
                return ok, result
            end
        end
        
        self.programWidget.lastError = result
        self.programWidget.exitCode = -1
        self.programWidget.running = false
    end
    
    return ok, result
end

function ProgramRunner:stop()
    if self.coroutine == nil or coroutine.status(self.coroutine) == "dead" then
        self.programWidget.running = false
        return
    end
    
    -- Close the coroutine
    if coroutine.close then
        coroutine.close(self.coroutine)
    end
    self.coroutine = nil
    self.programWidget.running = false
    self.programWidget.programInstance = nil
end

-- Program widget methods
function Program:execute(path, env, addEnvironment, ...)
    if self.running then
        self:stop()
    end
    
    self.path = path or self.path
    self.running = true
    self.exitCode = nil
    self.lastError = nil
    self.startTime = os.clock()
    self.endTime = nil
    
    local programRunner = ProgramRunner.new(self, env or self.environmentVars, addEnvironment)
    self.programInstance = programRunner
    
    programRunner:setArgs(...)
    local ok, result = programRunner:run(self.path, self.width, self.height)
    
    if not ok then
        self.running = false
        self.endTime = os.clock()
    end
    
    return ok, result
end

function Program:stop()
    if self.programInstance then
        self.programInstance:stop()
    end
    self.running = false
    self.endTime = os.clock()
    return self
end

function Program:sendEvent(event, ...)
    if self.programInstance then
        self.programInstance:resume(event, ...)
    end
    return self
end

function Program:isRunning()
    return self.running
end

function Program:getPath()
    return self.path
end

function Program:setPath(path)
    self.path = path
    return self
end

function Program:setEnvironment(env)
    self.environmentVars = env or {}
    return self
end

function Program:getEnvironment()
    return self.environmentVars
end

function Program:setArgs(...)
    self.args = {...}
    return self
end

function Program:getArgs()
    return self.args
end

function Program:getExitCode()
    return self.exitCode
end

function Program:getLastError()
    return self.lastError
end

function Program:getRuntime()
    if self.startTime then
        local endTime = self.endTime or os.clock()
        return endTime - self.startTime
    end
    return 0
end

function Program:setErrorCallback(callback)
    self.onError = callback
    return self
end

function Program:setDoneCallback(callback)
    self.onDone = callback
    return self
end

function Program:setOutputCallback(callback)
    self.onOutput = callback
    return self
end

function Program:render()
    Widget.render(self)
    
    -- Draw background
    local bgColor = self.enabled and colors.black or colors.gray
    term.setBackgroundColor(bgColor)
    
    for y = 1, self.height do
        term.setCursorPos(self.x, self.y + y - 1)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw program output if running
    if self.programInstance and self.programInstance.window then
        local window = self.programInstance.window
        local _, windowHeight = window.getSize()
        
        for y = 1, math.min(windowHeight, self.height) do
            local text, fg, bg = window.getLine(y)
            if text then
                term.setCursorPos(self.x, self.y + y - 1)
                if fg and bg then
                    term.blit(text, fg, bg)
                else
                    term.setTextColor(colors.white)
                    term.setBackgroundColor(colors.black)
                    term.write(text)
                end
            end
        end
    elseif not self.running and self.path ~= "" then
        -- Show program path when not running
        term.setCursorPos(self.x + 1, self.y + 1)
        term.setTextColor(colors.lightGray)
        term.setBackgroundColor(colors.black)
        term.write("Program: " .. self.path)
        
        if self.lastError then
            term.setCursorPos(self.x + 1, self.y + 2)
            term.setTextColor(colors.red)
            term.write("Error: " .. self.lastError)
        elseif self.exitCode ~= nil then
            term.setCursorPos(self.x + 1, self.y + 2)
            term.setTextColor(self.exitCode == 0 and colors.green or colors.yellow)
            term.write("Exit code: " .. self.exitCode)
        end
    else
        -- Show placeholder when no program set
        term.setCursorPos(self.x + 1, self.y + math.floor(self.height / 2))
        term.setTextColor(colors.gray)
        term.setBackgroundColor(colors.black)
        term.write("No program loaded")
    end
    
    -- Draw border if enabled
    if self.border then
        drawBorder(self.x, self.y, self.width, self.height, self.borderColor or colors.white, self.backgroundColor or colors.black)
    end
end

function Program:onClick(x, y)
    if self.programInstance then
        local relX = x - self.x + 1
        local relY = y - self.y + 1
        self.programInstance:resume("mouse_click", 1, relX, relY)
        return true
    end
    return false
end

function Program:onScroll(x, y, direction)
    if self.programInstance then
        local relX = x - self.x + 1
        local relY = y - self.y + 1
        self.programInstance:resume("mouse_scroll", direction, relX, relY)
        return true
    end
    return false
end

function Program:onDrag(x, y, button)
    if self.programInstance then
        local relX = x - self.x + 1
        local relY = y - self.y + 1
        self.programInstance:resume("mouse_drag", button, relX, relY)
        return true
    end
    return false
end

function Program:onKey(key)
    if self.programInstance then
        self.programInstance:resume("key", key)
        return true
    end
    return false
end

function Program:onChar(char)
    if self.programInstance then
        self.programInstance:resume("char", char)
        return true
    end
    return false
end

function Program:resize(width, height)
    Widget.resize(self, width, height)
    if self.programInstance then
        self.programInstance:resize(width, height)
    end
    return self
end

-- Helper method to restart the program
function Program:restart()
    if self.path and self.path ~= "" then
        return self:execute(self.path, self.environmentVars, self.addEnvironment, table.unpack(self.args))
    end
    return false, "No program path set"
end

-- Helper method to get program window object (for advanced usage)
function Program:getWindow()
    if self.programInstance then
        return self.programInstance.window
    end
    return nil
end

-- Helper method to check if program is responsive
function Program:isResponsive()
    if self.programInstance and self.programInstance.coroutine then
        return coroutine.status(self.programInstance.coroutine) ~= "dead"
    end
    return false
end

-- FilePicker Widget
local FilePicker = setmetatable({}, {__index = Widget})
FilePicker.__index = FilePicker

function FilePicker:new(props)
    local filepicker = Widget.new(self, props)
    filepicker.title = props.title or "Select File"
    filepicker.currentPath = props.currentPath or "/"
    filepicker.fileFilter = props.fileFilter or "*" -- file pattern to filter
    filepicker.allowDirectories = props.allowDirectories or false
    filepicker.onSelect = props.onSelect -- callback when file is selected
    filepicker.onCancel = props.onCancel -- callback when cancelled
    filepicker.showHiddenFiles = props.showHiddenFiles or false
    
    -- UI state
    filepicker.files = {}
    filepicker.directories = {}
    filepicker.selectedIndex = 1
    filepicker.scrollOffset = 0
    filepicker.selectedFile = ""
    filepicker.mode = props.mode or "open" -- "open" or "save"
    filepicker.modal = props.modal ~= false -- modal by default
    
    -- Full-screen modal layout
    local termWidth, termHeight = term.getSize()
    filepicker.width = termWidth
    filepicker.height = termHeight
    filepicker.x = 1
    filepicker.y = 1
    filepicker.zIndex = 1000 -- High z-index for modal
    
    -- Layout properties
    filepicker.headerHeight = 3
    filepicker.footerHeight = 4
    filepicker.listHeight = filepicker.height - filepicker.headerHeight - filepicker.footerHeight
    filepicker.pathBoxHeight = 1
    filepicker.buttonHeight = 3
    
    -- Load initial directory
    filepicker:loadDirectory()
    
    return filepicker
end

function FilePicker:render()
    local absX, absY = self:getAbsolutePos()
    local theme = currentTheme
    
    -- Draw main background
    term.setBackgroundColor(theme.surface or colors.lightGray)
    for y = 0, self.height - 1 do
        term.setCursorPos(absX, absY + y)
        term.write(string.rep(" ", self.width))
    end
    
    -- Draw border
    drawCharBorder(absX, absY, self.width, self.height, theme.border or colors.gray, theme.surface or colors.lightGray)
    
    -- Draw header with title
    term.setBackgroundColor(theme.primary or colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(absX + 1, absY + 1)
    term.write(string.rep(" ", self.width - 2))
    
    local titleText = " " .. self.title .. " "
    local titleX = absX + math.floor((self.width - #titleText) / 2)
    term.setCursorPos(titleX, absY + 1)
    term.write(titleText)
    
    -- Draw current path
    term.setBackgroundColor(theme.background or colors.black)
    term.setTextColor(theme.text or colors.white)
    term.setCursorPos(absX + 2, absY + 2)
    term.write("Path: ")
    
    local pathDisplayWidth = self.width - 8
    local displayPath = self.currentPath
    if #displayPath > pathDisplayWidth then
        displayPath = "..." .. displayPath:sub(#displayPath - pathDisplayWidth + 4)
    end
    term.write(displayPath)
    
    -- Clear remainder of path line
    local pathLineRemaining = pathDisplayWidth - #displayPath
    if pathLineRemaining > 0 then
        term.write(string.rep(" ", pathLineRemaining))
    end
    
    -- Draw file list area background
    term.setBackgroundColor(colors.white)
    for y = 0, self.listHeight - 1 do
        term.setCursorPos(absX + 1, absY + self.headerHeight + y)
        term.write(string.rep(" ", self.width - 2))
    end
    
    -- Draw file list
    self:drawFileList(absX + 1, absY + self.headerHeight)
    
    -- Draw filename input (for save mode)
    if self.mode == "save" then
        term.setBackgroundColor(theme.surface or colors.lightGray)
        term.setTextColor(theme.text or colors.black)
        term.setCursorPos(absX + 2, absY + self.height - 3)
        term.write("Filename: ")
        
        -- Draw filename input box
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        local filenameWidth = self.width - 12
        term.write(self.selectedFile:sub(1, filenameWidth))
        term.write(string.rep(" ", math.max(0, filenameWidth - #self.selectedFile)))
    end
    
    -- Draw buttons
    self:drawButtons(absX, absY + self.height - 2)
    
    -- Draw scrollbar if needed
    if #self.files + #self.directories > self.listHeight then
        self:drawScrollbar(absX + self.width - 2, absY + self.headerHeight)
    end
    
    term.setBackgroundColor(colors.black)
end

function FilePicker:drawFileList(startX, startY)
    local allItems = {}
    
    -- Add parent directory option
    if self.currentPath ~= "/" then
        table.insert(allItems, {name = "..", type = "parent", displayName = "[DIR] .."})
    end
    
    -- Add directories first
    for _, dir in ipairs(self.directories) do
        if self.showHiddenFiles or not dir:match("^%.") then
            -- Safety check to ensure dir is a valid string
            if dir then
                table.insert(allItems, {name = dir, type = "directory", displayName = "[DIR] " .. dir})
            end
        end
    end
    
    -- Add files
    for _, file in ipairs(self.files) do
        if self.showHiddenFiles or not file:match("^%.") then
            local icon = self:getFileIcon(file)
            -- Safety check to ensure both icon and file are valid strings
            if icon and file then
                table.insert(allItems, {name = file, type = "file", displayName = icon .. " " .. file})
            end
        end
    end
    
    -- Draw visible items
    for i = 1, self.listHeight do
        local itemIndex = i + self.scrollOffset
        term.setCursorPos(startX, startY + i - 1)
        
        if itemIndex <= #allItems then
            local item = allItems[itemIndex]
            local isSelected = itemIndex == self.selectedIndex
            
            -- Set colors based on selection and type
            if isSelected then
                term.setBackgroundColor(currentTheme.primary or colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.white)
                if item.type == "directory" or item.type == "parent" then
                    term.setTextColor(colors.blue)
                else
                    term.setTextColor(colors.black)
                end
            end
            
            -- Truncate long names
            local displayWidth = self.width - 4
            local displayText = item.displayName or item.name or "Unknown"
            if #displayText > displayWidth then
                displayText = displayText:sub(1, displayWidth - 3) .. "..."
            end
            
            term.write(displayText)
            
            -- Fill remainder of line
            local remaining = displayWidth - #displayText
            if remaining > 0 then
                term.write(string.rep(" ", remaining))
            end
        else
            -- Empty line
            term.setBackgroundColor(colors.white)
            term.write(string.rep(" ", self.width - 2))
        end
    end
end

function FilePicker:drawButtons(startX, startY)
    local theme = currentTheme
    local buttonY = startY
    
    -- Calculate button positions
    local buttonSpacing = 2
    local buttonWidth = 10
    local totalButtonWidth = buttonWidth * 3 + buttonSpacing * 2
    local buttonStartX = startX + math.floor((self.width - totalButtonWidth) / 2)
    
    -- OK/Open button
    local okText = self.mode == "save" and " Save " or " Open "
    term.setBackgroundColor(theme.success or colors.green)
    term.setTextColor(colors.white)
    term.setCursorPos(buttonStartX, buttonY)
    term.write(okText .. string.rep(" ", buttonWidth - #okText))
    
    -- Cancel button
    term.setBackgroundColor(theme.error or colors.red)
    term.setTextColor(colors.white)
    term.setCursorPos(buttonStartX + buttonWidth + buttonSpacing, buttonY)
    term.write(" Cancel " .. string.rep(" ", buttonWidth - 8))
    
    -- Up directory button
    term.setBackgroundColor(theme.secondary or colors.lightBlue)
    term.setTextColor(colors.white)
    term.setCursorPos(buttonStartX + (buttonWidth + buttonSpacing) * 2, buttonY)
    term.write("   \30   ")  -- Using up arrow character from CC: Tweaked character set
end

function FilePicker:drawScrollbar(x, y)
    local totalItems = #self.files + #self.directories + (self.currentPath ~= "/" and 1 or 0)
    if totalItems <= self.listHeight then return end
    
    local scrollbarHeight = self.listHeight - 2  -- Reserve space for arrows
    local thumbHeight = math.max(1, math.floor(scrollbarHeight * self.listHeight / totalItems))
    local thumbPosition = math.floor(self.scrollOffset * (scrollbarHeight - thumbHeight) / (totalItems - self.listHeight))
    
    -- Draw up arrow
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black)
    term.setCursorPos(x, y)
    term.write("\30")  -- Up arrow
    
    -- Draw scrollbar track
    term.setBackgroundColor(currentTheme.scrollbar.track or colors.gray)
    for i = 1, scrollbarHeight do
        term.setCursorPos(x, y + i)
        term.write(" ")
    end
    
    -- Draw scrollbar thumb
    term.setBackgroundColor(currentTheme.scrollbar.thumb or colors.lightGray)
    for i = 0, thumbHeight - 1 do
        term.setCursorPos(x, y + 1 + thumbPosition + i)
        term.write(" ")
    end
    
    -- Draw down arrow
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black)
    term.setCursorPos(x, y + scrollbarHeight + 1)
    term.write("\31")  -- Down arrow
end

function FilePicker:getFileIcon(filename)
    local ext = filename:match("%.([^%.]+)$")
    if not ext then return "[FILE]" end
    
    ext = ext:lower()
    
    -- Common file type indicators using only CC characters
    if ext == "lua" then return "[LUA]"
    elseif ext == "txt" then return "[TXT]"
    elseif ext == "json" or ext == "xml" then return "[DATA]"
    elseif ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" then return "[IMG]"
    elseif ext == "mp3" or ext == "wav" or ext == "ogg" then return "[SND]"
    elseif ext == "mp4" or ext == "avi" or ext == "mov" then return "[VID]"
    elseif ext == "zip" or ext == "tar" or ext == "gz" then return "[ARC]"
    elseif ext == "exe" or ext == "app" then return "[EXE]"
    else return "[FILE]"
    end
end

function FilePicker:loadDirectory()
    self.files = {}
    self.directories = {}
    
    -- Use real CC: Tweaked file system
    if fs.exists(self.currentPath) and fs.isDir(self.currentPath) then
        local items = fs.list(self.currentPath)
        
        for _, item in ipairs(items) do
            local fullPath = fs.combine(self.currentPath, item)
            
            if fs.isDir(fullPath) then
                -- Add directory
                table.insert(self.directories, item)
            else
                -- Add file if it matches the filter
                if self:matchesFilter(item) then
                    table.insert(self.files, item)
                end
            end
        end
    else
        -- Fallback to root directory if path doesn't exist
        self.currentPath = "/"
        if fs.exists("/") then
            local items = fs.list("/")
            for _, item in ipairs(items) do
                local fullPath = fs.combine("/", item)
                if fs.isDir(fullPath) then
                    table.insert(self.directories, item)
                else
                    if self:matchesFilter(item) then
                        table.insert(self.files, item)
                    end
                end
            end
        end
    end
    
    -- Reset selection
    self.selectedIndex = 1
    self.scrollOffset = 0
    
    -- Sort items
    table.sort(self.directories)
    table.sort(self.files)
end

function FilePicker:matchesFilter(filename)
    if self.fileFilter == "*" then return true end
    
    -- Simple pattern matching - in a real implementation you might want more sophisticated filtering
    local pattern = self.fileFilter:gsub("%*", ".*")
    return filename:match(pattern) ~= nil
end

function FilePicker:onClick(relX, relY)
    if not self.enabled then return end
    
    local listStartY = self.headerHeight + 1
    local listEndY = listStartY + self.listHeight - 1
    
    -- Check if click is in file list area
    if relY >= listStartY and relY <= listEndY then
        local clickedIndex = relY - listStartY + 1 + self.scrollOffset
        self:selectItem(clickedIndex)
        return true
    end
    
    -- Check button clicks
    if relY == self.height - 1 then
        local buttonSpacing = 2
        local buttonWidth = 8
        local totalButtonWidth = buttonWidth * 3 + buttonSpacing * 2
        local buttonStartX = math.floor((self.width - totalButtonWidth) / 2) + 1
        
        if relX >= buttonStartX and relX < buttonStartX + buttonWidth then
            -- OK/Open/Save button
            self:confirmSelection()
        elseif relX >= buttonStartX + buttonWidth + buttonSpacing and relX < buttonStartX + (buttonWidth + buttonSpacing) * 2 then
            -- Cancel button
            self:cancel()
        elseif relX >= buttonStartX + (buttonWidth + buttonSpacing) * 2 and relX < buttonStartX + totalButtonWidth then
            -- Up directory button
            self:goUpDirectory()
        end
        return true
    end
    
    return false
end

function FilePicker:selectItem(index)
    local allItems = self:getAllItems()
    if index < 1 or index > #allItems then return end
    
    self.selectedIndex = index
    local item = allItems[index]
    
    if item.type == "file" then
        self.selectedFile = item.name
    elseif item.type == "directory" and item.name ~= ".." then
        -- Double-click to enter directory
        self:enterDirectory(item.name)
    elseif item.type == "parent" then
        self:goUpDirectory()
    end
    
    self:ensureSelectedVisible()
end

function FilePicker:getAllItems()
    local allItems = {}
    
    if self.currentPath ~= "/" then
        table.insert(allItems, {name = "..", type = "parent"})
    end
    
    for _, dir in ipairs(self.directories) do
        if self.showHiddenFiles or not dir:match("^%.") then
            table.insert(allItems, {name = dir, type = "directory"})
        end
    end
    
    for _, file in ipairs(self.files) do
        if self.showHiddenFiles or not file:match("^%.") then
            table.insert(allItems, {name = file, type = "file"})
        end
    end
    
    return allItems
end

function FilePicker:ensureSelectedVisible()
    local totalItems = #self:getAllItems()
    
    if self.selectedIndex <= self.scrollOffset then
        self.scrollOffset = math.max(0, self.selectedIndex - 1)
    elseif self.selectedIndex > self.scrollOffset + self.listHeight then
        self.scrollOffset = self.selectedIndex - self.listHeight
    end
    
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, totalItems - self.listHeight))
end

function FilePicker:enterDirectory(dirName)
    self.currentPath = fs.combine(self.currentPath, dirName)
    self:loadDirectory()
end

function FilePicker:goUpDirectory()
    if self.currentPath == "/" then return end
    
    -- Use fs.getDir to get parent directory
    local parentPath = fs.getDir(self.currentPath)
    self.currentPath = parentPath == "" and "/" or parentPath
    self:loadDirectory()
end

function FilePicker:confirmSelection()
    local allItems = self:getAllItems()
    if self.selectedIndex > 0 and self.selectedIndex <= #allItems then
        local item = allItems[self.selectedIndex]
        
        if item.type == "file" or (item.type == "directory" and self.allowDirectories) then
            local fullPath = fs.combine(self.currentPath, item.name)
            
            if self.onSelect then
                self:onSelect(fullPath, item.name, item.type)
            end
            
            self.visible = false
        elseif item.type == "directory" then
            self:enterDirectory(item.name)
        end
    elseif self.mode == "save" and self.selectedFile ~= "" then
        local fullPath = fs.combine(self.currentPath, self.selectedFile)
        
        if self.onSelect then
            self:onSelect(fullPath, self.selectedFile, "file")
        end
        
        self.visible = false
    end
end

function FilePicker:cancel()
    if self.onCancel then
        self:onCancel()
    end
    self.visible = false
end

function FilePicker:handleKey(key)
    if not self.enabled then return false end
    
    if key == keys.up then
        self.selectedIndex = math.max(1, self.selectedIndex - 1)
        self:ensureSelectedVisible()
        return true
    elseif key == keys.down then
        local maxIndex = #self:getAllItems()
        self.selectedIndex = math.min(maxIndex, self.selectedIndex + 1)
        self:ensureSelectedVisible()
        return true
    elseif key == keys.enter then
        self:confirmSelection()
        return true
    elseif key == keys.escape then
        self:cancel()
        return true
    elseif key == keys.backspace and self.mode == "save" then
        if #self.selectedFile > 0 then
            self.selectedFile = self.selectedFile:sub(1, -2)
        end
        return true
    end
    
    return false
end

function FilePicker:handleChar(char)
    if not self.enabled then return false end
    
    if self.mode == "save" then
        -- Add character to filename
        self.selectedFile = self.selectedFile .. char
        return true
    end
    
    return false
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

-- Helper function to remove a widget from the global widgets list
function PixelUI.removeWidget(widget)
    for i, w in ipairs(widgets) do
        if w == widget then
            table.remove(widgets, i)
            break
        end
    end
    -- Also remove from root container if it's there
    if rootContainer then
        rootContainer:removeChild(widget)
    end
end

-- Helper function to recursively remove all children of a widget
function PixelUI.removeWidgetAndChildren(widget)
    -- First remove all children recursively
    if widget.children then
        for _, child in ipairs(widget.children) do
            PixelUI.removeWidgetAndChildren(child)
        end
    end
    -- Then remove the widget itself
    PixelUI.removeWidget(widget)
end

-- Developer-friendly: PixelUI handles the event loop and animation internally
function PixelUI.run(userConfig)
    -- userConfig: { onKey, onEvent, onQuit, onStart, ... } (optional)
    local animationInterval = 0.05 -- 20 FPS
    local timerId = os.startTimer(animationInterval)
    local running = true
    
    -- Initialize thread manager
    ThreadManager.running = true
    
    if userConfig and userConfig.onStart then userConfig.onStart() end
    
    while running do
        -- Handle events
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        if event == "timer" and p1 == timerId then
            -- Step through all background threads
            ThreadManager:step()
            
            -- Update animations and toasts
            animationFrame() -- update all animations
            PixelUI.updateToasts() -- update toast notifications
            
            -- Render the UI
            PixelUI.render()
            
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
                -- Removed default 'q' key quit behavior
                end
            end
            if userConfig and userConfig.onExit and userConfig.onExit() then
                running = false
            end
        end
    end
    
    -- Clean up threads
    ThreadManager:stopAll()
    ThreadManager.running = false
    
    if userConfig and userConfig.onQuit then userConfig.onQuit() end
    term.setBackgroundColor(colors.black)
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
    
    -- If this button is meant to be a child of another widget, don't add it globally
    if not props.isChildWidget then
        table.insert(widgets, button)
        if rootContainer then
            rootContainer:addChild(button)
        end
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

function PixelUI.image(props)
    local image = Image:new(props)
    table.insert(widgets, image)
    if rootContainer then
        rootContainer:addChild(image)
    end
    return image
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

function PixelUI.notificationToast(props)
    local toast = NotificationToast:new(props)
    -- Don't add to container automatically - toasts manage their own positioning
    return toast
end

function PixelUI.dataGrid(props)
    local grid = DataGrid:new(props)
    table.insert(widgets, grid)
    if rootContainer then
        rootContainer:addChild(grid)
    end
    return grid
end

function PixelUI.filePicker(props)
    local picker = FilePicker:new(props)
    table.insert(widgets, picker)
    if rootContainer then
        rootContainer:addChild(picker)
    end
    return picker
end

function PixelUI.richTextBox(props)
    local richtext = RichTextBox:new(props)
    table.insert(widgets, richtext)
    if rootContainer then
        rootContainer:addChild(richtext)
    end
    return richtext
end

function PixelUI.codeEditor(props)
    local editor = CodeEditor:new(props)
    table.insert(widgets, editor)
    if rootContainer then
        rootContainer:addChild(editor)
    end
    
    -- Add any custom completion sources
    if props.completionSources then
        for sourceName, items in pairs(props.completionSources) do
            editor:addCompletionSource(sourceName, items)
        end
    end
    
    return editor
end

function PixelUI.accordion(props)
    local accordion = Accordion:new(props)
    table.insert(widgets, accordion)
    if rootContainer then
        rootContainer:addChild(accordion)
    end
    return accordion
end

function PixelUI.minimap(props)
    local minimap = Minimap:new(props)
    table.insert(widgets, minimap)
    if rootContainer then
        rootContainer:addChild(minimap)
    end
    return minimap
end

function PixelUI.statusBar(props)
    local statusbar = StatusBar:new(props)
    table.insert(widgets, statusbar)
    if rootContainer then
        rootContainer:addChild(statusbar)
    end
    return statusbar
end

function PixelUI.program(props)
    local program = Program:new(props)
    table.insert(widgets, program)
    if rootContainer then
        rootContainer:addChild(program)
    end
    return program
end

-- Convenience function for showing toast notifications
function PixelUI.showToast(message, title, type, duration)
    local toast = PixelUI.notificationToast({
        message = message,
        title = title or "",
        type = type or "info",
        duration = duration or 3000
    })
    toast:show()
    return toast
end

-- Update toasts (should be called in the main loop)
function PixelUI.updateToasts()
    for i = #widgets, 1, -1 do
        local widget = widgets[i]
        if widget.__index == NotificationToast then
            widget:update()
        end
    end
end

-- Core rendering and event handling functions
function PixelUI.render()
    -- Clear the screen first
    term.setBackgroundColor(colors.black)
    term.clear()

    -- Check for visible modal widgets and render only them if present
    local activeModal = nil
    for _, widget in ipairs(widgets) do
        if ((widget.__index == MsgBox or widget.__index == FilePicker) and widget.visible and widget.modal ~= false) or
           (widget.__index == Modal and widget.visible) then
            activeModal = widget
            break
        end
    end

    if activeModal then
        activeModal:draw()
    else
        -- Render root container if it exists
        if rootContainer then
            rootContainer:draw()
        else
            -- Render all widgets directly if no container (except toasts)
            for _, widget in ipairs(widgets) do
                if widget.visible ~= false and widget.__index ~= NotificationToast then
                    widget:draw()
                end
            end
        end
    end
    
    -- Always render toasts last (on top of everything, including modals)
    for _, widget in ipairs(widgets) do
        if widget.__index == NotificationToast and widget.visible ~= false then
            widget:draw()
        end
    end
    
    -- Render auto-completion popups on top of everything (including toasts)
    local function renderAutoCompletions(widgetList)
        for _, widget in ipairs(widgetList) do
            if widget.__index == CodeEditor and widget.visible ~= false and widget.completionVisible then
                widget:renderAutoCompletion()
            end
            -- Recursively check children
            if widget.children then
                renderAutoCompletions(widget.children)
            end
        end
    end
    
    -- Render ComboBox dropdowns on top of everything else
    local function renderComboBoxDropdowns(widgetList)
        for _, widget in ipairs(widgetList) do
            if widget.__index == ComboBox and widget.visible ~= false and widget.isOpen then
                widget:renderDropdown()
            end
            -- Recursively check children
            if widget.children then
                renderComboBoxDropdowns(widget.children)
            end
        end
    end
    
    -- Render auto-completions from all widgets (including nested ones)
    renderAutoCompletions(widgets)
    
    -- Render ComboBox dropdowns from all widgets (including nested ones)
    renderComboBoxDropdowns(widgets)
    
    -- Also check modal and root container
    if activeModal and activeModal.children then
        renderAutoCompletions(activeModal.children)
        renderComboBoxDropdowns(activeModal.children)
    end
    if rootContainer and rootContainer.children then
        renderAutoCompletions(rootContainer.children)
        renderComboBoxDropdowns(rootContainer.children)
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

        -- Check for modal widgets first - they should block all other interactions
        local activeModal = nil
        for _, widget in ipairs(widgets) do
            if ((widget.__index == MsgBox or widget.__index == FilePicker) and widget.visible and widget.modal ~= false) or
               (widget.__index == Modal and widget.visible) then
                activeModal = widget
                break
            end
        end

        if activeModal then
            -- Only handle events for the modal widget
            if activeModal.handleClick then
                activeModal:handleClick(x, y)
            end
            return
        end

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
        
        -- Check for modal widgets first - they should block all other interactions
        local activeModal = nil
        for _, widget in ipairs(widgets) do
            if ((widget.__index == MsgBox or widget.__index == FilePicker) and widget.visible and widget.modal ~= false) or
               (widget.__index == Modal and widget.visible) then
                activeModal = widget
                break
            end
        end

        if activeModal and activeModal.handleKey then
            activeModal:handleKey(key)
            return
        end
        
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
        
        -- Check for modal widgets first
        local activeModal = nil
        for _, widget in ipairs(widgets) do
            if ((widget.__index == MsgBox or widget.__index == FilePicker) and widget.visible and widget.modal ~= false) or
               (widget.__index == Modal and widget.visible) then
                activeModal = widget
                break
            end
        end

        if activeModal and activeModal.handleChar then
            activeModal:handleChar(char)
            return
        end
        
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

-- Thread Management API
function PixelUI.spawnThread(func, name)
    if type(func) ~= "function" then
        error("PixelUI.spawnThread: first argument must be a function")
    end
    return ThreadManager:create(func, name)
end

function PixelUI.killThread(id)
    return ThreadManager:kill(id)
end

function PixelUI.getThread(id)
    return ThreadManager:get(id)
end

function PixelUI.getAllThreads()
    return ThreadManager:getAll()
end

function PixelUI.isThreadAlive(id)
    return ThreadManager:isAlive(id)
end

function PixelUI.getThreadStats()
    return ThreadManager:getStats()
end

function PixelUI.onThreadError(id, callback)
    local thread = ThreadManager:get(id)
    if thread then
        thread.onError = callback
        return true
    end
    return false
end

function PixelUI.onThreadComplete(id, callback)
    local thread = ThreadManager:get(id)
    if thread then
        thread.onComplete = callback
        return true
    end
    return false
end

-- Convenience function for running a task with automatic UI updates
function PixelUI.runAsync(func, options)
    options = options or {}
    local taskName = options.name or "AsyncTask"
    local showProgress = options.showProgress
    local progressWidget = nil
    
    if showProgress then
        progressWidget = PixelUI.loadingIndicator({
            x = options.progressX or 1,
            y = options.progressY or 1,
            width = options.progressWidth or 20,
            text = options.progressText or "Loading...",
            style = options.progressStyle or "bar"
        })
    end
    
    local threadId = PixelUI.spawnThread(function()
        local success, result = pcall(func)
        
        -- Hide progress indicator
        if progressWidget then
            progressWidget.visible = false
        end
        
        if success then
            if options.onSuccess then
                options.onSuccess(result)
            end
        else
            if options.onError then
                options.onError(result)
            else
                PixelUI.showToast("Task failed: " .. tostring(result), taskName, "error")
            end
        end
        
        if options.onComplete then
            options.onComplete(success, result)
        end
    end, taskName)
    
    return threadId, progressWidget
end

-- Sleep function that works properly in threads
function PixelUI.sleep(duration)
    local startTime = os.clock()
    while os.clock() - startTime < duration do
        coroutine.yield()
    end
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
PixelUI.NotificationToast = NotificationToast
PixelUI.DataGrid = DataGrid
PixelUI.FilePicker = FilePicker
PixelUI.RichTextBox = RichTextBox
PixelUI.CodeEditor = CodeEditor
PixelUI.Accordion = Accordion
PixelUI.Minimap = Minimap
PixelUI.StatusBar = StatusBar
PixelUI.Program = Program

-- Export thread manager for advanced usage
PixelUI.ThreadManager = ThreadManager

-- ========================================
-- PLUGIN SYSTEM
-- ========================================

-- Enhanced Event System
local EventManager = {
    listeners = {},
    once = {}
}

function EventManager:on(eventName, callback, once)
    if not self.listeners[eventName] then
        self.listeners[eventName] = {}
    end
    
    local listener = {
        callback = callback,
        id = #self.listeners[eventName] + 1
    }
    
    table.insert(self.listeners[eventName], listener)
    
    if once then
        if not self.once[eventName] then
            self.once[eventName] = {}
        end
        self.once[eventName][listener.id] = true
    end
    
    return listener.id
end

function EventManager:off(eventName, listenerId)
    if not self.listeners[eventName] then return false end
    
    for i, listener in ipairs(self.listeners[eventName]) do
        if listener.id == listenerId then
            table.remove(self.listeners[eventName], i)
            if self.once[eventName] then
                self.once[eventName][listenerId] = nil
            end
            return true
        end
    end
    return false
end

function EventManager:emit(eventName, data)
    if not self.listeners[eventName] then return {} end
    
    local results = {}
    local toRemove = {}
    
    for i, listener in ipairs(self.listeners[eventName]) do
        local success, result = pcall(listener.callback, data)
        if success then
            table.insert(results, result)
        end
        
        -- Mark for removal if it's a once listener
        if self.once[eventName] and self.once[eventName][listener.id] then
            table.insert(toRemove, i)
        end
    end
    
    -- Remove once listeners (in reverse order to maintain indices)
    for i = #toRemove, 1, -1 do
        local idx = toRemove[i]
        local listener = self.listeners[eventName][idx]
        table.remove(self.listeners[eventName], idx)
        if self.once[eventName] then
            self.once[eventName][listener.id] = nil
        end
    end
    
    return results
end

function EventManager:listEvents()
    local events = {}
    for eventName, listeners in pairs(self.listeners) do
        events[eventName] = #listeners
    end
    return events
end

-- Service Registry System
local ServiceRegistry = {
    services = {}
}

function ServiceRegistry:register(serviceName, serviceInstance)
    if self.services[serviceName] then
        error("Service '" .. serviceName .. "' is already registered")
    end
    
    self.services[serviceName] = serviceInstance
    
    -- Emit service registration event
    EventManager:emit("serviceRegistered", {
        name = serviceName,
        service = serviceInstance
    })
    
    return true
end

function ServiceRegistry:unregister(serviceName)
    if not self.services[serviceName] then
        return false
    end
    
    local service = self.services[serviceName]
    self.services[serviceName] = nil
    
    -- Emit service unregistration event
    EventManager:emit("serviceUnregistered", {
        name = serviceName,
        service = service
    })
    
    return true
end

function ServiceRegistry:get(serviceName)
    return self.services[serviceName]
end

function ServiceRegistry:list()
    local serviceList = {}
    for name, _ in pairs(self.services) do
        table.insert(serviceList, name)
    end
    return serviceList
end

function ServiceRegistry:exists(serviceName)
    return self.services[serviceName] ~= nil
end

-- Configuration Management System
local ConfigManager = {
    configs = {},
    defaults = {}
}

function ConfigManager:setDefault(pluginId, defaultConfig)
    self.defaults[pluginId] = defaultConfig
    
    -- If no config exists yet, use the default
    if not self.configs[pluginId] then
        self.configs[pluginId] = self:deepCopy(defaultConfig)
    end
end

function ConfigManager:get(pluginId, key)
    local config = self.configs[pluginId] or {}
    
    if key then
        return config[key]
    else
        return config
    end
end

function ConfigManager:set(pluginId, key, value)
    if not self.configs[pluginId] then
        self.configs[pluginId] = {}
    end
    
    if type(key) == "table" then
        -- Setting entire config
        self.configs[pluginId] = self:mergeConfig(self.defaults[pluginId] or {}, key)
    else
        -- Setting single key
        self.configs[pluginId][key] = value
    end
    
    -- Emit config change event
    EventManager:emit("configChanged", {
        pluginId = pluginId,
        key = key,
        value = value,
        config = self.configs[pluginId]
    })
end

function ConfigManager:merge(pluginId, newConfig)
    local existing = self.configs[pluginId] or {}
    self.configs[pluginId] = self:mergeConfig(existing, newConfig)
    
    -- Emit config change event
    EventManager:emit("configChanged", {
        pluginId = pluginId,
        config = self.configs[pluginId]
    })
end

function ConfigManager:reset(pluginId)
    if self.defaults[pluginId] then
        self.configs[pluginId] = self:deepCopy(self.defaults[pluginId])
    else
        self.configs[pluginId] = {}
    end
end

function ConfigManager:validate(pluginId, schema)
    local config = self.configs[pluginId] or {}
    
    for key, validation in pairs(schema) do
        local value = config[key]
        
        -- Check required
        if validation.required and value == nil then
            error("Missing required config key: " .. key)
        end
        
        -- Check type
        if value ~= nil and validation.type and type(value) ~= validation.type then
            error("Invalid type for config key '" .. key .. "': expected " .. validation.type .. ", got " .. type(value))
        end
        
        -- Check min/max for numbers
        if value ~= nil and type(value) == "number" then
            if validation.min and value < validation.min then
                error("Config key '" .. key .. "' must be at least " .. validation.min)
            end
            if validation.max and value > validation.max then
                error("Config key '" .. key .. "' must be at most " .. validation.max)
            end
        end
    end
    
    return true
end

function ConfigManager:deepCopy(orig)
    local copy = {}
    for key, value in pairs(orig) do
        if type(value) == "table" then
            copy[key] = self:deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

function ConfigManager:mergeConfig(defaults, userConfig)
    local merged = self:deepCopy(defaults)
    
    for key, value in pairs(userConfig) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = self:mergeConfig(merged[key], value)
        else
            merged[key] = value
        end
    end
    
    return merged
end

-- Drawing Utilities API
local DrawingUtils = {
    
}

function DrawingUtils.drawPixel(x, y, color, bgColor)
    if bgColor then
        term.setBackgroundColor(bgColor)
    end
    if color then
        term.setTextColor(color)
    end
    term.setCursorPos(x, y)
    term.write(" ")
end

function DrawingUtils.drawText(x, y, text, color, bgColor)
    if bgColor then
        term.setBackgroundColor(bgColor)
    end
    if color then
        term.setTextColor(color)
    end
    term.setCursorPos(x, y)
    term.write(text)
end

function DrawingUtils.drawFilledRect(x, y, width, height, color)
    term.setBackgroundColor(color)
    for row = 0, height - 1 do
        term.setCursorPos(x, y + row)
        term.write(string.rep(" ", width))
    end
end

function DrawingUtils.drawBorder(x, y, width, height, borderColor, bgColor)
    bgColor = bgColor or colors.black
    drawCharBorder(x, y, width, height, borderColor, bgColor)
end

function DrawingUtils.drawLine(x1, y1, x2, y2, color, char)
    char = char or " "
    if color then
        term.setBackgroundColor(color)
    end
    
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy
    
    local x, y = x1, y1
    
    while true do
        term.setCursorPos(x, y)
        term.write(char)
        
        if x == x2 and y == y2 then break end
        
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end
end

function DrawingUtils.drawCircle(centerX, centerY, radius, color, filled)
    if color then
        term.setBackgroundColor(color)
    end
    
    if filled then
        -- Draw filled circle
        for y = -radius, radius do
            for x = -radius, radius do
                if x * x + y * y <= radius * radius then
                    term.setCursorPos(centerX + x, centerY + y)
                    term.write(" ")
                end
            end
        end
    else
        -- Draw circle outline using Bresenham's algorithm
        local x = 0
        local y = radius
        local d = 3 - 2 * radius
        
        local function drawCirclePoints(cx, cy, x, y)
            local points = {
                {cx + x, cy + y}, {cx - x, cy + y},
                {cx + x, cy - y}, {cx - x, cy - y},
                {cx + y, cy + x}, {cx - y, cy + x},
                {cx + y, cy - x}, {cx - y, cy - x}
            }
            
            for _, point in ipairs(points) do
                term.setCursorPos(point[1], point[2])
                term.write(" ")
            end
        end
        
        drawCirclePoints(centerX, centerY, x, y)
        
        while y >= x do
            x = x + 1
            if d > 0 then
                y = y - 1
                d = d + 4 * (x - y) + 10
            else
                d = d + 4 * x + 6
            end
            drawCirclePoints(centerX, centerY, x, y)
        end
    end
end

function DrawingUtils.drawArc(centerX, centerY, radius, startAngle, endAngle, color, thickness)
    thickness = thickness or 1
    if color then
        term.setBackgroundColor(color)
    end
    
    local angleStep = 1 / radius -- Smaller step for smoother arcs
    
    for angle = startAngle, endAngle, angleStep do
        local rad = math.rad(angle)
        for t = 0, thickness - 1 do
            local x = centerX + math.floor((radius + t) * math.cos(rad))
            local y = centerY + math.floor((radius + t) * math.sin(rad))
            term.setCursorPos(x, y)
            term.write(" ")
        end
    end
end

function DrawingUtils.drawGradient(x, y, width, height, startColor, endColor, direction)
    direction = direction or "horizontal"
    
    -- Simple gradient approximation using available colors
    local colors_list = {
        colors.white, colors.orange, colors.magenta, colors.lightBlue,
        colors.yellow, colors.lime, colors.pink, colors.gray,
        colors.lightGray, colors.cyan, colors.purple, colors.blue,
        colors.brown, colors.green, colors.red, colors.black
    }
    
    if direction == "horizontal" then
        for col = 0, width - 1 do
            local factor = col / (width - 1)
            -- Simple color interpolation (would need proper color mixing in real implementation)
            local colorIndex = math.floor(factor * (#colors_list - 1)) + 1
            local currentColor = colors_list[math.min(colorIndex, #colors_list)]
            
            term.setBackgroundColor(currentColor)
            for row = 0, height - 1 do
                term.setCursorPos(x + col, y + row)
                term.write(" ")
            end
        end
    else -- vertical
        for row = 0, height - 1 do
            local factor = row / (height - 1)
            local colorIndex = math.floor(factor * (#colors_list - 1)) + 1
            local currentColor = colors_list[math.min(colorIndex, #colors_list)]
            
            term.setBackgroundColor(currentColor)
            for col = 0, width - 1 do
                term.setCursorPos(x + col, y + row)
                term.write(" ")
            end
        end
    end
end

local PluginManager = {
    plugins = {},
    hooks = {},
    widgetExtensions = {},
    themeExtensions = {},
    initialized = false
}

-- Enhanced dependency management
function PluginManager:parseDependency(depString)
    -- Parse dependency strings like "pluginId@1.2.0" or "pluginId>=1.0.0"
    local id, constraint = depString:match("^([^@>=<]+)(.*)$")
    if not id then
        return { id = depString, constraint = nil }
    end
    
    local operator, version = "", ""
    if constraint:match("^@") then
        version = constraint:sub(2)
        operator = "="
    elseif constraint:match("^>=") then
        version = constraint:sub(3)
        operator = ">="
    elseif constraint:match("^<=") then
        version = constraint:sub(3)
        operator = "<="
    elseif constraint:match("^>") then
        version = constraint:sub(2)
        operator = ">"
    elseif constraint:match("^<") then
        version = constraint:sub(2)
        operator = "<"
    end
    
    return {
        id = id,
        constraint = constraint ~= "" and { operator = operator, version = version } or nil
    }
end

function PluginManager:compareVersions(version1, version2)
    -- Simple semantic version comparison
    local function parseVersion(v)
        local major, minor, patch = v:match("^(%d+)%.(%d+)%.(%d+)")
        return {
            major = tonumber(major) or 0,
            minor = tonumber(minor) or 0,
            patch = tonumber(patch) or 0
        }
    end
    
    local v1 = parseVersion(version1)
    local v2 = parseVersion(version2)
    
    if v1.major ~= v2.major then
        return v1.major - v2.major
    elseif v1.minor ~= v2.minor then
        return v1.minor - v2.minor
    else
        return v1.patch - v2.patch
    end
end

function PluginManager:checkDependency(dependency, targetPlugin)
    if not targetPlugin then
        return false, "Plugin not found"
    end
    
    if not dependency.constraint then
        return true -- No version constraint
    end
    
    local operator = dependency.constraint.operator
    local requiredVersion = dependency.constraint.version
    local actualVersion = targetPlugin.version
    
    local comparison = self:compareVersions(actualVersion, requiredVersion)
    
    if operator == "=" and comparison == 0 then
        return true
    elseif operator == ">=" and comparison >= 0 then
        return true
    elseif operator == "<=" and comparison <= 0 then
        return true
    elseif operator == ">" and comparison > 0 then
        return true
    elseif operator == "<" and comparison < 0 then
        return true
    end
    
    return false, "Version constraint not satisfied: requires " .. dependency.constraint.operator .. dependency.constraint.version .. ", found " .. actualVersion
end

function PluginManager:validateDependencies(plugin)
    local missing = {}
    local incompatible = {}
    
    for _, depString in ipairs(plugin.dependencies) do
        local dependency = self:parseDependency(depString)
        local targetPlugin = self.plugins[dependency.id]
        
        if not targetPlugin then
            table.insert(missing, dependency.id)
        elseif not targetPlugin.loaded then
            table.insert(missing, dependency.id .. " (not loaded)")
        else
            local satisfied, reason = self:checkDependency(dependency, targetPlugin)
            if not satisfied then
                table.insert(incompatible, dependency.id .. ": " .. reason)
            end
        end
    end
    
    return missing, incompatible
end

function PluginManager:detectCircularDependencies(pluginId, visited, chain)
    visited = visited or {}
    chain = chain or {}
    
    if visited[pluginId] then
        return false -- Already processed, no cycle here
    end
    
    for _, id in ipairs(chain) do
        if id == pluginId then
            return true, "Circular dependency detected: " .. table.concat(chain, " -> ") .. " -> " .. pluginId
        end
    end
    
    local plugin = self.plugins[pluginId]
    if not plugin then
        return false
    end
    
    table.insert(chain, pluginId)
    
    for _, depString in ipairs(plugin.dependencies) do
        local dependency = self:parseDependency(depString)
        local hasCircle, reason = self:detectCircularDependencies(dependency.id, visited, chain)
        if hasCircle then
            return true, reason
        end
    end
    
    table.remove(chain)
    visited[pluginId] = true
    return false
end

function PluginManager:getDependents(pluginId)
    local dependents = {}
    for id, plugin in pairs(self.plugins) do
        for _, depString in ipairs(plugin.dependencies) do
            local dependency = self:parseDependency(depString)
            if dependency.id == pluginId then
                table.insert(dependents, id)
                break
            end
        end
    end
    return dependents
end

function PluginManager:getLoadOrder(plugins)
    local order = {}
    local visited = {}
    local visiting = {}
    
    local function visit(pluginId)
        if visited[pluginId] then
            return true
        end
        
        if visiting[pluginId] then
            return false, "Circular dependency involving " .. pluginId
        end
        
        local plugin = plugins[pluginId] or self.plugins[pluginId]
        if not plugin then
            return false, "Plugin not found: " .. pluginId
        end
        
        visiting[pluginId] = true
        
        for _, depString in ipairs(plugin.dependencies) do
            local dependency = self:parseDependency(depString)
            local success, err = visit(dependency.id)
            if not success then
                return false, err
            end
        end
        
        visiting[pluginId] = nil
        visited[pluginId] = true
        table.insert(order, pluginId)
        return true
    end
    
    for pluginId, _ in pairs(plugins) do
        if not visited[pluginId] then
            local success, err = visit(pluginId)
            if not success then
                return nil, err
            end
        end
    end
    
    return order
end

-- Plugin registration and management
function PluginManager:registerPlugin(pluginInfo)
    if type(pluginInfo) ~= "table" then
        error("Plugin info must be a table")
    end
    
    local plugin = {
        id = pluginInfo.id or error("Plugin must have an id"),
        name = pluginInfo.name or pluginInfo.id,
        version = pluginInfo.version or "1.0.0",
        author = pluginInfo.author or "Unknown",
        description = pluginInfo.description or "",
        dependencies = pluginInfo.dependencies or {},
        
        -- Plugin lifecycle functions
        onLoad = pluginInfo.onLoad,
        onUnload = pluginInfo.onUnload,
        onEnable = pluginInfo.onEnable,
        onDisable = pluginInfo.onDisable,
        
        -- Plugin content
        widgets = pluginInfo.widgets or {},
        themes = pluginInfo.themes or {},
        hooks = pluginInfo.hooks or {},
        api = pluginInfo.api or {},
        
        -- Configuration support
        config = pluginInfo.config or {},
        configSchema = pluginInfo.configSchema or {},
        
        -- Plugin state
        loaded = false,
        enabled = false,
        loadTime = nil,
        error = nil
    }
    
    -- Set up default configuration
    if plugin.config and type(plugin.config) == "table" then
        ConfigManager:setDefault(plugin.id, plugin.config)
    end
    
    -- Check for circular dependencies
    self.plugins[plugin.id] = plugin -- Temporarily add for cycle detection
    local hasCircle, reason = self:detectCircularDependencies(plugin.id)
    if hasCircle then
        self.plugins[plugin.id] = nil -- Remove from registry
        error("Cannot register plugin '" .. plugin.id .. "': " .. reason)
    end
    
    -- Don't validate dependencies yet - allow registration with missing deps
    -- Dependencies will be validated during loading
    
    -- Emit plugin registration event
    EventManager:emit("pluginRegistered", {
        plugin = plugin
    })
    
    return plugin
end

function PluginManager:loadPlugin(pluginId)
    local plugin = self.plugins[pluginId]
    if not plugin then
        error("Plugin '" .. pluginId .. "' not found")
    end
    
    if plugin.loaded then
        return true -- Already loaded
    end
    
    -- Validate dependencies
    local missing, incompatible = self:validateDependencies(plugin)
    if #missing > 0 then
        plugin.error = "Missing dependencies: " .. table.concat(missing, ", ")
        return false, plugin.error
    end
    if #incompatible > 0 then
        plugin.error = "Incompatible dependencies: " .. table.concat(incompatible, ", ")
        return false, plugin.error
    end
    
    -- Load dependencies first (in correct order)
    for _, depString in ipairs(plugin.dependencies) do
        local dependency = self:parseDependency(depString)
        local success, err = self:loadPlugin(dependency.id)
        if not success then
            plugin.error = "Failed to load dependency '" .. dependency.id .. "': " .. (err or "Unknown error")
            return false, plugin.error
        end
    end
    
    -- Call plugin's onLoad function
    if plugin.onLoad then
        local success, err = pcall(plugin.onLoad, plugin)
        if not success then
            plugin.error = "Load callback failed: " .. (err or "Unknown error")
            return false, plugin.error
        end
    end
    
    -- Register plugin widgets
    for widgetName, widgetClass in pairs(plugin.widgets) do
        self:registerWidget(widgetName, widgetClass, plugin)
    end
    
    -- Register plugin themes
    for themeName, themeData in pairs(plugin.themes) do
        self:registerTheme(themeName, themeData, plugin)
    end
    
    -- Register plugin hooks
    for hookName, hookFunc in pairs(plugin.hooks) do
        self:registerHook(hookName, hookFunc, plugin)
    end
    
    -- Expose plugin API to PixelUI
    if plugin.api then
        for apiName, apiFunc in pairs(plugin.api) do
            PixelUI[apiName] = apiFunc
        end
    end
    
    plugin.loaded = true
    plugin.loadTime = os.clock()
    plugin.error = nil -- Clear any previous errors
    
    -- Emit plugin loaded event
    EventManager:emit("pluginLoaded", {
        plugin = plugin
    })
    
    return true
end

function PluginManager:unloadPlugin(pluginId, force)
    local plugin = self.plugins[pluginId]
    if not plugin or not plugin.loaded then
        return false
    end
    
    -- Check for dependent plugins
    local dependents = self:getDependents(pluginId)
    if #dependents > 0 and not force then
        plugin.error = "Cannot unload plugin - other plugins depend on it: " .. table.concat(dependents, ", ")
        return false, plugin.error
    end
    
    -- If force unload, unload all dependents first
    if force then
        for _, dependentId in ipairs(dependents) do
            self:unloadPlugin(dependentId, true)
        end
    end
    
    -- Disable first if enabled
    if plugin.enabled then
        self:disablePlugin(pluginId)
    end
    
    -- Call plugin's onUnload function
    if plugin.onUnload then
        pcall(plugin.onUnload, plugin)
    end
    
    -- Remove plugin widgets
    for widgetName, _ in pairs(plugin.widgets) do
        self:unregisterWidget(widgetName, plugin)
    end
    
    -- Remove plugin themes
    for themeName, _ in pairs(plugin.themes) do
        self:unregisterTheme(themeName, plugin)
    end
    
    -- Remove plugin hooks
    for hookName, _ in pairs(plugin.hooks) do
        self:unregisterHook(hookName, plugin)
    end
    
    -- Remove plugin API from PixelUI
    if plugin.api then
        for apiName, _ in pairs(plugin.api) do
            PixelUI[apiName] = nil
        end
    end
    
    plugin.loaded = false
    plugin.error = nil
    
    -- Emit plugin unloaded event
    EventManager:emit("pluginUnloaded", {
        plugin = plugin
    })
    
    return true
end

function PluginManager:enablePlugin(pluginId)
    local plugin = self.plugins[pluginId]
    if not plugin or not plugin.loaded or plugin.enabled then
        return false
    end
    
    if plugin.onEnable then
        local success, err = pcall(plugin.onEnable, plugin)
        if not success then
            plugin.error = err
            return false
        end
    end
    
    plugin.enabled = true
    
    -- Emit plugin enabled event
    EventManager:emit("pluginEnabled", {
        plugin = plugin
    })
    
    return true
end

function PluginManager:disablePlugin(pluginId)
    local plugin = self.plugins[pluginId]
    if not plugin or not plugin.enabled then
        return false
    end
    
    if plugin.onDisable then
        pcall(plugin.onDisable, plugin)
    end
    
    plugin.enabled = false
    
    -- Emit plugin disabled event
    EventManager:emit("pluginDisabled", {
        plugin = plugin
    })
    
    return true
end

-- Widget extension system
function PluginManager:registerWidget(widgetName, widgetClass, plugin)
    if not widgetClass or type(widgetClass) ~= "table" then
        error("Widget class must be a table")
    end
    
    local fullName = "plugin_" .. widgetName
    self.widgetExtensions[fullName] = {
        class = widgetClass,
        plugin = plugin,
        name = widgetName
    }
    
    -- Create factory function in PixelUI
    PixelUI[widgetName] = function(props)
        local widget = widgetClass:new(props)
        table.insert(widgets, widget)
        if rootContainer then
            rootContainer:addChild(widget)
        end
        return widget
    end
end

function PluginManager:unregisterWidget(widgetName, plugin)
    local fullName = "plugin_" .. widgetName
    if self.widgetExtensions[fullName] and self.widgetExtensions[fullName].plugin == plugin then
        self.widgetExtensions[fullName] = nil
        PixelUI[widgetName] = nil
    end
end

-- Theme extension system
function PluginManager:registerTheme(themeName, themeData, plugin)
    if not themeData or type(themeData) ~= "table" then
        error("Theme data must be a table")
    end
    
    self.themeExtensions[themeName] = {
        data = themeData,
        plugin = plugin
    }
end

function PluginManager:unregisterTheme(themeName, plugin)
    if self.themeExtensions[themeName] and self.themeExtensions[themeName].plugin == plugin then
        self.themeExtensions[themeName] = nil
    end
end

function PluginManager:getTheme(themeName)
    local theme = self.themeExtensions[themeName]
    return theme and theme.data or nil
end

function PluginManager:listThemes()
    local themes = {}
    for name, _ in pairs(self.themeExtensions) do
        table.insert(themes, name)
    end
    return themes
end

-- Hook system for plugin extensibility
function PluginManager:registerHook(hookName, hookFunc, plugin)
    if not self.hooks[hookName] then
        self.hooks[hookName] = {}
    end
    
    table.insert(self.hooks[hookName], {
        func = hookFunc,
        plugin = plugin
    })
end

function PluginManager:unregisterHook(hookName, plugin)
    if not self.hooks[hookName] then return end
    
    for i = #self.hooks[hookName], 1, -1 do
        if self.hooks[hookName][i].plugin == plugin then
            table.remove(self.hooks[hookName], i)
        end
    end
end

function PluginManager:runHook(hookName, ...)
    if not self.hooks[hookName] then return end
    
    local results = {}
    for _, hook in ipairs(self.hooks[hookName]) do
        if hook.plugin.enabled then
            local success, result = pcall(hook.func, ...)
            if success then
                table.insert(results, result)
            end
        end
    end
    return results
end

-- Plugin discovery and loading from files
function PluginManager:loadPluginFromFile(filePath)
    if not fs.exists(filePath) then
        error("Plugin file not found: " .. filePath)
    end
    
    local env = {
        -- Provide safe environment for plugin
        PixelUI = PixelUI,
        colors = colors,
        term = term,
        fs = fs,
        os = os,
        http = http,
        math = math,
        string = string,
        table = table,
        pairs = pairs,
        ipairs = ipairs,
        type = type,
        tostring = tostring,
        tonumber = tonumber,
        error = error,
        assert = assert,
        pcall = pcall,
        xpcall = xpcall,
        coroutine = coroutine,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        rawget = rawget,
        rawset = rawset,
        rawlen = rawlen,
        next = next,
        select = select,
        print = print,
        
        -- Enhanced plugin API
        registerPlugin = function(pluginInfo)
            local plugin = self:registerPlugin(pluginInfo)
            -- Immediately load the plugin after registration
            local loadSuccess = self:loadPlugin(plugin.id)
            if not loadSuccess then
                error("Failed to auto-load plugin: " .. plugin.id .. " - " .. tostring(plugin.error))
            end
            return plugin
        end,
        
        -- Event system access
        emit = function(eventName, data)
            return EventManager:emit(eventName, data)
        end,
        
        on = function(eventName, callback, once)
            return EventManager:on(eventName, callback, once)
        end,
        
        off = function(eventName, listenerId)
            return EventManager:off(eventName, listenerId)
        end,
        
        -- Service registry access
        registerService = function(serviceName, serviceInstance)
            return ServiceRegistry:register(serviceName, serviceInstance)
        end,
        
        getService = function(serviceName)
            return ServiceRegistry:get(serviceName)
        end,
        
        -- Configuration access
        getConfig = function(pluginId, key)
            return ConfigManager:get(pluginId or "global", key)
        end,
        
        setConfig = function(pluginId, key, value)
            return ConfigManager:set(pluginId or "global", key, value)
        end,
        
        -- Drawing utilities
        draw = DrawingUtils
    }
    
    -- Load and execute plugin file
    local file = fs.open(filePath, "r")
    local content = file.readAll()
    file.close()
    
    local func, err = load(content, filePath, "t", env)
    if not func then
        error("Failed to load plugin: " .. err)
    end
    
    local success, result = pcall(func)
    if not success then
        error("Failed to execute plugin: " .. result)
    end
    
    return result
end

function PluginManager:loadPluginsFromDirectory(dirPath)
    if not fs.exists(dirPath) or not fs.isDir(dirPath) then
        return {}
    end
    
    local loadedPlugins = {}
    local files = fs.list(dirPath)
    
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            local fullPath = fs.combine(dirPath, file)
            local success, result = pcall(function()
                return self:loadPluginFromFile(fullPath)
            end)
            
            if success then
                table.insert(loadedPlugins, {
                    file = file,
                    path = fullPath,
                    plugin = result
                })
            end
        end
    end
    
    return loadedPlugins
end

function PluginManager:loadPluginFromURL(url, tempFileName)
    -- Validate URL
    if not url or type(url) ~= "string" then
        error("URL must be a valid string")
    end
    
    if not url:match("^https?://") then
        error("URL must use http or https protocol")
    end
    
    -- Generate temporary filename if not provided
    if not tempFileName then
        local urlPath = url:match("/([^/]+)$") or "plugin.lua"
        tempFileName = "temp_" .. os.epoch("utc") .. "_" .. urlPath
    end
    
    -- Ensure temp filename ends with .lua
    if not tempFileName:match("%.lua$") then
        tempFileName = tempFileName .. ".lua"
    end
    
    local tempPath = fs.combine("temp", tempFileName)
    
    -- Create temp directory if it doesn't exist
    if not fs.exists("temp") then
        fs.makeDir("temp")
    end
    
    -- Download the plugin using CC:Tweaked's http API
    local response, err = http.get(url)
    if not response then
        error("Failed to download plugin from URL: " .. (err or "Unknown error"))
    end
    
    local content = response.readAll()
    response.close()
    
    if not content or content == "" then
        error("Downloaded plugin file is empty")
    end
    
    -- Save to temporary file
    local file = fs.open(tempPath, "w")
    file.write(content)
    file.close()
    
    -- Load the plugin from the temporary file
    local success, result = pcall(function()
        return self:loadPluginFromFile(tempPath)
    end)
    
    -- Clean up temporary file
    if fs.exists(tempPath) then
        fs.delete(tempPath)
    end
    
    if not success then
        error("Failed to load plugin from URL: " .. result)
    end
    
    return result
end

-- Plugin information and management
function PluginManager:listPlugins()
    local pluginList = {}
    for id, plugin in pairs(self.plugins) do
        table.insert(pluginList, {
            id = id,
            name = plugin.name,
            version = plugin.version,
            author = plugin.author,
            description = plugin.description,
            loaded = plugin.loaded,
            enabled = plugin.enabled,
            loadTime = plugin.loadTime,
            error = plugin.error
        })
    end
    return pluginList
end

function PluginManager:getPlugin(pluginId)
    return self.plugins[pluginId]
end

function PluginManager:isPluginLoaded(pluginId)
    local plugin = self.plugins[pluginId]
    return plugin and plugin.loaded or false
end

function PluginManager:isPluginEnabled(pluginId)
    local plugin = self.plugins[pluginId]
    return plugin and plugin.enabled or false
end

-- Plugin system API for PixelUI
function PixelUI.registerPlugin(pluginInfo)
    return PluginManager:registerPlugin(pluginInfo)
end

function PixelUI.loadPlugin(pluginId)
    return PluginManager:loadPlugin(pluginId)
end

function PixelUI.unloadPlugin(pluginId)
    return PluginManager:unloadPlugin(pluginId)
end

function PixelUI.enablePlugin(pluginId)
    return PluginManager:enablePlugin(pluginId)
end

function PixelUI.disablePlugin(pluginId)
    return PluginManager:disablePlugin(pluginId)
end

function PixelUI.forceUnloadPlugin(pluginId)
    return PluginManager:unloadPlugin(pluginId, true)
end

function PixelUI.getPluginDependencies(pluginId)
    local plugin = PluginManager:getPlugin(pluginId)
    if not plugin then return nil end
    
    local deps = {}
    for _, depString in ipairs(plugin.dependencies) do
        local dependency = PluginManager:parseDependency(depString)
        table.insert(deps, dependency)
    end
    return deps
end

function PixelUI.getPluginDependents(pluginId)
    return PluginManager:getDependents(pluginId)
end

function PixelUI.validatePluginDependencies(pluginId)
    local plugin = PluginManager:getPlugin(pluginId)
    if not plugin then return false, "Plugin not found" end
    
    local missing, incompatible = PluginManager:validateDependencies(plugin)
    return #missing == 0 and #incompatible == 0, missing, incompatible
end

function PixelUI.getPluginLoadOrder(pluginIds)
    local plugins = {}
    for _, id in ipairs(pluginIds) do
        local plugin = PluginManager:getPlugin(id)
        if plugin then
            plugins[id] = plugin
        end
    end
    return PluginManager:getLoadOrder(plugins)
end

function PixelUI.loadPluginFromFile(filePath)
    return PluginManager:loadPluginFromFile(filePath)
end

function PixelUI.loadPluginsFromDirectory(dirPath)
    return PluginManager:loadPluginsFromDirectory(dirPath)
end

function PixelUI.loadPluginFromURL(url, tempFileName)
    return PluginManager:loadPluginFromURL(url, tempFileName)
end

function PixelUI.listPlugins()
    return PluginManager:listPlugins()
end

function PixelUI.getPlugin(pluginId)
    return PluginManager:getPlugin(pluginId)
end

function PixelUI.isPluginLoaded(pluginId)
    return PluginManager:isPluginLoaded(pluginId)
end

function PixelUI.isPluginEnabled(pluginId)
    return PluginManager:isPluginEnabled(pluginId)
end

function PixelUI.runHook(hookName, ...)
    return PluginManager:runHook(hookName, ...)
end

function PixelUI.registerHook(hookName, hookFunc, plugin)
    return PluginManager:registerHook(hookName, hookFunc, plugin)
end

function PixelUI.getPluginTheme(themeName)
    return PluginManager:getTheme(themeName)
end

function PixelUI.listPluginThemes()
    return PluginManager:listThemes()
end

-- Event System API
function PixelUI.on(eventName, callback, once)
    return EventManager:on(eventName, callback, once)
end

function PixelUI.off(eventName, listenerId)
    return EventManager:off(eventName, listenerId)
end

function PixelUI.emit(eventName, data)
    return EventManager:emit(eventName, data)
end

function PixelUI.listEvents()
    return EventManager:listEvents()
end

-- Service Registry API
function PixelUI.registerService(serviceName, serviceInstance)
    return ServiceRegistry:register(serviceName, serviceInstance)
end

function PixelUI.unregisterService(serviceName)
    return ServiceRegistry:unregister(serviceName)
end

function PixelUI.getService(serviceName)
    return ServiceRegistry:get(serviceName)
end

function PixelUI.listServices()
    return ServiceRegistry:list()
end

function PixelUI.serviceExists(serviceName)
    return ServiceRegistry:exists(serviceName)
end

-- Configuration API
function PixelUI.getConfig(pluginId, key)
    return ConfigManager:get(pluginId, key)
end

function PixelUI.setConfig(pluginId, key, value)
    return ConfigManager:set(pluginId, key, value)
end

function PixelUI.getPluginConfig(pluginId)
    return ConfigManager:get(pluginId)
end

function PixelUI.setPluginConfig(pluginId, config)
    return ConfigManager:set(pluginId, config)
end

function PixelUI.resetPluginConfig(pluginId)
    return ConfigManager:reset(pluginId)
end

function PixelUI.validatePluginConfig(pluginId, schema)
    return ConfigManager:validate(pluginId, schema)
end

-- Drawing Utilities API
PixelUI.draw = DrawingUtils

-- Automatic plugin loading on init
local originalInit = PixelUI.init
function PixelUI.init()
    originalInit()
    
    -- Auto-load plugins from standard directory
    if fs.exists("plugins") and fs.isDir("plugins") then
        PixelUI.loadPluginsFromDirectory("plugins")
        
        -- Auto-enable all loaded plugins
        for _, plugin in pairs(PluginManager.plugins) do
            if plugin.loaded then
                PluginManager:enablePlugin(plugin.id)
            end
        end
    end
    
    PluginManager.initialized = true
end

-- Export plugin manager for advanced usage
PixelUI.PluginManager = PluginManager

-- Convenience API for plugin operations
PixelUI.plugins = {
    loadFromURL = function(url, tempFileName)
        return PixelUI.loadPluginFromURL(url, tempFileName)
    end,
    loadFromFile = function(filePath)
        return PixelUI.loadPluginFromFile(filePath)
    end,
    loadFromDirectory = function(dirPath)
        return PixelUI.loadPluginsFromDirectory(dirPath)
    end,
    list = function()
        return PixelUI.listPlugins()
    end,
    enable = function(pluginId)
        return PixelUI.enablePlugin(pluginId)
    end,
    disable = function(pluginId)
        return PixelUI.disablePlugin(pluginId)
    end,
    get = function(pluginId)
        return PixelUI.getPlugin(pluginId)
    end,
    isLoaded = function(pluginId)
        return PixelUI.isPluginLoaded(pluginId)
    end,
    isEnabled = function(pluginId)
        return PixelUI.isPluginEnabled(pluginId)
    end,
    -- Configuration shortcuts
    getConfig = function(pluginId, key)
        return PixelUI.getPluginConfig(pluginId, key)
    end,
    setConfig = function(pluginId, config)
        return PixelUI.setPluginConfig(pluginId, config)
    end,
    resetConfig = function(pluginId)
        return PixelUI.resetPluginConfig(pluginId)
    end,
    -- Dependency management shortcuts
    getDependencies = function(pluginId)
        return PixelUI.getPluginDependencies(pluginId)
    end,
    getDependents = function(pluginId)
        return PixelUI.getPluginDependents(pluginId)
    end,
    validateDependencies = function(pluginId)
        return PixelUI.validatePluginDependencies(pluginId)
    end,
    getLoadOrder = function(pluginIds)
        return PixelUI.getPluginLoadOrder(pluginIds)
    end,
    forceUnload = function(pluginId)
        return PixelUI.forceUnloadPlugin(pluginId)
    end
}

-- Event system shortcuts
PixelUI.events = {
    on = PixelUI.on,
    off = PixelUI.off,
    emit = PixelUI.emit,
    list = PixelUI.listEvents
}

-- Service registry shortcuts
PixelUI.services = {
    register = PixelUI.registerService,
    unregister = PixelUI.unregisterService,
    get = PixelUI.getService,
    list = PixelUI.listServices,
    exists = PixelUI.serviceExists
}

return PixelUI