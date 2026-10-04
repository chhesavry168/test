--[[
    NOVA Client GUI v3 — Full Redesign
    Location: StarterPlayer > StarterPlayerScripts (LocalScript)
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================
-- THEME
-- =====================================================
local T = {
    Accent     = Color3.fromRGB(124, 92, 255),   -- violet
    Accent2    = Color3.fromRGB(0, 212, 255),    -- cyan
    Accent3    = Color3.fromRGB(255, 92, 180),   -- pink (rare accent)
    Bg         = Color3.fromRGB(10, 10, 15),
    Panel      = Color3.fromRGB(16, 16, 22),
    Card       = Color3.fromRGB(24, 24, 33),
    CardHover  = Color3.fromRGB(30, 30, 42),
    Border     = Color3.fromRGB(40, 40, 56),
    Text       = Color3.fromRGB(242, 242, 250),
    SubText    = Color3.fromRGB(140, 140, 165),
    Off        = Color3.fromRGB(50, 50, 66),
}

local FONT       = Enum.Font.GothamMedium
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack

-- =====================================================
-- STATE
-- =====================================================
local state = { FPSBoost = false, AntiLag = false, AntiAFK = false }

-- =====================================================
-- GUI ROOT
-- =====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "NOVA"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = playerGui

-- =====================================================
-- FLOATING ICON (clickable + draggable)
-- =====================================================
local ICON_SIZE = 58

local icon = Instance.new("Frame")
icon.Name = "FloatingIcon"
icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
icon.Position = UDim2.new(0, 60, 0, 140)
icon.BackgroundColor3 = T.Bg
icon.BorderSizePixel = 0
icon.Parent = gui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = icon

-- gradient background
local iconGrad = Instance.new("UIGradient")
iconGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 20, 46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 22)),
})
iconGrad.Rotation = 135
iconGrad.Parent = icon

-- animated border
local iconStroke = Instance.new("UIStroke")
iconStroke.Thickness = 2
iconStroke.Color = T.Accent
iconStroke.Parent = icon

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(0.5, T.Accent2),
    ColorSequenceKeypoint.new(1, T.Accent3),
})
strokeGrad.Parent = iconStroke

-- soft outer glow
local iconGlow = Instance.new("ImageLabel")
iconGlow.Size = UDim2.new(1, 36, 1, 36)
iconGlow.Position = UDim2.new(0, -18, 0, -18)
iconGlow.BackgroundTransparency = 1
iconGlow.Image = "rbxassetid://5028857472"
iconGlow.ImageColor3 = T.Accent
iconGlow.ImageTransparency = 0.55
iconGlow.ZIndex = 0
iconGlow.Parent = icon

-- letter "N"
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "N"
iconLabel.Font = FONT_BLACK
iconLabel.TextSize = 26
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.Parent = icon

local iconTextGrad = Instance.new("UIGradient")
iconTextGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Accent2),
})
iconTextGrad.Rotation = 45
iconTextGrad.Parent = iconLabel

-- a pulse ring behind the icon
local pulse = Instance.new("Frame")
pulse.AnchorPoint = Vector2.new(0.5, 0.5)
pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
pulse.Size = UDim2.new(1, 0, 1, 0)
pulse.BackgroundTransparency = 1
pulse.ZIndex = 0
pulse.Parent = icon

local pulseCorner = Instance.new("UICorner")
pulseCorner.CornerRadius = UDim.new(1, 0)
pulseCorner.Parent = pulse

local pulseStroke = Instance.new("UIStroke")
pulseStroke.Color = T.Accent
pulseStroke.Thickness = 2
pulseStroke.Transparency = 0.5
pulseStroke.Parent = pulse

-- =====================================================
-- DRAG + CLICK SYSTEM (the fix)
-- =====================================================
local DRAG_THRESHOLD = 6     -- pixels moved before counting as a drag
local dragging       = false
local dragMoved      = false
local dragStart      = nil
local startPos       = nil

