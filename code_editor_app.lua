-- PixelUI Code Editor Application
-- A full-featured code editor with file operations, syntax highlighting, and auto-completion

local PixelUI = require("pixelui")

-- Application state
local app = {
    currentFile = nil,
    unsavedChanges = false,
    editor = nil,
    statusBar = nil,
    toolbar = nil,
    toolbarVisible = false,
    toolbarButtons = {},
    fileExplorer = nil,
    explorerVisible = false
}

function createCodeEditor()
    PixelUI.init()
    
    -- Get terminal size for responsive layout
    local termWidth, termHeight = term.getSize()
    
    -- Create main code editor
    app.editor = PixelUI.codeEditor({
        x = 1,
        y = 3, -- Leave space for toolbar
        width = termWidth,
        height = termHeight - 4, -- Leave space for toolbar and status bar
        border = false,
        autoComplete = true,
        syntaxHighlight = true,
        showLineNumbers = true,
        completionSources = {
            -- Comprehensive completion sources
            lua_keywords = {
                "and", "break", "do", "else", "elseif", "end", "false", "for",
                "function", "if", "in", "local", "nil", "not", "or", "repeat",
                "return", "then", "true", "until", "while"
            },
            lua_builtins = {
                "print", "error", "assert", "type", "tostring", "tonumber",
                "pairs", "ipairs", "next", "pcall", "xpcall", "getmetatable", "setmetatable",
                "rawget", "rawset", "rawlen", "select", "unpack", "pack", "require"
            },
            string_methods = {
                "string.byte", "string.char", "string.dump", "string.find", "string.format",
                "string.gmatch", "string.gsub", "string.len", "string.lower", "string.match",
                "string.rep", "string.reverse", "string.sub", "string.upper"
            },
            table_methods = {
                "table.concat", "table.insert", "table.pack", "table.remove",
                "table.sort", "table.unpack"
            },
            math_methods = {
                "math.abs", "math.acos", "math.asin", "math.atan", "math.atan2", "math.ceil",
                "math.cos", "math.cosh", "math.deg", "math.exp", "math.floor", "math.fmod",
                "math.frexp", "math.huge", "math.ldexp", "math.log", "math.max", "math.min",
                "math.modf", "math.pi", "math.pow", "math.rad", "math.random", "math.randomseed",
                "math.sin", "math.sinh", "math.sqrt", "math.tan", "math.tanh"
            },
            cc_apis = {
                "term", "colors", "fs", "os", "redstone", "peripheral", "turtle",
                "pocket", "gps", "http", "textutils", "paintutils", "parallel",
                "vector", "bit", "bit32", "coroutine", "debug", "io", "package"
            },
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
            }
        },
        onChange = function()
            app.unsavedChanges = true
            updateStatusBar()
        end
    })
    
    -- Create status bar
    app.statusBar = PixelUI.label({
        x = 1,
        y = termHeight,
        width = termWidth,
        height = 1,
        text = "Ready | Press Alt to open toolbar | F1: Help",
        textColor = colors.white,
        bgColor = colors.gray,
        alignment = "left"
    })
    
    -- Create toolbar (initially hidden)
    createToolbar()
    
    -- Set initial content
    app.editor:setText([[-- PixelUI Code Editor
-- A feature-rich code editor with syntax highlighting and auto-completion
-- 
-- Keyboard shortcuts:
-- Alt: Toggle toolbar
-- Ctrl+S: Save file
-- Ctrl+O: Open file
-- Ctrl+N: New file
-- F1: Show help
-- F2: Toggle file explorer
-- F3: Find in file
-- F5: Run file
-- Esc: Close dialogs

local PixelUI = require("pixelui")

function main()
    PixelUI.init()
    
    -- Your code here
    
    PixelUI.run()
end

main()]])
    
    -- Focus the editor
    PixelUI.setFocus(app.editor)
    
    -- Set up global key handlers
    setupKeyHandlers()
    
    -- Start the application
    PixelUI.run({
        onStart = function()
            print("PixelUI Code Editor started!")
        end,
        onQuit = function()
            if app.unsavedChanges then
                showSaveDialog()
            else
                print("Code Editor closed.")
            end
        end
    })
end

