-- PixelUI Framework Demo - Frame-based Component Showcase
-- This demo showcases each widget individually in separate frames

-- Load the PixelUI framework
local PixelUI = require("pixelui")

-- Initialize the UI framework
PixelUI.init()

-- Demo state and configuration
local demo = {
    currentFrame = 1,
    totalFrames = 24,  -- Increased to include RangeSlider and Chart demos
    frames = {
        {name = "Label", component = "label", 
         description = "Static text display widget with alignment and color options"},
        {name = "Button", component = "button", 
         description = "Interactive button widget with click events and styling"},
        {name = "TextBox", component = "textBox", 
         description = "Text input field with placeholder and change events"},
        {name = "CheckBox", component = "checkBox", 
         description = "Toggle checkbox with labels and state management"},
        {name = "Slider", component = "slider", 
         description = "Value slider with range and step controls"},
        {name = "RangeSlider", component = "rangeSlider", 
         description = "Dual-handle range slider for selecting value ranges"},
        {name = "ProgressBar", component = "progressBar", 
         description = "Visual progress indicator with customizable styling"},
        {name = "ListView", component = "listView", 
         description = "Scrollable list with item selection and events"},
        {name = "Container", component = "container", 
         description = "Layout container for organizing child widgets"},
        {name = "ToggleSwitch", component = "toggleSwitch", 
         description = "Modern toggle switch for boolean values"},
        {name = "RadioButton", component = "radioButton", 
         description = "Single selection from a group of options"},
        {name = "ComboBox", component = "comboBox", 
         description = "Dropdown selection list with expandable options"},
        {name = "TabControl", component = "tabControl", 
         description = "Tabbed interface for organizing content"},
        {name = "NumericUpDown", component = "numericUpDown", 
         description = "Numeric input with increment/decrement buttons"},
        {name = "GroupBox", component = "groupBox", 
         description = "Visual grouping container with border and title"},
        {name = "Canvas", component = "canvas", 
         description = "Custom drawing surface for pixel-level graphics"},
        {name = "Chart", component = "chart", 
         description = "Data visualization with line, bar, and scatter chart types"},
        {name = "MsgBox", component = "msgBox", 
         description = "Modal message box dialog with buttons and icons"},
        {name = "ColorPicker", component = "colorPicker", 
         description = "Interactive color picker dialog with palette and preview"},
        {name = "Loading", component = "loading", 
         description = "Loading indicators and spinners for progress display"},
        {name = "Animation", component = "animation",
         description = "Advanced animation system: move, color, bounce, fade, and more!"},
        {name = "Draggable", component = "draggable",
         description = "Draggable widget: drag the box by its header area!"},
        {name = "ScrollBar", component = "scrollBar",
         description = "Standalone ScrollBar widget: vertical and horizontal styles, interactive!"},
        {name = "Scrollable", component = "scrollable",
         description = "Scrollable container: try scrolling the content with mouse wheel!"}
    },
    -- Component-specific state
    state = {
        textInput = "",
        checkboxState = false,
        sliderValue = 50,
        rangeSliderMin = 25,
        rangeSliderMax = 75,
        progressValue = 35,
        selectedItem = 1,
        listItems = {"Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"},
        buttonClicks = 0,
        labelText = "Hello, PixelUI!",
        toggleState = false,
        radioGroup1 = 1,
        comboSelection = 1,
        tabSelection = 1,
        numericValue = 42,
        containerBorder = true,
        canvasPattern = 1,
        msgBoxResult = "None",
        showMsgBox = false,
        selectedColor = colors.white,
        colorPickerVisible = false,
        -- Chart state
        chartType = "line",
        chartRenderMode = "lines",
        chartData = {
            {x = 1, y = 10}, {x = 2, y = 25}, {x = 3, y = 15}, {x = 4, y = 30}, 
            {x = 5, y = 20}, {x = 6, y = 35}, {x = 7, y = 28}, {x = 8, y = 40}
        },
        -- Loading indicator states
        loadingProgress = 25,
        spinnerActive = true,
        loadingStyle = "bar",
        spinnerStyle = "classic",
        -- ScrollBar state
        scrollBarValue = 30,
        scrollBarHValue = 60
    }
}

-- Navigation functions
function demo:nextFrame()
    if self.currentFrame < self.totalFrames then
        self.currentFrame = self.currentFrame + 1
        self:refreshFrame()
    end
end

function demo:prevFrame()
    if self.currentFrame > 1 then
        self.currentFrame = self.currentFrame - 1
        self:refreshFrame()
    end
end

function demo:refreshFrame()
    PixelUI.clear()
    self:createFrameUI()
end

-- Main frame UI creation
function demo:createFrameUI()
    local frame = self.frames[self.currentFrame]
    
    -- Title bar
    PixelUI.label({
        x = 2, y = 1,
        text = "PixelUI Demo - Frame " .. self.currentFrame .. " of " .. self.totalFrames,
        color = colors.yellow
    })
    
    -- Component name and description
    PixelUI.label({
        x = 2, y = 3,
        text = "Component: " .. frame.name,
        color = colors.lime
    })
    
    PixelUI.label({
        x = 2, y = 4,
        text = frame.description,
        color = colors.lightGray
    })
    
    -- Navigation buttons
    if self.currentFrame > 1 then
        PixelUI.button({
            x = 2, y = 18,
            text = "< Previous",
            background = colors.blue,
            color = colors.white,
            width = 12,
            height = 1,
            onClick = function()
                self:prevFrame()
            end
        })
    end
    
    if self.currentFrame < self.totalFrames then
        PixelUI.button({
            x = 16, y = 18,
            text = "Next >",
            background = colors.blue,
            color = colors.white,
            width = 12,
            height = 1,
            onClick = function()
                self:nextFrame()
            end
        })
    end
    
    -- Quit button
    PixelUI.button({
        x = 45, y = 18,
        text = "Quit",
        background = colors.red,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            self.running = false
        end
    })
    
    -- Component-specific demo
    self:createComponentDemo(frame.component)
