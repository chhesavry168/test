--[[
    NOVA Client GUI v6 — Fresh Redesign
    Location: StarterPlayer > StarterPlayerScripts (LocalScript)
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
-- THEME
-- =====================================================
local T = {
    Base       = Color3.fromRGB(7, 7, 11),
    Surface    = Color3.fromRGB(14, 14, 20),
    Elevated   = Color3.fromRGB(20, 20, 29),
    Border     = Color3.fromRGB(34, 34, 48),
    Text       = Color3.fromRGB(250, 250, 255),
    SubText    = Color3.fromRGB(130, 130, 155),
    Muted      = Color3.fromRGB(75, 75, 95),
    Violet     = Color3.fromRGB(140, 100, 255),
    Cyan       = Color3.fromRGB(0, 225, 255),
    Mint       = Color3.fromRGB(80, 245, 190),
    Pink       = Color3.fromRGB(255, 105, 200),
    Red        = Color3.fromRGB(255, 75, 110),
    Off        = Color3.fromRGB(42, 42, 58),
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
    FPSBoost    = false,
    AntiLag     = false,
    AntiAFK     = false,
    FullBright  = false,
    InfiniteJmp = false,
    NoClip      = false,
    WalkSpeed   = 16,
    JumpPower   = 50,
}

-- =====================================================
-- HELPERS
-- =====================================================
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = r or UDim.new(0,12); c.Parent = p; return c end
local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke"); s.Color = c or T.Border; s.Thickness = t or 1
    s.Transparency = tr or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function grad(p, cols, rot)
    local g = Instance.new("UIGradient")
    local k = {}; for i,c in ipairs(cols) do table.insert(k, ColorSequenceKeypoint.new((i-1)/(#cols-1), c)) end
    g.Color = ColorSequence.new(k); g.Rotation = rot or 0; g.Parent = p; return g
end
local function pad(p,l,r,t,b)
    local u = Instance.new("UIPadding")
    u.PaddingLeft=UDim.new(0,l or 0); u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingTop=UDim.new(0,t or 0); u.PaddingBottom=UDim.new(0,b or 0); u.Parent=p; return u
end
local function shadow(p, size, trans)
    local s = Instance.new("ImageLabel")
    s.Size = UDim2.new(1, size, 1, size)
    s.Position = UDim2.new(0, -size/2, 0, -size/2)
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://5028857472"
    s.ImageColor3 = Color3.new(0,0,0)
    s.ImageTransparency = trans or 0.4
    s.ZIndex = 0
    s.Parent = p
    return s
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
-- FLOATING BUTTON (hexagonal + hover expand)
-- =====================================================
local COLLAPSED = 52
local EXPANDED  = 118

local launcher = Instance.new("Frame")
launcher.Name = "Launcher"
launcher.Size = UDim2.fromOffset(COLLAPSED, COLLAPSED)
launcher.Position = UDim2.new(0, 40, 0.5, -26)
launcher.BackgroundColor3 = T.Surface
launcher.BorderSizePixel = 0
launcher.ClipsDescendants = true
launcher.Parent = gui
corner(launcher, UDim.new(1, 0))

-- inner dark gradient
local lgGrad = Instance.new("UIGradient")
lgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 22, 44)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 20)),
})
lgGrad.Rotation = 135
lgGrad.Parent = launcher

-- animated conic border (rainbow)
local lgStroke = Instance.new("UIStroke")
lgStroke.Thickness = 2
lgStroke.Color = Color3.new(1,1,1)
lgStroke.Parent = launcher

local conicGrad = Instance.new("UIGradient")
conicGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, T.Violet),
    ColorSequenceKeypoint.new(0.25, T.Cyan),
    ColorSequenceKeypoint.new(0.50, T.Mint),
    ColorSequenceKeypoint.new(0.75, T.Pink),
    ColorSequenceKeypoint.new(1.00, T.Violet),
})
conicGrad.Parent = lgStroke

-- pulsing halo
local halo = Instance.new("Frame")
halo.AnchorPoint = Vector2.new(0.5,0.5)
halo.Position = UDim2.new(0.5,0,0.5,0)
halo.Size = UDim2.new(1,0,1,0)
halo.BackgroundTransparency = 1
halo.ZIndex = 0
halo.Parent = launcher
corner(halo, UDim.new(1,0))
local haloStroke = stroke(halo, T.Violet, 2, 0.4)