function createToolbar()
    local termWidth = term.getSize()
    
    -- Store toolbar buttons for easy access
    app.toolbarButtons = {}
    
    app.toolbar = PixelUI.container({
        x = 1,
        y = 1,
        width = termWidth,
        height = 2,
        bgColor = colors.lightGray,
        visible = false
    })
    
    -- File menu buttons
    local fileBtn = PixelUI.button({
        x = 2,
        y = 1,
        width = 8,
        height = 1,
        text = "File",
        bgColor = colors.blue,
        textColor = colors.white,
        visible = false, -- Start hidden
        onClick = function()
            showFileMenu()
        end
    })
    
    local editBtn = PixelUI.button({
        x = 11,
        y = 1,
        width = 8,
        height = 1,
        text = "Edit",
        bgColor = colors.green,
        textColor = colors.white,
        visible = false, -- Start hidden
        onClick = function()
            showEditMenu()
        end
    })
    
    local viewBtn = PixelUI.button({
        x = 20,
        y = 1,
        width = 8,
        height = 1,
        text = "View",
        bgColor = colors.purple,
        textColor = colors.white,
        visible = false, -- Start hidden
        onClick = function()
            showViewMenu()
        end
    })
    
    local runBtn = PixelUI.button({
        x = 29,
        y = 1,
        width = 8,
        height = 1,
        text = "Run",
        bgColor = colors.orange,
        textColor = colors.white,
        visible = false, -- Start hidden
        onClick = function()
            runCurrentFile()
            -- Hide toolbar after action
            if app.toolbarVisible then
                toggleToolbar()
            end
        end
    })
    
    local helpBtn = PixelUI.button({
        x = 38,
        y = 1,
        width = 8,
        height = 1,
        text = "Help",
        bgColor = colors.cyan,
        textColor = colors.white,
        visible = false, -- Start hidden
        onClick = function()
            showHelp()
            -- Hide toolbar after action
            if app.toolbarVisible then
                toggleToolbar()
            end
        end
    })
    
    -- Store references to buttons
    app.toolbarButtons = {fileBtn, editBtn, viewBtn, runBtn, helpBtn}
    
    app.toolbar:addChild(fileBtn)
    app.toolbar:addChild(editBtn)
    app.toolbar:addChild(viewBtn)
    app.toolbar:addChild(runBtn)
    app.toolbar:addChild(helpBtn)
end

function toggleToolbar()
    app.toolbarVisible = not app.toolbarVisible
    app.toolbar.visible = app.toolbarVisible
    
    -- Show/hide all toolbar buttons
    if app.toolbarButtons then
        for _, button in ipairs(app.toolbarButtons) do
            button.visible = app.toolbarVisible
        end
    end
    
    -- Adjust editor position
    local termWidth, termHeight = term.getSize()
    if app.toolbarVisible then
        app.editor.y = 3
        app.editor.height = termHeight - 4
    else
        app.editor.y = 1
        app.editor.height = termHeight - 1
    end
    
    updateStatusBar()
end

function setupKeyHandlers()
    -- Override global key handling for shortcuts
    local originalHandleEvent = PixelUI.handleEvent
    
    PixelUI.handleEvent = function(event, ...)
        local args = {...}
        
        if event == "key" then
            local key = args[1]
            
            -- Alt key toggles toolbar
            if key == keys.leftAlt or key == keys.rightAlt then
                toggleToolbar()
                return
            end
            
            -- Check for Ctrl combinations
            -- Note: In CC:Tweaked, we simulate Ctrl combinations with function keys
            if key == keys.f11 then -- Simulate Ctrl+S
                saveFile()
                return
            elseif key == keys.f12 then -- Simulate Ctrl+O
                openFile()
                return
            elseif key == keys.f10 then -- Simulate Ctrl+N
                newFile()
                return
            elseif key == keys.f1 then
                showHelp()
                return
            elseif key == keys.f2 then
                toggleFileExplorer()
                return
            elseif key == keys.f3 then
                showFindDialog()
                return
            elseif key == keys.f5 then
                runCurrentFile()
                return
            elseif key == keys.escape then
                if app.toolbarVisible then
                    toggleToolbar()
                end
                return
            end
        end
        
        -- Call original handler
        return originalHandleEvent(event, ...)
    end
end

