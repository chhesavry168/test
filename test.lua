--[[
    NOVA Client GUI v5
    Location: StarterPlayer > StarterPlayerScripts (LocalScript)
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =====================================================
-- THEME
-- =====================================================
local T = {
    Bg         = Color3.fromRGB(8, 8, 12),
    Panel      = Color3.fromRGB(15, 15, 22),
    Card       = Color3.fromRGB(21, 21, 30),
    CardHover  = Color3.fromRGB(27, 27, 38),
    Border     = Color3.fromRGB(38, 38, 54),
    BorderHot  = Color3.fromRGB(110, 80, 255),
    Text       = Color3.fromRGB(244, 244, 252),
    SubText    = Color3.fromRGB(138, 138, 165),
    Dim        = Color3.fromRGB(90, 90, 110),
    Accent     = Color3.fromRGB(124, 92, 255),
    Accent2    = Color3.fromRGB(0, 220, 255),
    Accent3    = Color3.fromRGB(255, 92, 180),
    Off        = Color3.fromRGB(46, 46, 62),
}

local FONT   = Enum.Font.GothamMedium
local FONT_S = Enum.Font.GothamSemibold
local FONT_B = Enum.Font.GothamBold
local FONT_K = Enum.Font.GothamBlack

-- =====================================================
-- STATE
-- =====================================================
local State = {
    FPSBoost    = false,
    AntiLag     = false,
    AntiAFK     = false,
    FullBright  = false,
    InfiniteJmp = false,
    WalkSpeed   = 16,
    JumpPower   = 50,
}

-- =====================================================
-- HELPERS
-- =====================================================
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0,12); c.Parent = p; return c end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or T.Border; s.Thickness = t or 1; s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end
local function gradient(p, cols, rot)
    local g = Instance.new("UIGradient")
    local k = {}
    for i,c in ipairs(cols) do table.insert(k, ColorSequenceKeypoint.new((i-1)/(#cols-1), c)) end
    g.Color = ColorSequence.new(k); g.Rotation = rot or 0; g.Parent = p; return g
end
local function padding(p,l,r,t,b)
    local u = Instance.new("UIPadding")
    u.PaddingLeft = UDim.new(0,l or 0); u.PaddingRight = UDim.new(0,r or 0)
    u.PaddingTop  = UDim.new(0,t or 0); u.PaddingBottom= UDim.new(0,b or 0)
    u.Parent = p; return u
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
-- FLOATING "NOVA" BUTTON
-- =====================================================
local BTN_W, BTN_H = 130, 46

local novaBtn = Instance.new("Frame")
novaBtn.Name = "NovaButton"
novaBtn.Size = UDim2.fromOffset(BTN_W, BTN_H)
novaBtn.Position = UDim2.new(0, 60, 0, 140)
novaBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
novaBtn.BorderSizePixel = 0
novaBtn.Active = true
novaBtn.Parent = gui

corner(novaBtn, UDim.new(1, 0))

local btnBgGrad = Instance.new("UIGradient")
btnBgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 16, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 18)),
})
btnBgGrad.Rotation = 135
btnBgGrad.Parent = novaBtn

-- Animated gradient border (rainbow)
local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 2
btnStroke.Color = Color3.new(1, 1, 1)
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
btnStroke.Parent = novaBtn

local borderGrad = Instance.new("UIGradient")
borderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, T.Accent),
    ColorSequenceKeypoint.new(0.25, T.Accent2),
    ColorSequenceKeypoint.new(0.50, T.Accent3),
    ColorSequenceKeypoint.new(0.75, T.Accent2),
    ColorSequenceKeypoint.new(1.00, T.Accent),
})
borderGrad.Parent = btnStroke

-- Text
local novaText = Instance.new("TextLabel")
novaText.Size = UDim2.new(1, 0, 1, 0)
novaText.BackgroundTransparency = 1
novaText.Text = "NOVA"
novaText.Font = FONT_K
novaText.TextSize = 16
novaText.TextColor3 = Color3.new(1, 1, 1)
novaText.Parent = novaBtn

