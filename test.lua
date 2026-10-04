--[[
    NOVA v7 — Clean Dark UI
    LocalScript → StarterPlayer > StarterPlayerScripts
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local Stats            = game:GetService("Stats")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================
-- THEME  (clean, flat, minimal borders)
-- =====================================================
local T = {
    Base      = Color3.fromRGB(12, 12, 15),      -- window background
    Surface   = Color3.fromRGB(18, 18, 22),      -- cards
    Surface2  = Color3.fromRGB(24, 24, 29),      -- hover
    Divider   = Color3.fromRGB(30, 30, 36),      -- very subtle lines
    Text      = Color3.fromRGB(240, 240, 245),
    SubText   = Color3.fromRGB(130, 130, 140),
    Muted     = Color3.fromRGB(80, 80, 90),
    Accent    = Color3.fromRGB(130, 100, 255),   -- one accent only
    AccentDim = Color3.fromRGB(90, 70, 180),
    Off       = Color3.fromRGB(40, 40, 48),
    Red       = Color3.fromRGB(230, 70, 90),
}

local FONT   = Enum.Font.Gotham
local FONT_M = Enum.Font.GothamMedium
local FONT_S = Enum.Font.GothamSemibold
local FONT_B = Enum.Font.GothamBold

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
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = p
    return c
end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or T.Divider
    s.Thickness = t or 1
    s.Transparency = tr or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end
local function pad(p,l,r,t,b)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l or 0); u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingTop=UDim.new(0,t or 0);  u.PaddingBottom=UDim.new(0,b or 0)
    u.Parent=p
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
-- FLOATING "NOVA" TEXT BUTTON (no circle, no pill)
-- =====================================================
local btnW, btnH = 92, 32

local launcher = Instance.new("TextButton")
launcher.Name = "Launcher"
launcher.Size = UDim2.fromOffset(btnW, btnH)
launcher.Position = UDim2.new(0, 30, 0.5, -16)
launcher.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
launcher.AutoButtonColor = false
launcher.Text = ""
launcher.Parent = gui
corner(launcher, UDim.new(0, 6))

-- animated gradient underline (only accent, no full border)
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

-- animated underline sweep
task.spawn(function()
    while launcher.Parent do
        for i = 0, 1, 0.01 do
            ulGrad.Offset = Vector2.new(i, 0)
            lgGrad.Offset = Vector2.new(i, 0)
            RunService.RenderStepped:Wait()
        end
        for i = 1, 0, -0.01 do
            ulGrad.Offset = Vector2.new(i, 0)
            lgGrad.Offset = Vector2.new(i, 0)
            RunService.RenderStepped:Wait()
        end
    end
end)

-- drag + click
local THRESH = 6
local dragging, moved, startPos, dragStart = false, false, nil, nil

launcher.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging, moved = true, false
        dragStart = i.Position
        startPos = launcher.Position
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
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
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
    TweenService:Create(launcher, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 28)}):Play()
end)
launcher.MouseLeave:Connect(function()
    TweenService:Create(launcher, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(15, 15, 20)}):Play()
end)

-- =====================================================
-- MENU
-- =====================================================
local MW, MH = 620, 420
local HEADER_H = 56
local TABS_H = 40

local menu = Instance.new("Frame")
menu.Name = "Menu"
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

-- =====================================================
-- HEADER
-- =====================================================
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

-- divider under header
local headerDiv = Instance.new("Frame")
headerDiv.Size = UDim2.new(1, 0, 0, 1)
headerDiv.Position = UDim2.new(0, 0, 0, HEADER_H)
headerDiv.BackgroundColor3 = T.Divider
headerDiv.BorderSizePixel = 0
headerDiv.Parent = menu

-- close ✕
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
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = T.Red, TextColor3 = Color3.new(1,1,1)
    }):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(22, 22, 27), TextColor3 = T.SubText
    }):Play()
end)

-- minimize —
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
    TweenService:Create(minBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(40, 40, 48), TextColor3 = Color3.new(1,1,1)
    }):Play()
end)
minBtn.MouseLeave:Connect(function()
    TweenService:Create(minBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(22, 22, 27), TextColor3 = T.SubText
    }):Play()
end)

-- =====================================================
-- TAB STRIP (text-only, minimal)
-- =====================================================
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

-- sliding underline indicator
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 60, 0, 2)
indicator.Position = UDim2.new(0, 16, 1, -3)
indicator.BackgroundColor3 = T.Accent
indicator.BorderSizePixel = 0
indicator.Parent = tabStrip
corner(indicator, UDim.new(1, 0))

-- divider
local tabDiv = Instance.new("Frame")
tabDiv.Size = UDim2.new(1, 0, 0, 1)
tabDiv.Position = UDim2.new(0, 0, 0, HEADER_H + TABS_H + 1)
tabDiv.BackgroundColor3 = T.Divider
tabDiv.BorderSizePixel = 0
tabDiv.Parent = menu

-- =====================================================
-- PAGE HOLDER
-- =====================================================
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