local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragMoved = false
        dragStart = input.Position
        startPos  = icon.Position
    end
end

local function onInputChanged(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    if not dragMoved and (math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD) then
        dragMoved = true
    end

    if dragMoved then
        icon.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end

local function onInputEnded(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    if dragging and not dragMoved then
        -- It was a real click → toggle menu
        if _G.__NOVA_toggleMenu then _G.__NOVA_toggleMenu() end
    end

    dragging  = false
    dragMoved = false
end

icon.InputBegan:Connect(onInputBegan)
UserInputService.InputChanged:Connect(onInputChanged)
UserInputService.InputEnded:Connect(onInputEnded)

-- Pulse animation
task.spawn(function()
    while icon.Parent do
        pulse.Size = UDim2.new(1, 0, 1, 0)
        pulseStroke.Transparency = 0.5
        TweenService:Create(pulse, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 40, 1, 40)
        }):Play()
        TweenService:Create(pulseStroke, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
        task.wait(1.6)
    end
end)

-- Border gradient rotation
task.spawn(function()
    while icon.Parent do
        strokeGrad.Rotation = (strokeGrad.Rotation + 1) % 360
        iconTextGrad.Rotation = (iconTextGrad.Rotation + 1) % 360
        RunService.RenderStepped:Wait()
    end
end)

-- =====================================================
-- MAIN MENU (hidden initially)
-- =====================================================
local menu = Instance.new("Frame")
menu.Name = "NOVA_Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.new(0.5, 0, 0.5, 0)
menu.Size = UDim2.fromOffset(680, 440)
menu.BackgroundColor3 = T.Bg
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Visible = false
menu.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 18)
menuCorner.Parent = menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = T.Border
menuStroke.Thickness = 1
menuStroke.Parent = menu

local menuGrad = Instance.new("UIGradient")
menuGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 26)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 9, 14)),
})
menuGrad.Rotation = 135
menuGrad.Parent = menu

-- Ambient glow blobs (background flair)
local function makeBlob(pos, size, color, transparency)
    local b = Instance.new("Frame")
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = pos
    b.Size = UDim2.fromOffset(size, size)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = transparency
    b.BorderSizePixel = 0
    b.ZIndex = 0
    b.Parent = menu
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = b
    return b
end

makeBlob(UDim2.new(0, 60,  0, 60),  200, T.Accent,  0.86)
makeBlob(UDim2.new(1, -60, 1, -60), 240, T.Accent2, 0.90)

-- =====================================================
-- SIDEBAR
-- =====================================================
local SIDEBAR_W = 200

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
sidebar.BackgroundColor3 = T.Panel
sidebar.BackgroundTransparency = 0.15
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = menu

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 18)
sideCorner.Parent = sidebar

local sideMask = Instance.new("Frame")
sideMask.Size = UDim2.new(0, 18, 1, 0)
sideMask.Position = UDim2.new(1, -18, 0, 0)
sideMask.BackgroundColor3 = T.Panel
sideMask.BackgroundTransparency = 0.15
sideMask.BorderSizePixel = 0
sideMask.ZIndex = 2
sideMask.Parent = sidebar

-- Brand block
local brand = Instance.new("Frame")
brand.Size = UDim2.new(1, 0, 0, 82)
brand.BackgroundTransparency = 1
brand.ZIndex = 3
brand.Parent = sidebar

-- Logo mark
local mark = Instance.new("Frame")
mark.Size = UDim2.fromOffset(38, 38)
mark.Position = UDim2.new(0, 20, 0, 22)
mark.BackgroundColor3 = T.Accent
mark.BorderSizePixel = 0
mark.ZIndex = 3
mark.Parent = brand

local markCorner = Instance.new("UICorner")
markCorner.CornerRadius = UDim.new(0, 11)
markCorner.Parent = mark

local markGrad = Instance.new("UIGradient")
markGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Accent2),
})
markGrad.Rotation = 45
markGrad.Parent = mark