end

-- Create component-specific demonstrations
function demo:createComponentDemo(component)
    if component == "label" then
        self:createLabelDemo()
    elseif component == "button" then
        self:createButtonDemo()
    elseif component == "textBox" then
        self:createTextBoxDemo()
    elseif component == "checkBox" then
        self:createCheckBoxDemo()
    elseif component == "slider" then
        self:createSliderDemo()
    elseif component == "rangeSlider" then
        self:createRangeSliderDemo()
    elseif component == "progressBar" then
        self:createProgressBarDemo()
    elseif component == "listView" then
        self:createListViewDemo()
    elseif component == "container" then
        self:createContainerDemo()
    elseif component == "toggleSwitch" then
        self:createToggleSwitchDemo()
    elseif component == "radioButton" then
        self:createRadioButtonDemo()
    elseif component == "comboBox" then
        self:createComboBoxDemo()
    elseif component == "tabControl" then
        self:createTabControlDemo()
    elseif component == "numericUpDown" then
        self:createNumericUpDownDemo()
    elseif component == "groupBox" then
        self:createGroupBoxDemo()
    elseif component == "canvas" then
        self:createCanvasDemo()
    elseif component == "chart" then
        self:createChartDemo()
    elseif component == "msgBox" then
        self:createMsgBoxDemo()
    elseif component == "colorPicker" then
        self:createColorPickerDemo()
    elseif component == "loading" then
        self:createLoadingDemo()
    elseif component == "animation" then
        self:createAnimationDemo()
    elseif component == "draggable" then
        self:createDraggableDemo()
    elseif component == "scrollBar" then
        self:createScrollBarDemo()
    elseif component == "scrollable" then
        self:createScrollableDemo()
    end
end

-- Label demonstration
function demo:createLabelDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Basic Label:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 7,
        text = self.state.labelText,
        color = colors.cyan
    })
    
    PixelUI.label({
        x = 2, y = 9,
        text = "Colored Labels:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 10,
        text = "Red Text",
        color = colors.red
    })
    
    PixelUI.label({
        x = 12, y = 10,
        text = "Green Text",
        color = colors.green
    })
    
    PixelUI.label({
        x = 24, y = 10,
        text = "Blue Text",
        color = colors.blue
    })
    
    -- Change text button
    PixelUI.button({
        x = 2, y = 12,
        text = "Change Text",
        background = colors.orange,
        color = colors.white,
        width = 14,
        height = 1,
        onClick = function()
            local texts = {"Hello, World!", "PixelUI Rocks!", "Amazing Labels!", "Cool Framework!"}
            self.state.labelText = texts[math.random(#texts)]
            self:refreshFrame()
        end
    })
end

-- Button demonstration
function demo:createButtonDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Button Examples:",
        color = colors.white
    })
    
    PixelUI.button({
        x = 2, y = 8,
        text = "Click Me! (" .. self.state.buttonClicks .. ")",
        background = colors.green,
        color = colors.white,
        width = 20,
        height = 2,
        onClick = function()
            self.state.buttonClicks = self.state.buttonClicks + 1
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 25, y = 8,
        text = "Disabled",
        background = colors.gray,
        color = colors.lightGray,
        enabled = false,
        width = 12,
        height = 2
    })
    
    PixelUI.button({
        x = 2, y = 11,
        text = "Small",
        background = colors.purple,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            print("Small button clicked!")
        end
    })
    
    PixelUI.button({
        x = 12, y = 11,
        text = "Medium Button",
        background = colors.orange,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            print("Medium button clicked!")
        end
    })
end

-- TextBox demonstration
function demo:createTextBoxDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Text Input:",
        color = colors.white
    })
    
    PixelUI.textBox({
        x = 2, y = 8,
        width = 30,
        placeholder = "Type something here...",
        color = colors.white,
        background = colors.black,
        onChange = function(self, text)
            demo.state.textInput = text
        end
    })
    
    PixelUI.label({
        x = 2, y = 10,
        text = "You typed: " .. self.state.textInput,
        color = colors.lime
    })
    
    PixelUI.button({
        x = 2, y = 12,
        text = "Clear",
        background = colors.red,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.textInput = ""
            self:refreshFrame()
        end
    })
end

-- CheckBox demonstration
function demo:createCheckBoxDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Checkbox Examples:",
        color = colors.white
    })
    
    PixelUI.checkBox({
        x = 2, y = 8,
        text = "Enable notifications",
        checked = self.state.checkboxState,
        color = colors.white,
        onToggle = function(self, checked)
            demo.state.checkboxState = checked
            demo:refreshFrame()
        end
    })
    
    PixelUI.checkBox({
        x = 2, y = 10,
        text = "Always checked (disabled)",
        checked = true,
        enabled = false,
        color = colors.gray
    })
    
    PixelUI.label({
        x = 2, y = 12,
        text = "Notifications are: " .. (self.state.checkboxState and "ON" or "OFF"),
        color = self.state.checkboxState and colors.green or colors.red
    })
end

