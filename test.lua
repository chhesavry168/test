--[[
    NOVA v9 — Clean Dark UI + Deep SPY Logger
    LocalScript → StarterPlayer > StarterPlayerScripts

    Deep capture:
      • Remote args fully decoded (numbers, strings, tables expanded)
      • When a GUI opens, it scans its children for TextLabels/Buttons
        and logs names + prices (auto-detects $ / price / robux patterns)
      • Purchase / buy detection: Remotes or GUIs containing "buy",
        "purchase", "shop", "checkout" get parsed for item name + cost
      • Attack / damage: parses remotes with "attack", "hit", "damage",
        "deal", "combat" and logs the target + value
      • Tool equip / unequip with full details
      • Humanoid.Health changes (damage taken / healed)
      • NumberValue / IntValue / StringValue changes
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local Stats            = game:GetService("Stats")
local HttpService      = game:GetService("HttpService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================
-- THEME
-- =====================================================
local T = {
    Base      = Color3.fromRGB(12, 12, 15),
    Surface   = Color3.fromRGB(18, 18, 22),
    Surface2  = Color3.fromRGB(24, 24, 29),
    Surface3  = Color3.fromRGB(28, 33, 44),
    Divider   = Color3.fromRGB(30, 30, 36),
    Text      = Color3.fromRGB(240, 240, 245),
    SubText   = Color3.fromRGB(130, 130, 140),
    Muted     = Color3.fromRGB(80, 80, 90),
    Accent    = Color3.fromRGB(130, 100, 255),
    Off       = Color3.fromRGB(40, 40, 48),
    Red       = Color3.fromRGB(230, 70, 90),
    Green     = Color3.fromRGB(90, 220, 150),
    Yellow    = Color3.fromRGB(240, 200, 80),
    Pink      = Color3.fromRGB(240, 120, 200),
    Blue      = Color3.fromRGB(120, 180, 255),
    Purple    = Color3.fromRGB(170, 120, 255),
    Orange    = Color3.fromRGB(255, 160, 90),
}

local FONT   = Enum.Font.Gotham
local FONT_M = Enum.Font.GothamMedium
local FONT_S = Enum.Font.GothamSemibold
local FONT_B = Enum.Font.GothamBold
local FONT_K = Enum.Font.GothamBlack

-- =====================================================
-- STATE
-- =====================================================
local State = {
    FPSBoost=false, AntiLag=false, AntiAFK=false,
    FullBright=false, InfiniteJmp=false, NoClip=false,
    WalkSpeed=16, JumpPower=50,
}

-- =====================================================
-- HELPERS
-- =====================================================
local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0,6); c.Parent = p; return c
end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or T.Divider; s.Thickness = t or 1; s.Transparency = tr or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function pad(p,l,r,t,b)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l or 0); u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingTop=UDim.new(0,t or 0);  u.PaddingBottom=UDim.new(0,b or 0); u.Parent=p
end
local function ts()
    return string.format("[%02d:%02d:%02d]",
        tonumber(os.date("%H")), tonumber(os.date("%M")), tonumber(os.date("%S")))
end
local function fullPath(inst)
    if not inst then return "nil" end
    local ok, path = pcall(function()
        local parts = {}; local cur = inst
        while cur and cur ~= game do
            table.insert(parts, 1, cur.Name); cur = cur.Parent
        end
        return "game." .. table.concat(parts, ".")
    end)
    return ok and path or inst.Name
end
local function valToLua(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(v)
    if t == "Vector3" then
        return string.format("Vector3.new(%g, %g, %g)", v.X, v.Y, v.Z)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%g, %g)", v.X, v.Y)
    elseif t == "CFrame" then
        return "CFrame.new(" .. tostring(v) .. ")"
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)",
            math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255))
    elseif t == "Instance" then
        return fullPath(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "EnumItem" then
        return tostring(v)
    elseif t == "table" then
        local parts = {}
        for k, val in pairs(v) do
            local key = (type(k) == "string") and k or ("[" .. tostring(k) .. "]")
            table.insert(parts, tostring(key) .. " = " .. valToLua(val, depth + 1))
        end
        if #parts == 0 then return "{}" end
        return "{ " .. table.concat(parts, ", ") .. " }"
    else
        return tostring(v)
    end
end
local function humanReadable(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(v)
    if t == "Instance" then return v.Name .. " (" .. v.ClassName .. ")"
    elseif t == "table" then
        local parts = {}
        for k, val in pairs(v) do
            table.insert(parts, tostring(k) .. "=" .. humanReadable(val, depth + 1))
        end
        return table.concat(parts, ", ")
    elseif t == "string" then return v
    elseif t == "number" then
        if v == math.floor(v) then return tostring(math.floor(v)) end
        return string.format("%.2f", v)
    else
        return tostring(v)
    end
end

-- Detect price-looking strings/numbers
local function looksLikePrice(str)
    if type(str) ~= "string" then return false end
    return str:match("^%$") or str:match("^%d+$") or str:lower():find("robux")
        or str:lower():find("coins") or str:lower():find("cash") or str:lower():find("gold")
        or str:lower():find("gems") or str:lower():find("token")
end

-- =====================================================
-- ROOT
-- =====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "NOVA"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.Parent = playerGui

-- =====================================================
-- LAUNCHER
-- =====================================================
local launcher = Instance.new("TextButton")
launcher.Name = "Launcher"
launcher.Size = UDim2.fromOffset(92, 32)
launcher.Position = UDim2.new(0, 30, 0.5, -16)
launcher.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
launcher.AutoButtonColor = false
launcher.Text = ""
launcher.Parent = gui
corner(launcher, UDim.new(0, 6))

local underline = Instance.new("Frame")
underline.Size = UDim2.new(1, -16, 0, 2)
underline.Position = UDim2.new(0, 8, 1, -5)
underline.BackgroundColor3 = T.Accent
underline.BorderSizePixel = 0
underline.Parent = launcher
corner(underline, UDim.new(1, 0))

local ulGrad = Instance.new("UIGradient")
ulGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 200, 255)),
    ColorSequenceKeypoint.new(1, T.Accent),
})
ulGrad.Parent = underline

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "NOVA"
label.Font = FONT_B
label.TextSize = 14
label.TextColor3 = T.Text
label.Parent = launcher

