-- Auto-completion Demo for PixelUI CodeEditor
-- This example demonstrates the enhanced CodeEditor with auto-completion features

local PixelUI = require("pixelui")

function createAutoCompletionDemo()
    PixelUI.init()
    
    -- Create a code editor with auto-completion enabled
    local codeEditor = PixelUI.codeEditor({
        x = 2,
        y = 2,
        width = 48,
        height = 15,
        border = true,
        autoComplete = true,
        syntaxHighlight = true,
        completionSources = {
            -- Add custom PixelUI API completions
            pixelui_widgets = {
                "PixelUI.button", "PixelUI.label", "PixelUI.textBox", "PixelUI.checkBox",
                "PixelUI.slider", "PixelUI.progressBar", "PixelUI.listView", 
                "PixelUI.container", "PixelUI.window", "PixelUI.modal", "PixelUI.grid",
                "PixelUI.canvas", "PixelUI.chart", "PixelUI.codeEditor", "PixelUI.richTextBox",
                "PixelUI.colorPicker", "PixelUI.filePicker", "PixelUI.dataGrid"
            },
            pixelui_methods = {
                "PixelUI.init", "PixelUI.run", "PixelUI.render", "PixelUI.clear",
                "PixelUI.handleEvent", "PixelUI.setFocus", "PixelUI.clearFocus",
                "PixelUI.showToast", "PixelUI.spawnThread", "PixelUI.killThread"
            },
            cc_colors = {
                "colors.white", "colors.orange", "colors.magenta", "colors.lightBlue",
                "colors.yellow", "colors.lime", "colors.pink", "colors.gray",
                "colors.lightGray", "colors.cyan", "colors.purple", "colors.blue",
                "colors.brown", "colors.green", "colors.red", "colors.black"
            }
        }
    })
    
    -- Set some initial code with helpful comments
    codeEditor:setText([[-- PixelUI Code Editor with Auto-completion
-- Try typing the following to see auto-completion in action:
-- 1. Type any letter to trigger auto-completion
-- 2. Press F1 to manually trigger completion
-- 3. Type 'PixelUI.' to see API methods
-- 4. Type 'colors.' to see color constants  
-- 5. Type 'string.' to see string methods
-- 6. Type 'table.' to see table methods
-- 7. Use Up/Down arrows to navigate completions
-- 8. Press Tab or Enter to insert completion

local PixelUI = require("pixelui")

function main()
    PixelUI.init()
    
    -- Create a simple button
    local button = PixelUI.button({
        x = 10,
        y = 5,
        width = 15,
        height = 3,
        text = "Click Me!",
        bgColor = colors.blue,
        textColor = colors.white,
        onClick = function()
            print("Button clicked!")
        end
    })
    
    -- Start the main loop
    PixelUI.run()
end

-- Call main function
main()]])
    
    -- Create instruction label
    local instructions = PixelUI.label({
        x = 2,
        y = 18,
        width = 48,
        height = 6,
        text = "Auto-completion Instructions:\n" ..
               "• Type any letter to trigger completion\n" ..
               "• Press F1 to manually trigger completion\n" ..
               "• Type 'PixelUI.' or 'colors.' for API completions\n" ..
               "• Type 'string.' or 'table.' for methods\n" ..
               "• Use ↑↓ arrows to navigate, Tab/Enter to insert",
        textColor = colors.yellow,
        bgColor = colors.black,
        alignment = "left"
    })
    
    -- Create toggle button for auto-completion
    local autoCompleteEnabled = true
    local toggleButton = PixelUI.button({
        x = 52,
        y = 2,
        width = 20,
        height = 3,
        text = "Auto-complete: ON",
        bgColor = colors.green,
        textColor = colors.white,
        onClick = function()
            autoCompleteEnabled = not autoCompleteEnabled
            codeEditor.autoComplete = autoCompleteEnabled
            
            if autoCompleteEnabled then
                toggleButton.text = "Auto-complete: ON"
                toggleButton.bgColor = colors.green
            else
                toggleButton.text = "Auto-complete: OFF"
                toggleButton.bgColor = colors.red
                codeEditor:hideAutoCompletion()
            end
        end
    })
    
    -- Create button to add custom completion source
    local customButton = PixelUI.button({
        x = 52,
        y = 6,
        width = 20,
        height = 3,
        text = "Add Custom Items",
        bgColor = colors.purple,
        textColor = colors.white,
        onClick = function()
            -- Add some custom completion items
            codeEditor:addCompletionSource("custom_functions", {
                "myCustomFunction", "anotherFunction", "utilityHelper",
                "processData", "validateInput", "formatOutput"
            })
            
            codeEditor:addCompletionSource("variables", {
                "userData", "configOptions", "tempData", "results",
                "errorMessage", "successFlag", "iterations"
            })
            
            PixelUI.showToast("Custom completion items added!", "Success", "success", 2000)
        end
    })
    
    -- Create info label
    local infoLabel = PixelUI.label({
        x = 52,
        y = 11,
        width = 20,
        height = 8,
        text = "Features:\n" ..
               "• Context-aware\n" ..
               "• Lua keywords\n" ..
               "• Built-in functions\n" ..
               "• API methods\n" ..
               "• Variable detection\n" ..
               "• Custom sources\n" ..
               "• Smart filtering",
        textColor = colors.lightBlue,
        bgColor = colors.black,
        alignment = "left"
    })
    
    -- Focus the code editor
    PixelUI.setFocus(codeEditor)
    
    -- Start the demo
    PixelUI.run({
        onStart = function()
            print("Auto-completion Demo Started!")
            print("Try typing in the code editor to see completions.")
        end,
        onQuit = function()
            print("Auto-completion Demo Ended.")
        end
    })
end

-- Run the demo
createAutoCompletionDemo()