-- Slider demonstration
function demo:createSliderDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Slider (Value: " .. self.state.sliderValue .. "):",
        color = colors.white
    })
    
    PixelUI.slider({
        x = 2, y = 8,
        width = 30,
        value = self.state.sliderValue,
        min = 0,
        max = 100,
        step = 5,
        onChange = function(self, value)
            demo.state.sliderValue = value
            demo:refreshFrame()
        end
    })
    
    -- Visual representation
    local barWidth = math.floor(self.state.sliderValue / 100 * 20)
    PixelUI.label({
        x = 2, y = 10,
        text = "Visual: [" .. string.rep("=", barWidth) .. string.rep("-", 20 - barWidth) .. "]",
        color = colors.cyan
    })
    
    PixelUI.button({
        x = 2, y = 12,
        text = "Random",
        background = colors.purple,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.state.sliderValue = math.random(0, 100)
            self:refreshFrame()
        end
    })
end

-- RangeSlider demonstration
function demo:createRangeSliderDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Range Slider (Range: " .. self.state.rangeSliderMin .. " - " .. self.state.rangeSliderMax .. "):",
        color = colors.white
    })
    
    PixelUI.rangeSlider({
        x = 2, y = 8,
        width = 30,
        minValue = self.state.rangeSliderMin,
        maxValue = self.state.rangeSliderMax,
        rangeMin = 0,
        rangeMax = 100,
        step = 5,
        onChange = function(self, minVal, maxVal)
            demo.state.rangeSliderMin = minVal
            demo.state.rangeSliderMax = maxVal
            demo:refreshFrame()
        end
    })
    
    -- Visual representation of selected range
    local totalWidth = 30
    local minPos = math.floor(self.state.rangeSliderMin / 100 * totalWidth)
    local maxPos = math.floor(self.state.rangeSliderMax / 100 * totalWidth)
    local beforeRange = string.rep(".", minPos)
    local withinRange = string.rep("=", maxPos - minPos)
    local afterRange = string.rep(".", totalWidth - maxPos)
    
    PixelUI.label({
        x = 2, y = 10,
        text = "Visual: [" .. beforeRange .. withinRange .. afterRange .. "]",
        color = colors.cyan
    })
    
    PixelUI.label({
        x = 2, y = 11,
        text = "Range size: " .. (self.state.rangeSliderMax - self.state.rangeSliderMin),
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 2, y = 13,
        text = "Random Range",
        background = colors.orange,
        color = colors.white,
        width = 14,
        height = 1,
        onClick = function()
            local min = math.random(0, 70)
            local max = math.random(min + 10, 100)
            self.state.rangeSliderMin = min
            self.state.rangeSliderMax = max
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 18, y = 13,
        text = "Reset",
        background = colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.rangeSliderMin = 25
            self.state.rangeSliderMax = 75
            self:refreshFrame()
        end
    })
end

-- ProgressBar demonstration
function demo:createProgressBarDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Progress Bar (" .. self.state.progressValue .. "%):",
        color = colors.white
    })
    
    PixelUI.progressBar({
        x = 2, y = 8,
        width = 30,
        value = self.state.progressValue,
        max = 100,
        color = colors.lime,
        background = colors.gray
    })
    
    PixelUI.button({
        x = 2, y = 10,
        text = "+10%",
        background = colors.green,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.progressValue = math.min(100, self.state.progressValue + 10)
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 12, y = 10,
        text = "-10%",
        background = colors.orange,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.progressValue = math.max(0, self.state.progressValue - 10)
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 22, y = 10,
        text = "Reset",
        background = colors.red,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.progressValue = 0
            self:refreshFrame()
        end
    })
end

-- ListView demonstration
function demo:createListViewDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "List View:",
        color = colors.white
    })
    
    PixelUI.listView({
        x = 2, y = 8,
        width = 20,
        height = 6,
        items = self.state.listItems,
        selectedIndex = self.state.selectedItem,
        onSelect = function(self, item, index)
            demo.state.selectedItem = index
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 25, y = 8,
        text = "Selected:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 25, y = 9,
        text = self.state.listItems[self.state.selectedItem] or "None",
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 25, y = 10,
        text = "Index: " .. self.state.selectedItem,
        color = colors.cyan
    })
end

-- Container demonstration
function demo:createContainerDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Container with Border:",
        color = colors.white
    })
    
    -- Main container
    PixelUI.container({
        x = 2, y = 8,
        width = 40,
        height = 8,
        background = colors.black,
        border = true,
        borderColor = colors.blue
    })
    
    -- Content inside container
    PixelUI.label({
        x = 4, y = 9,
        text = "This content is inside the container",
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 4, y = 11,
        text = "Button in Container",
        background = colors.green,
        color = colors.white,
        width = 18,
        height = 1,
        onClick = function()
            print("Container button clicked!")
        end
    })
    
    PixelUI.label({
        x = 4, y = 13,
        text = "Containers organize child widgets",
        color = colors.cyan
    })
    
    PixelUI.label({
        x = 4, y = 14,
        text = "and provide visual grouping.",
        color = colors.cyan
    })
end