local textGrad = Instance.new("UIGradient")
textGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, T.Accent2),
})
textGrad.Rotation = 45
textGrad.Parent = novaText

-- Glow
local btnGlow = Instance.new("ImageLabel")
btnGlow.Size = UDim2.new(1, 36, 1, 36)
btnGlow.Position = UDim2.new(0, -18, 0, -18)
btnGlow.BackgroundTransparency = 1
btnGlow.Image = "rbxassetid://5028857472"
btnGlow.ImageColor3 = T.Accent
btnGlow.ImageTransparency = 0.5
btnGlow.ZIndex = 0
btnGlow.Parent = novaBtn

-- =====================================================
-- ANIMATED BORDER LOOP
-- =====================================================
task.spawn(function()
    while novaBtn.Parent do
        for _ = 1, 360 do
            borderGrad.Rotation = (borderGrad.Rotation + 1) % 360
            textGrad.Rotation = (textGrad.Rotation + 1) % 360
            RunService.RenderStepped:Wait()
        end
        -- cycle colors occasionally for extra flair
        local palette = {
            {T.Accent,  T.Accent2, T.Accent3, T.Accent2, T.Accent},
            {T.Accent2, T.Accent3, T.Accent,  T.Accent3, T.Accent2},
            {T.Accent3, T.Accent,  T.Accent2, T.Accent,  T.Accent3},
        }
        local pick = palette[math.random(1, #palette)]
        borderGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, pick[1]),
            ColorSequenceKeypoint.new(0.25, pick[2]),
            ColorSequenceKeypoint.new(0.50, pick[3]),
            ColorSequenceKeypoint.new(0.75, pick[4]),
            ColorSequenceKeypoint.new(1.00, pick[5]),
        })
    end
end)

-- =====================================================
-- DRAG + CLICK
-- =====================================================
local DRAG_THRESHOLD = 6
local dragging, dragMoved, dragStart, startPos = false, false, nil, nil

novaBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragMoved = true, false
        dragStart = input.Position
        startPos  = novaBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - dragStart
    if not dragMoved and (math.abs(d.X) > DRAG_THRESHOLD or math.abs(d.Y) > DRAG_THRESHOLD) then
        dragMoved = true
    end
    if dragMoved then
        novaBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragging and not dragMoved then
        if _G.__NOVA_toggle then _G.__NOVA_toggle() end
    end
    dragging, dragMoved = false, false
end)

-- hover scale
novaBtn.MouseEnter:Connect(function()
    TweenService:Create(novaBtn, TweenInfo.new(0.2), {
        Size = UDim2.fromOffset(BTN_W + 6, BTN_H + 4)
    }):Play()
end)
novaBtn.MouseLeave:Connect(function()
    TweenService:Create(novaBtn, TweenInfo.new(0.2), {
        Size = UDim2.fromOffset(BTN_W, BTN_H)
    }):Play()
end)

-- =====================================================
-- MAIN MENU
-- =====================================================
local MENU_W, MENU_H = 720, 460
local SIDEBAR_W = 190
local TOPBAR_H = 62

local menu = Instance.new("Frame")
menu.Name = "NOVA_Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.new(0.5, 0, 0.5, 0)
menu.Size = UDim2.fromOffset(MENU_W, MENU_H)
menu.BackgroundColor3 = T.Bg
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Visible = false
menu.Parent = gui

corner(menu, UDim.new(0, 18))
stroke(menu, T.Border, 1)

local menuGrad = Instance.new("UIGradient")
menuGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 23)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 13)),
})
menuGrad.Rotation = 135
menuGrad.Parent = menu

-- ambient blobs
local function blob(pos, size, color, trans)
    local b = Instance.new("Frame")
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.Position = pos
    b.Size = UDim2.fromOffset(size, size)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = trans
    b.BorderSizePixel = 0
    b.ZIndex = 0
    b.Parent = menu
    corner(b, UDim.new(1, 0))