-- "N" mark
local nMark = Instance.new("TextLabel")
nMark.Size = UDim2.fromOffset(COLLAPSED, COLLAPSED)
nMark.Position = UDim2.new(0, 0, 0, 0)
nMark.BackgroundTransparency = 1
nMark.Text = "N"
nMark.Font = FONT_K
nMark.TextSize = 22
nMark.TextColor3 = Color3.new(1,1,1)
nMark.ZIndex = 3
nMark.Parent = launcher
local nGrad = grad(nMark, {T.Violet, T.Cyan}, 45)

-- expanded wordmark (fades in on hover)
local wordmark = Instance.new("TextLabel")
wordmark.Size = UDim2.new(1, -COLLAPSED, 1, 0)
wordmark.Position = UDim2.new(0, COLLAPSED - 4, 0, 0)
wordmark.BackgroundTransparency = 1
wordmark.Text = "NOVA"
wordmark.Font = FONT_K
wordmark.TextSize = 16
wordmark.TextColor3 = Color3.new(1,1,1)
wordmark.TextXAlignment = Enum.TextXAlignment.Left
wordmark.TextTransparency = 1
wordmark.ZIndex = 3
wordmark.Parent = launcher
local wGrad = grad(wordmark, {Color3.fromRGB(255,255,255), T.Cyan}, 0)

-- pulse loop
task.spawn(function()
    while launcher.Parent do
        halo.Size = UDim2.new(1,0,1,0)
        haloStroke.Transparency = 0.4
        TweenService:Create(halo, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 40, 1, 40)
        }):Play()
        TweenService:Create(haloStroke, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
        task.wait(1.8)
    end
end)

-- rainbow border loop
task.spawn(function()
    while launcher.Parent do
        for _ = 1, 360 do
            conicGrad.Rotation = (conicGrad.Rotation + 1) % 360
            nGrad.Rotation = (nGrad.Rotation + 2) % 360
            wGrad.Rotation = (wGrad.Rotation + 1.5) % 360
            RunService.RenderStepped:Wait()
        end
        local palettes = {
            {T.Violet, T.Cyan, T.Mint, T.Pink, T.Violet},
            {T.Cyan, T.Mint, T.Pink, T.Violet, T.Cyan},
            {T.Mint, T.Pink, T.Violet, T.Cyan, T.Mint},
            {T.Pink, T.Violet, T.Cyan, T.Mint, T.Pink},
        }
        local p = palettes[math.random(1,#palettes)]
        conicGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, p[1]),
            ColorSequenceKeypoint.new(0.25, p[2]),
            ColorSequenceKeypoint.new(0.50, p[3]),
            ColorSequenceKeypoint.new(0.75, p[4]),
            ColorSequenceKeypoint.new(1.00, p[5]),
        })
    end
end)

-- hover expand
launcher.MouseEnter:Connect(function()
    TweenService:Create(launcher, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(EXPANDED, COLLAPSED)
    }):Play()
    TweenService:Create(wordmark, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
end)
launcher.MouseLeave:Connect(function()
    TweenService:Create(launcher, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.fromOffset(COLLAPSED, COLLAPSED)
    }):Play()
    TweenService:Create(wordmark, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
end)

-- =====================================================
-- DRAG + CLICK
-- =====================================================
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

-- =====================================================
-- MENU FRAME
-- =====================================================
local MW, MH = 700, 470

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
corner(menu, UDim.new(0, 20))
stroke(menu, T.Border, 1)

local mGrad = Instance.new("UIGradient")
mGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12,12,18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6,6,10)),
})
mGrad.Rotation = 135
mGrad.Parent = menu

-- ambient glow blobs
local function blob(pos, size, color, trans, z)
    local b = Instance.new("Frame")
    b.AnchorPoint = Vector2.new(0.5,0.5)
    b.Position = pos
    b.Size = UDim2.fromOffset(size,size)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = trans
    b.BorderSizePixel = 0
    b.ZIndex = z or 0
    b.Parent = menu
    corner(b, UDim.new(1,0))
    return b
end
blob(UDim2.new(0.15, 0, 0.0, 0), 260, T.Violet, 0.9, 0)
blob(UDim2.new(0.9, 0, 1.0, 0), 300, T.Cyan, 0.93, 0)

