-- NOVA Client GUI
-- Place in StarterPlayerScripts (LocalScript)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== CONFIG ====================
local CONFIG = {
    AccentColor = Color3.fromRGB(120, 90, 255),
    AccentColor2 = Color3.fromRGB(90, 200, 255),
    BackgroundColor = Color3.fromRGB(18, 18, 24),
    PanelColor = Color3.fromRGB(24, 24, 32),
    TextColor = Color3.fromRGB(240, 240, 245),
    SubTextColor = Color3.fromRGB(150, 150, 165),
    SwitchOff = Color3.fromRGB(60, 60, 75),
    SwitchOn = Color3.fromRGB(120, 90, 255),
}

-- ==================== STATS ====================
local state = {
    FPSBoost = false,
    AntiLag = false,
    AntiAFK = false,
}

-- ==================== GUI CREATION ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NOVA"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ==================== FLOATING ICON ====================
local floatingIcon = Instance.new("Frame")
floatingIcon.Name = "FloatingIcon"
floatingIcon.Size = UDim2.new(0, 56, 0, 56)
floatingIcon.Position = UDim2.new(0, 100, 0, 150)
floatingIcon.BackgroundColor3 = CONFIG.BackgroundColor
floatingIcon.BorderSizePixel = 0
floatingIcon.Active = true
floatingIcon.Draggable = true
floatingIcon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = floatingIcon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = CONFIG.AccentColor
iconStroke.Thickness = 2
iconStroke.Transparency = 0.2
iconStroke.Parent = floatingIcon

local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CONFIG.AccentColor),
    ColorSequenceKeypoint.new(1, CONFIG.AccentColor2),
})
iconGradient.Rotation = 45
iconGradient.Parent = iconStroke

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "N"
iconLabel.TextColor3 = CONFIG.TextColor
iconLabel.Font = Enum.Font.GothamBlack
iconLabel.TextSize = 26
iconLabel.Parent = floatingIcon

local iconGradientText = Instance.new("UIGradient")
iconGradientText.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CONFIG.AccentColor),
    ColorSequenceKeypoint.new(1, CONFIG.AccentColor2),
})
iconGradientText.Rotation = 45
iconGradientText.Parent = iconLabel

-- Glow effect (decorative)
local iconGlow = Instance.new("ImageLabel")
iconGlow.Size = UDim2.new(1, 30, 1, 30)
iconGlow.Position = UDim2.new(0, -15, 0, -15)
iconGlow.BackgroundTransparency = 1
iconGlow.Image = "rbxassetid://5028857472"
iconGlow.ImageColor3 = CONFIG.AccentColor
iconGlow.ImageTransparency = 0.7
iconGlow.ZIndex = 0
iconGlow.Parent = floatingIcon

-- ==================== MAIN MENU ====================
local mainMenu = Instance.new("Frame")
mainMenu.Name = "MainMenu"
mainMenu.Size = UDim2.new(0, 620, 0, 400)
mainMenu.Position = UDim2.new(0.5, -310, 0.5, -200)
mainMenu.BackgroundColor3 = CONFIG.BackgroundColor
mainMenu.BorderSizePixel = 0
mainMenu.Visible = false
mainMenu.ClipsDescendants = true
mainMenu.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 14)
menuCorner.Parent = mainMenu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(45, 45, 60)
menuStroke.Thickness = 1
menuStroke.Parent = mainMenu

local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
})
menuGradient.Rotation = 90
menuGradient.Parent = mainMenu

-- ==================== SIDEBAR ====================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 170, 1, 0)
sidebar.BackgroundColor3 = CONFIG.PanelColor
sidebar.BorderSizePixel = 0
sidebar.Parent = mainMenu

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 14)
sidebarCorner.Parent = sidebar

-- Hide right corners by using a cover
local sidebarCover = Instance.new("Frame")
sidebarCover.Size = UDim2.new(0, 20, 1, 0)
sidebarCover.Position = UDim2.new(1, -20, 0, 0)
sidebarCover.BackgroundColor3 = CONFIG.PanelColor
sidebarCover.BorderSizePixel = 0
sidebarCover.Parent = sidebar

-- Logo
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(1, 0, 0, 70)
logoFrame.BackgroundTransparency = 1
logoFrame.Parent = sidebar

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, -30, 1, 0)
logoText.Position = UDim2.new(0, 25, 0, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "NOVA"
logoText.TextColor3 = CONFIG.TextColor
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 24
logoText.TextXAlignment = Enum.TextXAlignment.Left
logoText.Parent = logoFrame

local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CONFIG.AccentColor),
    ColorSequenceKeypoint.new(1, CONFIG.AccentColor2),
})
logoGrad.Rotation = 45
logoGrad.Parent = logoText

-- Separator
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -30, 0, 1)
sep.Position = UDim2.new(0, 15, 0, 65)
sep.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
sep.BorderSizePixel = 0
sep.Parent = sidebar

