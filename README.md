# PixelUI for ComputerCraft/CC: Tweaked

A modern, feature-rich, extensible UI framework for ComputerCraft and CC: Tweaked, designed for advanced desktop-style applications, games, and tools. PixelUI brings a full suite of widgets, event handling, animations, and more to your in-game computers.

[![Download on PineStore](https://raster.shields.io/badge/dynamic/json?url=https%3A%2F%2Fpinestore.cc%2Fapi%2Fproject%2F154&query=%24.project.downloads&suffix=%20downloads&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iNzYuOTA0IiBoZWlnaHQ9Ijg5LjI5NSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDc2OS4wNCA4OTIuOTUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM5YWIyZjIiPgogIDxwYXRoIGQ9Im00MTAgODUxYzAtMTIgMjYtMjEgNTgtMjEgMTUgMCAyMiA0IDE3IDktMTQgMTItNzUgMjItNzUgMTJ6Ii8%2BCiAgPHBhdGggZD0ibTU4NSA3NDJjLTEtNDkgNC03MiAxNi04NSAyMi0yNCAzMC02OCAxNi04Ni0xMi0xNC0yNy0zOS00OC03OC0xMC0xOS05LTI2IDQtNDEgMjItMjQgMjEtNjctMi0xNDQtMjEtNjktMzktMTQ0LTQ4LTE5NS00LTI2LTItMzMgMTEtMzMgMzEgMCAxMTIgMzMgMTQxIDU4IDI4IDIzIDgxIDkyIDcxIDkyLTIgMCA1IDI2IDE2IDU3IDI4IDc5IDI5IDIyNCAzIDMwOC0xMCAzMy0xOSA2Mi0xOSA2NS00IDI2LTEzMiAxNTAtMTU1IDE1MC0zIDAtNi0zMC02LTY4eiIvPgogIDxwYXRoIGQ9Im02OCA2NzNjLTcyLTEwOS03MS0yNzggMy00MjMgMzYtNzEgNjItMTAwIDEyOC0xNDAgNDMtMjcgNjUtMzQgMTE4LTM2IDEwMC00IDk4IDExLTE5IDEzNi0zNCAzNy03OCA4OC05NiAxMTMtMjggMzktMzEgNDgtMjEgNjUgMTEgMTcgNiAyNy0zMyA3OS00MCA1My00NCA2Mi0zMiA3OCAxNyAyMyAxOCA1NyAyIDczLTYgNi0xNCAzMS0xNyA1NC02IDQyLTYgNDItMzMgMXoiLz4KIDwvZz4KIDxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0xNC43NCAtNC42ODI2KSIgZmlsbD0iIzU5YTY0ZiI%2BCiAgPHBhdGggZD0ibTM2NSA4MTNjLTUzLTYtMTM5LTMzLTE5Mi02MS02OC0zNS04My02Ny01OC0xMjIgMjYtNTkgNDAtNjcgNzgtNDkgNjggMzMgMTY3IDU4IDI2NiA2OSA1OCA1IDEwNiAxMiAxMDkgMTQgMiAzIDYgMzIgOSA2NSA4IDg1IDAgOTEtMTAxIDkwLTQ0LTEtOTQtNC0xMTEtNnoiLz4KICA8cGF0aCBkPSJtNDEwIDQ1OWMtNjctNy0xNjAtMjktMTk5LTQ4LTI3LTE0LTM0LTM2LTIwLTYzIDIxLTM4IDk3LTEzNiAxNTAtMTkzIDI1LTI3IDU4LTcxIDczLTk3IDI1LTQzIDMxLTQ3IDU0LTQyIDQwIDEwIDQyIDEyIDQyIDUyIDAgMjAgNiA1NyAxNCA4MiAyNCA3MyA1NCAxOTIgNjIgMjM2IDUgMzUgMyA0NS0xNSA2My0yMyAyMy0zNiAyNC0xNjEgMTB6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZWNiMjUiPgogIDxwYXRoIGQ9Im01NTggNjc0Yy0yLTItNTEtOS0xMDktMTQtMTAyLTExLTIwNC0zNy0yNjQtNjktMTYtOC0zMi0xNC0zNC0xMi00IDMtMzEtNDgtMzEtNjEgMC01IDIxLTMxIDQ2LTU4IDUxLTU0IDcxLTYwIDEzMC0zNSAxOSA4IDgzIDE5IDE0MiAyNSA1OCA2IDEwNyAxMiAxMDcgMTNzMTUgMjYgMzMgNTZjMjcgNDMgMzIgNjMgMzAgOTktMiAzNS04IDQ3LTI1IDUzLTExIDQtMjMgNi0yNSAzeiIvPgogPC9nPgogPGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE0Ljc0IC00LjY4MjYpIiBmaWxsPSIjZWNlZGVmIj4KICA8cGF0aCBkPSJtMjYwIDg5MGMtMzQtOC03MC00MS03MC02NSAwLTYtOS0yMC0yMC0zMHMtMjAtMjItMjAtMjctMTMtMjEtMzAtMzVjLTM1LTI5LTQxLTgzLTEzLTEyMiAxNS0yMiAxNS0yNi0xLTU2LTE4LTMzLTE4LTMzIDI3LTkxIDI4LTM2IDQyLTYzIDM2LTY4LTIzLTI1IDktNzggMTIwLTE5NyAzNi0zOCA3Mi04MSA4Mi05NiAxMC0xNCAyNS0zMCAzMy0zNSAzNi0yMCA3IDMyLTUzIDk3LTQ4IDUxLTEyNiAxNTAtMTQ5IDE4OS0xMCAxOC05IDI0IDEwIDQwIDIzIDE5IDIzIDE5LTI5IDcxLTUzIDUyLTUzIDUyLTM4IDgyIDE0IDI4IDE0IDMzLTEwIDc2LTMyIDU3LTIzIDgxIDQ2IDEyMCAzNCAxOSA0OSAzMyA0NSA0Mi0xNCAzNyAzNiA3NSA5OCA3NSAyNSAwIDQwLTcgNTQtMjUgMTgtMjMgMjctMjUgOTUtMjUgOTQgMCAxMDItOCA5My04OS02LTUzLTUtNTkgMTQtNjQgMzItOCAyNi02NC0xNS0xMzItMzUtNTgtMzUtNTgtOS04MiAyMS0xOSAyNC0yOSAxOS01Ni0xMC00Ny00NC0xNzUtNjEtMjI3LTgtMjUtMTQtNjItMTQtODMgMC0yNy01LTM5LTE3LTQzLTEwLTMtMjUtOC0zMy0xMC0xMi00LTEyLTYtMS0xNCAyNy0xNiA1NiA1IDY5IDUxIDM1IDExNyA0MyAxNDggNDYgMTcwIDIgMTMgMTEgNTEgMjEgODQgMjEgNzEgMjEgMTIxIDAgMTQ1LTE0IDE1LTEzIDE5IDUgNDMgMTEgMTQgMjAgMzAgMjAgMzVzNyAxNSAxNSAyMmMyMSAxNyAxNiA3NS0xMCAxMDItMTggMTktMjAgMzItMTcgNzkgNCA1MCAyIDU4LTE5IDcyLTEyIDktNTAgMTktODMgMjMtNDUgNS02NSAxMy04MyAzMi0yNiAyOC05MiAzOC0xNTMgMjJ6Ii8%2BCiA8L2c%2BCiA8ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtMTQuNzQgLTQuNjgyNikiIGZpbGw9IiM3ZTY3NGQiPgogIDxwYXRoIGQ9Im0yNDggODU0Yy0zMC0xNi00Ny01OS0zMC03NiA4LTggMjMtNyA1NCAyIDI0IDcgNjEgMTQgODMgMTcgNTQgNyA1OSAxNSAzNSA0Ni0xOCAyMy0yOSAyNy02OCAyNy0yNi0xLTU5LTctNzQtMTZ6Ii8%2BCiA8L2c%2BCjwvc3ZnPgo%3D&label=PineStore)](https://pinestore.cc/projects/154/pixelui) [![Website](https://img.shields.io/badge/Visit-Website-blue?logo=googlechrome&logoColor=white)](https://shlomo1412.github.io/pixelui-website/)


---

## 🚀 Super Features

- **Comprehensive Widget Library**: Buttons, labels, text boxes, checkboxes, sliders, range sliders, progress bars, list views, containers, group boxes, color pickers, color picker dialogs, tab controls, combo boxes, numeric up/down, spinners, loading indicators, scrollbars, modal dialogs, charts, draggable widgets, notification toasts, data grids/tables, and more.
- **Background Threads System**: Run background tasks while keeping the UI responsive! Perfect for HTTP requests, file processing, and long-running operations.
- **Advanced Layouts**: Absolute, vertical, horizontal, and smart margin/grid layouts for complex UIs.
- **Scrollable Containers**: True scrollable containers with automatic scrollbars, strict clipping, and event handling.
- **Event System**: Mouse, keyboard, scroll, drag, and focus events, with full propagation and focus management.
- **Animation Engine**: Animate any widget property (position, color, size, etc.) with custom easing, chaining, and callbacks.
- **Theming**: Fully themeable with color schemes, per-widget overrides, and easy customization.
- **Modal & Context Menus**: Modal dialogs and context menus that block or overlay the UI as needed.
- **Draggable Widgets**: Make any widget draggable, with custom drag areas and callbacks.
- **Password & Masked Input**: Secure text boxes for password entry.
- **Pixel Canvas**: Draw pixel-level graphics with the Canvas widget.
- **Extensible**: Easily add your own widgets or extend existing ones.
- **Demo Suite**: Includes a full-featured demo app showcasing every widget and feature.

---

## 📦 Installation

1. **Download** `pixelui.lua` and (optionally) `example.lua` to your ComputerCraft computer.
2. Place `pixelui.lua` in the same directory as your main program.
3. In your program, load PixelUI:

```lua
local PixelUI = require("pixelui")
```

If you use the demo, run:

```lua
example.lua
```

---

## 🛠️ Usage & API

### 1. **Initialization**

```lua
local PixelUI = require("pixelui")
PixelUI.init()
```

### 2. **Creating Widgets**

Widgets are created with `PixelUI.<widget>()` functions. Example:

```lua
PixelUI.label({ x = 2, y = 2, text = "Hello!", color = colors.cyan })
PixelUI.button({ x = 2, y = 4, text = "Click Me", onClick = function() print("Clicked!") end })
```

### 3. **Containers & Layouts**

```lua
local container = PixelUI.container({ x = 1, y = 1, width = 20, height = 10, border = true, isScrollable = true })
container:addChild(PixelUI.label({ x = 2, y = 2, text = "Inside!" }))
```

- **Layouts**: Set `layout = "vertical"` or `"horizontal"` for auto-arrangement. Use `autoMargin = true` for smart spacing.

### 4. **Scrollable Containers**

- Set `isScrollable = true` on a container. Add children as usual. If content exceeds the container, scrollbars appear and mouse wheel works.

### 5. **Event Handling**

- All widgets support `onClick`, and many support `onChange`, `onSelect`, `onToggle`, etc.
- Keyboard and mouse events are handled automatically by `PixelUI.run()`.

### 6. **Animation**

```lua
PixelUI.animate(widget, {
  to = { x = 10, y = 5, background = colors.red },
  duration = 1.0,
  easing = "outQuad",
  onComplete = function(w) print("Done!") end
})
```

### 7. **Modal Dialogs**

```lua
PixelUI.msgBox({
  title = "Hello!",
  message = "This is a modal dialog.",
  buttons = {"OK", "Cancel"},
  onButton = function(box, idx, text) print("You chose " .. text) end
})

-- Color picker dialog
local colorDialog = PixelUI.colorPickerDialog({
  title = "Choose Color",
  selectedColor = colors.blue,
  onColorSelected = function(color) print("Selected:", color) end
})
colorDialog:show()
```

### 8. **Draggable Widgets**

```lua
PixelUI.button({
  x = 5, y = 5, text = "Drag Me!", draggable = true,
  dragArea = { x = 1, y = 1, width = 10, height = 1 },
  onDragStart = function(self, relX, relY) print("Started drag") end,
  onDragEnd = function(self) print("Stopped drag") end
})
```

### 9. **Theming**

```lua
PixelUI.setTheme({
  primary = colors.purple,
  background = colors.black,
  button = { background = colors.purple, text = colors.white }
})
```

---


## 📚 Widget Reference (Detailed)

Below is a comprehensive reference for every widget and feature in PixelUI. Each section includes all properties, events, usage examples, and advanced notes.

---

### `PixelUI.label(props)` — **Static Text**
**Properties:**
- `x`, `y`: Position
- `text`: The string to display
- `color`: Text color (default: theme.text)
- `background`: Background color (optional)
- `align`: `"left"`, `"center"`, `"right"` (default: left)
- `width`: Optional width (for alignment/wrapping)
- `wrap`: `true` to wrap text (default: false)

**Events:** None

**Example:**
```lua
PixelUI.label({ x = 2, y = 2, text = "Hello!", color = colors.cyan, align = "center", width = 20 })
```

**Notes:**
- Use `wrap = true` and `width` for multi-line labels.

---

### `PixelUI.button(props)` — **Clickable Button**
**Properties:**
- `x`, `y`, `width`, `height`
- `text`: Button label
- `color`: Text color
- `background`: Button color
- `border`: Show border (default: true)
- `icon`: Optional icon (character or string)
- `draggable`: Make button draggable
- `dragArea`: Restrict drag area

**Events:**
- `onClick(self, x, y, button)`: Called when clicked
- `onDragStart(self, relX, relY)`, `onDragEnd(self)`

**Example:**
```lua
PixelUI.button({ x = 2, y = 4, text = "Click Me", onClick = function() print("Clicked!") end })
```

**Notes:**
- Supports keyboard activation if focused.

---

### `PixelUI.textBox(props)` — **Text Input**
**Properties:**
- `x`, `y`, `width`
- `text`: Initial value
- `placeholder`: Placeholder text
- `color`, `background`, `border`
- `password`: Mask input (for passwords)
- `maxLength`: Maximum input length
- `readonly`: Prevent editing

**Events:**
- `onChange(self, value)`: On text change
- `onEnter(self, value)`: On Enter key

**Example:**
```lua
PixelUI.textBox({ x = 2, y = 6, width = 16, placeholder = "Type here...", onChange = function(self, v) print(v) end })
```

**Notes:**
- Use `password = true` for password fields.

---

### `PixelUI.checkBox(props)` — **Checkbox**
**Properties:**
- `x`, `y`
- `checked`: Initial state (bool)
- `text`: Label
- `color`, `background`

**Events:**
- `onToggle(self, checked)`: When toggled

**Example:**
```lua
PixelUI.checkBox({ x = 2, y = 8, text = "Enable", checked = true, onToggle = function(self, c) print(c) end })
```

---

### `PixelUI.slider(props)` — **Slider**
**Properties:**
- `x`, `y`, `width`
- `min`, `max`, `value`
- `color`, `background`, `barColor`
- `showValue`: Show value as text

**Events:**
- `onChange(self, value)`: On value change

**Example:**
```lua
PixelUI.slider({ x = 2, y = 10, width = 20, min = 0, max = 100, value = 50, onChange = function(self, v) print(v) end })
```

---

### `PixelUI.rangeSlider(props)` — **Range Slider**
**Properties:**
- `x`, `y`, `width`
- `rangeMin`, `rangeMax`: Overall range bounds
- `minValue`, `maxValue`: Current selected range
- `step`: Value increment step
- `trackColor`, `fillColor`, `knobColor`: Colors
- `showValues`: Show range values as text
- `valueFormat`: Format string for values (default: "%.0f")

**Events:**
- `onChange(self, minValue, maxValue)`: On range change

**Example:**
```lua
PixelUI.rangeSlider({ 
  x = 2, y = 10, width = 25, 
  rangeMin = 0, rangeMax = 100, 
  minValue = 20, maxValue = 80,
  onChange = function(self, min, max) print("Range:", min, "-", max) end 
})
```

---

### `PixelUI.progressBar(props)` — **Progress Bar**
**Properties:**
- `x`, `y`, `width`
- `progress`: 0-100 (percent)
- `color`, `background`, `barColor`
- `text`: Optional label

**Events:** None

**Example:**
```lua
PixelUI.progressBar({ x = 2, y = 12, width = 20, progress = 75, text = "Loading..." })
```

---

### `PixelUI.listView(props)` — **List with Selection**
**Properties:**
- `x`, `y`, `width`, `height`
- `items`: Array of strings/tables
- `selected`: Index of selected item
- `multiSelect`: Allow multiple selection
- `color`, `background`, `selectedColor`

**Events:**
- `onSelect(self, idx, item)`: On selection

**Example:**
```lua
PixelUI.listView({ x = 2, y = 14, width = 20, height = 5, items = {"A", "B", "C"}, onSelect = function(self, idx, item) print(item) end })
```

---

### `PixelUI.container(props)` — **Layout/Grouping, Scrollable**
**Properties:**
- `x`, `y`, `width`, `height`
- `border`: Show border
- `isScrollable`: Enable scrolling
- `layout`: `"vertical"`, `"horizontal"`, or `nil`
- `autoMargin`: Smart spacing
- `children`: Array of widgets

**Methods:**
- `addChild(widget)`, `removeChild(widget)`

**Events:** None (children handle their own events)

**Example:**
```lua
local c = PixelUI.container({ x = 1, y = 1, width = 20, height = 10, border = true, isScrollable = true })
c:addChild(PixelUI.label({ x = 2, y = 2, text = "Inside!" }))
```

**Notes:**
- Scrollable containers clip children and handle scrollbars automatically.
- Use `layout` for auto-arrangement.

---

### `PixelUI.toggleSwitch(props)` — **Modern Toggle**
**Properties:**
- `x`, `y`
- `checked`: Initial state
- `color`, `background`
- `text`: Label

**Events:**
- `onToggle(self, checked)`

**Example:**
```lua
PixelUI.toggleSwitch({ x = 2, y = 20, checked = true, text = "On/Off" })
```

---

### `PixelUI.radioButton(props)` — **Radio Button**
**Properties:**
- `x`, `y`
- `text`: Label
- `group`: Group name (only one selected per group)
- `checked`: Initial state

**Events:**
- `onSelect(self)`

**Example:**
```lua
PixelUI.radioButton({ x = 2, y = 22, text = "Option 1", group = "grp1", checked = true })
```

---

### `PixelUI.comboBox(props)` — **Dropdown**
**Properties:**
- `x`, `y`, `width`
- `items`: Array of options
- `selected`: Index
- `color`, `background`

**Events:**
- `onSelect(self, idx, item)`

**Example:**
```lua
PixelUI.comboBox({ x = 2, y = 24, width = 16, items = {"Red", "Green", "Blue"}, onSelect = function(self, idx, item) print(item) end })
```

---

### `PixelUI.tabControl(props)` — **Tabs**
**Properties:**
- `x`, `y`, `width`, `height`
- `tabs`: Array of tab names
- `selected`: Index
- `children`: Array of containers (one per tab)

**Events:**
- `onTabChange(self, idx, name)`

**Example:**
```lua
PixelUI.tabControl({ x = 2, y = 26, width = 20, height = 8, tabs = {"A", "B"}, children = {tabA, tabB} })
```

---

### `PixelUI.numericUpDown(props)` — **Numeric Input**
**Properties:**
- `x`, `y`, `width`
- `min`, `max`, `value`, `step`
- `color`, `background`

**Events:**
- `onChange(self, value)`

**Example:**
```lua
PixelUI.numericUpDown({ x = 2, y = 28, width = 8, min = 0, max = 10, value = 5, step = 1 })
```

---

### `PixelUI.groupBox(props)` — **Visual Grouping**
**Properties:**
- `x`, `y`, `width`, `height`
- `text`: Optional label
- `color`, `background`, `border`

**Events:** None

**Example:**
```lua
PixelUI.groupBox({ x = 2, y = 30, width = 20, height = 6, text = "Group" })
```

---

### `PixelUI.canvas(props)` — **Pixel Drawing**
**Properties:**
- `x`, `y`, `width`, `height`
- `background`

**Methods:**
- `setPixel(x, y, color)`, `getPixel(x, y)`

**Events:** None

**Example:**
```lua
local c = PixelUI.canvas({ x = 2, y = 32, width = 10, height = 5 })
c:setPixel(1, 1, colors.red)
```

---

### `PixelUI.chart(props)` — **Data Visualization**
**Properties:**
- `x`, `y`, `width`, `height`
- `data`: Array of data points (tables with x, y properties or arrays)
- `chartType`: `"line"`, `"bar"`, or `"scatter"` (default: "line")
- `title`, `xLabel`, `yLabel`: Chart labels
- `background`, `axisColor`, `dataColor`: Colors
- `titleColor`, `labelColor`, `gridColor`: Text colors
- `showGrid`: Show grid lines (default: true)
- `autoScale`: Auto-scale axes (default: true)
- `minX`, `maxX`, `minY`, `maxY`: Manual axis bounds (when autoScale = false)

**Events:** None

**Example:**
```lua
local data = {{x=1, y=10}, {x=2, y=25}, {x=3, y=15}, {x=4, y=30}}
PixelUI.chart({ 
  x = 2, y = 5, width = 30, height = 12,
  data = data, chartType = "line",
  title = "Sample Chart", xLabel = "Time", yLabel = "Value"
})
```

---

### `PixelUI.msgBox(props)` — **Modal Dialog**
**Properties:**
- `title`, `message`
- `buttons`: Array of button labels
- `color`, `background`

**Events:**
- `onButton(self, idx, text)`

**Example:**
```lua
PixelUI.msgBox({ title = "Hello!", message = "This is a modal dialog.", buttons = {"OK", "Cancel"}, onButton = function(self, idx, text) print(text) end })
```

---

### `PixelUI.colorPicker(props)` — **Color Picker**
**Properties:**
- `x`, `y`
- `selectedColor`: Initial color
- `gridColumns`: Number of columns in color grid (default: 4)
- `colorSize`: Size of each color swatch (default: 2)
- `showPreview`: Show color preview area (default: true)
- `showName`: Show color name (default: true)

**Events:**
- `onChange(self, color, index, name)`

**Example:**
```lua
PixelUI.colorPicker({ x = 2, y = 34, selectedColor = colors.red, onChange = function(self, color, index, name) print(name) end })
```

---

### `PixelUI.colorPickerDialog(props)` — **Modal Color Picker Dialog**
**Properties:**
- `title`: Dialog title (default: "Select Color")
- `selectedColor`: Initial color selection
- `onColorSelected`: Callback when color is selected
- `onCancel`: Callback when dialog is cancelled

**Events:**
- `onColorSelected(color)`: Called when OK is clicked with selected color
- `onCancel()`: Called when Cancel is clicked or dialog is closed

**Methods:**
- `show()`: Display the modal dialog
- `hide()`: Close the dialog

**Example:**
```lua
local dialog = PixelUI.colorPickerDialog({
    title = "Choose Your Color",
    selectedColor = colors.blue,
    onColorSelected = function(color)
        print("Selected color:", color)
        -- Apply the color to your widget/application
    end,
    onCancel = function()
        print("Color selection cancelled")
    end
})
dialog:show()
```

**Notes:**
- Uses an 8-column grid layout for better horizontal space utilization
- Includes color preview swatch and color name display
- Features OK, Cancel, and Reset buttons
- Modal dialog blocks interaction with other UI elements
- Automatically centers on screen

---

### `PixelUI.loadingIndicator(props)` — **Loading Bar/Spinner**
**Properties:**
- `x`, `y`, `width`
- `progress`: 0-100 (for bar)
- `style`: `"bar"` or `"spinner"`
- `color`, `background`
- `text`: Optional label

**Events:** None

**Example:**
```lua
PixelUI.loadingIndicator({ x = 2, y = 36, width = 20, progress = 50, style = "bar", color = colors.cyan, text = "Loading..." })
```

---

### `PixelUI.spinner(props)` — **Animated Spinner**
**Properties:**
- `x`, `y`
- `style`: `"classic"`, `"dots"`, etc.
- `color`, `background`
- `text`: Optional label
- `active`: Show/hide spinner

**Events:** None

**Example:**
```lua
PixelUI.spinner({ x = 2, y = 38, style = "classic", color = colors.lime, text = "Processing...", active = true })
```

---

### `PixelUI.scrollBar(props)` — **Standalone Scrollbar**
**Properties:**
- `x`, `y`, `length`
- `orientation`: `"vertical"` or `"horizontal"`
- `min`, `max`, `value`
- `color`, `background`, `barColor`

**Events:**
- `onChange(self, value)`

**Example:**
```lua
PixelUI.scrollBar({ x = 22, y = 2, length = 10, orientation = "vertical", min = 0, max = 100, value = 50, onChange = function(self, v) print(v) end })
```

---

### `PixelUI.passwordBox(props)` — **Password Input**
**Properties:**
- Same as `textBox`, but always masked

**Events:**
- Same as `textBox`

**Example:**
```lua
PixelUI.passwordBox({ x = 2, y = 40, width = 16, placeholder = "Password" })
```

---

### `PixelUI.modal(props)` — **Custom Modal**
**Properties:**
- `x`, `y`, `width`, `height`
- `content`: Widget or container
- `background`, `border`

**Events:**
- Custom, via content widgets

**Example:**
```lua
PixelUI.modal({ x = 5, y = 5, width = 20, height = 10, content = PixelUI.label({ text = "Custom!" }) })
```

---

### `PixelUI.window(props)` — **Windowed UI**
**Properties:**
- `x`, `y`, `width`, `height`
- `title`: Window title
- `content`: Widget or container
- `draggable`, `resizable`

**Events:**
- `onClose(self)`

**Example:**
```lua
PixelUI.window({ x = 1, y = 1, width = 30, height = 12, title = "My Window", content = PixelUI.label({ text = "Window!" }) })
```

---

### `PixelUI.breadcrumb(props)` — **Breadcrumb Navigation**
**Properties:**
- `x`, `y`, `items`: Array of strings
- `color`, `background`

**Events:**
- `onSelect(self, idx, item)`

**Example:**
```lua
PixelUI.breadcrumb({ x = 2, y = 42, items = {"Home", "Settings"}, onSelect = function(self, idx, item) print(item) end })
```

---

### `PixelUI.treeView(props)` — **Tree View**
**Properties:**
- `x`, `y`, `width`, `height`
- `tree`: Nested table structure
- `selected`: Path or index

**Events:**
- `onSelect(self, path, node)`

**Example:**
```lua
PixelUI.treeView({ x = 2, y = 44, width = 20, height = 8, tree = { {text="Root", children={ {text="Child"} } } }, onSelect = function(self, path, node) print(node.text) end })
```

---

### `PixelUI.spacer(props)` — **Layout Spacer**
**Properties:**
- `width`, `height`

**Events:** None

**Example:**
```lua
PixelUI.spacer({ width = 2, height = 1 })
```

---

### `PixelUI.notificationToast(props)` — **Toast Notifications**
**Properties:**
- `message`: Main notification text
- `title`: Optional title text (default: "")
- `type`: Notification type - `"info"`, `"success"`, `"warning"`, `"error"` (default: "info")
- `duration`: Auto-hide duration in milliseconds (default: 3000)
- `x`, `y`, `width`, `height`: Position and size
- `closeable`: Show close button (default: true)
- `autoHide`: Auto-hide after duration (default: true)
- `background`, `color`, `titleColor`: Custom colors

**Events:**
- `onShow()`: Called when toast is shown
- `onHide()`: Called when toast is hidden
- `onClick(relX, relY)`: Called when toast is clicked

**Methods:**
- `show()`: Display the toast notification
- `hide()`: Hide the toast notification

**Example:**
```lua
local toast = PixelUI.notificationToast({
    message = "Operation completed successfully!",
    title = "Success",
    type = "success",
    duration = 4000
})
toast:show()

-- Or use the convenience function
PixelUI.showToast("Hello World!", "Info", "info", 3000)
```

---

### `PixelUI.dataGrid(props)` — **Data Table/Grid**
**Properties:**
- `x`, `y`, `width`, `height`: Position and size
- `columns`: Array of column definitions with `field`, `title`, `width`
- `data`: Array of data rows (objects or arrays)
- `showHeaders`: Show column headers (default: true)
- `alternatingRows`: Alternate row colors (default: true)
- `gridLines`: Show grid lines (default: true)
- `sortable`: Enable column sorting (default: true)
- `selectable`: Enable row selection (default: true)
- `multiSelect`: Allow multiple row selection (default: false)
- `headerColor`, `headerBackground`: Header styling
- `selectedColor`, `selectedBackground`: Selected row styling
- `alternateBackground`: Alternate row color
- `gridLineColor`: Grid line color

**Events:**
- `onRowSelect(rowIndex, rowData)`: Called when row is selected
- `onRowDoubleClick(rowIndex, rowData)`: Called on row double-click
- `onSort(columnIndex, direction)`: Called when column is sorted
- `onCellClick(rowIndex, columnIndex, cellData)`: Called on cell click

**Methods:**
- `sortData()`: Sort data by current sort column
- `selectRow(index)`: Select a specific row
- `deselectRow(index)`: Deselect a specific row
- `isRowSelected(index)`: Check if row is selected

**Example:**
```lua
PixelUI.dataGrid({
    x = 2, y = 8, width = 45, height = 12,
    columns = {
        {field = "id", title = "ID", width = 4},
        {field = "name", title = "Name", width = 14},
        {field = "department", title = "Dept", width = 12}
    },
    data = {
        {id = 1, name = "Alice", department = "Engineering"},
        {id = 2, name = "Bob", department = "Marketing"}
    },
    onRowSelect = function(rowIndex, rowData)
        print("Selected:", rowData.name)
    end
})
```

---

## 🎨 Theming (Advanced)

PixelUI supports full theming. You can set global or per-widget themes:

```lua
PixelUI.setTheme({
  primary = colors.purple,
  background = colors.black,
  button = { background = colors.purple, text = colors.white },
  label = { text = colors.yellow },
  ...
})
```

- **Per-widget themes**: Pass `theme = { ... }` in widget props to override.
- **Dynamic theming**: Change theme at runtime; widgets update automatically.

---

## 🌀 Animation Engine (Advanced)

Animate any widget property:

```lua
PixelUI.animate(widget, {
  to = { x = 10, y = 5, background = colors.red },
  duration = 1.0,
  easing = "outQuad",
  onComplete = function(w) print("Done!") end
})
```

- **Properties**: Any numeric/color property can be animated.
- **Easing**: Supports `linear`, `inQuad`, `outQuad`, `inOutQuad`, etc.
- **Chaining**: Animate multiple widgets or properties in sequence.
- **Callbacks**: `onComplete`, `onUpdate`.

---

## 🗔 Modal & Context Menus (Advanced)

- `PixelUI.msgBox` and `PixelUI.modal` create modal dialogs.
- **Context menus**: Use a container with `isModal = true` and custom content.
- **Modal stacking**: Multiple modals can be layered.

---

## 🖱️ Drag-and-Drop (Advanced)

- Any widget with `draggable = true` can be dragged.
- Use `onDragStart`, `onDragEnd`, and `onDrop` for custom logic.
- Restrict drag area with `dragArea`.

---

## 🧵 Background Threads System (Advanced)

PixelUI includes a powerful cooperative threading system that allows you to run background tasks while keeping your UI responsive. Perfect for HTTP requests, file operations, and long-running computations!

### Quick Start

```lua
-- Spawn a simple background task
PixelUI.spawnThread(function()
    for i = 1, 100 do
        print("Background task progress:", i)
        PixelUI.sleep(0.1) -- Yield control back to UI
    end
end, "myTask")

-- Run an async operation with automatic cleanup
PixelUI.runAsync(function()
    local response = http.get("https://api.example.com/data")
    if response then
        local data = response.readAll()
        response.close()
        -- Update UI with the data
        myLabel:setText("Received: " .. #data .. " bytes")
    end
end)
```

### Thread Management Functions

#### `PixelUI.spawnThread(func, name)`
Creates and starts a new background thread.
- `func`: The function to run in the background
- `name`: Optional thread name for identification
- Returns: Thread ID

#### `PixelUI.killThread(threadId)`
Stops and removes a running thread.
- `threadId`: ID of thread to stop

#### `PixelUI.runAsync(func, name)`
Convenience function that spawns a thread with automatic error handling.
- Shows toast notifications for errors
- Automatically cleans up on completion

#### `PixelUI.sleep(seconds)`
Yields control back to the main UI loop for the specified time.
- `seconds`: Time to sleep (can be fractional)
- Must be called from within a thread

### Thread System Features

- **Cooperative Multitasking**: Threads yield control voluntarily, preventing UI freezing
- **Automatic Cleanup**: Threads are automatically removed when they complete or error
- **Error Handling**: Uncaught errors show toast notifications and don't crash the UI
- **Thread Monitoring**: Get thread status and information
- **Integration**: Works seamlessly with PixelUI's event system and animations

### Real-World Examples

#### HTTP API Calls
```lua
local function fetchUserData(userId)
    PixelUI.runAsync(function()
        loadingSpinner:show()
        
        local url = "https://api.example.com/users/" .. userId
        local response = http.get(url)
        
        if response then
            local userData = textutils.unserializeJSON(response.readAll())
            response.close()
            
            -- Update UI on main thread
            userNameLabel:setText(userData.name)
            userEmailLabel:setText(userData.email)
        else
            PixelUI.showToast("Failed to fetch user data", "Error", "error")
        end
        
        loadingSpinner:hide()
    end, "fetchUser")
end
```

#### File Processing
```lua
local function processLargeFile(filename)
    PixelUI.spawnThread(function()
        local file = fs.open(filename, "r")
        if not file then return end
        
        local lineCount = 0
        local progressBar = PixelUI.progressBar({x=10, y=10, width=20})
        
        while true do
            local line = file.readLine()
            if not line then break end
            
            lineCount = lineCount + 1
            
            -- Process the line here
            processLine(line)
            
            -- Update progress every 100 lines
            if lineCount % 100 == 0 then
                progressBar:setProgress(lineCount / estimatedTotalLines)
                PixelUI.sleep(0.01) -- Yield to keep UI responsive
            end
        end
        
        file.close()
        PixelUI.showToast("Processed " .. lineCount .. " lines", "Complete", "success")
    end, "fileProcessor")
end
```

#### Background Monitoring
```lua
local function startSystemMonitor()
    PixelUI.spawnThread(function()
        while true do
            -- Check system stats
            local freeSpace = fs.getFreeSpace("/")
            local energy = turtle and turtle.getFuelLevel() or 0
            
            -- Update UI indicators
            diskSpaceLabel:setText("Free: " .. freeSpace .. " bytes")
            if turtle then
                fuelLabel:setText("Fuel: " .. energy)
            end
            
            -- Check every 5 seconds
            PixelUI.sleep(5)
        end
    end, "systemMonitor")
end
```

### Best Practices

1. **Always Yield**: Call `PixelUI.sleep()` in loops to prevent blocking the UI
2. **Handle Errors**: Use `PixelUI.runAsync()` for automatic error handling
3. **Clean Resources**: Close files, HTTP responses, and peripherals properly
4. **Update UI Safely**: All UI updates should happen on the main thread
5. **Use Meaningful Names**: Name your threads for easier debugging
6. **Monitor Long Tasks**: Show progress indicators for lengthy operations

### Thread Lifecycle

1. **Creation**: Thread is created with `spawnThread()` or `runAsync()`
2. **Execution**: Thread runs cooperatively, yielding with `sleep()`
3. **Completion**: Thread ends naturally or via `killThread()`
4. **Cleanup**: Thread is automatically removed from the thread manager

The thread system integrates seamlessly with PixelUI's main event loop, ensuring your UI remains responsive while background tasks run efficiently.

---

## 🧩 Custom Widgets (Advanced)

Inherit from `PixelUI.Widget`:

```lua
local MyWidget = PixelUI.Widget:extend()
function MyWidget:render() ... end
function MyWidget:onClick(x, y, button) ... end
```

Register with `PixelUI.registerWidget("myWidget", MyWidget)` to use as `PixelUI.myWidget()`.

---

---

## 🧑‍💻 Advanced Usage

- **Custom Widgets**: Inherit from `PixelUI.Widget` and implement `:render()` and event handlers.
- **Direct Widget Access**: All widget classes are available as `PixelUI.Label`, `PixelUI.Button`, etc.
- **Manual Event Loop**: Use `PixelUI.handleEvent(event, ...)` for custom event processing.
- **Root Container**: Use `PixelUI.setRootContainer(container)` to replace the default root.

---

## 🏁 Demo

Run `example.lua` for a full interactive demo of every widget and feature. Study the code for real-world usage patterns and advanced tricks.

---

## ❓ FAQ

- **Q: Can I use PixelUI in my own programs?**  
  A: Yes! Just require `pixelui.lua` and start building UIs.
- **Q: Is it fast?**  
  A: Yes, it's optimized for CC: Tweaked and supports hundreds of widgets.
- **Q: Can I theme it?**  
  A: Yes, see the theming section above.
- **Q: How do I add my own widgets?**  
  A: Inherit from `PixelUI.Widget` and register your widget.

---

## 📝 License

MIT License. Use freely in your own projects, mods, and servers.

---

## 💬 Support & Contributions

- Issues, suggestions, and PRs are welcome!
- For help, open an issue or ask in the CC: Tweaked Discord.

---

Enjoy building beautiful UIs in ComputerCraft with PixelUI!
