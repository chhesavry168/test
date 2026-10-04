--[[
    NOVA Client GUI v2
    Place in StarterPlayer > StarterPlayerScripts (LocalScript)
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== THEME ====================
local THEME = {
    Accent      = Color3.fromRGB(122, 92, 255),
    Accent2     = Color3.fromRGB(92, 200, 255),
    Bg          = Color3.fromRGB(14, 14, 20),
    Panel       = Color3.fromRGB(22, 22, 30),
    Card        = Color3.fromRGB(28, 28, 38),
    CardHover   = Color3.fromRGB(34, 34, 46),
    Border      = Color3.fromRGB(42, 42, 56),
    Text        = Color3.fromRGB(240, 240, 248),
    SubText     = Color3.fromRGB(150, 150, 168),
    SwitchOff   = Color3.fromRGB(55, 55, 72),
}

-- ==================== STATE ====================
local state = {
    FPSBoost = false,
    AntiLag  = false,
    AntiAFK  = false,
}

-- ==================== SCREEN GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NOVA"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- ==================== FLOATING ICON ====================
local icon = Instance.new("Frame")
icon.Name = "FloatingIcon"
icon.Size = UDim2.new(0, 54, 0, 54)
icon.Position = UDim2.new(0, 80, 0, 120)
icon.BackgroundColor3 = THEME.Bg
icon.BorderSizePixel = 0
icon.Active = true
icon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Thickness = 2
iconStroke.Color = THEME.Accent
iconStroke.Parent = icon

-- Gradient stroke
local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.Accent),
    ColorSequenceKeypoint.new(1, THEME.Accent2),
})
strokeGrad.Rotation = 45
strokeGrad.Parent = iconStroke

-- Gradient BG
local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 22)),
})
bgGrad.Rotation = 135
bgGrad.Parent = icon

local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.new(1, 0, 1, 0)
iconText.BackgroundTransparency = 1
iconText.Text = "N"
iconText.Font = Enum.Font.GothamBlack
iconText.TextSize = 24
iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
iconText.Parent = icon

local textGrad = Instance.new("UIGradient")
textGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.Accent),
    ColorSequenceKeypoint.new(1, THEME.Accent2),
})
textGrad.Rotation = 45
textGrad.Parent = iconText

-- Click detector (invisible button on top)
local iconBtn = Instance.new("TextButton")
iconBtn.Size = UDim2.new(1, 0, 1, 0)
iconBtn.BackgroundTransparency = 1
iconBtn.Text = ""
iconBtn.Parent = icon

-- ==================== DRAG SYSTEM ====================
local dragging, dragStart, startPos

icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = icon.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        icon.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==================== MAIN MENU ====================
local menu = Instance.new("Frame")
menu.Name = "MainMenu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.new(0.5, 0, 0.5, 0)
menu.Size = UDim2.new(0, 640, 0, 420)
menu.BackgroundColor3 = THEME.Bg
menu.BorderSizePixel = 0
menu.Visible = false
menu.ClipsDescendants = true
menu.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 16)
menuCorner.Parent = menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = THEME.Border
menuStroke.Thickness = 1
menuStroke.Parent = menu

local menuGrad = Instance.new("UIGradient")
menuGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 11, 17)),
})
menuGrad.Rotation = 135
menuGrad.Parent = menu

-- ==================== SIDEBAR ====================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.BackgroundColor3 = THEME.Panel
sidebar.BorderSizePixel = 0
sidebar.Parent = menu

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 16)
sidebarCorner.Parent = sidebar

-- Right-side corner mask to square off right edge
local sidebarMask = Instance.new("Frame")
sidebarMask.Size = UDim2.new(0, 16, 1, 0)
sidebarMask.Position = UDim2.new(1, -16, 0, 0)
sidebarMask.BackgroundColor3 = THEME.Panel
sidebarMask.BorderSizePixel = 0
sidebarMask.Parent = sidebar

-- Brand header
local brand = Instance.new("Frame")
brand.Size = UDim2.new(1, 0, 0, 74)
brand.BackgroundTransparency = 1
brand.Parent = sidebar

local brandDot = Instance.new("Frame")
brandDot.Size = UDim2.new(0, 8, 0, 8)
brandDot.Position = UDim2.new(0, 22, 0, 34)
brandDot.BackgroundColor3 = THEME.Accent
brandDot.BorderSizePixel = 0
brandDot.Parent = brand

local brandDotCorner = Instance.new("UICorner")
brandDotCorner.CornerRadius = UDim.new(1, 0)
brandDotCorner.Parent = brandDot

local brandDotGrad = Instance.new("UIGradient")
brandDotGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.Accent),
    ColorSequenceKeypoint.new(1, THEME.Accent2),
})
brandDotGrad.Parent = brandDot

local brandText = Instance.new("TextLabel")
brandText.Size = UDim2.new(1, -40, 1, 0)
brandText.Position = UDim2.new(0, 40, 0, 0)
brandText.BackgroundTransparency = 1
brandText.Text = "NOVA"
brandText.Font = Enum.Font.GothamBlack
brandText.TextSize = 22
brandText.TextColor3 = THEME.Text
brandText.TextXAlignment = Enum.TextXAlignment.Left
brandText.Parent = brand