end
blob(UDim2.new(0, 40, 0, 30), 220, T.Accent, 0.88)
blob(UDim2.new(1, -30, 1, -10), 260, T.Accent2, 0.92)

-- =====================================================
-- SIDEBAR
-- =====================================================
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
sidebar.BackgroundColor3 = T.Panel
sidebar.BackgroundTransparency = 0.08
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = menu
corner(sidebar, UDim.new(0, 18))

local sideMask = Instance.new("Frame")
sideMask.Size = UDim2.new(0, 18, 1, 0)
sideMask.Position = UDim2.new(1, -18, 0, 0)
sideMask.BackgroundColor3 = T.Panel
sideMask.BackgroundTransparency = 0.08
sideMask.BorderSizePixel = 0
sideMask.ZIndex = 2
sideMask.Parent = sidebar

local brand = Instance.new("Frame")
brand.Size = UDim2.new(1, 0, 0, 86)
brand.BackgroundTransparency = 1
brand.ZIndex = 3
brand.Parent = sidebar

local mark = Instance.new("Frame")
mark.Size = UDim2.fromOffset(40, 40)
mark.Position = UDim2.new(0, 20, 0, 22)
mark.BackgroundColor3 = T.Accent
mark.BorderSizePixel = 0
mark.ZIndex = 3
mark.Parent = brand
corner(mark, UDim.new(0, 12))
gradient(mark, {T.Accent, T.Accent2}, 45)

local markLabel = Instance.new("TextLabel")
markLabel.Size = UDim2.new(1, 0, 1, 0)
markLabel.BackgroundTransparency = 1
markLabel.Text = "N"
markLabel.Font = FONT_K
markLabel.TextSize = 22
markLabel.TextColor3 = Color3.new(1, 1, 1)
markLabel.ZIndex = 4
markLabel.Parent = mark

local brandName = Instance.new("TextLabel")
brandName.Size = UDim2.new(1, -80, 0, 20)
brandName.Position = UDim2.new(0, 72, 0, 24)
brandName.BackgroundTransparency = 1
brandName.Text = "NOVA"
brandName.Font = FONT_K
brandName.TextSize = 18
brandName.TextColor3 = T.Text
brandName.TextXAlignment = Enum.TextXAlignment.Left
brandName.ZIndex = 3
brandName.Parent = brand

local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(1, -80, 0, 14)
brandSub.Position = UDim2.new(0, 72, 0, 44)
brandSub.BackgroundTransparency = 1
brandSub.Text = "CLIENT v5"
brandSub.Font = FONT
brandSub.TextSize = 10
brandSub.TextColor3 = T.Dim
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.ZIndex = 3
brandSub.Parent = brand

local sideDiv = Instance.new("Frame")
sideDiv.Size = UDim2.new(1, -32, 0, 1)
sideDiv.Position = UDim2.new(0, 16, 0, 86)
sideDiv.BackgroundColor3 = T.Border
sideDiv.BackgroundTransparency = 0.4
sideDiv.BorderSizePixel = 0
sideDiv.ZIndex = 3
sideDiv.Parent = sidebar

local nav = Instance.new("Frame")
nav.Size = UDim2.new(1, 0, 1, -102)
nav.Position = UDim2.new(0, 0, 0, 98)
nav.BackgroundTransparency = 1
nav.ZIndex = 3
nav.Parent = sidebar
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = nav
padding(nav, 12, 12, 0, 0)

-- =====================================================
-- TOPBAR
-- =====================================================
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -SIDEBAR_W, 0, TOPBAR_H)
topBar.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 3
topBar.Parent = menu

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -180, 0, 22)
pageTitle.Position = UDim2.new(0, 24, 0, 14)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "General"
pageTitle.TextColor3 = T.Text
pageTitle.Font = FONT_K
pageTitle.TextSize = 18
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.ZIndex = 3
pageTitle.Parent = topBar

