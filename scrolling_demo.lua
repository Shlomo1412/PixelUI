-- Scrolling Demo for PixelUI RichTextBox and CodeEditor
-- This example demonstrates the enhanced scrolling features

local PixelUI = require("pixelui")

function createScrollingDemo()
    PixelUI.init()
    
    -- Create a large text content for testing scrolling
    local largeText = [[This is a scrolling demo for PixelUI text widgets.

Line 3: Use the arrow keys to navigate through the text.
Line 4: Page Up and Page Down keys scroll by a full screen.
Line 5: Home key moves to the beginning of the current line.
Line 6: End key moves to the end of the current line.
Line 7: 
Line 8: Function key shortcuts:
Line 9: F2 - Go to top of document
Line 10: F3 - Go to bottom of document
Line 11: F4 - Scroll left (horizontal)
Line 12: F5 - Scroll right (horizontal)
Line 13:
Line 14: Mouse scrolling:
Line 15: Use the mouse wheel to scroll up and down within the text area.
Line 16: This works for both RichTextBox and CodeEditor widgets.
Line 17:
Line 18: This is a very long line that should require horizontal scrolling to see all of its content properly when the text extends beyond the visible width of the text widget.
Line 19:
Line 20: Programming API methods:
Line 21: scrollToLine(n) - Scroll to specific line number
Line 22: scrollBy(n) - Scroll by n lines (positive = down, negative = up)
Line 23: scrollToTop() - Go to first line
Line 24: scrollToBottom() - Go to last line
Line 25:
Line 26: Auto-scrolling:
Line 27: The cursor automatically stays visible when navigating.
Line 28: Text insertion will auto-scroll to keep cursor in view.
Line 29:
Line 30: Performance:
Line 31: Scrolling is optimized for large documents.
Line 32: Only visible lines are rendered for better performance.
Line 33:
Line 34: Try typing new content at the end of this document!
Line 35: The editor will automatically scroll to keep your cursor visible.
Line 36:
Line 37: Editing features:
Line 38: - Insert text anywhere
Line 39: - Delete with backspace
Line 40: - Navigate with all arrow keys
Line 41: - Word wrap (if enabled)
Line 42: - Syntax highlighting (CodeEditor)
Line 43: - Auto-completion (CodeEditor)
Line 44:
Line 45: End of demo content. Try scrolling around!]]
    
    -- Create a RichTextBox for general text editing
    local richTextBox = PixelUI.richTextBox({
        x = 2,
        y = 2,
        width = 35,
        height = 15,
        border = true,
        showLineNumbers = true,
        text = largeText
    })
    
    -- Create a CodeEditor for code editing with syntax highlighting
    local codeEditor = PixelUI.codeEditor({
        x = 39,
        y = 2,
        width = 35,
        height = 15,
        border = true,
        autoComplete = true,
        syntaxHighlight = true
    })
    
    -- Set some sample code in the editor
    codeEditor:setText([[-- Sample Lua Code for Scrolling Demo
local PixelUI = require("pixelui")

function createWindow()
    local window = PixelUI.window({
        x = 5, y = 5,
        width = 30, height = 20,
        title = "My Window",
        closable = true
    })
    
    local button = PixelUI.button({
        x = 2, y = 2,
        width = 10, height = 3,
        text = "Click Me",
        onClick = function()
            print("Button clicked!")
        end
    })
    
    window:addChild(button)
    return window
end

function main()
    PixelUI.init()
    
    local myWindow = createWindow()
    
    -- This is a long comment line that demonstrates horizontal scrolling when the text extends beyond the visible area
    
    PixelUI.run()
end

-- More code to demonstrate scrolling...
for i = 1, 100 do
    print("Line " .. i .. ": This is a test line for scrolling")
end

main()]])
    
    -- Create instruction panel
    local instructions = PixelUI.label({
        x = 2,
        y = 18,
        width = 72,
        height = 6,
        text = "Scrolling Controls:\n" ..
               "Arrow Keys: Navigate • Page Up/Down: Scroll by screen • Home/End: Line start/end\n" ..
               "F2: Document top • F3: Document bottom • F4/F5: Horizontal scroll • Mouse wheel: Scroll\n" ..
               "\n" ..
               "Left: RichTextBox with line numbers | Right: CodeEditor with syntax highlighting\n" ..
               "Try typing, navigating, and scrolling in both widgets!",
        textColor = colors.yellow,
        bgColor = colors.black,
        alignment = "left"
    })
    
    -- Create scroll control buttons for demonstration
    local scrollTopBtn = PixelUI.button({
        x = 76,
        y = 2,
        width = 12,
        height = 2,
        text = "Scroll To Top",
        bgColor = colors.blue,
        textColor = colors.white,
        onClick = function()
            if richTextBox.focused then
                richTextBox:scrollToTop()
            elseif codeEditor.focused then
                codeEditor:scrollToTop()
            end
        end
    })
    
    local scrollBottomBtn = PixelUI.button({
        x = 76,
        y = 5,
        width = 12,
        height = 2,
        text = "Scroll To End",
        bgColor = colors.red,
        textColor = colors.white,
        onClick = function()
            if richTextBox.focused then
                richTextBox:scrollToBottom()
            elseif codeEditor.focused then
                codeEditor:scrollToBottom()
            end
        end
    })
    
    local scrollByBtn = PixelUI.button({
        x = 76,
        y = 8,
        width = 12,
        height = 2,
        text = "Scroll +5",
        bgColor = colors.green,
        textColor = colors.white,
        onClick = function()
            if richTextBox.focused then
                richTextBox:scrollBy(5)
            elseif codeEditor.focused then
                codeEditor:scrollBy(5)
            end
        end
    })
    
    local scrollLineBtn = PixelUI.button({
        x = 76,
        y = 11,
        width = 12,
        height = 2,
        text = "Go Line 20",
        bgColor = colors.purple,
        textColor = colors.white,
        onClick = function()
            if richTextBox.focused then
                richTextBox:scrollToLine(20)
                richTextBox.cursorY = 20
                richTextBox.cursorX = 1
            elseif codeEditor.focused then
                codeEditor:scrollToLine(20)
                codeEditor.cursorY = 20
                codeEditor.cursorX = 1
            end
        end
    })
    
    -- Focus the rich text box initially
    PixelUI.setFocus(richTextBox)
    
    -- Start the demo
    PixelUI.run({
        onStart = function()
            print("Scrolling Demo Started!")
            print("Use keyboard and mouse to test scrolling in both text widgets.")
        end,
        onQuit = function()
            print("Scrolling Demo Ended.")
        end
    })
end

-- Run the demo
createScrollingDemo()