function showFileMenu()
    local menu = PixelUI.modal({
        x = 5,
        y = 5,
        width = 30,
        height = 15,
        title = "File Menu",
        closable = true,
        onClose = function()
            -- Ensure toolbar is hidden when menu is closed
            if app.toolbarVisible then
                toggleToolbar()
            end
        end
    })
    
    local newBtn = PixelUI.button({
        x = 2, y = 2, width = 26, height = 2,
        text = "New File (F10)",
        isChildWidget = true,
        onClick = function()
            newFile()
            menu:close()
        end
    })
    
    local openBtn = PixelUI.button({
        x = 2, y = 5, width = 26, height = 2,
        text = "Open File (F12)",
        isChildWidget = true,
        onClick = function()
            openFile()
            menu:close()
        end
    })
    
    local saveBtn = PixelUI.button({
        x = 2, y = 8, width = 26, height = 2,
        text = "Save File (F11)",
        isChildWidget = true,
        onClick = function()
            saveFile()
            menu:close()
        end
    })
    
    local saveAsBtn = PixelUI.button({
        x = 2, y = 11, width = 26, height = 2,
        text = "Save As...",
        isChildWidget = true,
        onClick = function()
            saveFileAs()
            menu:close()
        end
    })
    
    menu:addChild(newBtn)
    menu:addChild(openBtn)
    menu:addChild(saveBtn)
    menu:addChild(saveAsBtn)
end

function showEditMenu()
    PixelUI.showToast("Edit menu - Find (F3), Replace, Goto Line", "Info", "info", 3000)
    -- Hide toolbar after showing edit menu
    if app.toolbarVisible then
        toggleToolbar()
    end
end

function showViewMenu()
    local menu = PixelUI.modal({
        x = 25,
        y = 5,
        width = 35,
        height = 12,
        title = "View Menu",
        closable = true,
        onClose = function()
            if app.toolbarVisible then
                toggleToolbar()
            end
        end
    })
    
    local explorerBtn = PixelUI.button({
        x = 2, y = 2, width = 31, height = 2,
        text = "File Explorer (F2)",
        isChildWidget = true,
        onClick = function()
            toggleFileExplorer()
            menu:close()
        end
    })
    
    local lineNumbersBtn = PixelUI.button({
        x = 2, y = 5, width = 31, height = 2,
        text = "Toggle Line Numbers",
        isChildWidget = true,
        onClick = function()
            app.editor.showLineNumbers = not app.editor.showLineNumbers
            PixelUI.showToast("Line numbers " .. (app.editor.showLineNumbers and "enabled" or "disabled"), "Info", "info", 2000)
            menu:close()
        end
    })
    
    local programRunnerBtn = PixelUI.button({
        x = 2, y = 8, width = 31, height = 2,
        text = "Program Runner (F5)",
        isChildWidget = true,
        onClick = function()
            if app.currentFile then
                runProgramFullScreen()
            else
                PixelUI.showToast("Save file first to run", "Warning", "warning", 2000)
            end
            menu:close()
        end
    })
    
    menu:addChild(explorerBtn)
    menu:addChild(lineNumbersBtn)
    menu:addChild(programRunnerBtn)
end

function newFile()
    if app.unsavedChanges then
        -- Show save dialog first
        showSaveDialog(function()
            app.editor:setText("")
            app.currentFile = nil
            app.unsavedChanges = false
            updateStatusBar()
        end)
    else
        app.editor:setText("")
        app.currentFile = nil
        app.unsavedChanges = false
        updateStatusBar()
    end
end

function openFile()
    local filePicker = PixelUI.filePicker({
        x = 5,
        y = 5,
        width = 40,
        height = 20,
        title = "Open File",
        fileTypes = {".lua", ".txt", ".md", ".json"},
        onSelect = function(_, filepath)
            if fs.exists(filepath) and not fs.isDir(filepath) then
                local file = fs.open(filepath, "r")
                if file then
                    local content = file.readAll()
                    file.close()
                    
                    app.editor:setText(content)
                    app.currentFile = filepath
                    app.unsavedChanges = false
                    updateStatusBar()
                    
                    PixelUI.showToast("File opened: " .. filepath, "Success", "success", 2000)
                else
                    PixelUI.showToast("Failed to open file", "Error", "error", 3000)
                end
            end
        end
    })