-- ToggleSwitch demonstration
function demo:createToggleSwitchDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Modern Toggle Switch Examples:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 8,
        text = "Wi-Fi:",
        color = colors.white
    })
    
    PixelUI.toggleSwitch({
        x = 10, y = 8,
        text = "Enable",
        checked = self.state.toggleState,
        onToggle = function(self, checked)
            demo.state.toggleState = checked
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 2, y = 10,
        text = "Bluetooth:",
        color = colors.gray
    })
    
    PixelUI.toggleSwitch({
        x = 13, y = 10,
        text = "Connect",
        checked = false,
        enabled = false
    })
    
    PixelUI.label({
        x = 2, y = 12,
        text = "Dark Mode:",
        color = colors.white
    })
    
    PixelUI.toggleSwitch({
        x = 14, y = 12,
        checked = self.state.darkMode or false,
        onToggle = function(self, checked)
            demo.state.darkMode = checked
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 2, y = 14,
        text = "Notifications:",
        color = colors.white
    })
    
    PixelUI.toggleSwitch({
        x = 17, y = 14,
        text = "Allow",
        checked = self.state.notifications ~= false,
        color = colors.yellow,
        onToggle = function(self, checked)
            demo.state.notifications = checked
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 2, y = 16,
        text = "Status: Wi-Fi is " .. (self.state.toggleState and "ON" or "OFF") .. 
              ", Dark Mode " .. (self.state.darkMode and "ON" or "OFF"),
        color = self.state.toggleState and colors.green or colors.red
    })
    
    PixelUI.button({
        x = 2, y = 18,
        text = "Toggle All",
        background = colors.purple,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            self.state.toggleState = not self.state.toggleState
            self.state.darkMode = not self.state.darkMode
            self.state.notifications = not self.state.notifications
            self:refreshFrame()
        end
    })
end

-- RadioButton demonstration
function demo:createRadioButtonDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Radio Button Group (Select Theme):",
        color = colors.white
    })
    
    local themes = {"Light", "Dark", "Auto", "Classic"}
    
    for i, theme in ipairs(themes) do
        PixelUI.radioButton({
            x = 2, y = 7 + i,
            text = theme,
            checked = self.state.radioGroup1 == i,
            group = "theme",
            onSelect = function()
                demo.state.radioGroup1 = i
                demo:refreshFrame()
            end
        })
    end
    
    PixelUI.label({
        x = 25, y = 8,
        text = "Selected Theme:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 25, y = 9,
        text = themes[self.state.radioGroup1],
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 25, y = 11,
        text = "Radio buttons allow",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 25, y = 12,
        text = "single selection from",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 25, y = 13,
        text = "a group of options.",
        color = colors.lightGray
    })
end

-- ComboBox demonstration
function demo:createComboBoxDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Combo Box (Dropdown):",
        color = colors.white
    })
    
    local countries = {"United States", "Canada", "United Kingdom", "Germany", "France", "Japan", "Australia"}
    
    PixelUI.comboBox({
        x = 2, y = 8,
        width = 20,
        items = countries,
        selectedIndex = self.state.comboSelection,
        onSelect = function(combobox, item, index)
            demo.state.comboSelection = index
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 2, y = 10,
        text = "Selected Country:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 11,
        text = countries[self.state.comboSelection],
        color = colors.lime
    })
    
    PixelUI.label({
        x = 25, y = 8,
        text = "ComboBox provides",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 25, y = 9,
        text = "a dropdown list for",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 25, y = 10,
        text = "space-efficient",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 25, y = 11,
        text = "selection.",
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 2, y = 13,
        text = "Random Country",
        background = colors.orange,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            self.state.comboSelection = math.random(1, #countries)
            self:refreshFrame()
        end
    })
end

-- TabControl demonstration
function demo:createTabControlDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Tab Control:",
        color = colors.white
    })
    
    local tabs = {
        {text = "General"},
        {text = "Advanced"}, 
        {text = "Security"},
        {text = "About"}
    }
    
    PixelUI.tabControl({
        x = 2, y = 8,
        width = 40,
        height = 8,
        tabs = tabs,
        selectedIndex = self.state.tabSelection,
        onChange = function(widget, index)
            demo.state.tabSelection = index
            demo:refreshFrame()
        end
    })
    
    -- Tab content
    local content = {
        "General settings and preferences",
        "Advanced configuration options",
        "Security and privacy settings",
        "About this application v1.0"
    }
    
    PixelUI.label({
        x = 4, y = 11,
        text = content[self.state.tabSelection],
        color = colors.cyan
    })
    
    if self.state.tabSelection == 1 then
        PixelUI.checkBox({
            x = 4, y = 13,
            text = "Auto-save enabled",
            checked = true,
            color = colors.white
        })
    elseif self.state.tabSelection == 2 then
        PixelUI.label({
            x = 4, y = 13,
            text = "Debug mode: OFF",
            color = colors.red
        })
    elseif self.state.tabSelection == 3 then
        PixelUI.label({
            x = 4, y = 13,
            text = "Encryption: AES-256",
            color = colors.green
        })
    else
        PixelUI.label({
            x = 4, y = 13,
            text = "Copyright 2024 PixelUI",
            color = colors.lightGray
        })
    end
end

-- NumericUpDown demonstration
function demo:createNumericUpDownDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Numeric Up/Down:",
        color = colors.white
    })
    
    PixelUI.numericUpDown({
        x = 2, y = 8,
        width = 15,
        value = self.state.numericValue,
        min = 0,
        max = 999,
        step = 1,
        onChange = function(self, value)
            demo.state.numericValue = value
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 20, y = 8,
        text = "Current: " .. self.state.numericValue,
        color = colors.cyan
    })
    
    PixelUI.label({
        x = 2, y = 10,
        text = "Range: 0 to 999",
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 2, y = 12,
        text = "Set to 100",
        background = colors.green,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.state.numericValue = 100
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 14, y = 12,
        text = "Random",
        background = colors.purple,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.state.numericValue = math.random(0, 999)
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 26, y = 12,
        text = "Reset",
        background = colors.red,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.numericValue = 42
            self:refreshFrame()
        end
    })
end