local function createPage(name)
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
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = p
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
            TextColor3 = active and T.Text or T.SubText
        }):Play()
    end

    tab.MouseEnter:Connect(function()
        if tab.TextColor3 ~= T.Text then
            TweenService:Create(tab, TweenInfo.new(0.15), {
                TextColor3 = Color3.fromRGB(190,190,205)
            }):Play()
        end
    end)
    tab.MouseLeave:Connect(function()
        if tab.TextColor3 ~= T.Text then
            TweenService:Create(tab, TweenInfo.new(0.15), {
                TextColor3 = T.SubText
            }):Play()
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

    local entry = {button = tab, setActive = setActive}
    tabs[#tabs+1] = entry
    return entry
end

-- =====================================================
-- ROW: TOGGLE  (flat, no switch circle knob)
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
    title.Size = UDim2.new(1, -120, 0, 18)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_M
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -120, 0, 14)
    sub.Position = UDim2.new(0, 14, 0, 30)
    sub.BackgroundTransparency = 1
    sub.Text = desc
    sub.TextColor3 = T.SubText
    sub.Font = FONT
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = row

    -- Minimal toggle: rectangular track + rectangular knob (no full circles)
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(40, 20)
    track.Position = UDim2.new(1, -54, 0.5, -10)
    track.BackgroundColor3 = T.Off
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, UDim.new(0, 4))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, UDim.new(0, 3))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = track

    local isOn = false
    local function set(on)
        isOn = on
        if on then
            TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = T.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -18, 0.5, -8)
            }):Play()
        else
            TweenService:Create(track, TweenInfo.new(0.18), {BackgroundColor3 = T.Off}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 2, 0.5, -8)
            }):Play()
        end
        if callback then pcall(callback, on) end
    end

    btn.MouseButton1Click:Connect(function() set(not isOn) end)

    -- whole row is clickable too
    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            -- skip if clicked the switch (btn handles that)
        end
    end)

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface2}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundColor3 = T.Surface}):Play()
    end)

    return row, set
end

-- =====================================================
-- ROW: SLIDER  (flat, thin track)
-- =====================================================
local function createSlider(parent, name, minV, maxV, default, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = T.Surface
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    corner(row, UDim.new(0, 6))

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 18)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_M
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = row

    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0, 70, 0, 18)
    value.Position = UDim2.new(1, -84, 0, 10)
    value.BackgroundTransparency = 1
    value.Text = tostring(default)
    value.TextColor3 = T.Accent
    value.Font = FONT_B
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 4)
    track.Position = UDim2.new(0, 14, 0, 42)
    track.BackgroundColor3 = T.Off
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, UDim.new(1, 0))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(10, 10)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = track
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
            draggingS = true
            setFromX(i.Position.X)
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
            or i.UserInputType == Enum.UserInputType.Touch then
            draggingS = false
        end
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
-- REAL FEATURES
-- =====================================================
local fpsSnap = {}
local function setFPSBoost(on)
    if on then
        fpsSnap = {shadows=Lighting.GlobalShadows, fog=Lighting.FogEnd, bright=Lighting.Brightness,
                   ed=Lighting.EnvironmentDiffuseScale, es=Lighting.EnvironmentSpecularScale}
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e5
        Lighting.Brightness = 2
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        pcall(function() Lighting.ShadowSoftness = 0 end)
        for _,e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled = false end end
        pcall(function() Workspace.GlobalWind = Vector3.new(0,0,0) end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        Lighting.GlobalShadows = fpsSnap.shadows ~= false
        Lighting.FogEnd = fpsSnap.fog or 1e5
        Lighting.Brightness = fpsSnap.bright or 2
        Lighting.EnvironmentDiffuseScale = fpsSnap.ed or 1
        Lighting.EnvironmentSpecularScale = fpsSnap.es or 1
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
        _G.__NOVA_LagConn = Workspace.DescendantAdded:Connect(function(d)
            if State.AntiLag and (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles")) then
                task.defer(function() pcall(function() d.Enabled = false end) end)
            end
        end)
    else
        for _,d in ipairs(lagHidden) do pcall(function() d.Enabled = true end) end
        lagHidden = {}
        if _G.__NOVA_LagConn then _G.__NOVA_LagConn:Disconnect() _G.__NOVA_LagConn = nil end
    end
end

local afkConn
local function setAntiAFK(on)
    if on then
        if not afkConn then
            afkConn = player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
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
        Lighting.Ambient = Color3.fromRGB(178,178,178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        if not Lighting:FindFirstChild("NOVA_CC") then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "NOVA_CC"; cc.Brightness = 0.15; cc.Contrast = 0.05; cc.Parent = Lighting
        end
    else
        Lighting.Ambient = brightSnap.amb or Lighting.Ambient
        Lighting.OutdoorAmbient = brightSnap.oamb or Lighting.OutdoorAmbient
        Lighting.Brightness = brightSnap.br or 2
        Lighting.ClockTime = brightSnap.ct or 14
        Lighting.FogEnd = brightSnap.fog or 1e5
        Lighting.GlobalShadows = brightSnap.sh ~= false
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
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end
end
local function setJumpPower(v)
    local c = player.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower = true h.JumpPower = v end
    end
end

player.CharacterAdded:Connect(function(c)
    c:WaitForChild("Humanoid")
    task.wait(0.2)
    setWalkSpeed(State.WalkSpeed)
    setJumpPower(State.JumpPower)
end)

-- =====================================================
-- BUILD PAGES
-- =====================================================
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
        Size = UDim2.fromOffset(MW, MH)
    }):Play()
    task.wait(0.05)
    busy = false
end

local function closeMenu()
    if not isOpen or busy then return end
    busy = true; isOpen = false
    TweenService:Create(menu, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(MW - 40, MH - 20)
    }):Play()
    task.wait(0.15)
    menu.Visible = false
    busy = false
end

_G.__NOVA_toggle = function() if isOpen then closeMenu() else openMenu() end end

closeBtn.MouseButton1Click:Connect(closeMenu)
minBtn.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then _G.__NOVA_toggle() end
end)

print("[NOVA] v7 loaded.")