local brandGrad = Instance.new("UIGradient")
brandGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.Text),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 200)),
})
brandGrad.Rotation = 45
brandGrad.Parent = brandText

local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(1, -40, 0, 14)
brandSub.Position = UDim2.new(0, 40, 0, 46)
brandSub.BackgroundTransparency = 1
brandSub.Text = "CLIENT"
brandSub.Font = Enum.Font.GothamMedium
brandSub.TextSize = 9
brandSub.TextColor3 = THEME.SubText
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = brand

local brandSubGrad = Instance.new("UIGradient")
brandSubGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.Accent),
    ColorSequenceKeypoint.new(1, THEME.Accent2),
})
brandSubGrad.Parent = brandSub

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -32, 0, 1)
divider.Position = UDim2.new(0, 16, 0, 74)
divider.BackgroundColor3 = THEME.Border
divider.BorderSizePixel = 0
divider.Parent = sidebar

-- Nav container
local nav = Instance.new("Frame")
nav.Size = UDim2.new(1, 0, 1, -90)
nav.Position = UDim2.new(0, 0, 0, 88)
nav.BackgroundTransparency = 1
nav.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = nav

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft = UDim.new(0, 12)
navPad.PaddingRight = UDim.new(0, 12)
navPad.PaddingTop = UDim.new(0, 4)
navPad.Parent = nav

-- ==================== TOP BAR ====================
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -180, 0, 56)
topBar.Position = UDim2.new(0, 180, 0, 0)
topBar.BackgroundTransparency = 1
topBar.Parent = menu

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -140, 1, 0)
pageTitle.Position = UDim2.new(0, 22, 0, 0)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "General"
pageTitle.TextColor3 = THEME.Text
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextSize = 17
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = topBar

local pageSub = Instance.new("TextLabel")
pageSub.Size = UDim2.new(1, -140, 0, 14)
pageSub.Position = UDim2.new(0, 22, 0, 32)
pageSub.BackgroundTransparency = 1
pageSub.Text = "Client tweaks & optimizations"
pageSub.TextColor3 = THEME.SubText
pageSub.Font = Enum.Font.Gotham
pageSub.TextSize = 11
pageSub.TextXAlignment = Enum.TextXAlignment.Left
pageSub.Parent = topBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -46, 0.5, -16)
closeBtn.BackgroundColor3 = THEME.Card
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.SubText
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeBtn

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 32, 0, 32)
minBtn.Position = UDim2.new(1, -84, 0.5, -16)
minBtn.BackgroundColor3 = THEME.Card
minBtn.Text = "—"
minBtn.TextColor3 = THEME.SubText
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.AutoButtonColor = false
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 9)
minCorner.Parent = minBtn

-- ==================== CONTENT ====================
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -180, 1, -56)
content.Position = UDim2.new(0, 180, 0, 56)
content.BackgroundTransparency = 1
content.Parent = menu

local contentPad = Instance.new("UIPadding")
contentPad.PaddingLeft = UDim.new(0, 18)
contentPad.PaddingRight = UDim.new(0, 18)
contentPad.PaddingTop = UDim.new(0, 4)
contentPad.PaddingBottom = UDim.new(0, 18)
contentPad.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- ==================== TOGGLE CREATOR ====================
local function createToggle(name, desc, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 62)
    card.BackgroundColor3 = THEME.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = content

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = THEME.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 0, 20)
    title.Position = UDim2.new(0, 18, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    -- Desc
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -110, 0, 16)
    sub.Position = UDim2.new(0, 18, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Text = desc
    sub.TextColor3 = THEME.SubText
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = card

    -- Switch
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 48, 0, 26)
    sw.Position = UDim2.new(1, -66, 0.5, -13)
    sw.BackgroundColor3 = THEME.SwitchOff
    sw.BorderSizePixel = 0
    sw.Parent = card

    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = sw

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
    knob.BorderSizePixel = 0
    knob.Parent = sw

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local knobShadow = Instance.new("ImageLabel")
    knobShadow.Size = UDim2.new(1, 8, 1, 8)
    knobShadow.Position = UDim2.new(0, -4, 0, -4)
    knobShadow.BackgroundTransparency = 1
    knobShadow.Image = "rbxassetid://5028857472"
    knobShadow.ImageColor3 = Color3.new(0, 0, 0)
    knobShadow.ImageTransparency = 0.85
    knobShadow.ZIndex = 0
    knobShadow.Parent = knob

    local swBtn = Instance.new("TextButton")
    swBtn.Size = UDim2.new(1, 0, 1, 0)
    swBtn.BackgroundTransparency = 1
    swBtn.Text = ""
    swBtn.Parent = sw

    local isOn = false

    local function setSwitch(on)
        isOn = on
        state[name:gsub("%s", "")] = on

        if on then
            TweenService:Create(sw, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                BackgroundColor3 = THEME.Accent
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -23, 0.5, -10)
            }):Play()
        else
            TweenService:Create(sw, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                BackgroundColor3 = THEME.SwitchOff
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 3, 0.5, -10)
            }):Play()
        end

        -- Apply function
        if name == "FPS Boost" then
            if on then
                local blur = Instance.new("BlurEffect")
                blur.Name = "NOVA_Blur"
                blur.Size = 0
                blur.Parent = Lighting
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

    swBtn.MouseButton1Click:Connect(function()
        setSwitch(not isOn)
    end)

    -- Card hover
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {
            BackgroundColor3 = THEME.CardHover
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {
            Color = THEME.Accent
        }):Play()
    end)

    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {
            BackgroundColor3 = THEME.Card
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {
            Color = THEME.Border
        }):Play()
    end)

    return card