local lgGrad = Instance.new("UIGradient")
lgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
})
lgGrad.Parent = label

task.spawn(function()
    while launcher.Parent do
        for i = 0, 1, 0.01 do
            ulGrad.Offset = Vector2.new(i, 0); lgGrad.Offset = Vector2.new(i, 0)
            RunService.RenderStepped:Wait()
        end
        for i = 1, 0, -0.01 do
            ulGrad.Offset = Vector2.new(i, 0); lgGrad.Offset = Vector2.new(i, 0)
            RunService.RenderStepped:Wait()
        end
    end
end)

local THRESH = 6
local dragging, moved, startPos, dragStart = false, false, nil, nil
launcher.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging, moved = true, false
        dragStart = i.Position; startPos = launcher.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMovement
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = i.Position - dragStart
    if not moved and (math.abs(d.X) > THRESH or math.abs(d.Y) > THRESH) then moved = true end
    if moved then
        launcher.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1
        and i.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragging and not moved then
        if _G.__NOVA_toggle then _G.__NOVA_toggle() end
    end
    dragging, moved = false, false
end)
launcher.MouseEnter:Connect(function()
    TweenService:Create(launcher, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,28)}):Play()
end)
launcher.MouseLeave:Connect(function()
    TweenService:Create(launcher, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(15,15,20)}):Play()
end)

-- =====================================================
-- MENU
-- =====================================================
local MW, MH = 800, 480
local HEADER_H = 56
local TABS_H = 40

local menu = Instance.new("Frame")
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.new(0.5, 0, 0.5, 0)
menu.Size = UDim2.fromOffset(MW, MH)
menu.BackgroundColor3 = T.Base
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Visible = false
menu.Parent = gui
corner(menu, UDim.new(0, 10))
stroke(menu, T.Divider, 1, 0.4)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.Parent = menu

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 22)
title.Position = UDim2.new(0, 20, 0, 17)
title.BackgroundTransparency = 1
title.Text = "NOVA"
title.Font = FONT_B
title.TextSize = 16
title.TextColor3 = T.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local headerDiv = Instance.new("Frame")
headerDiv.Size = UDim2.new(1, 0, 0, 1)
headerDiv.Position = UDim2.new(0, 0, 0, HEADER_H)
headerDiv.BackgroundColor3 = T.Divider
headerDiv.BorderSizePixel = 0
headerDiv.Parent = menu

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
closeBtn.AutoButtonColor = false
closeBtn.Text = "✕"
closeBtn.TextColor3 = T.SubText
closeBtn.Font = FONT_B
closeBtn.TextSize = 14
closeBtn.Parent = header
corner(closeBtn, UDim.new(0, 6))
closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Red, TextColor3 = Color3.new(1,1,1)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,27), TextColor3 = T.SubText}):Play()
end)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.fromOffset(28, 28)
minBtn.Position = UDim2.new(1, -72, 0, 14)
minBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
minBtn.AutoButtonColor = false
minBtn.Text = "—"
minBtn.TextColor3 = T.SubText
minBtn.Font = FONT_B
minBtn.TextSize = 14
minBtn.Parent = header
corner(minBtn, UDim.new(0, 6))
minBtn.MouseEnter:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,40,48), TextColor3 = Color3.new(1,1,1)}):Play()
end)
minBtn.MouseLeave:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22,22,27), TextColor3 = T.SubText}):Play()
end)

local tabStrip = Instance.new("Frame")
tabStrip.Size = UDim2.new(1, 0, 0, TABS_H)
tabStrip.Position = UDim2.new(0, 0, 0, HEADER_H + 1)
tabStrip.BackgroundTransparency = 1
tabStrip.Parent = menu

local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, -32, 1, 0)
tabRow.Position = UDim2.new(0, 16, 0, 0)
tabRow.BackgroundTransparency = 1
tabRow.Parent = tabStrip

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabRow

local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 60, 0, 2)
indicator.Position = UDim2.new(0, 16, 1, -3)
indicator.BackgroundColor3 = T.Accent
indicator.BorderSizePixel = 0
indicator.Parent = tabStrip
corner(indicator, UDim.new(1, 0))

local tabDiv = Instance.new("Frame")
tabDiv.Size = UDim2.new(1, 0, 0, 1)
tabDiv.Position = UDim2.new(0, 0, 0, HEADER_H + TABS_H + 1)
tabDiv.BackgroundColor3 = T.Divider
tabDiv.BorderSizePixel = 0
tabDiv.Parent = menu

local pageHolder = Instance.new("Frame")
pageHolder.Size = UDim2.new(1, 0, 1, -(HEADER_H + TABS_H + 2))
pageHolder.Position = UDim2.new(0, 0, 0, HEADER_H + TABS_H + 2)
pageHolder.BackgroundTransparency = 1
pageHolder.Parent = menu
pad(pageHolder, 16, 16, 12, 16)

local pages = {}
local tabs = {}

local function showPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
end

local function createPage(name, addLayout)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 2
    p.ScrollBarImageColor3 = T.Muted
    p.ScrollBarImageTransparency = 0.4
    p.CanvasSize = UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = pageHolder
    if addLayout ~= false then
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 8)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = p
    end
    pages[name] = p
    return p
end