-- =====================================================
-- HEADER (top bar with brand + FPS + ping)
-- =====================================================
local HEADER_H = 78

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.ZIndex = 4
header.Parent = menu

-- Brand mark
local bMark = Instance.new("Frame")
bMark.Size = UDim2.fromOffset(38, 38)
bMark.Position = UDim2.new(0, 22, 0, 20)
bMark.BackgroundColor3 = T.Violet
bMark.BorderSizePixel = 0
bMark.ZIndex = 4
bMark.Parent = header
corner(bMark, UDim.new(0, 11))
grad(bMark, {T.Violet, T.Cyan}, 45)

local bMarkLbl = Instance.new("TextLabel")
bMarkLbl.Size = UDim2.new(1,0,1,0)
bMarkLbl.BackgroundTransparency = 1
bMarkLbl.Text = "N"
bMarkLbl.Font = FONT_K
bMarkLbl.TextSize = 20
bMarkLbl.TextColor3 = Color3.new(1,1,1)
bMarkLbl.ZIndex = 5
bMarkLbl.Parent = bMark

-- Brand text
local bTitle = Instance.new("TextLabel")
bTitle.Size = UDim2.new(0, 200, 0, 20)
bTitle.Position = UDim2.new(0, 70, 0, 22)
bTitle.BackgroundTransparency = 1
bTitle.Text = "NOVA"
bTitle.TextColor3 = T.Text
bTitle.Font = FONT_K
bTitle.TextSize = 17
bTitle.TextXAlignment = Enum.TextXAlignment.Left
bTitle.ZIndex = 4
bTitle.Parent = header

local bSub = Instance.new("TextLabel")
bSub.Size = UDim2.new(0, 200, 0, 14)
bSub.Position = UDim2.new(0, 70, 0, 42)
bSub.BackgroundTransparency = 1
bSub.Text = "advanced client"
bSub.TextColor3 = T.SubText
bSub.Font = FONT
bSub.TextSize = 10
bSub.TextXAlignment = Enum.TextXAlignment.Left
bSub.ZIndex = 4
bSub.Parent = header

-- Live stats (right side)
local statsBar = Instance.new("Frame")
statsBar.Size = UDim2.fromOffset(220, 34)
statsBar.Position = UDim2.new(1, -300, 0, 24)
statsBar.BackgroundColor3 = T.Surface
statsBar.BackgroundTransparency = 0.4
statsBar.BorderSizePixel = 0
statsBar.ZIndex = 4
statsBar.Parent = header
corner(statsBar, UDim.new(0, 10))
stroke(statsBar, T.Border, 1, 0.4)

local function statCell(x, dotColor, label)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(0, 100, 1, 0)
    c.Position = UDim2.new(0, x, 0, 0)
    c.BackgroundTransparency = 1
    c.ZIndex = 5
    c.Parent = statsBar

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(6, 6)
    dot.Position = UDim2.new(0, 12, 0.5, -3)
    dot.BackgroundColor3 = dotColor
    dot.BorderSizePixel = 0
    dot.ZIndex = 5
    dot.Parent = c
    corner(dot, UDim.new(1,0))

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 40, 1, 0)
    lbl.Position = UDim2.new(0, 24, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = T.SubText
    lbl.Font = FONT_M
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5
    lbl.Parent = c

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 40, 1, 0)
    val.Position = UDim2.new(1, -42, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = "--"
    val.TextColor3 = T.Text
    val.Font = FONT_B
    val.TextSize = 11
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 5
    val.Parent = c

    return val
end

local fpsVal  = statCell(0,   T.Mint, "FPS")
local pingVal = statCell(110, T.Cyan, "MS")

-- live update
task.spawn(function()
    while menu.Parent do
        local ok, fps = pcall(function() return math.floor(Stats.RenderFPS:GetValue()) end)
        fpsVal.Text = ok and tostring(fps) or "--"
        local ok2, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        pingVal.Text = ok2 and tostring(ping) or "--"
        task.wait(0.5)
    end
end)

-- close & minimize
local function makeHeaderBtn(txt, xOff, hover)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(32, 32)
    b.Position = UDim2.new(1, xOff, 0, 23)
    b.BackgroundColor3 = T.Surface
    b.BackgroundTransparency = 0.3
    b.Text = txt
    b.TextColor3 = T.SubText
    b.Font = FONT_B
    b.TextSize = 14
    b.AutoButtonColor = false
    b.ZIndex = 5
    b.Parent = header
    corner(b, UDim.new(0, 9))
    stroke(b, T.Border, 1, 0.4)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0, BackgroundColor3 = hover or T.Elevated, TextColor3 = Color3.new(1,1,1)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundTransparency = 0.3, BackgroundColor3 = T.Surface, TextColor3 = T.SubText}):Play()
    end)
    return b