end

function saveFile()
    if app.currentFile then
        local file = fs.open(app.currentFile, "w")
        if file then
            file.write(app.editor:getText())
            file.close()
            app.unsavedChanges = false
            updateStatusBar()
            PixelUI.showToast("File saved: " .. app.currentFile, "Success", "success", 2000)
        else
            PixelUI.showToast("Failed to save file", "Error", "error", 3000)
        end
    else
        saveFileAs()
    end
end

function saveFileAs()
    local modal = PixelUI.modal({
        x = 10,
        y = 8,
        width = 40,
        height = 10,
        title = "Save As",
        closable = true
    })
    
    local filenameBox = PixelUI.textBox({
        x = 2,
        y = 3,
        width = 36,
        height = 1,
        placeholder = "Enter filename..."
    })
    
    local saveBtn = PixelUI.button({
        x = 2,
        y = 6,
        width = 15,
        height = 2,
        text = "Save",
        bgColor = colors.green,
        onClick = function()
            local filename = filenameBox.text
            if filename and filename ~= "" then
                local file = fs.open(filename, "w")
                if file then
                    file.write(app.editor:getText())
                    file.close()
                    app.currentFile = filename
                    app.unsavedChanges = false
                    updateStatusBar()
                    modal:close()
                    PixelUI.showToast("File saved: " .. filename, "Success", "success", 2000)
                else
                    PixelUI.showToast("Failed to save file", "Error", "error", 3000)
                end
            end
        end
    })
    
    local cancelBtn = PixelUI.button({
        x = 20,
        y = 6,
        width = 15,
        height = 2,
        text = "Cancel",
        bgColor = colors.red,
        onClick = function()
            modal:close()
        end
    })
    
    modal:addChild(filenameBox)
    modal:addChild(saveBtn)
    modal:addChild(cancelBtn)
    
    PixelUI.setFocus(filenameBox)
end

function showSaveDialog(callback)
    local modal = PixelUI.modal({
        x = 15,
        y = 10,
        width = 35,
        height = 8,
        title = "Unsaved Changes",
        closable = false
    })
    
    local label = PixelUI.label({
        x = 2,
        y = 2,
        width = 31,
        height = 2,
        text = "You have unsaved changes.\nDo you want to save?",
        alignment = "center"
    })
    
    local saveBtn = PixelUI.button({
        x = 2, y = 5, width = 8, height = 1,
        text = "Save", bgColor = colors.green,
        onClick = function()
            saveFile()
            modal:close()
            if callback then callback() end
        end
    })
    
    local dontSaveBtn = PixelUI.button({
        x = 12, y = 5, width = 10, height = 1,
        text = "Don't Save", bgColor = colors.orange,
        onClick = function()
            modal:close()
            if callback then callback() end
        end
    })
    
    local cancelBtn = PixelUI.button({
        x = 24, y = 5, width = 8, height = 1,
        text = "Cancel", bgColor = colors.red,
        onClick = function()
            modal:close()
        end
    })
    
    modal:addChild(label)
    modal:addChild(saveBtn)
    modal:addChild(dontSaveBtn)
    modal:addChild(cancelBtn)
end

function runCurrentFile()
    if app.currentFile and app.currentFile:match("%.lua$") then
        PixelUI.showToast("Running: " .. app.currentFile, "Info", "info", 2000)
        -- Save first if needed
        if app.unsavedChanges then
            saveFile()
        end
        
        -- Run the script in full screen mode
        runProgramFullScreen()
    else
        PixelUI.showToast("Save as .lua file first to run", "Warning", "warning", 3000)
    end
end