local function registerTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0, 84, 1, 0)
    tab.BackgroundTransparency = 1
    tab.Text = name
    tab.Font = FONT_M
    tab.TextSize = 13
    tab.TextColor3 = T.SubText
    tab.AutoButtonColor = false
    tab.LayoutOrder = order
    tab.Parent = tabRow

    local function setActive(active)
        TweenService:Create(tab, TweenInfo.new(0.18), {
            TextColor3 = active and T.Text or T.SubText }):Play()
    end

    tab.MouseEnter:Connect(function()
        if tab.TextColor3 ~= T.Text then
            TweenService:Create(tab, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(190,190,205)}):Play()
        end
    end)
    tab.MouseLeave:Connect(function()
        if tab.TextColor3 ~= T.Text then
            TweenService:Create(tab, TweenInfo.new(0.15), {TextColor3 = T.SubText}):Play()
        end
    end)
    tab.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do t.setActive(false) end
        setActive(true)
        TweenService:Create(indicator, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, tab.AbsolutePosition.X - tabStrip.AbsolutePosition.X, 1, -3),
            Size = UDim2.new(0, tab.AbsoluteSize.X, 0, 2),
        }):Play()
        showPage(name)
    end)

    local entry = {button = tab, setActive = setActive, name = name}
    tabs[#tabs+1] = entry
    return entry
end

-- =====================================================
-- TOGGLE / SLIDER ROWS (same as before)
-- =====================================================
local function createToggle(parent, name, desc, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = T.Surface
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    corner(row, UDim.new(0, 6))

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 18); title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1; title.Text = name; title.TextColor3 = T.Text
    title.Font = FONT_M; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -120, 0, 14); sub.Position = UDim2.new(0, 14, 0, 30)
    sub.BackgroundTransparency = 1; sub.Text = desc; sub.TextColor3 = T.SubText
    sub.Font = FONT; sub.TextSize = 10; sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 20); track.Position = UDim2.new(1, -54, 0.5, -10)
    track.BackgroundColor3 = T.Off; track.BorderSizePixel = 0; track.Parent = row
    corner(track, UDim.new(0, 4))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16); knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(230, 230, 240); knob.BorderSizePixel = 0
    knob.Parent = track; corner(knob, UDim.new(0, 3))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.Parent = track

    local isOn = false
    local function set(on)
        isOn = on
        if on then
            TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = T.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = T.Off}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
        if callback then pcall(callback, on) end
    end
    btn.MouseButton1Click:Connect(function() set(not isOn) end)
    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface2}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface}):Play()
    end)
    return row, set
end

local function createSlider(parent, name, minV, maxV, default, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = T.Surface; row.BorderSizePixel = 0
    row.LayoutOrder = order; row.Parent = parent
    corner(row, UDim.new(0, 6))

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 18); title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1; title.Text = name; title.TextColor3 = T.Text
    title.Font = FONT_M; title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row

    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0, 70, 0, 18); value.Position = UDim2.new(1, -84, 0, 10)
    value.BackgroundTransparency = 1; value.Text = tostring(default)
    value.TextColor3 = T.Accent; value.Font = FONT_B; value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right; value.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 4); track.Position = UDim2.new(0, 14, 0, 42)
    track.BackgroundColor3 = T.Off; track.BorderSizePixel = 0; track.Parent = row
    corner(track, UDim.new(1, 0))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent; fill.BorderSizePixel = 0; fill.Parent = track
    corner(fill, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Size = UDim2.fromOffset(10, 10)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0; knob.Parent = track
    corner(knob, UDim.new(1, 0))

    local draggingS = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV - minV) * rel + 0.5)
        value.Text = tostring(v)
        TweenService:Create(fill, TweenInfo.new(0.06), {Size = UDim2.new(rel,0,1,0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.06), {Position = UDim2.new(rel,0,0.5,0)}):Play()
        if callback then pcall(callback, v) end
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            draggingS = true; setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingS and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then draggingS = false end
    end)
    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface2}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface}):Play()
    end)
    return row
end

-- =====================================================
-- REAL FEATURES (same as v8)
-- =====================================================
local fpsSnap = {}
local function setFPSBoost(on)
    if on then
        fpsSnap = {shadows=Lighting.GlobalShadows, fog=Lighting.FogEnd, bright=Lighting.Brightness,
                   ed=Lighting.EnvironmentDiffuseScale, es=Lighting.EnvironmentSpecularScale}
        Lighting.GlobalShadows = false; Lighting.FogEnd = 1e5; Lighting.Brightness = 2
        Lighting.EnvironmentDiffuseScale = 0; Lighting.EnvironmentSpecularScale = 0
        pcall(function() Lighting.ShadowSoftness = 0 end)
        for _,e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = false end end
        pcall(function() Workspace.GlobalWind = Vector3.new(0,0,0) end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        Lighting.GlobalShadows = fpsSnap.shadows ~= false
        Lighting.FogEnd = fpsSnap.fog or 1e5; Lighting.Brightness = fpsSnap.bright or 2
        Lighting.EnvironmentDiffuseScale = fpsSnap.ed or 1; Lighting.EnvironmentSpecularScale = fpsSnap.es or 1
        for _,e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = true end end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
end

local lagHidden = {}
local function setAntiLag(on)
    if on then
        for _,d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles") then
                if d.Enabled then d.Enabled = false table.insert(lagHidden, d) end
            end
        end
    else
        for _,d in ipairs(lagHidden) do pcall(function() d.Enabled = true end) end
        lagHidden = {}
    end
end

local afkConn
local function setAntiAFK(on)
    if on then
        if not afkConn then
            afkConn = player.Idled:Connect(function()
                VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if afkConn then afkConn:Disconnect() afkConn = nil end
    end
end

local brightSnap = {}
local function setFullBright(on)
    if on then
        brightSnap = {amb=Lighting.Ambient, oamb=Lighting.OutdoorAmbient, br=Lighting.Brightness,
                      ct=Lighting.ClockTime, fog=Lighting.FogEnd, sh=Lighting.GlobalShadows}
        Lighting.Ambient = Color3.fromRGB(178,178,178); Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        if not Lighting:FindFirstChild("NOVA_CC") then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "NOVA_CC"; cc.Brightness = 0.15; cc.Contrast = 0.05; cc.Parent = Lighting
        end
    else
        Lighting.Ambient = brightSnap.amb or Lighting.Ambient
        Lighting.OutdoorAmbient = brightSnap.oamb or Lighting.OutdoorAmbient
        Lighting.Brightness = brightSnap.br or 2; Lighting.ClockTime = brightSnap.ct or 14
        Lighting.FogEnd = brightSnap.fog or 1e5; Lighting.GlobalShadows = brightSnap.sh ~= false
        local cc = Lighting:FindFirstChild("NOVA_CC"); if cc then cc:Destroy() end
    end
end

local infJumpConn
local function setInfiniteJump(on)
    if on then
        if not infJumpConn then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local c = player.Character
                if c then
                    local h = c:FindFirstChildOfClass("Humanoid")
                    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    else
        if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    end
end

local noclipConn
local function setNoClip(on)
    if on then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                local c = player.Character
                if c then
                    for _,p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                    end
                end
            end)
        end
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        local c = player.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

local function setWalkSpeed(v)
    local c = player.Character
    if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = v end end
end
local function setJumpPower(v)
    local c = player.Character
    if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h.UseJumpPower = true h.JumpPower = v end end
end

player.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid"); task.wait(0.2)
    setWalkSpeed(State.WalkSpeed); setJumpPower(State.JumpPower)
end)