end

createToggle("FPS Boost", "Improves frames per second", 1)
createToggle("Anti Lag",  "Disables laggy visuals",     2)
createToggle("Anti AFK",  "Prevents idle disconnect",   3)

-- ==================== SIDEBAR TAB ====================
local function createTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(1, 0, 0, 38)
    tab.BackgroundColor3 = THEME.Card
    tab.BackgroundTransparency = 1
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.LayoutOrder = order
    tab.Parent = nav

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 9)
    tabCorner.Parent = tab

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -36, 1, 0)
    label.Position = UDim2.new(0, 32, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = THEME.SubText
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tab

    -- Icon dot indicator
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0, 18, 0.5, -3)
    dot.BackgroundColor3 = THEME.SubText
    dot.BorderSizePixel = 0
    dot.Parent = tab

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot

    -- Active glow line
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(0, 3, 0, 0)
    glow.Position = UDim2.new(1, -6, 0.5, 0)
    glow.BackgroundColor3 = THEME.Accent
    glow.BorderSizePixel = 0
    glow.Parent = tab

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glow

    local function setActive(active)
        if active then
            TweenService:Create(tab, TweenInfo.new(0.2), {
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {
                TextColor3 = THEME.Text
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {
                BackgroundColor3 = THEME.Accent
            }):Play()
            TweenService:Create(glow, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 3, 0, 18)
            }):Play()
        else
            TweenService:Create(tab, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {
                TextColor3 = THEME.SubText
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.2), {
                BackgroundColor3 = THEME.SubText
            }):Play()
            TweenService:Create(glow, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 3, 0, 0)
            }):Play()
        end
    end

    tab.MouseEnter:Connect(function()
        if label.TextColor3 ~= THEME.Text then
            TweenService:Create(label, TweenInfo.new(0.15), {
                TextColor3 = Color3.fromRGB(200, 200, 215)
            }):Play()
        end
    end)

    tab.MouseLeave:Connect(function()
        if glow.Size.Y.Offset == 0 then
            TweenService:Create(label, TweenInfo.new(0.15), {
                TextColor3 = THEME.SubText
            }):Play()
        end
    end)

    return tab, setActive
end

local generalTab, setGeneralActive = createTab("General", 1)
setGeneralActive(true)

-- (Future tabs can be added here)

-- ==================== ANTI AFK ====================
local antiAfkConn
local function updateAntiAfk()
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

task.spawn(function()
    while task.wait(0.3) do
        updateAntiAfk()
    end
end)

-- ==================== OPEN / CLOSE ====================
local isOpen = false

local function openMenu()
    if isOpen then return end
    isOpen = true

    menu.Visible = true
    menu.Size = UDim2.new(0, 600, 0, 380)
    menu.BackgroundTransparency = 0
    menuGrad.Transparency = NumberSequence.new(0)

    TweenService:Create(menu, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 640, 0, 420)
    }):Play()

    -- Fade in cards
    for _, v in ipairs(content:GetChildren()) do
        if v:IsA("Frame") then
            v.BackgroundTransparency = 1
            TweenService:Create(v, TweenInfo.new(0.3), {
                BackgroundTransparency = 0
            }):Play()
        end
    end
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false

    TweenService:Create(menu, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 600, 0, 380)
    }):Play()

    task.wait(0.22)
    menu.Visible = false
end

-- IMPORTANT: Use iconBtn (child on top) for click so dragging still works via icon frame
iconBtn.MouseButton1Click:Connect(function()
    if isOpen then
        closeMenu()
    else
        openMenu()
    end
end)

closeBtn.MouseButton1Click:Connect(closeMenu)
minBtn.MouseButton1Click:Connect(closeMenu)

-- Button hovers
local function hoverBtn(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(48, 48, 64)
        }):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            TextColor3 = THEME.Text
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = THEME.Card
        }):Play()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            TextColor3 = THEME.SubText
        }):Play()
    end)
end

hoverBtn(closeBtn)
hoverBtn(minBtn)

-- Hover icon scale
icon.MouseEnter:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 60, 0, 60)
    }):Play()
end)

icon.MouseLeave:Connect(function()
    TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 54, 0, 54)
    }):Play()
end)

-- Animate gradient rotation
task.spawn(function()
    while task.wait() do
        strokeGrad.Rotation = (strokeGrad.Rotation + 1) % 360
        textGrad.Rotation = (textGrad.Rotation + 1) % 360
        RunService.RenderStepped:Wait()
    end
end)

print("[NOVA] Loaded.")