local pageSub = Instance.new("TextLabel")
pageSub.Size = UDim2.new(1, -180, 0, 14)
pageSub.Position = UDim2.new(0, 24, 0, 36)
pageSub.BackgroundTransparency = 1
pageSub.Text = "Client features & optimizations"
pageSub.TextColor3 = T.SubText
pageSub.Font = FONT
pageSub.TextSize = 11
pageSub.TextXAlignment = Enum.TextXAlignment.Left
pageSub.ZIndex = 3
pageSub.Parent = topBar

local function makeTopBtn(txt, xOff, hoverColor)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(34, 34)
    b.Position = UDim2.new(1, xOff, 0.5, -17)
    b.BackgroundColor3 = T.Card
    b.Text = txt
    b.TextColor3 = T.SubText
    b.Font = FONT_B
    b.TextSize = 15
    b.AutoButtonColor = false
    b.ZIndex = 3
    b.Parent = topBar
    corner(b, UDim.new(0, 10))
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = hoverColor or T.CardHover,
            TextColor3 = Color3.new(1, 1, 1)
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
local minBtn   = makeTopBtn("—", -88)

-- =====================================================
-- CONTENT
-- =====================================================
local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -SIDEBAR_W, 1, -TOPBAR_H)
contentHolder.Position = UDim2.new(0, SIDEBAR_W, 0, TOPBAR_H)
contentHolder.BackgroundTransparency = 1
contentHolder.ZIndex = 3
contentHolder.Parent = menu

local function makePage()
    local sp = Instance.new("ScrollingFrame")
    sp.Size = UDim2.new(1, 0, 1, 0)
    sp.BackgroundTransparency = 1
    sp.BorderSizePixel = 0
    sp.ScrollBarThickness = 3
    sp.ScrollBarImageColor3 = T.Accent
    sp.ScrollBarImageTransparency = 0.3
    sp.CanvasSize = UDim2.new(0, 0, 0, 0)
    sp.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sp.ZIndex = 3
    sp.Parent = contentHolder
    padding(sp, 22, 22, 8, 20)
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = sp
    return sp
end

local generalPage = makePage()

-- =====================================================
-- TOGGLE
-- =====================================================
local function createToggle(parent, name, desc, order, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 64)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 4
    card.Parent = parent
    corner(card, UDim.new(0, 12))
    local cs = stroke(card, T.Border, 1, 0.3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 20)
    title.Position = UDim2.new(0, 18, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_S
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5
    title.Parent = card

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -120, 0, 16)
    sub.Position = UDim2.new(0, 18, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Text = desc
    sub.TextColor3 = T.SubText
    sub.Font = FONT
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.ZIndex = 5
    sub.Parent = card

    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(48, 26)
    sw.Position = UDim2.new(1, -66, 0.5, -13)
    sw.BackgroundColor3 = T.Off
    sw.BorderSizePixel = 0
    sw.ZIndex = 5
    sw.Parent = card
    corner(sw, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 252)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = sw
    corner(knob, UDim.new(1, 0))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = sw

    local isOn = false
    local function set(on)
        isOn = on
        if on then
            TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = T.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -23, 0.5, -10)
            }):Play()
        else
            TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = T.Off}):Play()
            TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -10)
            }):Play()
        end
        if callback then pcall(callback, on) end
    end

    btn.MouseButton1Click:Connect(function() set(not isOn) end)

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = T.CardHover, BackgroundTransparency = 0}):Play()
        TweenService:Create(cs, TweenInfo.new(0.15), {Color = T.BorderHot, Transparency = 0}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = T.Card, BackgroundTransparency = 0.15}):Play()
        TweenService:Create(cs, TweenInfo.new(0.15), {Color = T.Border, Transparency = 0.3}):Play()
    end)

    return card, set
end