end

local closeBtn = makeHeaderBtn("✕", -46, T.Red)
local minBtn   = makeHeaderBtn("—", -84)

-- =====================================================
-- TAB STRIP (horizontal segmented control)
-- =====================================================
local TABS_H = 44
local tabStrip = Instance.new("Frame")
tabStrip.Size = UDim2.new(1, -44, 0, TABS_H)
tabStrip.Position = UDim2.new(0, 22, 0, HEADER_H)
tabStrip.BackgroundColor3 = T.Surface
tabStrip.BackgroundTransparency = 0.4
tabStrip.BorderSizePixel = 0
tabStrip.ZIndex = 4
tabStrip.Parent = menu
corner(tabStrip, UDim.new(0, 12))
stroke(tabStrip, T.Border, 1, 0.4)
pad(tabStrip, 4, 4, 4, 4)

-- indicator (sliding pill)
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 100, 1, 0)
indicator.Position = UDim2.new(0, 0, 0, 0)
indicator.BackgroundColor3 = T.Violet
indicator.BorderSizePixel = 0
indicator.ZIndex = 5
indicator.Parent = tabStrip
corner(indicator, UDim.new(0, 9))
grad(indicator, {T.Violet, T.Cyan}, 45)

local tabRow = Instance.new("Frame")
tabRow.Size = UDim2.new(1, 0, 1, 0)
tabRow.BackgroundTransparency = 1
tabRow.ZIndex = 6
tabRow.Parent = tabStrip

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabRow

-- =====================================================
-- PAGE HOLDER
-- =====================================================
local pageHolder = Instance.new("Frame")
pageHolder.Size = UDim2.new(1, -44, 1, -(HEADER_H + TABS_H + 34))
pageHolder.Position = UDim2.new(0, 22, 0, HEADER_H + TABS_H + 12)
pageHolder.BackgroundTransparency = 1
pageHolder.ZIndex = 4
pageHolder.Parent = menu

local pages = {}
local tabs = {}
local currentPage = nil

local function showPage(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
end

local function registerTab(name, order)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 110, 1, 0)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.AutoButtonColor = false
    tabBtn.LayoutOrder = order
    tabBtn.ZIndex = 6
    tabBtn.Parent = tabRow

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = FONT_S
    lbl.TextSize = 12
    lbl.TextColor3 = T.SubText
    lbl.ZIndex = 7
    lbl.Parent = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do
            t.deactivate()
        end
        -- move indicator
        TweenService:Create(indicator, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, tabBtn.AbsolutePosition.X - tabStrip.AbsolutePosition.X - 4, 0, 0),
            Size = UDim2.new(0, tabBtn.AbsoluteSize.X, 1, 0)
        }):Play()
        -- animate label
        TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = Color3.new(1,1,1)}):Play()
        showPage(name)
    end)

    tabBtn.MouseEnter:Connect(function()
        if lbl.TextColor3 ~= Color3.new(1,1,1) then
            TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,220)}):Play()
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if lbl.TextColor3 ~= Color3.new(1,1,1) then
            TweenService:Create(lbl, TweenInfo.new(0.15), {TextColor3 = T.SubText}):Play()
        end
    end)

    local function deactivate()
        TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = T.SubText}):Play()
    end

    tabs[#tabs+1] = {deactivate = deactivate, button = tabBtn}
    return tabBtn
end

local function createPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = T.Violet
    p.ScrollBarImageTransparency = 0.4
    p.CanvasSize = UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.ZIndex = 4
    p.Visible = false
    p.Parent = pageHolder
    pad(p, 0, 10, 0, 0)
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 10)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = p
    pages[name] = p
    return p
end

