--[[
    Remote Spy + Rayfield UI
    Records RemoteEvent / RemoteFunction calls and generates copyable code
]]

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables
local Recording = false
local Logs = {}          -- stores all captured remotes
local MaxLogs = 50       -- max logs to keep
local LastLog = nil

-- ========== Helper Functions ==========

local function GetPath(instance)
    if not instance then return "nil" end
    local path = instance.Name
    local parent = instance.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return "game." .. path
end

local function ValueToString(value, indent)
    indent = indent or 0
    local t = typeof(value)
    
    if t == "string" then
        return string.format("%q", value)
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(value)
    elseif t == "Instance" then
        return GetPath(value)
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%.3f, %.3f)", value.X, value.Y)
    elseif t == "CFrame" then
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
        return string.format("CFrame.new(%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f)",
            x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", value.R*255, value.G*255, value.B*255)
    elseif t == "table" then
        local parts = {}
        local isArray = #value > 0
        for k, v in pairs(value) do
            local keyStr = isArray and "" or ("[" .. ValueToString(k) .. "] = ")
            table.insert(parts, string.rep("    ", indent + 1) .. keyStr .. ValueToString(v, indent + 1))
        end
        if #parts == 0 then return "{}" end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. string.rep("    ", indent) .. "}"
    else
        return tostring(value)
    end
end

local function GenerateCode(remote, method, args)
    local path = GetPath(remote)
    local argStrings = {}
    
    for i, arg in ipairs(args) do
        table.insert(argStrings, ValueToString(arg))
    end
    
    local code = "-- " .. remote.ClassName .. " | " .. method .. "\n"
    code = code .. path .. ":" .. method .. "("
    
    if #argStrings > 0 then
        code = code .. "\n    " .. table.concat(argStrings, ",\n    ") .. "\n"
    end
    
    code = code .. ")"
    return code
end

local function AddLog(remote, method, args)
    if not Recording then return end
    
    local code = GenerateCode(remote, method, args)
    local entry = {
        Remote = remote,
        Method = method,
        Args = args,
        Code = code,
        Time = os.date("%H:%M:%S")
    }
    
    table.insert(Logs, 1, entry) -- newest first
    if #Logs > MaxLogs then
        table.remove(Logs)
    end
    
    LastLog = entry
    
    -- Update UI
    if UpdateLogDisplay then
        UpdateLogDisplay()
    end
    
    Rayfield:Notify({
        Title = "Remote Captured",
        Content = remote.Name .. ":" .. method,
        Duration = 2,
        Image = 4483362458
    })
end

-- ========== Hook ==========

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if Recording and typeof(self) == "Instance" then
        if (method == "FireServer" or method == "fireServer") and self:IsA("RemoteEvent") then
            task.spawn(AddLog, self, "FireServer", args)
        elseif (method == "InvokeServer" or method == "invokeServer") and self:IsA("RemoteFunction") then
            task.spawn(AddLog, self, "InvokeServer", args)
        end
    end
    
    return oldNamecall(self, ...)
end))

-- ========== UI ==========

local Window = Rayfield:CreateWindow({
    Name = "Remote Spy",
    LoadingTitle = "Remote Spy",
    LoadingSubtitle = "by Grok",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("Remote Spy", 4483362458)
local MainSection = MainTab:CreateSection("Controls")

-- Recording Toggle
local RecordToggle = MainTab:CreateToggle({
    Name = "Record Remotes",
    CurrentValue = false,
    Flag = "RecordToggle",
    Callback = function(Value)
        Recording = Value
        Rayfield:Notify({
            Title = Value and "Recording Started" or "Recording Stopped",
            Content = Value and "Now capturing remotes..." or "Stopped capturing",
            Duration = 3
        })
    end,
})

-- Status Label
local StatusLabel = MainTab:CreateLabel("Status: Idle | Logs: 0")

-- Log Display
local LogParagraph = MainTab:CreateParagraph({
    Title = "Latest Remote",
    Content = "No remotes captured yet.\nEnable recording and interact with the game."
})

function UpdateLogDisplay()
    StatusLabel:Set("Status: " .. (Recording and "Recording" or "Idle") .. " | Logs: " .. #Logs)
    
    if LastLog then
        LogParagraph:Set({
            Title = LastLog.Remote.Name .. "  •  " .. LastLog.Method .. "  •  " .. LastLog.Time,
            Content = LastLog.Code
        })
    end
end

-- Buttons
MainTab:CreateButton({
    Name = "Copy Latest Remote Code",
    Callback = function()
        if LastLog then
            setclipboard(LastLog.Code)
            Rayfield:Notify({
                Title = "Copied!",
                Content = "Remote code copied to clipboard",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Nothing to copy",
                Content = "No remotes captured yet",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateButton({
    Name = "Copy All Logs",
    Callback = function()
        if #Logs == 0 then
            Rayfield:Notify({Title = "Empty", Content = "No logs to copy", Duration = 2})
            return
        end
        
        local allCode = ""
        for i, log in ipairs(Logs) do
            allCode = allCode .. "-- Log #" .. i .. " | " .. log.Time .. "\n" .. log.Code .. "\n\n"
        end
        
        setclipboard(allCode)
        Rayfield:Notify({
            Title = "Copied!",
            Content = #Logs .. " logs copied to clipboard",
            Duration = 3
        })
    end,
})

MainTab:CreateButton({
    Name = "Clear All Logs",
    Callback = function()
        Logs = {}
        LastLog = nil
        LogParagraph:Set({
            Title = "Latest Remote",
            Content = "Logs cleared."
        })
        UpdateLogDisplay()
        Rayfield:Notify({Title = "Cleared", Content = "All logs removed", Duration = 2})
    end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Info", 4483362458)
InfoTab:CreateParagraph({
    Title = "How to use",
    Content = "1. Enable 'Record Remotes'\n2. Play the game / click buttons / do actions\n3. Captured remotes will appear here\n4. Click 'Copy Latest Remote Code' to get the script\n5. Paste it in your executor to fire the same remote again"
})

InfoTab:CreateParagraph({
    Title = "Notes",
    Content = "• Only records client → server calls (FireServer / InvokeServer)\n• Some games detect hooks and may kick you\n• Max 50 logs are kept\n• Works best on Synapse, Script-Ware, Wave, etc."
})

-- Initial status
UpdateLogDisplay()

print("[Remote Spy] Loaded successfully!")
