-- Enhanced CodeEditor Plugin with extended auto-completion
-- This plugin demonstrates how to extend the CodeEditor's auto-completion with custom functionality

-- Custom Enhanced CodeEditor with additional features
local EnhancedCodeEditor = setmetatable({}, {__index = PixelUI.CodeEditor})
EnhancedCodeEditor.__index = EnhancedCodeEditor

function EnhancedCodeEditor:new(props)
    local editor = PixelUI.CodeEditor:new(props)
    setmetatable(editor, EnhancedCodeEditor)
    
    -- Enhanced completion features
    editor.snippetCompletion = props.snippetCompletion ~= false
    editor.functionSignatures = props.functionSignatures ~= false
    editor.documentationHints = props.documentationHints ~= false
    
    -- Code snippets for quick insertion
    editor.snippets = {
        ["if"] = "if condition then\n    -- code here\nend",
        ["for"] = "for i = 1, 10 do\n    -- code here\nend",
        ["while"] = "while condition do\n    -- code here\nend",
        ["function"] = "function name()\n    -- code here\n    return result\nend",
        ["local"] = "local variable = value",
        ["table"] = "local tbl = {\n    key = value,\n    -- more items\n}",
        ["class"] = "local ClassName = {}\nClassName.__index = ClassName\n\nfunction ClassName:new(props)\n    local obj = setmetatable({}, ClassName)\n    -- initialize properties\n    return obj\nend",
        ["pcall"] = "local success, result = pcall(function()\n    -- protected code here\nend)",
        ["widget"] = "local widget = PixelUI.WIDGET_TYPE({\n    x = 1,\n    y = 1,\n    width = 10,\n    height = 3,\n    -- additional properties\n})"
    }
    
    -- Function signatures for better context
    editor.functionSignatures = {
        ["print"] = "print(...) -- Prints values to the console",
        ["pairs"] = "pairs(table) -- Returns iterator for table key-value pairs",
        ["ipairs"] = "ipairs(array) -- Returns iterator for array indices and values",
        ["type"] = "type(value) -- Returns the type of a value as string",
        ["tostring"] = "tostring(value) -- Converts value to string",
        ["tonumber"] = "tonumber(string, base) -- Converts string to number",
        ["pcall"] = "pcall(func, ...) -- Protected call, returns success, result",
        ["string.find"] = "string.find(str, pattern, init, plain) -- Finds pattern in string",
        ["string.sub"] = "string.sub(str, start, end) -- Returns substring",
        ["string.gsub"] = "string.gsub(str, pattern, replacement, n) -- Global substitution",
        ["table.insert"] = "table.insert(array, pos, value) -- Inserts value into array",
        ["table.remove"] = "table.remove(array, pos) -- Removes element from array",
        ["table.sort"] = "table.sort(array, comp) -- Sorts array in-place",
        ["PixelUI.button"] = "PixelUI.button({x, y, width, height, text, onClick, ...}) -- Creates button widget",
        ["PixelUI.label"] = "PixelUI.label({x, y, width, height, text, ...}) -- Creates label widget"
    }
    
    return editor
end

-- Enhanced auto-completion that includes snippets
function EnhancedCodeEditor:addCompletionOptions(source, category)
    for _, item in ipairs(source) do
        if item:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
            local completion = {
                text = item,
                category = category,
                display = item .. " (" .. category .. ")"
            }
            
            -- Add signature if available
            if self.functionSignatures and self.functionSignatures[item] then
                completion.signature = self.functionSignatures[item]
                completion.display = item .. " - " .. self.functionSignatures[item]:match("^[^%-]+") .. " (" .. category .. ")"
            end
            
            table.insert(self.completionOptions, completion)
        end
    end
    
    -- Add snippets if enabled
    if self.snippetCompletion and category == "keyword" then
        for snippet, code in pairs(self.snippets) do
            if snippet:lower():find(self.completionPrefix:lower(), 1, true) == 1 then
                table.insert(self.completionOptions, {
                    text = snippet,
                    category = "snippet",
                    display = snippet .. " - " .. code:match("^[^\n]+") .. " (snippet)",
                    isSnippet = true,
                    code = code
                })
            end
        end
    end
end

-- Enhanced completion insertion with snippet support
function EnhancedCodeEditor:insertCompletion()
    if not self.completionVisible or #self.completionOptions == 0 then return false end
    
    local completion = self.completionOptions[self.completionSelected]
    local currentLine = self.lines[self.cursorY] or ""
    
    if completion.isSnippet then
        -- Insert snippet with proper indentation
        local beforePrefix = currentLine:sub(1, self.completionStartX - 1)
        local afterCursor = currentLine:sub(self.cursorX)
        local indent = beforePrefix:match("^(%s*)")
        
        -- Split snippet into lines and add indentation
        local snippetLines = {}
        for line in completion.code:gmatch("[^\n]+") do
            if #snippetLines == 0 then
                -- First line doesn't need extra indentation
                table.insert(snippetLines, line)
            else
                -- Subsequent lines get the current indentation
                table.insert(snippetLines, indent .. line)
            end
        end
        
        -- Replace current line with first snippet line
        self.lines[self.cursorY] = beforePrefix .. snippetLines[1] .. afterCursor
        
        -- Insert additional lines if needed
        for i = 2, #snippetLines do
            table.insert(self.lines, self.cursorY + i - 1, snippetLines[i])
        end
        
        -- Position cursor at end of insertion
        if #snippetLines > 1 then
            self.cursorY = self.cursorY + #snippetLines - 1
            self.cursorX = #snippetLines[#snippetLines] + 1
        else
            self.cursorX = self.completionStartX + #snippetLines[1]
        end
    else
        -- Regular completion insertion
        local beforePrefix = currentLine:sub(1, self.completionStartX - 1)
        local afterCursor = currentLine:sub(self.cursorX)
        local newLine = beforePrefix .. completion.text .. afterCursor
        
        self.lines[self.cursorY] = newLine
        self.cursorX = self.completionStartX + #completion.text
    end
    
    self:hideAutoCompletion()
    return true