-- =====================================================
-- ROW (toggle / slider) — new "chip" design
-- =====================================================
local function createToggle(parent, name, desc, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 62)
    row.BackgroundColor3 = T.Elevated
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 4
    row.Parent = parent
    corner(row, UDim.new(0, 14))
    local rs = stroke(row, T.Border, 1, 0.4)

    -- left accent bar (glows when ON)
    local accentBar = Instance.new("Frame")
    accentBar.AnchorPoint = Vector2.new(0, 0.5)
    accentBar.Position = UDim2.new(0, 12, 0.5, 0)
    accentBar.Size = UDim2.new(0, 3, 0, 0)
    accentBar.BackgroundColor3 = T.Violet
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 5
    accentBar.Parent = row
    corner(accentBar, UDim.new(1, 0))

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -140, 0, 20)
    title.Position = UDim2.new(0, 28, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_S
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5
    title.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -140, 0, 16)
    sub.Position = UDim2.new(0, 28, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Text = desc
    sub.TextColor3 = T.SubText
    sub.Font = FONT
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.ZIndex = 5
    sub.Parent = row

    -- status pill
    local pill = Instance.new("TextLabel")
    pill.Size = UDim2.fromOffset(46, 22)
    pill.Position = UDim2.new(1, -110, 0.5, -11)
    pill.BackgroundColor3 = T.Off
    pill.BackgroundTransparency = 0.4
    pill.Text = "OFF"
    pill.TextColor3 = T.SubText
    pill.Font = FONT_B
    pill.TextSize = 9
    pill.ZIndex = 5
    pill.Parent = row
    corner(pill, UDim.new(0, 7))

    -- switch
    local sw = Instance.new("Frame")
    sw.Size = UDim2.fromOffset(48, 26)
    sw.Position = UDim2.new(1, -60, 0.5, -13)
    sw.BackgroundColor3 = T.Off
    sw.BorderSizePixel = 0
    sw.ZIndex = 5
    sw.Parent = row
    corner(sw, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(245,245,252)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = sw
    corner(knob, UDim.new(1, 0))

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = sw

    local isOn = false
    local function set(on)
        isOn = on
        if on then
            TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = T.Violet}):Play()
            TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -23, 0.5, -10)
            }):Play()
            TweenService:Create(accentBar, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 3, 0, 34)
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.2), {
                BackgroundColor3 = T.Violet, BackgroundTransparency = 0, TextColor3 = Color3.new(1,1,1)
            }):Play()
            pill.Text = "ON"
        else
            TweenService:Create(sw, TweenInfo.new(0.22), {BackgroundColor3 = T.Off}):Play()
            TweenService:Create(knob, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -10)
            }):Play()
            TweenService:Create(accentBar, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 3, 0, 0)
            }):Play()
            TweenService:Create(pill, TweenInfo.new(0.2), {
                BackgroundColor3 = T.Off, BackgroundTransparency = 0.4, TextColor3 = T.SubText
            }):Play()
            pill.Text = "OFF"
        end
        if callback then pcall(callback, on) end
    end

    btn.MouseButton1Click:Connect(function() set(not isOn) end)

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(26,26,38)}):Play()
        TweenService:Create(rs, TweenInfo.new(0.15), {Color = T.Violet, Transparency = 0}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.15), {BackgroundTransparency = 0.15, BackgroundColor3 = T.Elevated}):Play()
        TweenService:Create(rs, TweenInfo.new(0.15), {Color = T.Border, Transparency = 0.4}):Play()
    end)

    return row, set
end