-- Sidebar buttons container
local sidebarButtons = Instance.new("Frame")
sidebarButtons.Size = UDim2.new(1, 0, 1, -80)
sidebarButtons.Position = UDim2.new(0, 0, 0, 80)
sidebarButtons.BackgroundTransparency = 1
sidebarButtons.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebarButtons

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingLeft = UDim.new(0, 12)
sidebarPadding.PaddingRight = UDim.new(0, 12)
sidebarPadding.PaddingTop = UDim.new(0, 5)
sidebarPadding.Parent = sidebarButtons

-- ==================== TOP BAR (Minimize + Close) ====================
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -170, 0, 40)
topBar.Position = UDim2.new(0, 170, 0, 0)
topBar.BackgroundTransparency = 1
topBar.Parent = mainMenu

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "General"
titleLabel.TextColor3 = CONFIG.TextColor
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
closeBtn.Text = "✕"
closeBtn.TextColor3 = CONFIG.SubTextColor
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -72, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
minBtn.Text = "—"
minBtn.TextColor3 = CONFIG.SubTextColor
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.AutoButtonColor = false
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minBtn

-- ==================== CONTENT AREA ====================
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -170, 1, -40)
content.Position = UDim2.new(0, 170, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainMenu

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 15)
contentPadding.PaddingRight = UDim.new(0, 15)
contentPadding.PaddingTop = UDim.new(0, 5)
contentPadding.PaddingBottom = UDim.new(0, 15)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 10)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- ==================== TOGGLE FUNCTION ====================
local function createToggle(name, desc, order)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 58)
    toggleFrame.BackgroundColor3 = CONFIG.PanelColor
    toggleFrame.BorderSizePixel = 0
    toggleFrame.LayoutOrder = order
    toggleFrame.Parent = content

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleFrame

    local toggleStroke = Instance.new("UIStroke")
    toggleStroke.Color = Color3.fromRGB(45, 45, 60)
    toggleStroke.Thickness = 1
    toggleStroke.Parent = toggleFrame

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 22)
    title.Position = UDim2.new(0, 15, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = CONFIG.TextColor
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = toggleFrame

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -80, 0, 16)
    descLabel.Position = UDim2.new(0, 15, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = CONFIG.SubTextColor
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 11
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = toggleFrame

    -- Switch background
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 46, 0, 24)
    switchBg.Position = UDim2.new(1, -60, 0.5, -12)
    switchBg.BackgroundColor3 = CONFIG.SwitchOff
    switchBg.BorderSizePixel = 0
    switchBg.Parent = toggleFrame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchBg

    -- Switch knob
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = CONFIG.TextColor
    knob.BorderSizePixel = 0
    knob.Parent = switchBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    -- Click button
    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(1, 0, 1, 0)
    switchBtn.BackgroundTransparency = 1
    switchBtn.Text = ""
    switchBtn.Parent = switchBg

    local isOn = false

    local function animateSwitch(on)
        isOn = on
        state[name:gsub("%s", "")] = on

        if on then
            TweenService:Create(switchBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                BackgroundColor3 = CONFIG.SwitchOn
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                Position = UDim2.new(1, -21, 0.5, -9)
            }):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                BackgroundColor3 = CONFIG.SwitchOff
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0, 3, 0.5, -9)
            }):Play()
        end

        -- Apply function
        if name == "FPS Boost" then
            if on then
                if not Lighting:FindFirstChild("NOVA_FPSBoost") then
                    local bloom = Instance.new("BlurEffect")
                    bloom.Name = "NOVA_FPSBoost"
                    bloom.Size = 0
                    bloom.Parent = Lighting
                    
                    local atmosphere = Instance.new("Atmosphere")
                    atmosphere.Name = "NOVA_FPSBoost_Atm"
                    atmosphere.Density = 0
                    atmosphere.Parent = Lighting
                end
            else
                local b = Lighting:FindFirstChild("NOVA_FPSBoost")
                if b then b:Destroy() end
                local a = Lighting:FindFirstChild("NOVA_FPSBoost_Atm")
                if a then a:Destroy() end
            end
        elseif name == "Anti Lag" then
            if on then
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                        v.Enabled = false
                    end
                end
            end
        elseif name == "Anti AFK" then
            -- Anti AFK handled by connection below
        end
    end

    switchBtn.MouseButton1Click:Connect(function()
        animateSwitch(not isOn)
    end)

    -- Hover effect
    toggleFrame.MouseEnter:Connect(function()
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Color = CONFIG.AccentColor
        }):Play()
    end)

    toggleFrame.MouseLeave:Connect(function()
        TweenService:Create(toggleStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(45, 45, 60)
        }):Play()
    end)

    return toggleFrame
end

