-- PixelUI Line Chart Demo
-- A comprehensive demonstration of the Chart widget's line chart capabilities

-- Load the PixelUI framework
local PixelUI = require("pixelui")

-- Initialize the UI framework
PixelUI.init()

-- Demo state and configuration
local demo = {
    running = true,
    datasets = {
        {
            name = "Sales Data",
            data = {
                {x = 1, y = 15}, {x = 2, y = 28}, {x = 3, y = 22}, {x = 4, y = 35}, 
                {x = 5, y = 40}, {x = 6, y = 33}, {x = 7, y = 45}, {x = 8, y = 38},
                {x = 9, y = 52}, {x = 10, y = 48}, {x = 11, y = 60}, {x = 12, y = 55}
            },
            color = colors.cyan
        },
        {
            name = "Temperature",
            data = {
                {x = 1, y = 18}, {x = 2, y = 20}, {x = 3, y = 25}, {x = 4, y = 28}, 
                {x = 5, y = 32}, {x = 6, y = 35}, {x = 7, y = 38}, {x = 8, y = 40},
                {x = 9, y = 36}, {x = 10, y = 30}, {x = 11, y = 25}, {x = 12, y = 22}
            },
            color = colors.orange
        },
        {
            name = "Stock Price",
            data = {
                {x = 1, y = 100}, {x = 2, y = 105}, {x = 3, y = 98}, {x = 4, y = 112}, 
                {x = 5, y = 120}, {x = 6, y = 115}, {x = 7, y = 125}, {x = 8, y = 130},
                {x = 9, y = 118}, {x = 10, y = 135}, {x = 11, y = 140}, {x = 12, y = 145}
            },
            color = colors.lime
        },
        {
            name = "User Growth",
            data = {
                {x = 1, y = 50}, {x = 2, y = 65}, {x = 3, y = 80}, {x = 4, y = 95}, 
                {x = 5, y = 110}, {x = 6, y = 125}, {x = 7, y = 140}, {x = 8, y = 155},
                {x = 9, y = 170}, {x = 10, y = 185}, {x = 11, y = 200}, {x = 12, y = 220}
            },
            color = colors.magenta
        },
        {
            name = "Random Data",
            data = {},
            color = colors.yellow
        }
    },
    currentDataset = 1,
    showGrid = true,
    autoScale = true,
    renderMode = "lines", -- "lines" or "pixels"
    animationSpeed = 1.0,
    chartWidth = 45,
    chartHeight = 12
}

-- Generate random data for the random dataset
function demo:generateRandomData()
    self.datasets[5].data = {}
    for i = 1, math.random(5, 15) do
        table.insert(self.datasets[5].data, {x = i, y = math.random(10, 100)})
    end
end

-- Add a new data point to current dataset
function demo:addDataPoint()
    local dataset = self.datasets[self.currentDataset]
    if #dataset.data < 20 then
        local nextX = #dataset.data + 1
        local newY = math.random(10, 150)
        table.insert(dataset.data, {x = nextX, y = newY})
    end
end

-- Remove last data point from current dataset
function demo:removeDataPoint()
    local dataset = self.datasets[self.currentDataset]
    if #dataset.data > 2 then
        table.remove(dataset.data)
    end
end

-- Clear current dataset
function demo:clearDataset()
    local dataset = self.datasets[self.currentDataset]
    dataset.data = {{x = 1, y = math.random(20, 80)}}
end

-- Create a smooth sine wave dataset
function demo:createSineWave()
    local dataset = self.datasets[self.currentDataset]
    dataset.data = {}
    for i = 1, 20 do
        local x = i
        local y = 50 + 30 * math.sin((i - 1) * 0.5)
        table.insert(dataset.data, {x = x, y = y})
    end
end

-- Create an exponential growth dataset
function demo:createExponentialData()
    local dataset = self.datasets[self.currentDataset]
    dataset.data = {}
    for i = 1, 12 do
        local x = i
        local y = 10 * math.pow(1.2, i - 1)
        table.insert(dataset.data, {x = x, y = y})
    end
end