-- slider row
local function createSlider(parent, name, minV, maxV, default, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 72)
    row.BackgroundColor3 = T.Elevated
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 4
    row.Parent = parent
    corner(row, UDim.new(0, 14))
    local rs = stroke(row, T.Border, 1, 0.4)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 0, 18)
    title.Position = UDim2.new(0, 20, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = T.Text
    title.Font = FONT_S
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5
    title.Parent = row

    local valBox = Instance.new("Frame")
    valBox.Size = UDim2.fromOffset(58, 22)
    valBox.Position = UDim2.new(1, -78, 0, 10)
    valBox.BackgroundColor3 = T.Surface
    valBox.BorderSizePixel = 0
    valBox.ZIndex = 5
    valBox.Parent = row
    corner(valBox, UDim.new(0, 7))
    stroke(valBox, T.Border, 1, 0.4)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1,0,1,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = T.Violet
    valLbl.Font = FONT_B
    valLbl.TextSize = 12
    valLbl.ZIndex = 6
    valLbl.Parent = valBox

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -40, 0, 8)
    track.Position = UDim2.new(0, 20, 0, 46)
    track.BackgroundColor3 = T.Off
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = row
    corner(track, UDim.new(1,0))

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - minV)/(maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = T.Violet
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = track
    corner(fill, UDim.new(1,0))
    grad(fill, {T.Violet, T.Cyan}, 0)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(fill.Size.X.Scale, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 7
    knob.Parent = track
    corner(knob, UDim.new(1,0))
    stroke(knob, T.Violet, 2, 0.2)

    local draggingS = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV - minV) * rel + 0.5)
        valLbl.Text = tostring(v)
        TweenService:Create(fill, TweenInfo.new(0.08), {Size = UDim2.new(rel,0,1,0)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.08), {Position = UDim2.new(rel,0,0.5,0)}):Play()
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
        TweenService:Create(rs, TweenInfo.new(0.15), {Color = T.Violet, Transparency = 0}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(rs, TweenInfo.new(0.15), {Color = T.Border, Transparency = 0.4}):Play()
    end)
    return row
end

-- =====================================================
-- REAL FEATURES
-- =====================================================
local fpsSnap = {}
local function setFPSBoost(on)
    if on then
        fpsSnap = {shadows = Lighting.GlobalShadows, fog = Lighting.FogEnd, bright = Lighting.Brightness,
                   ed = Lighting.EnvironmentDiffuseScale, es = Lighting.EnvironmentSpecularScale}
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
        local cc = Lighting:FindFirstChild("NOVA_CC")
        if cc then cc:Destroy() end
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
local generalPage = createPage("General")
local movementPage = createPage("Movement")
local visualPage = createPage("Visuals")

-- General tab
registerTab("General", 1)
createToggle(generalPage, "FPS Boost",    "Boost rendering performance", 1, function(on) State.FPSBoost = on setFPSBoost(on) end)
createToggle(generalPage, "Anti Lag",     "Disable particle & effects lag", 2, function(on) State.AntiLag = on setAntiLag(on) end)
createToggle(generalPage, "Anti AFK",     "Prevent 20-minute idle kick", 3, function(on) State.AntiAFK = on setAntiAFK(on) end)

-- Movement tab
registerTab("Movement", 2)
createToggle(movementPage, "Infinite Jump", "Jump endlessly mid-air", 1, function(on) State.InfiniteJmp = on setInfiniteJump(on) end)
createToggle(movementPage, "No Clip",       "Walk through walls", 2, function(on) State.NoClip = on setNoClip(on) end)
createSlider(movementPage, "Walk Speed", 16, 250, 16, 3, function(v) State.WalkSpeed = v setWalkSpeed(v) end)
createSlider(movementPage, "Jump Power", 50, 300, 50, 4, function(v) State.JumpPower = v setJumpPower(v) end)

-- Visuals tab
registerTab("Visuals", 3)
createToggle(visualPage, "Full Bright", "See in the dark everywhere", 1, function(on) State.FullBright = on setFullBright(on) end)

-- activate first tab (need to trigger click since indicator depends on size)
task.defer(function()
    task.wait(0.1)
    tabs[1].button:FindFirstChildOfClass("TextButton") -- no-op
    tabs[1].button.MouseButton1Click:Fire()
    -- manual trigger:
    for _,t in ipairs(tabs) do t.deactivate() end
    local lbl = tabs[1].button:FindFirstChildOfClass("TextLabel")
    if lbl then lbl.TextColor3 = Color3.new(1,1,1) end
    TweenService:Create(indicator, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, tabs[1].button.AbsoluteSize.X, 1, 0)
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
    menu.Size = UDim2.fromOffset(MW - 80, MH - 40)
    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(MW, MH)
    }):Play()
    task.wait(0.1)
    busy = false
end

local function closeMenu()
    if not isOpen or busy then return end
    busy = true; isOpen = false
    TweenService:Create(menu, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(MW - 80, MH - 40)
    }):Play()
    task.wait(0.2)
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

print("[NOVA] v6 loaded — click the pill button.")