-- PAGES
local generalPage  = createPage("General")
local movementPage = createPage("Movement")
local visualPage   = createPage("Visuals")

registerTab("General", 1)
createToggle(generalPage, "FPS Boost", "Boost rendering performance", 1, function(on) State.FPSBoost = on setFPSBoost(on) end)
createToggle(generalPage, "Anti Lag",  "Disable particle & effects lag", 2, function(on) State.AntiLag = on setAntiLag(on) end)
createToggle(generalPage, "Anti AFK",  "Prevent 20-minute idle kick", 3, function(on) State.AntiAFK = on setAntiAFK(on) end)

registerTab("Movement", 2)
createToggle(movementPage, "Infinite Jump", "Jump endlessly mid-air", 1, function(on) State.InfiniteJmp = on setInfiniteJump(on) end)
createToggle(movementPage, "No Clip",       "Walk through walls", 2, function(on) State.NoClip = on setNoClip(on) end)
createSlider(movementPage, "Walk Speed", 16, 250, 16, 3, function(v) State.WalkSpeed = v setWalkSpeed(v) end)
createSlider(movementPage, "Jump Power", 50, 300, 50, 4, function(v) State.JumpPower = v setJumpPower(v) end)

registerTab("Visuals", 3)
createToggle(visualPage, "Full Bright", "See in the dark everywhere", 1, function(on) State.FullBright = on setFullBright(on) end)

-- =====================================================
-- SPY PAGE
-- =====================================================
local spyPage = createPage("Spy", false)

local spyTop = Instance.new("Frame")
spyTop.Size = UDim2.new(1, 0, 0, 28)
spyTop.BackgroundTransparency = 1
spyTop.LayoutOrder = 0
spyTop.Parent = spyPage

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.fromOffset(66, 26); pauseBtn.Position = UDim2.new(0, 0, 0, 0)
pauseBtn.BackgroundColor3 = T.Surface; pauseBtn.AutoButtonColor = false
pauseBtn.Text = "Pause"; pauseBtn.TextColor3 = T.SubText
pauseBtn.Font = FONT_M; pauseBtn.TextSize = 11; pauseBtn.Parent = spyTop
corner(pauseBtn, UDim.new(0, 6))
pauseBtn.MouseEnter:Connect(function()
    TweenService:Create(pauseBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface2, TextColor3 = T.Text}):Play()
end)
pauseBtn.MouseLeave:Connect(function()
    TweenService:Create(pauseBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface, TextColor3 = T.SubText}):Play()
end)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.fromOffset(66, 26); clearBtn.Position = UDim2.new(0, 74, 0, 0)
clearBtn.BackgroundColor3 = T.Surface; clearBtn.AutoButtonColor = false
clearBtn.Text = "Clear"; clearBtn.TextColor3 = T.SubText
clearBtn.Font = FONT_M; clearBtn.TextSize = 11; clearBtn.Parent = spyTop
corner(clearBtn, UDim.new(0, 6))
clearBtn.MouseEnter:Connect(function()
    TweenService:Create(clearBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface2, TextColor3 = T.Text}):Play()
end)
clearBtn.MouseLeave:Connect(function()
    TweenService:Create(clearBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface, TextColor3 = T.SubText}):Play()
end)

local chipRow = Instance.new("Frame")
chipRow.Size = UDim2.new(1, -160, 0, 26); chipRow.Position = UDim2.new(0, 148, 0, 0)
chipRow.BackgroundTransparency = 1; chipRow.ClipsDescendants = true; chipRow.Parent = spyTop

local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.Padding = UDim.new(0, 6); chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
chipLayout.Parent = chipRow

local spyFilters = {"All", "Remotes", "Items", "GUI", "Shop", "Combat", "Actions", "Values"}
local activeFilter = "All"

local CATEGORY_COLORS = {
    Remote = T.Blue, Item = T.Green, GUI = T.Yellow,
    Shop = T.Orange, Combat = T.Red, Action = T.Pink,
    Property = T.Purple, Value = T.Purple, Instance = T.SubText, Error = T.Red,
}

local spyLogs = {}
local spyPaused = false
local spyNextId = 1
local rowCache = {}
local currentCode = ""

local spyBody = Instance.new("Frame")
spyBody.Size = UDim2.new(1, 0, 1, -38); spyBody.Position = UDim2.new(0, 0, 0, 38)
spyBody.BackgroundTransparency = 1; spyBody.LayoutOrder = 1; spyBody.Parent = spyPage

local listPanel = Instance.new("Frame")
listPanel.Size = UDim2.new(0.55, -5, 1, 0)
listPanel.BackgroundColor3 = T.Surface; listPanel.BorderSizePixel = 0
listPanel.Parent = spyBody
corner(listPanel, UDim.new(0, 6))

local listScroll = Instance.new("ScrollingFrame")
listScroll.Size = UDim2.new(1, -8, 1, -8); listScroll.Position = UDim2.new(0, 4, 0, 4)
listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0
listScroll.ScrollBarThickness = 2; listScroll.ScrollBarImageColor3 = T.Muted
listScroll.CanvasSize = UDim2.new(0,0,0,0); listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
listScroll.Parent = listPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2); listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listScroll

local detailPanel = Instance.new("Frame")
detailPanel.Size = UDim2.new(0.45, -5, 1, 0); detailPanel.Position = UDim2.new(0.55, 5, 0, 0)
detailPanel.BackgroundColor3 = T.Surface; detailPanel.BorderSizePixel = 0
detailPanel.Parent = spyBody
corner(detailPanel, UDim.new(0, 6))
pad(detailPanel, 12, 12, 10, 10)

local dTitle = Instance.new("TextLabel")
dTitle.Size = UDim2.new(1, 0, 0, 18); dTitle.BackgroundTransparency = 1
dTitle.Text = "Select an event"; dTitle.Font = FONT_B; dTitle.TextSize = 13
dTitle.TextColor3 = T.Text; dTitle.TextXAlignment = Enum.TextXAlignment.Left
dTitle.Parent = detailPanel