local markLabel = Instance.new("TextLabel")
markLabel.Size = UDim2.new(1, 0, 1, 0)
markLabel.BackgroundTransparency = 1
markLabel.Text = "N"
markLabel.Font = FONT_BLACK
markLabel.TextSize = 20
markLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
markLabel.ZIndex = 4
markLabel.Parent = mark

local brandName = Instance.new("TextLabel")
brandName.Size = UDim2.new(1, -78, 0, 20)
brandName.Position = UDim2.new(0, 68, 0, 24)
brandName.BackgroundTransparency = 1
brandName.Text = "NOVA"
brandName.Font = FONT_BLACK
brandName.TextSize = 18
brandName.TextColor3 = T.Text
brandName.TextXAlignment = Enum.TextXAlignment.Left
brandName.ZIndex = 3
brandName.Parent = brand

local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(1, -78, 0, 14)
brandSub.Position = UDim2.new(0, 68, 0, 44)
brandSub.BackgroundTransparency = 1
brandSub.Text = "CLIENT v3"
brandSub.Font = FONT
brandSub.TextSize = 10
brandSub.TextColor3 = T.SubText
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.ZIndex = 3
brandSub.Parent = brand

-- Divider
local sideDiv = Instance.new("Frame")
sideDiv.Size = UDim2.new(1, -32, 0, 1)
sideDiv.Position = UDim2.new(0, 16, 0, 82)
sideDiv.BackgroundColor3 = T.Border
sideDiv.BackgroundTransparency = 0.4
sideDiv.BorderSizePixel = 0
sideDiv.ZIndex = 3
sideDiv.Parent = sidebar

-- Nav
local nav = Instance.new("Frame")
nav.Size = UDim2.new(1, 0, 1, -100)
nav.Position = UDim2.new(0, 0, 0, 94)
nav.BackgroundTransparency = 1
nav.ZIndex = 3
nav.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = nav

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft = UDim.new(0, 12)
navPad.PaddingRight = UDim.new(0, 12)
navPad.Parent = nav

-- =====================================================
-- TOP BAR
-- =====================================================
local TOPBAR_H = 66

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -SIDEBAR_W, 0, TOPBAR_H)
topBar.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 3
topBar.Parent = menu

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -160, 0, 22)
pageTitle.Position = UDim2.new(0, 24, 0, 16)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "General"
pageTitle.TextColor3 = T.Text
pageTitle.Font = FONT_BOLD
pageTitle.TextSize = 18
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.ZIndex = 3
pageTitle.Parent = topBar

local pageSub = Instance.new("TextLabel")
pageSub.Size = UDim2.new(1, -160, 0, 16)
pageSub.Position = UDim2.new(0, 24, 0, 38)
pageSub.BackgroundTransparency = 1
pageSub.Text = "Performance tweaks and client optimizations"
pageSub.TextColor3 = T.SubText
pageSub.Font = FONT
pageSub.TextSize = 11
pageSub.TextXAlignment = Enum.TextXAlignment.Left
pageSub.ZIndex = 3
pageSub.Parent = topBar

-- Close button
local function makeTopBtn(text, xOffset, accent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(34, 34)
    b.Position = UDim2.new(1, xOffset, 0.5, -17)
    b.BackgroundColor3 = T.Card
    b.Text = text
    b.TextColor3 = T.SubText
    b.Font = FONT_BOLD
    b.TextSize = 15
    b.AutoButtonColor = false
    b.ZIndex = 3
    b.Parent = topBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = b

    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = accent or Color3.fromRGB(50, 50, 66),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = T.Card,
            TextColor3 = T.SubText
        }):Play()
    end)

    return b
end

local closeBtn = makeTopBtn("✕", -48, Color3.fromRGB(220, 60, 90))
local minBtn   = makeTopBtn("—", -88, nil)

