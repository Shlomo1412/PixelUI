-- Simple PixelUI Monitor Example
-- Shows how to redirect PixelUI output to a monitor peripheral

local PixelUI = require("pixelui")

-- Configuration - Change this to match your monitor's side
local MONITOR_SIDE = "top" -- Options: "top", "bottom", "left", "right", "front", "back"

-- Simple example function
local function runOnMonitor()
    -- Check if monitor is present
    if not peripheral.isPresent(MONITOR_SIDE) then
        error("No monitor found on side: " .. MONITOR_SIDE)
    end
    
    -- Check if it's actually a monitor
    if peripheral.getType(MONITOR_SIDE) ~= "monitor" then
        error("Peripheral on side " .. MONITOR_SIDE .. " is not a monitor")
    end
    
    -- Get the monitor peripheral
    local monitor = peripheral.wrap(MONITOR_SIDE)
    
    -- Configure monitor settings
    monitor.setTextScale(0.5) -- Smaller text for more space
    monitor.clear()
    
    -- Store original terminal for later restoration
    local originalTerm = term.current()
    
    -- Redirect all terminal output to the monitor
    term.redirect(monitor)
    
    -- Now initialize PixelUI - it will use the monitor as its display
    PixelUI.init()
    
    -- Get monitor dimensions
    local width, height = term.getSize()
    print("Monitor size: " .. width .. "x" .. height)
    
    -- Create a simple UI
    local container = PixelUI.container({
        x = 1,
        y = 1,
        width = width,
        height = height,
        background = colors.black,
        border = false
    })
    
    -- Title
    local title = PixelUI.label({
        text = "PixelUI on Monitor!",
        x = 2,
        y = 2,
        color = colors.yellow,
        width = width - 2
    })
    container:addChild(title)
    
    -- Info
    local info = PixelUI.label({
        text = "Monitor: " .. MONITOR_SIDE .. " | Size: " .. width .. "x" .. height,
        x = 2,
        y = 4,
        color = colors.lightGray,
        width = width - 2
    })
    container:addChild(info)
    
    -- Interactive button
    local button = PixelUI.button({
        text = "Click me on the monitor!",
        x = 2,
        y = 6,
        width = 25,
        height = 3,
        onClick = function()
            -- This will show on the monitor
            print("Button clicked on monitor!")
        end
    })
    container:addChild(button)
    
    -- Click counter
    local clickCount = 0
    local counter = PixelUI.label({
        text = "Clicks: " .. clickCount,
        x = 2,
        y = 10,
        color = colors.lime,
        width = 20
    })
    container:addChild(counter)
    
    -- Interactive toggle button
    local isToggled = false
    local toggleButton = PixelUI.button({
        text = "Toggle: OFF",
        x = 2,
        y = 12,
        width = 20,
        height = 3,
        background = colors.red
    })
    
    -- Set the onClick handler after creation
    toggleButton.onClick = function()
        isToggled = not isToggled
        -- Update button properties
        local newText = "Toggle: " .. (isToggled and "ON" or "OFF")
        local newColor = isToggled and colors.green or colors.red
        
        -- Update the button
        toggleButton.text = newText
        toggleButton.background = newColor
        
        clickCount = clickCount + 1
        counter.text = "Clicks: " .. clickCount
        print("Toggle switched to: " .. (isToggled and "ON" or "OFF"))
    end
    container:addChild(toggleButton)
    
    -- Instructions
    local instructions = PixelUI.label({
        text = "Touch the monitor to interact! Press Q on computer to exit.",
        x = 2,
        y = height - 2,
        color = colors.white,
        background = colors.blue,
        width = width - 2
    })
    container:addChild(instructions)
    
    -- Initial render
    PixelUI.render()
    
    -- Event loop
    local running = true
    while running do
        local event, p1, p2, p3, p4 = os.pullEvent()
        
        if event == "monitor_touch" and p1 == MONITOR_SIDE then
            -- Monitor was touched at coordinates p2, p3
            PixelUI.handleEvent("mouse_click", 1, p2, p3)
            
        elseif event == "monitor_scroll" and p1 == MONITOR_SIDE then
            -- Monitor was scrolled
            PixelUI.handleEvent("mouse_scroll", p2, p3, p4)
            
        elseif event == "key" then
            -- Key pressed on computer (not monitor)
            if p1 == keys.q then
                running = false
            else
                PixelUI.handleEvent("key", p1)
            end
            
        elseif event == "char" then
            -- Character typed
            PixelUI.handleEvent("char", p1)
        end
        
        -- Re-render the UI
        PixelUI.render()
    end
    
    -- Restore original terminal
    term.redirect(originalTerm)
    
    -- Clear the monitor
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Demo finished!")
    
    print("PixelUI monitor demo completed!")
end

-- Error handling
local function main()
    local success, error = pcall(runOnMonitor)
    
    if not success then
        print("Error: " .. error)
        print()
        print("Make sure:")
        print("1. A monitor is connected to the '" .. MONITOR_SIDE .. "' side")
        print("2. Update MONITOR_SIDE variable if monitor is on different side")
        print("3. PixelUI framework is available")
    end
end

-- Run the demo
main()