-- Create toggles
createToggle("FPS Boost", "Improve game performance", 1)
createToggle("Anti Lag", "Reduce visual lag spikes", 2)
createToggle("Anti AFK", "Prevent idle kick", 3)

-- ==================== ANTI AFK ====================
local antiAfkConnection
local function startAntiAfk()
    if antiAfkConnection then return end
    antiAfkConnection = player.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end

-- Hook Anti AFK toggle
task.spawn(function()
    while task.wait(0.2) do
        if state.AntiAFK then
            startAntiAfk()
        else
            stopAntiAfk()
        end
    end
end)

-- ==================== SIDEBAR TAB ====================
local function createSidebarTab(name, order)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(1, 0, 0, 36)
    tab.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    tab.BackgroundTransparency = 1
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.LayoutOrder = order
    tab.Parent = sidebarButtons

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tab

    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size = UDim2.new(1, -20, 1, 0)
    tabLabel.Position = UDim2.new(0, 15, 0, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Text = name
    tabLabel.TextColor3 = CONFIG.SubTextColor
    tabLabel.Font = Enum.Font.GothamMedium
    tabLabel.TextSize = 13
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tab

    -- active indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = CONFIG.AccentColor
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = tab

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(1, 0)
    indCorner.Parent = indicator

    tab.MouseEnter:Connect(function()
        if tabLabel.TextColor3 ~= CONFIG.TextColor then
            TweenService:Create(tabLabel, TweenInfo.new(0.15), {
                TextColor3 = Color3.fromRGB(200, 200, 215)
            }):Play()
        end
    end)

    tab.MouseLeave:Connect(function()
        if indicator.Visible == false then
            TweenService:Create(tabLabel, TweenInfo.new(0.15), {
                TextColor3 = CONFIG.SubTextColor
            }):Play()
        end
    end)

    tab.MouseButton1Click:Connect(function()
        for _, child in ipairs(sidebarButtons:GetChildren()) do
            if child:IsA("TextButton") then
                local lbl = child:FindFirstChildOfClass("TextLabel")
                local ind = child:FindFirstChild("Frame")
                if lbl then lbl.TextColor3 = CONFIG.SubTextColor end
                if ind and ind:IsA("Frame") then ind.Visible = false end
            end
        end
        tabLabel.TextColor3 = CONFIG.TextColor
        indicator.Visible = true
        titleLabel.Text = name
    end)

    return tab
end

local generalTab = createSidebarTab("General", 1)
-- Set active on start
task.defer(function()
    local lbl = generalTab:FindFirstChildOfClass("TextLabel")
    local ind = generalTab:FindFirstChild("Frame")
    if lbl then lbl.TextColor3 = CONFIG.TextColor end
    if ind then ind.Visible = true end
end)

-- ==================== OPEN/CLOSE ANIMATIONS ====================
local isOpen = false

local function openMenu()
    if isOpen then return end
    isOpen = true
    mainMenu.Visible = true
    mainMenu.Size = UDim2.new(0, 500, 0, 320)
    mainMenu.Position = UDim2.new(0.5, -250, 0.5, -160)

    TweenService:Create(mainMenu, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 620, 0, 400),
        Position = UDim2.new(0.5, -310, 0.5, -200)
    }):Play()

    -- Animate content fade in
    for _, v in ipairs(content:GetChildren()) do
        if v:IsA("Frame") then
            v.BackgroundTransparency = 1
            TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        end
    end
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    TweenService:Create(mainMenu, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 500, 0, 320),
        Position = UDim2.new(0.5, -250, 0.5, -160)
    }):Play()
    task.wait(0.25)
    mainMenu.Visible = false
end

floatingIcon.MouseButton1Click:Connect(function()
    if isOpen then
        closeMenu()
    else
        openMenu()
    end
end)

closeBtn.MouseButton1Click:Connect(closeMenu)

-- Minimize -> same as close but keep icon
minBtn.MouseButton1Click:Connect(function()
    closeMenu()
end)

-- Button hovers
local function buttonHover(btn, baseColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 70)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = baseColor
        }):Play()
    end)
end

buttonHover(closeBtn, Color3.fromRGB(35, 35, 45))
buttonHover(minBtn, Color3.fromRGB(35, 35, 45))

-- Floating icon hover
floatingIcon.MouseEnter:Connect(function()
    TweenService:Create(floatingIcon, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 60, 0, 60)
    }):Play()
end)

floatingIcon.MouseLeave:Connect(function()
    TweenService:Create(floatingIcon, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 56, 0, 56)
    }):Play()
end)

-- Gradient animation on floating icon
task.spawn(function()
    while task.wait() do
        for i = 0, 1, 0.02 do
            if iconGradient then
                iconGradient.Rotation = i * 360
                iconGradientText.Rotation = i * 360
            end
            RunService.RenderStepped:Wait()
        end
    end
end)

print("[NOVA] Loaded successfully.")