-- =====================================================
-- CONTENT
-- =====================================================
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H)
content.Position = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H)
content.BackgroundTransparency = 1
content.ZIndex = 3
content.Parent = menu

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft = UDim.new(0, 22)
contentPad.PaddingRight = UDim.new(0, 22)
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.PaddingBottom = UDim.new(0, 20)
contentPad.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- =====================================================
-- TOGGLE CARD
-- =====================================================
local function createToggle(name, desc, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 66)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 3
    card.Parent = content

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = card

    local cs = Instance.new("UIStroke")
    cs.Color = T.Border
    cs.Thickness = 1
    cs.Transparency = 0.3
    cs.Parent = card

    -- Name
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 0, 20)
    title.Position = UDim2.new(0, 18, 0, 14)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_BOLD
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 4
    title.Parent = card

    -- Description
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -110, 0, 16)
    subtitle.Position = UDim2.new(0, 18, 0, 36)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = desc
    subtitle.TextColor3 = T.SubText
    subtitle.Font = FONT
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 4
    subtitle.Parent = card

    -- Status badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 42, 0, 18)
    badge.Position = UDim2.new(1, -122, 0.5, -9)
    badge.BackgroundColor3 = T.Off
    badge.BackgroundTransparency = 0.4
    badge.Text = "OFF"
    badge.TextColor3 = T.SubText
    badge.Font = FONT_BOLD
    badge.TextSize = 9
    badge.ZIndex = 4
    badge.Parent = card

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 6)
    badgeCorner.Parent = badge

    -- Switch
    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(48, 26)
    sw.Position = UDim2.new(1, -66, 0.5, -13)
    sw.BackgroundColor3 = T.Off
    sw.BorderSizePixel = 0
    sw.ZIndex = 4
    sw.Parent = card

    local swc = Instance.new("UICorner")
    swc.CornerRadius = UDim.new(1, 0)
    swc.Parent = sw

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 252)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = sw

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 6
    btn.Parent = sw

    local isOn = false

    local function setSwitch(on)
        isOn = on
        state[name:gsub("%s", "")] = on

        if on then
            TweenService:Create(sw, TweenInfo.new(0.25), { BackgroundColor3 = T.Accent }):Play()
            TweenService:Create(knob, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -23, 0.5, -10)
            }):Play()
            TweenService:Create(badge, TweenInfo.new(0.2), {
                BackgroundColor3 = T.Accent,
                BackgroundTransparency = 0,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            badge.Text = "ON"
        else
            TweenService:Create(sw, TweenInfo.new(0.25), { BackgroundColor3 = T.Off }):Play()
            TweenService:Create(knob, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -10)
            }):Play()
            TweenService:Create(badge, TweenInfo.new(0.2), {
                BackgroundColor3 = T.Off,
                BackgroundTransparency = 0.4,
                TextColor3 = T.SubText
            }):Play()
            badge.Text = "OFF"
        end

        -- Apply feature
        if name == "FPS Boost" then
            if on then
                if not Lighting:FindFirstChild("NOVA_Blur") then
                    local b = Instance.new("BlurEffect")
                    b.Name = "NOVA_Blur"
                    b.Size = 0
                    b.Parent = Lighting
                end
            else
                local b = Lighting:FindFirstChild("NOVA_Blur")
                if b then b:Destroy() end
            end
        elseif name == "Anti Lag" then
            if on then
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail")
                        or v:IsA("Smoke") or v:IsA("Fire") then
                        pcall(function() v.Enabled = false end)
                    end
                end
            end
        end
    end

    btn.MouseButton1Click:Connect(function()
        setSwitch(not isOn)
    end)

    -- Hover
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), { BackgroundColor3 = T.CardHover }):Play()
        TweenService:Create(cs, TweenInfo.new(0.18), { Color = T.Accent, Transparency = 0 }):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), { BackgroundColor3 = T.Card }):Play()
        TweenService:Create(cs, TweenInfo.new(0.18), { Color = T.Border, Transparency = 0.3 }):Play()
    end)

    return card
end

createToggle("FPS Boost", "Boosts client frame rate", 1)
createToggle("Anti Lag",  "Disables heavy particle effects", 2)
createToggle("Anti AFK",  "Prevents 20-minute idle kick",  3)