function runProgramFullScreen()
    if not app.currentFile then
        PixelUI.showToast("No file to run", "Warning", "warning", 2000)
        return
    end
    
    local termWidth, termHeight = term.getSize()
    
    -- Clear the screen
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Create a full-screen program widget
    local programWidget = PixelUI.program({
        x = 1,
        y = 1,
        width = termWidth,
        height = termHeight,
        path = app.currentFile,
        environment = {
            EDITOR_FILE = app.currentFile,
            EDITOR_MODE = "run"
        },
        onError = function(prog, error, traceback)
            -- Show error and return to editor
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setCursorPos(1, 1)
            term.setTextColor(colors.red)
            print("Program Error:")
            print(error)
            if traceback and traceback ~= "" then
                print("\nTraceback:")
                print(traceback)
            end
            term.setTextColor(colors.white)
            print("\nPress any key to return to editor...")
            os.pullEvent("key")
            
            -- Return to editor
            returnToEditor()
            return false -- Don't suppress error display
        end,
        onDone = function(prog, success, result)
            -- Program finished, return to editor
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setCursorPos(1, 1)
            
            if success then
                term.setTextColor(colors.green)
                print("Program completed successfully")
                if result then
                    print("Result:", tostring(result))
                end
            else
                term.setTextColor(colors.red)
                print("Program failed")
                if result then
                    print("Error:", tostring(result))
                end
            end
            
            local runtime = prog:getRuntime()
            term.setTextColor(colors.yellow)
            print(string.format("Runtime: %.2f seconds", runtime))
            
            term.setTextColor(colors.white)
            print("\nPress any key to return to editor...")
            os.pullEvent("key")
            
            -- Return to editor
            returnToEditor()
        end
    })
    
    -- Execute the program
    local ok, result = programWidget:execute(app.currentFile)
    if not ok then
        -- Failed to start, show error and return to editor
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.red)
        print("Failed to start program:")
        print(result)
        term.setTextColor(colors.white)
        print("\nPress any key to return to editor...")
        os.pullEvent("key")
        
        returnToEditor()
        return
    end
    
    -- Run a simple event loop to handle the program
    while programWidget:isRunning() do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        -- Handle terminate event to allow Ctrl+T to stop the program
        if event == "terminate" then
            programWidget:stop()
            break
        end
        
        -- Forward events to the program
        programWidget:sendEvent(event, p1, p2, p3, p4, p5)
    end
    
    -- If we get here and the program is still running, it means we broke out of the loop
    if programWidget:isRunning() then
        programWidget:stop()
        
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.yellow)
        print("Program terminated by user")
        term.setTextColor(colors.white)
        print("\nPress any key to return to editor...")
        os.pullEvent("key")
        
        returnToEditor()
    end
end

function returnToEditor()
    -- Clear everything and restart the editor
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Reinitialize PixelUI and recreate the editor
    PixelUI.clear()
    createCodeEditor()
end

function showFindDialog()
    PixelUI.showToast("Find dialog - Coming soon!", "Info", "info", 2000)
end

function toggleFileExplorer()
    PixelUI.showToast("File explorer - Coming soon!", "Info", "info", 2000)
end

function showHelp()
    local help = PixelUI.modal({
        x = 5,
        y = 3,
        width = 50,
        height = 20,
        title = "PixelUI Code Editor Help",
        closable = true
    })
    
    local helpText = PixelUI.label({
        x = 2,
        y = 2,
        width = 46,
        height = 16,
        text = [[Keyboard Shortcuts:
Alt: Toggle toolbar
F1: Show this help
F2: Toggle file explorer
F3: Find in file
F5: Run current file full-screen
F10: New file (Ctrl+N)
F11: Save file (Ctrl+S)
F12: Open file (Ctrl+O)
Esc: Close dialogs

Auto-completion:
Type to trigger suggestions
F1 (in editor): Manual trigger
Up/Down: Navigate options
Tab/Enter: Insert completion
Mouse wheel: Scroll suggestions

Editor Features:
- Syntax highlighting
- Line numbers
- Auto-completion
- Scrolling support
- Multiple file types

Program Runner:
- Runs Lua scripts in full-screen mode
- Real-time program execution
- Automatic return to editor on exit
- Error handling with detailed output
- Ctrl+T to terminate running programs]],
        textColor = colors.white,
        alignment = "left"
    })
    
    help:addChild(helpText)
end

function updateStatusBar()
    local status = ""
    
    if app.currentFile then
        status = "File: " .. app.currentFile
    else
        status = "Untitled"
    end
    
    if app.unsavedChanges then
        status = status .. " [Modified]"
    end
    
    status = status .. " | Line: " .. app.editor.cursorY .. ", Col: " .. app.editor.cursorX
    status = status .. " | Press Alt for toolbar"
    
    app.statusBar.text = status
end

-- Start the application
createCodeEditor()
