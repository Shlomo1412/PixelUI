# PixelUI for ComputerCraft/CC: Tweaked

A modern, feature-rich, extensible UI framework for ComputerCraft and CC: Tweaked, designed for advanced desktop-style applications, games, and tools. PixelUI brings a full suite of widgets, event handling, animations, and more to your in-game computers.

---

## 🚀 Super Features

- **Comprehensive Widget Library**: Buttons, labels, text boxes, checkboxes, sliders, progress bars, list views, containers, group boxes, color pickers, tab controls, combo boxes, numeric up/down, spinners, loading indicators, scrollbars, modal dialogs, draggable widgets, and more.
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
- `color`: Initial color

**Events:**
- `onChange(self, color)`

**Example:**
```lua
PixelUI.colorPicker({ x = 2, y = 34, color = colors.red, onChange = function(self, c) print(c) end })
```

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