end

-- Enhanced completion rendering with signatures
function EnhancedCodeEditor:renderAutoCompletion()
    if not self.completionVisible or #self.completionOptions == 0 then return end
    
    local absX, absY = self:getAbsolutePos()
    local contentX = absX + (self.border and 1 or 0) + 4
    local contentY = absY + (self.border and 1 or 0)
    
    -- Calculate completion popup position
    local popupX = contentX + self.completionStartX - self.scrollX - 1
    local popupY = contentY + self.completionStartY - self.scrollY
    
    -- Adjust popup size for signatures
    local termWidth, termHeight = term.getSize()
    local popupWidth = math.min(self.maxCompletionWidth, 50) -- Wider for signatures
    local popupHeight = math.min(#self.completionOptions, self.maxCompletionHeight)
    
    -- Adjust position if needed
    if popupX + popupWidth > termWidth then
        popupX = termWidth - popupWidth
    end
    if popupY + popupHeight > termHeight then
        popupY = popupY - popupHeight - 1
    end
    
    popupX = math.max(1, popupX)
    popupY = math.max(1, popupY)
    
    -- Draw completion popup
    for i = 1, math.min(#self.completionOptions, popupHeight) do
        local option = self.completionOptions[i]
        local isSelected = (i == self.completionSelected)
        
        term.setCursorPos(popupX, popupY + i - 1)
        
        if isSelected then
            term.setBackgroundColor(colors.blue)
            term.setTextColor(colors.white)
        else
            -- Color code by category
            if option.category == "snippet" then
                term.setBackgroundColor(colors.purple)
                term.setTextColor(colors.white)
            elseif option.category == "keyword" then
                term.setBackgroundColor(colors.red)
                term.setTextColor(colors.white)
            elseif option.category == "builtin" then
                term.setBackgroundColor(colors.green)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.lightGray)
                term.setTextColor(colors.black)
            end
        end
        
        -- Truncate and display text
        local displayText = option.text
        if option.signature and isSelected then
            displayText = option.signature:match("^[^%-]+") or option.text
        end
        
        if #displayText > popupWidth - 2 then
            displayText = displayText:sub(1, popupWidth - 5) .. "..."
        end
        
        term.write(" " .. displayText .. string.rep(" ", popupWidth - #displayText - 1))
    end
    
    -- Draw border
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    
    -- Draw simple border
    for i = 0, popupHeight - 1 do
        if popupX > 1 then
            term.setCursorPos(popupX - 1, popupY + i)
            term.write("|")
        end
        if popupX + popupWidth <= termWidth then
            term.setCursorPos(popupX + popupWidth, popupY + i)
            term.write("|")
        end
    end
end

-- Register the enhanced code editor plugin
registerPlugin({
    id = "enhanced_code_editor",
    name = "Enhanced Code Editor Plugin",
    version = "1.0.0",
    author = "PixelUI Enhanced Team",
    description = "Provides enhanced CodeEditor with snippets, signatures, and improved auto-completion",
    
    widgets = {
        enhancedCodeEditor = EnhancedCodeEditor
    },
    
    onLoad = function(plugin)
        print("Enhanced Code Editor Plugin loaded - snippets and signatures available")
        
        -- Add enhanced completion sources
        local enhancedSources = {
            lua_patterns = {
                "%w+", "%d+", "%s+", "%p+", "%a+", "%l+", "%u+", "%c+", "%x+"
            },
            common_patterns = {
                "function.*end", "if.*then.*end", "for.*do.*end", "while.*do.*end",
                "repeat.*until", "local.*=", "return.*"
            },
            cc_events = {
                "timer", "char", "key", "key_up", "mouse_click", "mouse_up", 
                "mouse_scroll", "mouse_drag", "redstone", "terminate",
                "disk", "disk_eject", "peripheral", "peripheral_detach"
            }
        }
        
        -- Emit event with enhanced sources
        emit("enhancedCompletionLoaded", {
            plugin = plugin,
            sources = enhancedSources
        })
    end,
    
    onEnable = function(plugin)
        print("Enhanced Code Editor Plugin enabled - enhanced features active")
    end,
    
    api = {
        createEnhancedCodeEditor = function(props)
            local editor = EnhancedCodeEditor:new(props)
            return editor
        end,
        
        addSnippet = function(editor, name, code)
            if editor.snippets then
                editor.snippets[name] = code
            end
        end,
        
        addSignature = function(editor, funcName, signature)
            if editor.functionSignatures then
                editor.functionSignatures[funcName] = signature
            end
        end
    }
})