-- GroupBox demonstration
function demo:createGroupBoxDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Group Box Examples:",
        color = colors.white
    })
    
    -- First group box
    PixelUI.groupBox({
        x = 2, y = 8,
        width = 20,
        height = 4,
        title = "User Settings",
        titleColor = colors.yellow,
        borderColor = colors.blue
    })
    
    PixelUI.checkBox({
        x = 4, y = 9,
        text = "Show tooltips",
        checked = true,
        color = colors.white
    })
    
    PixelUI.checkBox({
        x = 4, y = 10,
        text = "Auto-backup",
        checked = false,
        color = colors.white
    })
    
    -- Second group box
    PixelUI.groupBox({
        x = 25, y = 8,
        width = 18,
        height = 5,
        title = "Display",
        titleColor = colors.lime,
        borderColor = colors.green
    })
    
    PixelUI.radioButton({
        x = 27, y = 9,
        text = "Windowed",
        checked = true,
        group = "display"
    })
    
    PixelUI.radioButton({
        x = 27, y = 10,
        text = "Fullscreen",
        checked = false,
        group = "display"
    })
    
    PixelUI.label({
        x = 2, y = 14,
        text = "GroupBoxes organize related controls visually",
        color = colors.lightGray
    })
end

-- Canvas demonstration
function demo:createCanvasDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Canvas (Custom Drawing):",
        color = colors.white
    })
    
    PixelUI.canvas({
        x = 2, y = 8,
        width = 30,
        height = 6,
        background = colors.black,
        border = true,
        borderColor = colors.white,
        onDraw = function(self, canvas)
            -- Draw a simple pattern
            for x = 1, self.width - 2 do
                for y = 1, self.height - 2 do
                    local color = colors.blue
                    if (x + y) % 2 == 0 then
                        color = colors.lightBlue
                    end
                    if x == math.floor(self.width / 2) or y == math.floor(self.height / 2) then
                        color = colors.yellow
                    end
                    canvas:setPixel(x, y, color)
                end
            end
        end
    })
    
    PixelUI.label({
        x = 35, y = 10,
        text = "Canvas allows",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 11,
        text = "custom pixel-level",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 10,
        text = "drawing and",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 11,
        text = "graphics.",
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 2, y = 15,
        text = "Redraw",
        background = colors.purple,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self:refreshFrame()
        end
    })
end

-- Chart demonstration
function demo:createChartDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Chart Widget (" .. self.state.chartType .. " chart, " .. self.state.chartRenderMode .. " mode):",
        color = colors.white
    })
    
    PixelUI.chart({
        x = 2, y = 8,
        width = 35,
        height = 10,
        data = self.state.chartData,
        chartType = self.state.chartType,
        renderMode = self.state.chartRenderMode,
        title = "Sample Data",
        xLabel = "Time",
        yLabel = "Value",
        dataColor = colors.cyan,
        showGrid = true
    })
    
    -- Chart type buttons
    PixelUI.label({
        x = 40, y = 8,
        text = "Chart Types:",
        color = colors.lightGray
    })
    
    PixelUI.button({
        x = 40, y = 10,
        text = "Line",
        background = self.state.chartType == "line" and colors.green or colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.chartType = "line"
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 40, y = 11,
        text = "Bar",
        background = self.state.chartType == "bar" and colors.green or colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.chartType = "bar"
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 40, y = 12,
        text = "Scatter",
        background = self.state.chartType == "scatter" and colors.green or colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.state.chartType = "scatter"
            self:refreshFrame()
        end
    })
    
    -- Render mode buttons (only for line charts)
    if self.state.chartType == "line" then
        PixelUI.label({
            x = 40, y = 13,
            text = "Render Mode:",
            color = colors.lightGray
        })
        
        PixelUI.button({
            x = 40, y = 14,
            text = "Lines",
            background = self.state.chartRenderMode == "lines" and colors.green or colors.gray,
            color = colors.white,
            width = 6,
            height = 1,
            onClick = function()
                self.state.chartRenderMode = "lines"
                self:refreshFrame()
            end
        })
        
        PixelUI.button({
            x = 47, y = 14,
            text = "Pixels",
            background = self.state.chartRenderMode == "pixels" and colors.green or colors.gray,
            color = colors.white,
            width = 6,
            height = 1,
            onClick = function()
                self.state.chartRenderMode = "pixels"
                self:refreshFrame()
            end
        })
    end
    
    -- Data manipulation buttons
    PixelUI.button({
        x = 40, y = self.state.chartType == "line" and 16 or 14,
        text = "New Data",
        background = colors.orange,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.state.chartData = {}
            for i = 1, 8 do
                table.insert(self.state.chartData, {x = i, y = math.random(5, 45)})
            end
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 40, y = self.state.chartType == "line" and 17 or 15,
        text = "Add Point",
        background = colors.blue,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            local nextX = #self.state.chartData + 1
            table.insert(self.state.chartData, {x = nextX, y = math.random(5, 45)})
            self:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 40, y = self.state.chartType == "line" and 18 or 16,
        text = "Clear",
        background = colors.red,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.state.chartData = {}
            self:refreshFrame()
        end
    })
end