-- =====================================================
-- SIDEBAR TAB
-- =====================================================
local function createTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(1, 0, 0, 40)
    tab.BackgroundColor3 = T.Card
    tab.BackgroundTransparency = 1
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.LayoutOrder = order
    tab.ZIndex = 4
    tab.Parent = nav

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent = tab

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 36, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = T.SubText
    label.Font = FONT_BOLD
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = tab

    -- left icon dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.Position = UDim2.new(0, 18, 0.5, -4)
    dot.BackgroundColor3 = T.SubText
    dot.BorderSizePixel = 0
    dot.ZIndex = 5
    dot.Parent = tab

    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(1, 0)
    dc.Parent = dot

    -- right indicator bar
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Size = UDim2.new(0, 3, 0, 0)
    bar.Position = UDim2.new(1, -6, 0.5, 0)
    bar.BackgroundColor3 = T.Accent
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = tab

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bar

    local function setActive(active)
        if active then
            TweenService:Create(tab, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            TweenService:Create(label, TweenInfo.new(0.2), { TextColor3 = T.Text }):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), { BackgroundColor3 = T.Accent }):Play()
            TweenService:Create(bar, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 3, 0, 22)
            }):Play()
        else
            TweenService:Create(tab, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(label, TweenInfo.new(0.2), { TextColor3 = T.SubText }):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), { BackgroundColor3 = T.SubText }):Play()
            TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.new(0, 3, 0, 0) }):Play()
        end
    end

    tab.MouseEnter:Connect(function()
        if bar.Size.Y.Offset == 0 then
            TweenService:Create(label, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(200, 200, 220) }):Play()
        end
    end)
    tab.MouseLeave:Connect(function()
        if bar.Size.Y.Offset == 0 then
            TweenService:Create(label, TweenInfo.new(0.15), { TextColor3 = T.SubText }):Play()
        end
    end)

    return setActive
end

local setGeneralActive = createTab("General", 1)
setGeneralActive(true)

-- =====================================================
-- ANTI AFK
-- =====================================================
local antiAfkConn
task.spawn(function()
    while task.wait(0.3) do
        if state.AntiAFK then
            if not antiAfkConn then
                antiAfkConn = player.Idled:Connect(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
        else
            if antiAfkConn then
                antiAfkConn:Disconnect()
                antiAfkConn = nil
            end
        end
    end
end)

-- =====================================================
-- OPEN / CLOSE LOGIC
-- =====================================================
local isOpen = false
local busy   = false

local function openMenu()
    if isOpen or busy then return end
    busy = true
    isOpen = true

    menu.Visible = true
    menu.Size = UDim2.fromOffset(560, 380)

    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(680, 440)
    }):Play()

    -- Icon reacts
    TweenService:Create(icon, TweenInfo.new(0.2), {
        BackgroundColor3 = T.Panel
    }):Play()

    task.wait(0.1)
    busy = false
end

local function closeMenu()
    if not isOpen or busy then return end
    busy = true
    isOpen = false

    TweenService:Create(menu, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(560, 380)
    }):Play()

    task.wait(0.22)
    menu.Visible = false
    busy = false
end

_G.__NOVA_toggleMenu = function()
    if isOpen then closeMenu() else openMenu() end
end

closeBtn.MouseButton1Click:Connect(closeMenu)
minBtn.MouseButton1Click:Connect(closeMenu)

-- Optional: press RightShift to toggle
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        _G.__NOVA_toggleMenu()
    end
end)

-- =====================================================
-- ICON HOVER SCALE
-- =====================================================
icon.MouseEnter:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.2), {
        Size = UDim2.fromOffset(ICON_SIZE + 6, ICON_SIZE + 6)
    }):Play()
end)
icon.MouseLeave:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.2), {
        Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
    }):Play()
end)

print("[NOVA] v3 loaded. Click the N icon to open the menu.")