-- =====================================================
-- SLIDER
-- =====================================================
local function createSlider(parent, name, minV, maxV, default, order, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = T.Card
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 4
    card.Parent = parent
    corner(card, UDim.new(0, 12))
    local cs = stroke(card, T.Border, 1, 0.3)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 18)
    title.Position = UDim2.new(0, 18, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_S
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5
    title.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 70, 0, 18)
    valLbl.Position = UDim2.new(1, -88, 0, 10)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = T.Accent
    valLbl.Font = FONT_B
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 5
    valLbl.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -36, 0, 8)
    track.Position = UDim2.new(0, 18, 0, 44)
    track.BackgroundColor3 = T.Off
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = card
    corner(track, UDim.new(1, 0))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = T.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = track
    corner(fill, UDim.new(1, 0))
    gradient(fill, {T.Accent, T.Accent2}, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    knob.Parent = track
    corner(knob, UDim.new(1, 0))
    stroke(knob, T.Accent, 2, 0.2)

    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV - minV) * rel + 0.5)
        valLbl.Text = tostring(v)
        TweenService:Create(fill, TweenInfo.new(0.08), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.08), {Position = UDim2.new(rel, 0, 0.5, 0)}):Play()
        if callback then pcall(callback, v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    card.MouseEnter:Connect(function()
        TweenService:Create(cs, TweenInfo.new(0.15), {Color = T.BorderHot, Transparency = 0}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(cs, TweenInfo.new(0.15), {Color = T.Border, Transparency = 0.3}):Play()
    end)

    return card
end

-- =====================================================
-- REAL FEATURES
-- =====================================================
local fpsSnap = {}
local function setFPSBoost(on)
    if on then
        fpsSnap = {
            shadows = Lighting.GlobalShadows,
            fog     = Lighting.FogEnd,
            bright  = Lighting.Brightness,
            ed      = Lighting.EnvironmentDiffuseScale,
            es      = Lighting.EnvironmentSpecularScale,
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e5
        Lighting.Brightness = 2
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        pcall(function() Lighting.ShadowSoftness = 0 end)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then e.Enabled = false end
        end
        pcall(function() Workspace.GlobalWind = Vector3.new(0,0,0) end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        Lighting.GlobalShadows = fpsSnap.shadows ~= false
        Lighting.FogEnd        = fpsSnap.fog or 1e5
        Lighting.Brightness    = fpsSnap.bright or 2
        Lighting.EnvironmentDiffuseScale = fpsSnap.ed or 1
        Lighting.EnvironmentSpecularScale = fpsSnap.es or 1
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then e.Enabled = true end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
end

local lagHidden = {}
local function setAntiLag(on)
    if on then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles") then
                if d.Enabled then
                    d.Enabled = false
                    table.insert(lagHidden, d)
                end
            end
        end
        _G.__NOVA_LagConn = Workspace.DescendantAdded:Connect(function(d)
            if State.AntiLag then
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                    or d:IsA("Fire") or d:IsA("Sparkles") then
                    task.defer(function() pcall(function() d.Enabled = false end) end)
                end
            end
        end)
    else
        for _, d in ipairs(lagHidden) do pcall(function() d.Enabled = true end) end
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
        brightSnap = {
            amb = Lighting.Ambient, oamb = Lighting.OutdoorAmbient,
            br = Lighting.Brightness, ct = Lighting.ClockTime,
            fog = Lighting.FogEnd, sh = Lighting.GlobalShadows,
        }
        Lighting.Ambient = Color3.fromRGB(178,178,178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        if not Lighting:FindFirstChild("NOVA_CC") then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Name = "NOVA_CC"
            cc.Brightness = 0.15
            cc.Contrast = 0.05
            cc.Parent = Lighting
        end
    else
        Lighting.Ambient = brightSnap.amb or Lighting.Ambient
        Lighting.OutdoorAmbient = brightSnap.oamb or Lighting.OutdoorAmbient
        Lighting.Brightness = brightSnap.br or 2
        Lighting.ClockTime = brightSnap.ct or 14
        Lighting.FogEnd = brightSnap.fog or 1e5
        Lighting.GlobalShadows = brightSnap.sh ~= false
        local cc = Lighting:FindFirstChild("NOVA_CC")
        if cc then cc:Destroy() end
    end
end

local infJumpConn
local function setInfiniteJump(on)
    if on then
        if not infJumpConn then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local char = player.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    else
        if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
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

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.2)
    setWalkSpeed(State.WalkSpeed)
    setJumpPower(State.JumpPower)
end)

-- =====================================================
-- BUILD GENERAL PAGE
-- =====================================================
createToggle(generalPage, "FPS Boost",    "Boost rendering performance", 1, function(on)
    State.FPSBoost = on; setFPSBoost(on)
end)
createToggle(generalPage, "Anti Lag",     "Disable particle & effects lag", 2, function(on)
    State.AntiLag = on; setAntiLag(on)
end)
createToggle(generalPage, "Anti AFK",     "Prevent 20-minute idle kick", 3, function(on)
    State.AntiAFK = on; setAntiAFK(on)
end)
createToggle(generalPage, "Full Bright",  "See in the dark everywhere", 4, function(on)
    State.FullBright = on; setFullBright(on)
end)
createToggle(generalPage, "Infinite Jump","Jump endlessly mid-air", 5, function(on)
    State.InfiniteJmp = on; setInfiniteJump(on)
end)

createSlider(generalPage, "Walk Speed", 16, 200, 16, 6, function(v)
    State.WalkSpeed = v; setWalkSpeed(v)
end)
createSlider(generalPage, "Jump Power", 50, 300, 50, 7, function(v)
    State.JumpPower = v; setJumpPower(v)
end)

-- =====================================================
-- SIDEBAR TABS
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
    corner(tab, UDim.new(0, 10))

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -44, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = T.SubText
    label.Font = FONT_S
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = tab

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.Position = UDim2.new(0, 20, 0.5, -4)
    dot.BackgroundColor3 = T.Dim
    dot.BorderSizePixel = 0
    dot.ZIndex = 5
    dot.Parent = tab
    corner(dot, UDim.new(1, 0))

    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.Size = UDim2.new(0, 3, 0, 0)
    bar.Position = UDim2.new(1, -6, 0.5, 0)
    bar.BackgroundColor3 = T.Accent
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = tab
    corner(bar, UDim.new(1, 0))

    local function setActive(active)
        if active then
            TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = T.Text}):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {BackgroundColor3 = T.Accent}):Play()
            TweenService:Create(bar, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 3, 0, 22)
            }):Play()
        else
            TweenService:Create(tab, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = T.SubText}):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {BackgroundColor3 = T.Dim}):Play()
            TweenService:Create(bar, TweenInfo.new(0.2), {Size = UDim2.new(0, 3, 0, 0)}):Play()
        end
    end

    tab.MouseEnter:Connect(function()
        if bar.Size.Y.Offset == 0 then
            TweenService:Create(label, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,220)}):Play()
        end
    end)
    tab.MouseLeave:Connect(function()
        if bar.Size.Y.Offset == 0 then
            TweenService:Create(label, TweenInfo.new(0.15), {TextColor3 = T.SubText}):Play()
        end
    end)

    return setActive
end

local setGeneralActive = createTab("General", 1)
setGeneralActive(true)

-- =====================================================
-- OPEN / CLOSE
-- =====================================================
local isOpen, busy = false, false

local function openMenu()
    if isOpen or busy then return end
    busy = true; isOpen = true
    menu.Visible = true
    menu.Size = UDim2.fromOffset(MENU_W - 80, MENU_H - 40)
    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(MENU_W, MENU_H)
    }):Play()
    task.wait(0.1)
    busy = false
end

local function closeMenu()
    if not isOpen or busy then return end
    busy = true; isOpen = false
    TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(MENU_W - 80, MENU_H - 40)
    }):Play()
    task.wait(0.2)
    menu.Visible = false
    busy = false
end

_G.__NOVA_toggle = function()
    if isOpen then closeMenu() else openMenu() end
end

closeBtn.MouseButton1Click:Connect(closeMenu)
minBtn.MouseButton1Click:Connect(closeMenu)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then _G.__NOVA_toggle() end
end)

print("[NOVA] v5 loaded — click the NOVA button.")