-- MsgBox demonstration
function demo:createMsgBoxDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Message Box System:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 8,
        text = "Click buttons to show different message boxes:",
        color = colors.lightGray
    })
    
    -- Info message box
    PixelUI.button({
        x = 2, y = 10,
        text = "Info Message",
        background = colors.blue,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            PixelUI.msgBox({
                title = "Information",
                message = "This is an informational message box.\n\nIt can contain multiple lines of text.",
                icon = "info",
                buttons = {"OK"},
                onButton = function(msgbox, buttonIndex, buttonText)
                    demo.state.msgBoxResult = "Info: " .. buttonText
                    demo:refreshFrame()
                end
            })
        end
    })
    
    -- Warning message box
    PixelUI.button({
        x = 20, y = 10,
        text = "Warning",
        background = colors.orange,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            PixelUI.msgBox({
                title = "Warning",
                message = "This is a warning message. Are you sure you want to continue?",
                icon = "warning",
                buttons = {"Yes", "No"},
                onButton = function(msgbox, buttonIndex, buttonText)
                    demo.state.msgBoxResult = "Warning: " .. buttonText
                    demo:refreshFrame()
                end
            })
        end
    })
    
    -- Error message box
    PixelUI.button({
        x = 2, y = 12,
        text = "Error Message",
        background = colors.red,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            PixelUI.msgBox({
                title = "Error",
                message = "An error has occurred!\n\nOperation failed: File not found.",
                icon = "error",
                buttons = {"Retry", "Cancel"},
                onButton = function(msgbox, buttonIndex, buttonText)
                    demo.state.msgBoxResult = "Error: " .. buttonText
                    demo:refreshFrame()
                end
            })
        end
    })
    
    -- Question message box
    PixelUI.button({
        x = 20, y = 12,
        text = "Question",
        background = colors.cyan,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            PixelUI.msgBox({
                title = "Question",
                message = "Do you want to save your changes before closing?",
                icon = "question",
                buttons = {"Save", "Don't Save", "Cancel"},
                onButton = function(msgbox, buttonIndex, buttonText)
                    demo.state.msgBoxResult = "Question: " .. buttonText
                    demo:refreshFrame()
                end
            })
        end
    })
    
    -- Custom message box
    PixelUI.button({
        x = 2, y = 14,
        text = "Custom Colors",
        background = colors.purple,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            PixelUI.msgBox({
                title = "Custom Style",
                message = "This message box has custom colors and styling!",
                icon = "info",
                buttons = {"Cool!", "Awesome!"},
                background = colors.pink,
                color = colors.black,
                titleColor = colors.purple,
                buttonBackground = colors.purple,
                buttonColor = colors.white,
                onButton = function(msgbox, buttonIndex, buttonText)
                    demo.state.msgBoxResult = "Custom: " .. buttonText
                    demo:refreshFrame()
                end
            })
        end
    })
    
    -- Show last result
    PixelUI.label({
        x = 2, y = 16,
        text = "Last Result: " .. self.state.msgBoxResult,
        color = colors.lime
    })
    
    PixelUI.label({
        x = 35, y = 10,
        text = "MsgBox features:",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 11,
        text = "- Multiple buttons",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 12,
        text = "- Different icons",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 13,
        text = "- Custom styling",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 14,
        text = "- Multi-line text",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 15,
        text = "- Modal dialogs",
        color = colors.lightGray
    })
end