-- Main UI creation
function demo:createUI()
    PixelUI.clear()
    
    -- Title
    PixelUI.label({
        x = 2, y = 1,
        text = "PixelUI Line Chart Demo - Advanced Features Showcase",
        color = colors.yellow
    })
    
    -- Current dataset info
    local currentDataset = self.datasets[self.currentDataset]
    PixelUI.label({
        x = 2, y = 3,
        text = "Current Dataset: " .. currentDataset.name .. " (" .. #currentDataset.data .. " points)",
        color = colors.lime
    })
    
    -- Main chart
    PixelUI.chart({
        x = 2, y = 5,
        width = self.chartWidth,
        height = self.chartHeight,
        data = currentDataset.data,
        chartType = "line",
        renderMode = self.renderMode,
        title = currentDataset.name .. " - Line Chart (" .. self.renderMode .. " mode)",
        xLabel = "Time Period",
        yLabel = "Value",
        dataColor = currentDataset.color,
        showGrid = self.showGrid,
        autoScale = self.autoScale,
        titleColor = colors.white,
        labelColor = colors.lightGray,
        axisColor = colors.lightGray,
        gridColor = colors.gray
    })
    
    -- Dataset selection buttons
    PixelUI.label({
        x = self.chartWidth + 5, y = 5,
        text = "Select Dataset:",
        color = colors.white
    })
    
    for i, dataset in ipairs(self.datasets) do
        PixelUI.button({
            x = self.chartWidth + 5, y = 6 + i,
            text = dataset.name,
            background = (i == self.currentDataset) and dataset.color or colors.gray,
            color = (i == self.currentDataset) and colors.black or colors.white,
            width = 15,
            height = 1,
            onClick = function()
                self.currentDataset = i
                if i == 5 and #dataset.data == 0 then
                    self:generateRandomData()
                end
                self:createUI()
            end
        })
    end
    
    -- Chart options
    PixelUI.label({
        x = self.chartWidth + 5, y = 13,
        text = "Chart Options:",
        color = colors.white
    })
    
    PixelUI.button({
        x = self.chartWidth + 5, y = 14,
        text = "Grid: " .. (self.showGrid and "ON" or "OFF"),
        background = self.showGrid and colors.green or colors.red,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            self.showGrid = not self.showGrid
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = self.chartWidth + 5, y = 15,
        text = "Scale: " .. (self.autoScale and "AUTO" or "MANUAL"),
        background = self.autoScale and colors.blue or colors.orange,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            self.autoScale = not self.autoScale
            self:createUI()
        end
    })
    
    -- Data manipulation
    PixelUI.label({
        x = 2, y = self.chartHeight + 7,
        text = "Data Manipulation:",
        color = colors.white
    })
    
    PixelUI.button({
        x = 2, y = self.chartHeight + 8,
        text = "Add Point",
        background = colors.green,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self:addDataPoint()
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = 14, y = self.chartHeight + 8,
        text = "Remove Point",
        background = colors.red,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            self:removeDataPoint()
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = 28, y = self.chartHeight + 8,
        text = "Clear All",
        background = colors.purple,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self:clearDataset()
            self:createUI()
        end
    })
    
    -- Pattern generation
    PixelUI.label({
        x = 2, y = self.chartHeight + 10,
        text = "Pattern Generation:",
        color = colors.white
    })
    
    PixelUI.button({
        x = 2, y = self.chartHeight + 11,
        text = "Sine Wave",
        background = colors.cyan,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self:createSineWave()
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = 14, y = self.chartHeight + 11,
        text = "Exponential",
        background = colors.orange,
        color = colors.white,
        width = 12,
        height = 1,
        onClick = function()
            self:createExponentialData()
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = 28, y = self.chartHeight + 11,
        text = "Random",
        background = colors.yellow,
        color = colors.black,
        width = 10,
        height = 1,
        onClick = function()
            self:generateRandomData()
            self:createUI()
        end
    })
    
    -- Rendering mode controls
    PixelUI.label({
        x = 40, y = self.chartHeight + 10,
        text = "Render Mode:",
        color = colors.white
    })
    
    PixelUI.button({
        x = 40, y = self.chartHeight + 11,
        text = "Lines",
        background = self.renderMode == "lines" and colors.green or colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.renderMode = "lines"
            self:createUI()
        end
    })
    
    PixelUI.button({
        x = 50, y = self.chartHeight + 11,
        text = "Pixels",
        background = self.renderMode == "pixels" and colors.green or colors.gray,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            self.renderMode = "pixels"
            self:createUI()
        end
    })
    
    -- Chart size controls
    PixelUI.label({
        x = self.chartWidth + 5, y = 17,
        text = "Chart Size:",
        color = colors.white
    })
    
    PixelUI.button({
        x = self.chartWidth + 5, y = 18,
        text = "Width +",
        background = colors.blue,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            if self.chartWidth < 60 then
                self.chartWidth = self.chartWidth + 5
                self:createUI()
            end
        end
    })
    
    PixelUI.button({
        x = self.chartWidth + 14, y = 18,
        text = "Width -",
        background = colors.blue,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            if self.chartWidth > 25 then
                self.chartWidth = self.chartWidth - 5
                self:createUI()
            end
        end
    })
    
    PixelUI.button({
        x = self.chartWidth + 5, y = 19,
        text = "Height +",
        background = colors.green,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            if self.chartHeight < 15 then
                self.chartHeight = self.chartHeight + 2
                self:createUI()
            end
        end
    })
    
    PixelUI.button({
        x = self.chartWidth + 14, y = 19,
        text = "Height -",
        background = colors.green,
        color = colors.white,
        width = 8,
        height = 1,
        onClick = function()
            if self.chartHeight > 8 then
                self.chartHeight = self.chartHeight - 2
                self:createUI()
            end
        end
    })
    
    -- Statistics display
    if #currentDataset.data > 0 then
        local minY, maxY, avgY = math.huge, -math.huge, 0
        for _, point in ipairs(currentDataset.data) do
            local y = point.y or point[2] or 0
            if y < minY then minY = y end
            if y > maxY then maxY = y end
            avgY = avgY + y
        end
        avgY = avgY / #currentDataset.data
        
        PixelUI.label({
            x = 2, y = self.chartHeight + 13,
            text = "Statistics:",
            color = colors.white
        })
        
        PixelUI.label({
            x = 2, y = self.chartHeight + 14,
            text = string.format("Min: %.1f, Max: %.1f, Avg: %.1f", minY, maxY, avgY),
            color = colors.cyan
        })
        
        PixelUI.label({
            x = 2, y = self.chartHeight + 15,
            text = string.format("Range: %.1f, Points: %d", maxY - minY, #currentDataset.data),
            color = colors.lightGray
        })
    end
    
    -- Instructions
    PixelUI.label({
        x = 2, y = self.chartHeight + 17,
        text = "Instructions: Select different datasets, modify chart options, and manipulate data.",
        color = colors.lightGray
    })
    
    PixelUI.label({
        x = 2, y = self.chartHeight + 18,
        text = "Try different patterns and observe how the line chart adapts to your data!",
        color = colors.lightGray
    })
    
    -- Exit button
    PixelUI.button({
        x = 2, y = self.chartHeight + 20,
        text = "Exit Demo",
        background = colors.red,
        color = colors.white,
        width = 10,
        height = 1,
        onClick = function()
            self.running = false
        end
    })
end

-- Welcome message
print("PixelUI Line Chart Demo")
print("======================")
print("This demo showcases the advanced features of the Chart widget")
print("specifically for line charts, including:")
print("- Multiple datasets with different patterns")
print("- Dynamic data manipulation") 
print("- Chart customization options")
print("- Real-time statistics")
print("- Interactive controls")
print()
print("Press any key to start the demo...")
os.pullEvent("key")

-- Initialize random data for the random dataset
demo:generateRandomData()

-- Create initial UI
demo:createUI()

-- Main event loop
PixelUI.run({
    onKey = function(key)
        if key == keys.q or key == keys.leftCtrl then
            demo.running = false
        end
    end,
    onExit = function()
        return not demo.running
    end
})

-- Exit message
print()
print("Thanks for trying the PixelUI Line Chart Demo!")
print()
print("Features demonstrated:")
print("- Line chart rendering with custom colors")
print("- Multiple dataset switching")
print("- Grid and scaling options")
print("- Data point manipulation")
print("- Pattern generation (sine, exponential, random)")
print("- Dynamic chart resizing")
print("- Real-time statistics")
print("- Interactive controls")
print()
print("The Chart widget supports line, bar, and scatter chart types.")
print("Try the main demo (example.lua) to see all chart types!")