local dSub = Instance.new("TextLabel")
dSub.Size = UDim2.new(1, 0, 0, 14); dSub.Position = UDim2.new(0, 0, 0, 20)
dSub.BackgroundTransparency = 1; dSub.Text = "Click a row to see its code"
dSub.Font = FONT; dSub.TextSize = 10; dSub.TextColor3 = T.SubText
dSub.TextXAlignment = Enum.TextXAlignment.Left; dSub.Parent = detailPanel

local dDivider = Instance.new("Frame")
dDivider.Size = UDim2.new(1, 0, 0, 1); dDivider.Position = UDim2.new(0, 0, 0, 40)
dDivider.BackgroundColor3 = T.Divider; dDivider.BorderSizePixel = 0; dDivider.Parent = detailPanel

local dCodeBox = Instance.new("Frame")
dCodeBox.Size = UDim2.new(1, 0, 1, -88); dCodeBox.Position = UDim2.new(0, 0, 0, 50)
dCodeBox.BackgroundColor3 = T.Base; dCodeBox.BorderSizePixel = 0; dCodeBox.Parent = detailPanel
corner(dCodeBox, UDim.new(0, 5))
stroke(dCodeBox, T.Divider, 1, 0.5)

local dCodeScroll = Instance.new("ScrollingFrame")
dCodeScroll.Size = UDim2.new(1, -12, 1, -12); dCodeScroll.Position = UDim2.new(0, 6, 0, 6)
dCodeScroll.BackgroundTransparency = 1; dCodeScroll.BorderSizePixel = 0
dCodeScroll.ScrollBarThickness = 2; dCodeScroll.ScrollBarImageColor3 = T.Muted
dCodeScroll.CanvasSize = UDim2.new(0,0,0,0); dCodeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
dCodeScroll.Parent = dCodeBox

local dCode = Instance.new("TextLabel")
dCode.Size = UDim2.new(1, 0, 0, 0); dCode.BackgroundTransparency = 1
dCode.Text = ""; dCode.Font = Enum.Font.Code; dCode.TextSize = 12
dCode.TextColor3 = Color3.fromRGB(200, 220, 240)
dCode.TextWrapped = true; dCode.TextXAlignment = Enum.TextXAlignment.Left
dCode.TextYAlignment = Enum.TextYAlignment.Top; dCode.AutomaticSize = Enum.AutomaticSize.Y
dCode.Parent = dCodeScroll

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(1, 0, 0, 30); copyBtn.Position = UDim2.new(0, 0, 1, -34)
copyBtn.BackgroundColor3 = T.Accent; copyBtn.AutoButtonColor = false
copyBtn.Text = "Copy Code"; copyBtn.TextColor3 = Color3.fromRGB(15,15,20)
copyBtn.Font = FONT_B; copyBtn.TextSize = 12; copyBtn.Parent = detailPanel
corner(copyBtn, UDim.new(0, 6))
copyBtn.MouseEnter:Connect(function()
    TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(150,200,255)}):Play()
end)
copyBtn.MouseLeave:Connect(function()
    TweenService:Create(copyBtn, TweenInfo.new(0.15), {BackgroundColor3 = T.Accent}):Play()
end)
copyBtn.MouseButton1Click:Connect(function()
    if currentCode ~= "" and setclipboard then
        setclipboard(currentCode)
        copyBtn.Text = "Copied!"
        task.wait(1)
        copyBtn.Text = "Copy Code"
    end
end)

local function matchesFilter(entry)
    if activeFilter == "All" then return true end
    if activeFilter == "Remotes" then return entry.category == "Remote" end
    if activeFilter == "Items"   then return entry.category == "Item" end
    if activeFilter == "GUI"     then return entry.category == "GUI" end
    if activeFilter == "Shop"    then return entry.category == "Shop" end
    if activeFilter == "Combat"  then return entry.category == "Combat" end
    if activeFilter == "Actions" then return entry.category == "Action" end
    if activeFilter == "Values"  then return entry.category == "Value" end
    return true
end

local function selectEntry(entry)
    dTitle.Text = entry.title
    dSub.Text = entry.time .. "  ·  " .. entry.category
    dCode.Text = entry.code or "-- no code captured"
    currentCode = entry.code or ""
end