-- ColorPicker demonstration
function demo:createColorPickerDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Color Picker System:",
        color = colors.white
    })
    
    PixelUI.label({
        x = 2, y = 8,
        text = "Interactive color selection with preview:",
        color = colors.lightGray
    })
    
    -- Color picker widget
    PixelUI.colorPicker({
        x = 2, y = 10,
        gridColumns = 4,
        colorSize = 2,
        showPreview = true,
        showName = true,
        selectedColor = self.state.selectedColor,
        onChange = function(colorpicker, color, index, name)
            demo.state.selectedColor = color
            demo:refreshFrame()
        end
    })
    
    -- Current selection display
    PixelUI.label({
        x = 25, y = 10,
        text = "Current Selection:",
        color = colors.white
    })
    
    -- Show selected color as a small preview
    PixelUI.label({
        x = 25, y = 12,
        text = "Color: ",
        color = colors.white
    })
    
    -- Color preview block
    for i = 0, 2 do
        for j = 0, 1 do
            PixelUI.label({
                x = 32 + i, y = 12 + j,
                text = " ",
                background = self.state.selectedColor,
                color = self.state.selectedColor
            })
        end
    end
    
    -- Show color name/info
    local colorNames = {
        [colors.white] = "White",
        [colors.orange] = "Orange", 
        [colors.magenta] = "Magenta",
        [colors.lightBlue] = "Light Blue",
        [colors.yellow] = "Yellow",
        [colors.lime] = "Lime",
        [colors.pink] = "Pink",
        [colors.gray] = "Gray",
        [colors.lightGray] = "Light Gray",
        [colors.cyan] = "Cyan",
        [colors.purple] = "Purple",
        [colors.blue] = "Blue",
        [colors.brown] = "Brown",
        [colors.green] = "Green",
        [colors.red] = "Red",
        [colors.black] = "Black"
    }
    
    PixelUI.label({
        x = 25, y = 14,
        text = "Name: " .. (colorNames[self.state.selectedColor] or "Unknown"),
        color = colors.cyan
    })
    
    PixelUI.label({
        x = 25, y = 15,
        text = "Value: " .. tostring(self.state.selectedColor),
        color = colors.lightGray
    })
    
    -- Create ColorPickerDialog button
    PixelUI.button({
        x = 2, y = 17,
        text = "Open Color Dialog",
        background = colors.blue,
        color = colors.white,
        width = 18,
        height = 1,
        onClick = function()
            if not demo.state.colorPickerDialog then
                demo.state.colorPickerDialog = PixelUI.colorPickerDialog({
                    title = "Choose Your Color",
                    selectedColor = demo.state.selectedColor,
                    onColorSelected = function(color)
                        demo.state.selectedColor = color
                        demo:refreshFrame()
                    end,
                    onCancel = function()
                        -- Color selection was cancelled
                    end
                })
            end
            demo.state.colorPickerDialog:show()
        end
    })
    
    -- Reset button
    PixelUI.button({
        x = 22, y = 17,
        text = "Reset to White",
        background = colors.purple,
        color = colors.white,
        width = 15,
        height = 1,
        onClick = function()
            demo.state.selectedColor = colors.white
            demo:refreshFrame()
        end
    })
    
    -- Random color button
    PixelUI.button({
        x = 39, y = 17,
        text = "Random",
        background = colors.orange,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            local availableColors = {
                colors.white, colors.orange, colors.magenta, colors.lightBlue,
                colors.yellow, colors.lime, colors.pink, colors.gray,
                colors.lightGray, colors.cyan, colors.purple, colors.blue,
                colors.brown, colors.green, colors.red, colors.black
            }
            demo.state.selectedColor = availableColors[math.random(#availableColors)]
            demo:refreshFrame()
        end
    })
end

-- Loading demonstration
function demo:createLoadingDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Loading Indicators & Spinners:",
        color = colors.white
    })
    
    -- Simple loading bar
    PixelUI.label({
        x = 2, y = 8,
        text = "Loading Bar (" .. self.state.loadingProgress .. "%):",
        color = colors.white
    })
    
    PixelUI.loadingIndicator({
        x = 2, y = 9,
        width = 25,
        progress = self.state.loadingProgress,
        style = self.state.loadingStyle,
        color = colors.cyan,
        background = colors.gray,
        text = "Loading...",
        showPercent = true,
        animated = true
    })
    
    -- Progress controls
    PixelUI.button({
        x = 2, y = 11,
        text = "+10%",
        background = colors.green,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            demo.state.loadingProgress = math.min(100, demo.state.loadingProgress + 10)
            demo:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 10, y = 11,
        text = "-10%",
        background = colors.orange,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            demo.state.loadingProgress = math.max(0, demo.state.loadingProgress - 10)
            demo:refreshFrame()
        end
    })
    
    PixelUI.button({
        x = 18, y = 11,
        text = "Reset",
        background = colors.red,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            demo.state.loadingProgress = 25
            demo:refreshFrame()
        end
    })
    
    -- Style selector
    PixelUI.button({
        x = 26, y = 11,
        text = "Style",
        background = colors.purple,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            local styles = {"bar", "dots", "pulse"}
            local currentIndex = 1
            for i, style in ipairs(styles) do
                if style == demo.state.loadingStyle then
                    currentIndex = i
                    break
                end
            end
            demo.state.loadingStyle = styles[(currentIndex % #styles) + 1]
            demo:refreshFrame()
        end
    })
    
    -- Spinners section
    PixelUI.label({
        x = 2, y = 13,
        text = "Animated Spinners:",
        color = colors.white
    })
    
    -- Classic spinner
    PixelUI.label({
        x = 2, y = 15,
        text = "Classic:",
        color = colors.lightGray
    })
    
    PixelUI.spinner({
        x = 11, y = 15,
        style = "classic",
        color = colors.cyan,
        text = "Loading...",
        textPosition = "right",
        active = self.state.spinnerActive
    })
    
    -- Dots spinner
    PixelUI.label({
        x = 25, y = 15,
        text = "Dots:",
        color = colors.lightGray
    })
    
    PixelUI.spinner({
        x = 31, y = 15,
        style = "dots",
        color = colors.lime,
        active = self.state.spinnerActive
    })
    
    -- Arrow spinner
    PixelUI.label({
        x = 2, y = 16,
        text = "Arrow:",
        color = colors.lightGray
    })
    
    PixelUI.spinner({
        x = 10, y = 16,
        style = "arrow",
        color = colors.yellow,
        active = self.state.spinnerActive
    })
    
    -- Clock spinner
    PixelUI.label({
        x = 17, y = 16,
        text = "Clock:",
        color = colors.lightGray
    })
    
    PixelUI.spinner({
        x = 25, y = 16,
        style = "clock",
        color = colors.orange,
        active = self.state.spinnerActive
    })
    
    -- Bar spinner
    PixelUI.label({
        x = 2, y = 17,
        text = "Bar:",
        color = colors.lightGray
    })
    
    PixelUI.spinner({
        x = 8, y = 17,
        style = "bar",
        color = colors.magenta,
        active = self.state.spinnerActive
    })
    
    -- Spinner controls
    PixelUI.button({
        x = 20, y = 17,
        text = self.state.spinnerActive and "Stop" or "Start",
        background = self.state.spinnerActive and colors.red or colors.green,
        color = colors.white,
        width = 6,
        height = 1,
        onClick = function()
            demo.state.spinnerActive = not demo.state.spinnerActive
            demo:refreshFrame()
        end
    })
    
    -- Style info
    PixelUI.label({
        x = 35, y = 8,
        text = "Current style:",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 9,
        text = string.upper(self.state.loadingStyle),
        color = colors.yellow
    })
    
    PixelUI.label({
        x = 35, y = 11,
        text = "Features:",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 35, y = 12,
        text = "* Animated",
        color = colors.white
    })
    
    PixelUI.label({
        x = 35, y = 13,
        text = "* Customizable",
        color = colors.white
    })
    
    PixelUI.label({
        x = 35, y = 14,
        text = "* Progress tracking",
        color = colors.white
    })
    
    PixelUI.label({
        x = 35, y = 15,
        text = "* Multiple styles",
        color = colors.white
    })
    
    PixelUI.label({
        x = 35, y = 16,
        text = "* Start/stop control",
        color = colors.white
    })
end

-- Animation demonstration
function demo:createAnimationDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Advanced Animation Demo:",
        color = colors.white
    })
    
    -- Animated box
    local box = PixelUI.button({
        x = 5, y = 10,
        width = 10, height = 3,
        text = "Animate Me!",
        background = colors.purple,
        color = colors.white,
        onClick = function(self)
            -- Animate position, color, and width
            PixelUI.animate(self, {
                to = { x = 30, width = 18 },
                duration = 1.2,
                easing = "outQuad",
                onComplete = function(w)
                    PixelUI.animate(w, {
                        to = { x = 5, width = 10 },
                        duration = 1.2,
                        easing = "inQuad"
                    })
                end
            })
            -- Animate color
            PixelUI.animate(self, {
                to = { background = colors.orange },
                duration = 0.6,
                easing = "linear",
                onComplete = function(w)
                    PixelUI.animate(w, {
                        to = { background = colors.purple },
                        duration = 0.6
                    })
                end
            })
        end
    })
    
    -- Animate on load (bounce)
    PixelUI.animate(box, {
        to = { y = 7 },
        duration = 0.5,
        easing = function(t) return math.sin(t * math.pi) end,
        onComplete = function(w)
            PixelUI.animate(w, {
                to = { y = 10 },
                duration = 0.5,
                easing = function(t) return math.sin(t * math.pi) end
            })
        end
    })
    
    PixelUI.label({
        x = 2, y = 15,
        text = "Click the purple button to animate!",
        color = colors.lime
    })
    PixelUI.label({
        x = 2, y = 17,
        text = "Animations: position, size, color, custom easing, chain, and more.",
        color = colors.lightGray
    })
