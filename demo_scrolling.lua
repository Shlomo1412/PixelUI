-- Test script for the reworked scrolling system
-- This will test both Container and ListView scrolling functionality

-- Load the PixelUI framework
local PixelUI = require("pixelui")

-- Initialize the UI framework
PixelUI.init()

print("PixelUI Scrolling System Test")
print("=============================")
print()
print("Testing Container Scrolling:")
print("- Creating container with 15 items (viewport shows ~4)")
print("- Use mouse wheel to scroll up/down")
print()

-- Create a scrollable container test
local container = PixelUI.container({
    x = 2, y = 5,
    width = 35,
    height = 8,
    background = colors.gray,
    border = true,
    isScrollable = true
})

-- Add test content to the container
for i = 1, 15 do
    local label = PixelUI.Label:new({
        x = 2, y = i * 2, -- Space items out vertically
        width = 30,
        text = "Container Item " .. i .. " - Scroll to see all items!",
        color = (i % 2 == 0) and colors.yellow or colors.cyan
    })
    container:addChild(label)
    
    -- Add some buttons for interaction testing
    if i % 4 == 0 then
        local button = PixelUI.Button:new({
            x = 2, y = i * 2 + 1,
            width = 20,
            text = "Test Button " .. i,
            onClick = function()
                print("Clicked button " .. i .. " while scrolled!")
            end
        })
        container:addChild(button)
    end
end

-- Create instructions
PixelUI.label({
    x = 40, y = 5,
    text = "Container Test:",
    color = colors.white
})

PixelUI.label({
    x = 40, y = 6,
    text = "15 items total",
    color = colors.orange
})

PixelUI.label({
    x = 40, y = 7,
    text = "~4 visible at once",
    color = colors.orange
})

PixelUI.label({
    x = 40, y = 8,
    text = "Mouse wheel to scroll",
    color = colors.lime
})

-- Test ListView scrolling
print("Testing ListView Scrolling:")
print("- Creating ListView with 20 items (shows 5)")
print("- Use mouse wheel to scroll through list")
print()

-- Create test items for ListView
local listItems = {}
for i = 1, 20 do
    table.insert(listItems, "ListView Item " .. i .. " - Test scrolling functionality")
end

PixelUI.label({
    x = 2, y = 15,
    text = "ListView Test:",
    color = colors.white
})

local listView = PixelUI.listView({
    x = 2, y = 17,
    width = 45,
    height = 5, -- Show only 5 items at once
    items = listItems,
    selectedIndex = 1,
    scrollable = true,
    onSelect = function(self, item, index)
        print("Selected: " .. item .. " (Index: " .. index .. ")")
    end
})

PixelUI.label({
    x = 50, y = 17,
    text = "ListView Test:",
    color = colors.white
})

PixelUI.label({
    x = 50, y = 18,
    text = "20 items total",
    color = colors.orange
})

PixelUI.label({
    x = 50, y = 19,
    text = "5 visible at once",
    color = colors.orange
})

PixelUI.label({
    x = 50, y = 20,
    text = "Wheel to scroll",
    color = colors.lime
})

PixelUI.label({
    x = 50, y = 21,
    text = "Click to select",
    color = colors.lightBlue
})

-- Instructions
print("Instructions:")
print("- Use mouse wheel on the gray container to scroll vertically")
print("- Use mouse wheel on the ListView to scroll through items") 
print("- Click buttons and list items to test interaction while scrolled")
print("- Press 'q' to quit")
print()

-- Start the UI event loop
PixelUI.run()

-- Simple event loop for testing
while true do
    local event, key = os.pullEvent()
    
    if event == "key" and key == keys.q then
        break
    end
    
    -- Let PixelUI handle the event
    PixelUI.handleEvent(event, key)
end

-- Cleanup
PixelUI.stop()
print()
print("Scrolling test completed!")
print("The reworked scrolling system should now be functional.")
