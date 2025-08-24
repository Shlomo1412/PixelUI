-- PixelUI Generated Code
local PixelUI = require("pixelui")

-- Create main container
local main = PixelUI.container({
    width = 51,
    height = 19
})

-- Button element
local element1 = PixelUI.button({
    x = 2,
    y = 3,
    width = 11,
    height = 3,
    text = "Click Me!",
})
main:addChild(element1)

-- Label element
local element2 = PixelUI.label({
    x = 2,
    y = 1,
    width = 49,
    height = 1,
    text = "PixelUI Demo - Generated with XCC",
    background = colors.orange,
})
main:addChild(element2)

-- RichTextBox element
local element3 = PixelUI.richTextBox({
    x = 2,
    y = 7,
    width = 11,
    height = 1,
    text = "Type here",
    showLineNumbers = false,
})
main:addChild(element3)

-- ComboBox element
local element4 = PixelUI.comboBox({
    x = 2,
    y = 9,
    width = 11,
    height = 1,
    items = {"Item 1", "Item 2"},
})
main:addChild(element4)

-- ListView element
local element5 = PixelUI.listView({
    x = 2,
    y = 11,
    width = 11,
    height = 8,
    items = {"Avilable", "PixelUI", "Widgets:", "Label", "Button", "TextBox", "PasswordBox", "CheckBox", "RadioButton", "ToggleSwitch", "Slider", "RangeSlider", "NumericUpDown", "ComboBox", "ColorPicker", "ColorPickerDialog", "RichTextBox", "CodeEditor", "ProgressBar", "ProgressRing", "LoadingIndicator", "Spinner", "Container", "GroupBox", "TabControl", "Grid", "Spacer", "Accordion", "ListView", "DataGrid", "TreeView", "Chart", "Breadcrumb", "ContextMenu", "StatusBar", "Modal", "Window", "MsgBox", "FilePicker", "NotificationToast", "Canvas", "Program"},
})
main:addChild(element5)

-- Slider element
local element6 = PixelUI.slider({
    x = 14,
    y = 3,
    width = 20,
    height = 1,
})
main:addChild(element6)

-- LoadingIndicator element
local element7 = PixelUI.loadingIndicator({
    x = 14,
    y = 5,
    width = 20,
    height = 1,
    progress = 47,
    text = "",
})
main:addChild(element7)

-- ToggleSwitch element
local element8 = PixelUI.toggleSwitch({
    x = 14,
    y = 7,
    width = 16,
    height = 1,
    text = "Toggle Me!",
})
main:addChild(element8)

-- NumericUpDown element
local element9 = PixelUI.numericUpDown({
    x = 14,
    y = 9,
    width = 16,
    height = 1,
})
main:addChild(element9)

-- RadioButton element
local element10 = PixelUI.radioButton({
    x = 14,
    y = 11,
    width = 16,
    height = 1,
    text = "Option 1",
    group = "1",
})
main:addChild(element10)

-- RadioButton element
local element11 = PixelUI.radioButton({
    x = 14,
    y = 13,
    width = 16,
    height = 1,
    text = "Option 2",
    checked = true,
    group = "1",
})
main:addChild(element11)

-- CheckBox element
local element12 = PixelUI.checkBox({
    x = 14,
    y = 15,
    width = 16,
    height = 1,
    text = "Check Me!",
})
main:addChild(element12)

-- Chart element
local element13 = PixelUI.chart({
    x = 31,
    y = 7,
    width = 20,
    height = 12,
    data = {{x = 1, y = 120}, {x = 2, y = 190}, {x = 3, y = 300}, {x = 4, y = 500}, {x = 5, y = 200}, {x = 6, y = 300}},
})
main:addChild(element13)

-- RangeSlider element
local element14 = PixelUI.rangeSlider({
    x = 35,
    y = 5,
    width = 16,
    height = 1,
})
main:addChild(element14)

-- TextBox element
local element15 = PixelUI.textBox({
    x = 14,
    y = 17,
    width = 16,
    height = 1,
    placeholder = "Type here!",
})
main:addChild(element15)

-- TextBox element
local element16 = PixelUI.textBox({
    x = 39,
    y = 3,
    width = 12,
    height = 1,
    password = true,
})
main:addChild(element16)

-- Start the UI
PixelUI.run()