end

-- Draggable widget demonstration
function demo:createDraggableDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Drag the box by its header area!",
        color = colors.white
    })

    -- Draggable box with a header area
    local box = PixelUI.button({
        x = 10, y = 10,
        width = 20, height = 5,
        text = "Drag Me!",
        background = colors.cyan,
        color = colors.black,
        draggable = true,
        dragArea = {x = 1, y = 1, width = 20, height = 1}, -- Only the top row is draggable
        onDragStart = function(self, relX, relY)
            self.background = colors.orange
        end,
        onDragEnd = function(self)
            self.background = colors.cyan
        end
    })
end

-- ScrollBar demonstration
function demo:createScrollBarDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Vertical ScrollBar:",
        color = colors.white
    })
    
    PixelUI.scrollBar({
        x = 2, y = 8,
        height = 8,
        orientation = "vertical",
        min = 0,
        max = 100,
        value = 30,
        pageSize = 4,
        onChange = function(self, value)
            -- Just show value in a label
            demo.state.scrollBarValue = value
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 6, y = 8,
        text = "Value: " .. tostring(demo.state.scrollBarValue or 30),
        color = colors.lime
    })
    
    PixelUI.label({
        x = 2, y = 12,
        text = "Horizontal ScrollBar:",
        color = colors.white
    })
    
    PixelUI.scrollBar({
        x = 2, y = 14,
        width = 20,
        orientation = "horizontal",
        min = 0,
        max = 100,
        value = 60,
        pageSize = 8,
        onChange = function(self, value)
            demo.state.scrollBarHValue = value
            demo:refreshFrame()
        end
    })
    
    PixelUI.label({
        x = 24, y = 14,
        text = "Value: " .. tostring(demo.state.scrollBarHValue or 60),
        color = colors.lime
    })
end

-- Scrollable Container demonstration
function demo:createScrollableDemo()
    PixelUI.label({
        x = 2, y = 6,
        text = "Scrollable Container (try mouse wheel):",
        color = colors.white
    })
    
    local container = PixelUI.container({
        x = 2, y = 8,
        width = 30,
        height = 8,
        background = colors.gray,
        border = true,
        isScrollable = true
    })

    -- Add lots of labels as true children of the container
    for i = 1, 20 do
        local label = PixelUI.Label:new({
            x = 2, y = i, -- relative to container content area
            width = 26,
            text = "Item " .. i,
            color = (i % 2 == 0) and colors.yellow or colors.cyan
        })
        container:addChild(label)
    end
    
    PixelUI.label({
        x = 35, y = 8,
        text = "Scroll to see more!",
        color = colors.lime
    })
end

-- Add to component demo switch
local oldCreateComponentDemo = demo.createComponentDemo
function demo:createComponentDemo(component)
    if component == "animation" then
        self:createAnimationDemo()
    else
        oldCreateComponentDemo(self, component)
    end
end

-- Initialize the demo
demo.running = true

-- Welcome message
print("PixelUI Framework Demo - Frame-based Component Showcase")
print("=======================================================")
print("This demo showcases each component in individual frames.")
print()
print("Navigation:")
print("- Use Next/Previous buttons or Left/Right arrow keys")
print("- Press Q to quit anytime")
print()
print("Components covered:")
for i, frame in ipairs(demo.frames) do
    print("  " .. i .. ". " .. frame.name)
end
print()
print("Press any key to start the demo...")
os.pullEvent("key")

-- Clear screen and set up initial UI
term.clear()
demo:createFrameUI()

-- Use PixelUI.run for automatic event loop and animation
PixelUI.run({
    onKey = function(key)
        if key == keys.q then
            return false -- Quit
        elseif key == keys.left then
            demo:prevFrame()
        elseif key == keys.right then
            demo:nextFrame()
        end
    end
})

-- Show exit message after run
print("Thanks for trying the PixelUI Framework Demo!")
print()
print("This demo showcased " .. demo.totalFrames .. " components:")
for i, frame in ipairs(demo.frames) do
    print("  " .. i .. ". " .. frame.name .. " - " .. frame.description)
end
print()
print("Navigation:")
print("- Left/Right arrows or Next/Prev buttons to navigate")
print("- Q key to quit")