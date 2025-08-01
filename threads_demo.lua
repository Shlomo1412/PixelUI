-- PixelUI Threads Demo
-- This example demonstrates how to use the thread system in PixelUI

local PixelUI = require("pixelui")

-- Initialize PixelUI
PixelUI.init()

-- Create UI elements
local statusLabel = PixelUI.label({
    x = 2, y = 2,
    text = "Thread Status: Ready",
    width = 30
})

local progressBar = PixelUI.progressBar({
    x = 2, y = 4,
    width = 30,
    value = 0
})

local dataLabel = PixelUI.label({
    x = 2, y = 6,
    text = "API Data: None",
    width = 50
})

local threadCountLabel = PixelUI.label({
    x = 2, y = 8,
    text = "Active Threads: 0",
    width = 20
})

-- Buttons for different thread operations
local startTaskButton = PixelUI.button({
    x = 2, y = 10,
    text = "Start Long Task",
    width = 15,
    onClick = function()
        statusLabel.text = "Thread Status: Running long task..."
        
        -- Spawn a thread for a long-running task
        local threadId = PixelUI.spawnThread(function()
            for i = 1, 100 do
                progressBar.value = i
                statusLabel.text = "Thread Status: Processing " .. i .. "/100"
                PixelUI.sleep(0.05) -- Sleep for 50ms
            end
            statusLabel.text = "Thread Status: Task completed!"
            PixelUI.showToast("Long task completed successfully!", "Success", "success")
        end, "LongTask")
        
        print("Started thread with ID: " .. threadId)
    end
})

local fetchDataButton = PixelUI.button({
    x = 20, y = 10,
    text = "Fetch Data",
    width = 12,
    onClick = function()
        dataLabel.text = "API Data: Fetching..."
        
        -- Simulate API call in background
        PixelUI.spawnThread(function()
            -- Simulate network delay
            PixelUI.sleep(2)
            
            -- Simulate getting data (in real scenario, you'd use http.get())
            local mockData = {
                temperature = math.random(15, 35),
                humidity = math.random(30, 80),
                timestamp = os.date()
            }
            
            dataLabel.text = string.format("Temp: %d°C, Humidity: %d%%, Time: %s", 
                mockData.temperature, mockData.humidity, mockData.timestamp)
            
            PixelUI.showToast("Data fetched successfully!", "API", "success")
        end, "DataFetcher")
    end
})

local killAllButton = PixelUI.button({
    x = 35, y = 10,
    text = "Kill All",
    width = 10,
    background = colors.red,
    onClick = function()
        local stats = PixelUI.getThreadStats()
        if stats.total > 0 then
            -- Kill all threads
            for _, thread in ipairs(PixelUI.getAllThreads()) do
                PixelUI.killThread(thread.id)
            end
            statusLabel.text = "Thread Status: All threads killed"
            PixelUI.showToast("All threads terminated", "System", "warning")
        else
            PixelUI.showToast("No threads to kill", "System", "info")
        end
    end
})

-- Background thread for continuous monitoring
local monitorThreadId = PixelUI.spawnThread(function()
    while true do
        local stats = PixelUI.getThreadStats()
        threadCountLabel.text = string.format("Active: %d, Total: %d", 
            stats.running + stats.suspended, stats.total)
        PixelUI.sleep(0.5) -- Update every 500ms
    end
end, "Monitor")

-- File processing example with async utility
local processFileButton = PixelUI.button({
    x = 2, y = 12,
    text = "Process File",
    width = 15,
    onClick = function()
        -- Use the convenient runAsync function
        local taskId, progressWidget = PixelUI.runAsync(function()
            -- Simulate file processing
            for i = 1, 50 do
                -- Simulate processing work
                PixelUI.sleep(0.1)
                -- In real scenario, you might process file chunks here
            end
            return "File processed successfully!"
        end, {
            name = "FileProcessor",
            showProgress = true,
            progressX = 2,
            progressY = 14,
            progressText = "Processing file...",
            onSuccess = function(result)
                PixelUI.showToast(result, "File Processing", "success")
            end,
            onError = function(error)
                PixelUI.showToast("Processing failed: " .. error, "File Processing", "error")
            end
        })
    end
})

-- HTTP request simulation
local httpButton = PixelUI.button({
    x = 20, y = 12,
    text = "HTTP Request",
    width = 15,
    onClick = function()
        PixelUI.spawnThread(function()
            dataLabel.text = "API Data: Making HTTP request..."
            
            -- In a real scenario, you would do:
            -- local response = http.get("https://api.example.com/data")
            -- if response then
            --     local data = response.readAll()
            --     response.close()
            --     dataLabel.text = "API Data: " .. data
            -- else
            --     dataLabel.text = "API Data: Request failed"
            -- end
            
            -- For demo purposes, simulate the request
            PixelUI.sleep(1.5)
            
            if math.random() > 0.3 then
                dataLabel.text = "API Data: {status: 'ok', users: 42, uptime: '99.9%'}"
                PixelUI.showToast("HTTP request successful", "Network", "success")
            else
                dataLabel.text = "API Data: Request failed (timeout)"
                PixelUI.showToast("HTTP request failed", "Network", "error")
            end
        end, "HTTPRequest")
    end
})

-- Error handling example
local errorButton = PixelUI.button({
    x = 38, y = 12,
    text = "Cause Error",
    width = 12,
    background = colors.orange,
    onClick = function()
        local threadId = PixelUI.spawnThread(function()
            PixelUI.sleep(1)
            error("This is a demo error!")
        end, "ErrorDemo")
        
        -- Set custom error handler
        PixelUI.onThreadError(threadId, function(errorMsg, thread)
            PixelUI.showToast("Custom error handler: " .. errorMsg, thread.name, "error")
            statusLabel.text = "Thread Status: Error occurred in " .. thread.name
        end)
    end
})

-- Info label
local infoLabel = PixelUI.label({
    x = 2, y = 16,
    text = "This demo shows PixelUI's thread system. Threads run in background while UI stays responsive.",
    width = 50,
    color = colors.lightGray
})

local instructionLabel = PixelUI.label({
    x = 2, y = 17,
    text = "Try clicking buttons and notice how the UI never freezes!",
    width = 50,
    color = colors.lightGray
})

-- Run the application
PixelUI.run({
    onStart = function()
        print("PixelUI Threads Demo Started")
        print("Press Q to quit")
        PixelUI.showToast("PixelUI Threads Demo Started", "System", "info")
    end,
    onKey = function(key)
        if key == keys.q then
            return false -- Exit
        end
    end,
    onQuit = function()
        print("Demo ended. All threads stopped.")
    end
})