local function makeRow(entry)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 26); row.BackgroundColor3 = T.Surface
    row.BackgroundTransparency = 1; row.AutoButtonColor = false; row.Text = ""
    row.LayoutOrder = entry.id; row.Parent = listScroll
    corner(row, UDim.new(0, 4))

    local chip = Instance.new("Frame")
    chip.Size = UDim2.fromOffset(3, 14); chip.Position = UDim2.new(0, 8, 0.5, -7)
    chip.BackgroundColor3 = CATEGORY_COLORS[entry.category] or T.SubText
    chip.BorderSizePixel = 0; chip.Parent = row
    corner(chip, UDim.new(1,0))

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(0, 58, 1, 0); tl.Position = UDim2.new(0, 16, 0, 0)
    tl.BackgroundTransparency = 1; tl.Text = entry.time
    tl.Font = Enum.Font.Code; tl.TextSize = 10; tl.TextColor3 = T.Muted
    tl.TextXAlignment = Enum.TextXAlignment.Left; tl.Parent = row

    local cl = Instance.new("TextLabel")
    cl.Size = UDim2.new(0, 62, 1, 0); cl.Position = UDim2.new(0, 76, 0, 0)
    cl.BackgroundTransparency = 1; cl.Text = entry.category
    cl.Font = FONT_B; cl.TextSize = 10
    cl.TextColor3 = CATEGORY_COLORS[entry.category] or T.SubText
    cl.TextXAlignment = Enum.TextXAlignment.Left; cl.Parent = row

    local text = entry.title
    if #text > 60 then text = text:sub(1, 57) .. "..." end

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -152, 1, 0); nl.Position = UDim2.new(0, 142, 0, 0)
    nl.BackgroundTransparency = 1; nl.Text = text
    nl.Font = FONT; nl.TextSize = 11; nl.TextColor3 = T.Text
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextTruncate = Enum.TextTruncate.AtEnd; nl.Parent = row

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.1), {BackgroundTransparency = 0, BackgroundColor3 = T.Surface2}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
    end)
    row.MouseButton1Click:Connect(function()
        selectEntry(entry)
        for _, r in ipairs(rowCache) do
            if r.entry.id ~= entry.id then
                TweenService:Create(r.button, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            end
        end
        TweenService:Create(row, TweenInfo.new(0.15), {
            BackgroundTransparency = 0, BackgroundColor3 = T.Surface3 }):Play()
    end)

    rowCache[#rowCache+1] = {button = row, entry = entry}
    return row
end

local function refreshSpyList()
    for _, r in ipairs(rowCache) do r.button:Destroy() end
    rowCache = {}
    for _, entry in ipairs(spyLogs) do
        if matchesFilter(entry) then makeRow(entry) end
    end
    if #spyLogs > 0 then
        local last = spyLogs[#spyLogs]
        if matchesFilter(last) then selectEntry(last) end
    end
end

local function addLog(category, title, code)
    if spyPaused then return end
    local entry = {
        id = spyNextId, time = ts(), category = category,
        title = title, code = code or ("-- " .. title),
    }
    spyNextId += 1
    spyLogs[#spyLogs+1] = entry
    if #spyLogs > 500 then table.remove(spyLogs, 1) end
    if matchesFilter(entry) then
        makeRow(entry)
        task.defer(function()
            listScroll.CanvasPosition = Vector2.new(0, math.max(0, listScroll.AbsoluteCanvasSize.Y))
        end)
        selectEntry(entry)
    end
end

for i, f in ipairs(spyFilters) do
    local chip = Instance.new("TextButton")
    chip.Size = UDim2.new(0, 66, 1, 0)
    chip.BackgroundColor3 = T.Surface; chip.BackgroundTransparency = 0.4
    chip.AutoButtonColor = false; chip.Text = f
    chip.Font = FONT_M; chip.TextSize = 10; chip.TextColor3 = T.SubText
    chip.LayoutOrder = i; chip.Parent = chipRow
    corner(chip, UDim.new(0, 6))
    chip.MouseButton1Click:Connect(function()
        activeFilter = f
        for _, c in ipairs(chipRow:GetChildren()) do
            if c:IsA("TextButton") then
                TweenService:Create(c, TweenInfo.new(0.15), {
                    BackgroundColor3 = T.Surface, BackgroundTransparency = 0.4, TextColor3 = T.SubText }):Play()
            end
        end
        TweenService:Create(chip, TweenInfo.new(0.15), {
            BackgroundColor3 = T.Accent, BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(15,15,20) }):Play()
        refreshSpyList()
    end)
    chip.MouseEnter:Connect(function()
        TweenService:Create(chip, TweenInfo.new(0.1), {BackgroundColor3 = T.Surface2}):Play()
    end)
    chip.MouseLeave:Connect(function()
        if activeFilter ~= f then
            TweenService:Create(chip, TweenInfo.new(0.1), {BackgroundColor3 = T.Surface}):Play()
        end
    end)
    if i == 1 then
        chip.BackgroundColor3 = T.Accent; chip.BackgroundTransparency = 0
        chip.TextColor3 = Color3.fromRGB(15,15,20)
    end
end

registerTab("Spy", 4)

-- =====================================================
-- DEEP CAPTURE HOOKS
-- =====================================================

-- Names hinting at a purchase / shop action
local BUY_HINTS = {"buy","purchase","shop","checkout","order","sell","cashout","acquire"}
local ATTACK_HINTS = {"attack","hit","damage","deal","strike","combat","shoot","punch","swing","slash","kill"}
local SPEED_HINTS = {"speed","walkspeed","boost","velocity","sprint","haste"}
local GUI_OPEN_HINTS = {"open","show","toggle","menu","display","enable"}
local GUI_CLOSE_HINTS = {"close","hide","disable","dismiss"}

local function hasHint(str, list)
    str = str:lower()
    for _, h in ipairs(list) do
        if str:find(h, 1, true) then return h end
    end
    return nil
end

-- Walk a GUI tree and pull out item names + prices
local function scanGuiContent(root, maxDepth, maxItems)
    maxDepth = maxDepth or 4
    maxItems = maxItems or 40
    local found = {}
    local visited = 0
    local function walk(node, depth)
        if depth > maxDepth or visited >= maxItems then return end
        for _, c in ipairs(node:GetChildren()) do
            visited += 1
            if visited >= maxItems then return end
            local entry
            if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("ImageButton") then
                local txt = c.Text
                if txt and txt ~= "" and #txt < 60 then
                    entry = { name = c.Name, text = txt, class = c.ClassName, path = c }
                    -- heuristic: it's a price if it contains $, digits, or currency words
                    if looksLikePrice(txt) then
                        entry.price = txt
                    end
                    table.insert(found, entry)
                end
            elseif c:IsA("TextButton") then
                table.insert(found, { name = c.Name, text = c.Text, class = c.ClassName, path = c })
            end
            walk(c, depth + 1)
        end
    end
    walk(root, 0)
    return found
end

-- Format a GUI scan as readable Lua
local function formatGuiScan(items)
    if #items == 0 then return "-- (no text elements found)" end
    local lines = {}
    for i, it in ipairs(items) do
        if it.price then
            table.insert(lines, string.format("--   [%d] %s  |  %s = %q   ← PRICE", i, it.name, it.class, it.text))
        else
            table.insert(lines, string.format("--   [%d] %s  |  %s = %q", i, it.name, it.class, it.text))
        end
    end
    return table.concat(lines, "\n")
end

-- 1. Remote hook (deep)
local function hookRemotes(parent)
    for _, inst in ipairs(parent:GetDescendants()) do
        if inst:IsA("RemoteEvent") then
            if not inst:GetAttribute("__NOVA_spy_hooked") then
                inst:SetAttribute("__NOVA_spy_hooked", true)
                inst.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local names, vals = {}, {}
                    for i = 1, #args do
                        table.insert(names, "arg" .. i)
                        table.insert(vals, string.format("--   arg%d (%s) = %s",
                            i, typeof(args[i]), valToLua(args[i])))
                    end
                    local readable = {}
                    for i = 1, #args do
                        table.insert(readable, "arg" .. i .. "=" .. humanReadable(args[i]))
                    end
                    local path = fullPath(inst)
                    local nameLower = inst.Name:lower()
                    local pathLower = path:lower()

                    -- classify
                    local cat = "Remote"
                    local titlePrefix = "◀ "
                    local extra = ""

                    local buyHint = hasHint(nameLower, BUY_HINTS) or hasHint(pathLower, BUY_HINTS)
                    local atkHint = hasHint(nameLower, ATTACK_HINTS) or hasHint(pathLower, ATTACK_HINTS)
                    local spdHint = hasHint(nameLower, SPEED_HINTS) or hasHint(pathLower, SPEED_HINTS)

                    if buyHint then
                        cat = "Shop"
                        extra = string.format("\n-- 🛒 Detected as SHOP/BUY (hint: %q)", buyHint)
                    elseif atkHint then
                        cat = "Combat"
                        extra = string.format("\n-- ⚔ Detected as COMBAT/ATTACK (hint: %q)", atkHint)
                    elseif spdHint then
                        cat = "Value"
                        extra = string.format("\n-- 🏃 Detected as SPEED (hint: %q)", spdHint)
                    end

                    local code = string.format(
                        "-- Received from server\n%s:OnClientEvent:Connect(function(%s)\n    -- ...\nend)\n\n-- Args:\n%s%s\n-- Human readable: %s",
                        path, table.concat(names, ", "),
                        table.concat(vals, "\n"), extra,
                        table.concat(readable, "  |  "))

                    addLog(cat, titlePrefix .. path .. " (" .. #args .. " args)", code)
                end)
            end
        end
    end
end
hookRemotes(game)
game.DescendantAdded:Connect(function(inst)
    if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
        task.defer(function() hookRemotes(inst.Parent or game) end)
    end
end)

-- 2. Backpack / tool
local function watchBackpack(bp)
    bp.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            local stats = {}
            for _, v in ipairs(child:GetChildren()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("StringValue") then
                    table.insert(stats, string.format("--   %s = %s (%s)", v.Name, tostring(v.Value), v.ClassName))
                end
            end
            local code = string.format(
                "-- Tool added to Backpack\nlocal tool = %s\n-- ToolName: %q\n-- ToolTip: %q\n%s",
                fullPath(child), child.Name, child.ToolTip or "",
                #stats > 0 and table.concat(stats, "\n") or "-- (no stats inside)")
            addLog("Item", "Picked up: " .. child.Name, code)
        end
    end)
    bp.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            addLog("Item", "Removed: " .. child.Name,
                "-- Tool removed\n" .. fullPath(child) .. ":Destroy()")
        end
    end)
    for _, c in ipairs(bp:GetChildren()) do
        if c:IsA("Tool") then
            addLog("Item", "Existing tool: " .. c.Name, "-- Tool: " .. fullPath(c))
        end
    end
end
local function onCharacter(char)
    local bp = player:WaitForChild("Backpack", 5)
    if bp then watchBackpack(bp) end
    char.ChildAdded:Connect(function(c)
        if c:IsA("Tool") then
            addLog("Item", "Equipped: " .. c.Name, "-- Equipped: " .. fullPath(c))
        end
    end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

-- 3. GUI open/close — with content scan!
local function watchGui(g)
    if not g:IsA("ScreenGui") then return end
    -- initial state
    if g.Enabled then
        task.defer(function()
            local items = scanGuiContent(g, 5, 60)
            addLog("GUI", "Already open: " .. g.Name,
                string.format("-- ScreenGui '%s' was open at start\n-- Path: %s\n-- Content:\n%s",
                    g.Name, fullPath(g), formatGuiScan(items)))
        end)
    end
    g:GetPropertyChangedSignal("Enabled"):Connect(function()
        if g.Enabled then
            local items = scanGuiContent(g, 5, 60)
            local code = string.format(
                "-- ScreenGui '%s' OPENED\n-- Path: %s\n-- Content captured:\n%s\n\n-- Reproduce:\nlocal gui = %s\ngui.Enabled = true",
                g.Name, fullPath(g), formatGuiScan(items), fullPath(g))
            addLog("GUI", "Opened: " .. g.Name .. " (" .. #items .. " elements)", code)
        else
            addLog("GUI", "Closed: " .. g.Name,
                string.format("-- ScreenGui '%s' CLOSED\nlocal gui = %s\ngui.Enabled = false", g.Name, fullPath(g)))
        end
    end)
end

for _, g in ipairs(playerGui:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name ~= "NOVA" then watchGui(g) end
end
playerGui.ChildAdded:Connect(function(c)
    if c:IsA("ScreenGui") and c.Name ~= "NOVA" then
        addLog("GUI", "ScreenGui created: " .. c.Name,
            "-- Created ScreenGui\nlocal gui = " .. fullPath(c))
        watchGui(c)
    end
end)

-- 4. Button clicks — with parent GUI context (so a "Buy" button click is logged)
local function hookButtons(root)
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not d:GetAttribute("__NOVA_spy_btn") then
            d:SetAttribute("__NOVA_spy_btn", true)
            d.MouseButton1Click:Connect(function()
                -- Walk up to find the enclosing ScreenGui name
                local anc, guiName = d.Parent, "?"
                while anc and anc ~= game do
                    if anc:IsA("ScreenGui") then guiName = anc.Name break end
                    anc = anc.Parent
                end
                local label = d.Text ~= "" and d.Text or d.Name
                local lower = (d.Name .. " " .. (d.Text or "")):lower()
                local isBuy = hasHint(lower, BUY_HINTS)
                local isAtk = hasHint(lower, ATTACK_HINTS)

                -- try to find sibling price
                local priceFound
                if d.Parent then
                    for _, sib in ipairs(d.Parent:GetDescendants()) do
                        if sib:IsA("TextLabel") then
                            if looksLikePrice(sib.Text) then priceFound = sib.Text break end
                        end
                    end
                end

                local cat = isBuy and "Shop" or (isAtk and "Combat" or "Action")
                local detail = string.format(
                    "-- Button clicked\n-- GUI: %s\n-- Button name: %q\n-- Button label: %q\n-- Path: %s%s%s",
                    guiName, d.Name, label, fullPath(d),
                    priceFound and ("\n-- Nearby price: " .. priceFound) or "",
                    isBuy and "\n-- 🛒 SHOP/BUY button" or (isAtk and "\n-- ⚔ COMBAT button" or "")
                )
                addLog(cat, "Click: " .. label .. " (in " .. guiName .. ")", detail)
            end)
        end
    end
end

-- hook buttons in existing ScreenGuis + future
for _, g in ipairs(playerGui:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name ~= "NOVA" then
        hookButtons(g)
        g.DescendantAdded:Connect(function(d)
            if d:IsA("TextButton") or d:IsA("ImageButton") then
                task.defer(function() hookButtons(g) end)
            end
        end)
    end
end
playerGui.ChildAdded:Connect(function(c)
    if c:IsA("ScreenGui") and c.Name ~= "NOVA" then
        hookButtons(c)
        c.DescendantAdded:Connect(function(d)
            if d:IsA("TextButton") or d:IsA("ImageButton") then
                task.defer(function() hookButtons(c) end)
            end
        end)
    end
end)

-- 5. Health changes (damage / heal)
local function watchHealth(h)
    local lastName = h.Health
    h:GetPropertyChangedSignal("Health"):Connect(function()
        local delta = h.Health - lastName
        local old = lastName
        lastName = h.Health
        if math.abs(delta) < 0.01 then return end
        local isDamage = delta < 0
        addLog("Combat",
            string.format("%s %.1f HP (%.1f → %.1f)",
                isDamage and "Took" or "Healed", math.abs(delta), old, h.Health),
            string.format("-- HP change\n-- Before: %.2f\n-- After:  %.2f\n-- Delta:  %+.2f (%s)",
                old, h.Health, delta, isDamage and "DAMAGE" or "HEAL"))
    end)
end
local function watchHumanoid(h)
    watchHealth(h)
    local lastState
    h.StateChanged:Connect(function(_, new)
        if new ~= lastState then
            lastState = new
            addLog("Action", "State: " .. new.Name,
                string.format("-- Humanoid state: %s", new.Name))
        end
    end)
end
local function onCharHum(c)
    local h = c:WaitForChild("Humanoid", 5)
    if h then watchHumanoid(h) end
end
player.CharacterAdded:Connect(onCharHum)
if player.Character then onCharHum(player.Character) end

-- 6. Keys / chat
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        addLog("Action", "Key: " .. input.KeyCode.Name,
            string.format("-- Key pressed: %s", input.KeyCode.Name))
    end
end)
player.Chatted:Connect(function(msg)
    addLog("Action", "Chat: " .. msg:sub(1, 40),
        string.format("-- Player chatted: %q", msg))
end)

-- 7. NumberValue / IntValue / StringValue watcher
local function watchValue(v)
    local function logIt()
        addLog("Value", string.format("%s = %s", v.Name, tostring(v.Value)),
            string.format("-- %s changed\n-- Path: %s\n-- New value: %s",
                v.ClassName, fullPath(v), valToLua(v.Value)))
    end
    v:GetPropertyChangedSignal("Value"):Connect(logIt)
end
for _, d in ipairs(game:GetDescendants()) do
    if d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") then
        watchValue(d)
    end
end
game.DescendantAdded:Connect(function(d)
    if d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") then
        watchValue(d)
    end
end)

-- 8. Position deltas (teleports)
local lastPos, lastPosTime = nil, 0
RunService.Heartbeat:Connect(function()
    local c = player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local now = tick()
    if now - lastPosTime < 0.5 then return end
    lastPosTime = now
    if lastPos then
        local delta = (hrp.Position - lastPos).Magnitude
        if delta > 40 then
            addLog("Action", string.format("Big move: %.0f studs", delta),
                string.format("-- Big position delta: %g studs", delta))
        end
    end
    lastPos = hrp.Position
end)

-- 9. Workspace instance add/remove (throttled)
local instThrottle = 0
Workspace.DescendantAdded:Connect(function(d)
    local now = tick()
    if now - instThrottle < 0.05 then return end
    instThrottle = now
    addLog("Instance", "+ " .. d.Name .. " (" .. d.ClassName .. ")",
        string.format("-- Added: %s\n-- ClassName: %s\nlocal obj = %s",
            d.Name, d.ClassName, fullPath(d)))
end)
Workspace.DescendantRemoving:Connect(function(d)
    local now = tick()
    if now - instThrottle < 0.05 then return end
    instThrottle = now
    addLog("Instance", "- " .. d.Name .. " (" .. d.ClassName .. ")",
        string.format("-- Removed: %s", d.Name))
end)

addLog("Action", "SPY v9 initialized",
    string.format("-- NOVA Spy v9 (deep capture)\n-- Player: %s\n-- PlaceId: %d",
        player.Name, game.PlaceId))

pauseBtn.MouseButton1Click:Connect(function()
    spyPaused = not spyPaused
    pauseBtn.Text = spyPaused and "Resume" or "Pause"
    pauseBtn.TextColor3 = spyPaused and T.Yellow or T.SubText
end)
clearBtn.MouseButton1Click:Connect(function()
    spyLogs = {}
    for _, r in ipairs(rowCache) do r.button:Destroy() end
    rowCache = {}
    spyNextId = 1
    dTitle.Text = "Select an event"
    dSub.Text = "Click a row to see its code"
    dCode.Text = ""
    currentCode = ""
end)

-- activate first tab
task.defer(function()
    task.wait(0.1)
    local first = tabs[1]
    for _, t in ipairs(tabs) do t.setActive(false) end
    first.setActive(true)
    TweenService:Create(indicator, TweenInfo.new(0.2), {
        Position = UDim2.new(0, first.button.AbsolutePosition.X - tabStrip.AbsolutePosition.X, 1, -3),
        Size = UDim2.new(0, first.button.AbsoluteSize.X, 0, 2),
    }):Play()
    showPage("General")
end)

-- =====================================================
-- OPEN / CLOSE
-- =====================================================
local isOpen, busy = false, false
local function openMenu()
    if isOpen or busy then return end
    busy = true; isOpen = true
    menu.Visible = true
    menu.Size = UDim2.fromOffset(MW - 40, MH - 20)
    TweenService:Create(menu, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(MW, MH) }):Play()
    task.wait(0.05); busy = false
end
local function closeMenu()
    if not isOpen or busy then return end
    busy = true; isOpen = false
    TweenService:Create(menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(MW - 40, MH - 20) }):Play()
    task.wait(0.15); menu.Visible = false; busy = false
end

_G.__NOVA_toggle = function() if isOpen then closeMenu() else openMenu() end end
closeBtn.MouseButton1Click:Connect(closeMenu)
minBtn.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then _G.__NOVA_toggle() end
end)

print("[NOVA] v9 loaded — deep SPY capture enabled.")
