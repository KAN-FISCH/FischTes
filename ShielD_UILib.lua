--[[
    ShielD CustomHub UI Library (Unified & Full-Featured)
    - 100% Vector Asset Icons (FontAwesome / Lucide)
    - Flat 2D Modern Dark UI (Zero 3D Gradients, Zero Lighting Blur)
    - Real-Time Live Search (Filters all components instantly)
    - Searchable Floating Dropdown (Single & Multi-Select with live filter)
    - High-Contrast Visible Input Boxes & Sliders
    - Full Dual API: CustomHub API & Speed_Library/Fluent API Compatibility
    - Sleek Toast Notification System
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local function generateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:',.<>/?`~"
    local str = {}
    for i = 1, length do
        local randIndex = math.random(1, #chars)
        str[i] = string.sub(chars, randIndex, randIndex)
    end
    return table.concat(str)
end

local function getSafeUIParent()
    if RunService:IsStudio() then
        return LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    end
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
end

local function CreateProtectedScreenGui(customName)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = customName or generateRandomString(32)
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    
    local parent = getSafeUIParent()
    if parent then
        ScreenGui.Parent = parent
    end
    
    pcall(function()
        ProtectGui(ScreenGui)
    end)
    
    task.defer(function()
        if ScreenGui and ScreenGui.Parent then
            ScreenGui.Enabled = true
        end
    end)
    
    return ScreenGui
end

local Library = {
    CurrentTab = nil,
    Flags = {},
    ActiveDropdown = nil,
}

-- Vector Icons (Lucide & FontAwesome asset mappings)
local ICONS = {
    ["zap"]          = "rbxassetid://10709789810",
    ["lightning"]    = "rbxassetid://10709789810",
    ["settings"]     = "rbxassetid://10734975692",
    ["gear"]         = "rbxassetid://10734975692",
    ["swords"]       = "rbxassetid://10734975486",
    ["combat"]       = "rbxassetid://10734975486",
    ["user"]         = "rbxassetid://10747373176",
    ["player"]       = "rbxassetid://10747373176",
    ["eye"]          = "rbxassetid://10723346959",
    ["visuals"]      = "rbxassetid://10723346959",
    ["search"]       = "rbxassetid://10734943674",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["check"]        = "rbxassetid://10709790644",
    ["close"]        = "rbxassetid://10747384394",
    ["minus"]        = "rbxassetid://10734896206",
    ["maximize"]     = "rbxassetid://10734886780",
    ["info"]         = "rbxassetid://10723415903",
    ["fish"]         = "rbxassetid://10709789810",
    ["shop"]         = "rbxassetid://10747372702",
    ["cart"]         = "rbxassetid://10747372702",
    ["crown"]        = "rbxassetid://10747372167",
    ["vip"]          = "rbxassetid://10747372167",
    ["gem"]          = "rbxassetid://10723356507",
    ["sparkles"]     = "rbxassetid://10734960100",
    ["map"]          = "rbxassetid://10723407389",
    ["pin"]          = "rbxassetid://10723407389",
    ["bell"]         = "rbxassetid://10723415903",
    ["hammer"]       = "rbxassetid://10734951339",
    ["mine"]         = "rbxassetid://10734951339",
    ["save"]         = "rbxassetid://10734952671",
    ["coins"]        = "rbxassetid://10709769508",
    ["scroll"]       = "rbxassetid://10723424838",
    ["anchor"]       = "rbxassetid://10709775084",
}

local THEME = {
    Background = Color3.fromRGB(24, 24, 28),
    BackgroundTransparency = 0.12,
    
    Card = Color3.fromRGB(34, 34, 40),
    CardTransparency = 0.2,
    CardBorder = Color3.fromRGB(60, 60, 72),
    CardBorderTransparency = 0.6,
    
    WindowBorder = Color3.fromRGB(68, 68, 80),
    WindowBorderTransparency = 0.65,
    
    Accent = Color3.fromRGB(168, 85, 247),       -- Purple #a855f7
    AccentDark = Color3.fromRGB(147, 51, 234),   -- #9333ea
    AccentGlow = Color3.fromRGB(192, 132, 252),   -- #c084fc
    
    Text = Color3.fromRGB(248, 248, 252),
    TextMuted = Color3.fromRGB(165, 168, 180),
    TextDark = Color3.fromRGB(115, 120, 135),
    
    TabActive = Color3.fromRGB(50, 50, 58),
    TabHover = Color3.fromRGB(36, 36, 44),
    
    ToggleTrackOff = Color3.fromRGB(52, 52, 60),
    SliderTrack = Color3.fromRGB(48, 48, 58),
    
    InputBackground = Color3.fromRGB(46, 46, 54),
    InputBackgroundTransparency = 0,
    InputBorder = Color3.fromRGB(80, 80, 96),
    InputBorderTransparency = 0.35,
    Placeholder = Color3.fromRGB(165, 168, 182),
    
    DropdownMenuBg = Color3.fromRGB(30, 30, 36),
    DropdownItemHover = Color3.fromRGB(45, 45, 55),
    
    FontBold = Enum.Font.GothamBold,
    FontSemiBold = Enum.Font.GothamSemibold,
    FontRegular = Enum.Font.Gotham,
}

local function CreateTween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function GetIconAsset(iconInput)
    if not iconInput or iconInput == "" then return ICONS["settings"] end
    local lower = tostring(iconInput):lower()
    if ICONS[lower] then
        return ICONS[lower]
    elseif tostring(iconInput):find("rbxassetid://") or tostring(iconInput):find("http") then
        return tostring(iconInput)
    end
    return ICONS["settings"]
end

local function CreateIconImage(iconInput, parent, size, color)
    local assetId = GetIconAsset(iconInput)
    if assetId == "" then return nil end
    local img = Instance.new("ImageLabel")
    img.Name = "Icon_" .. tostring(iconInput)
    img.Size = size or UDim2.fromOffset(16, 16)
    img.BackgroundTransparency = 1
    img.Image = assetId
    img.ImageColor3 = color or THEME.TextMuted
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = parent
    return img
end

local function MakeDraggable(dragBar, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local scale = 1
            local scaleObj = mainFrame:FindFirstChildOfClass("UIScale")
            if scaleObj and scaleObj.Scale > 0 then
                scale = scaleObj.Scale
            end
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + (delta.X / scale),
                startPos.Y.Scale,
                startPos.Y.Offset + (delta.Y / scale)
            )
        end
    end)
end

-- Global Notifications container
local NotificationGui = nil
function Library:SetNotification(notifConfig)
    notifConfig = notifConfig or {}
    local nTitle = notifConfig.Title or "Notification"
    local nContent = notifConfig.Content or notifConfig.Text or ""
    local nDelay = notifConfig.Delay or notifConfig.Time or 3.5

    if not NotificationGui or not NotificationGui.Parent then
        NotificationGui = CreateProtectedScreenGui()
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Name = "Toast"
    NotifFrame.Size = UDim2.fromOffset(260, 64)
    NotifFrame.Position = UDim2.new(1, 20, 1, -80)
    NotifFrame.BackgroundColor3 = THEME.Background
    NotifFrame.BorderSizePixel = 0
    NotifFrame.ZIndex = 200
    NotifFrame.Parent = NotificationGui

    local NCorner = Instance.new("UICorner")
    NCorner.CornerRadius = UDim.new(0, 10)
    NCorner.Parent = NotifFrame

    local NStroke = Instance.new("UIStroke")
    NStroke.Color = THEME.Accent
    NStroke.Transparency = 0.5
    NStroke.Thickness = 1
    NStroke.Parent = NotifFrame

    local NTitle = Instance.new("TextLabel")
    NTitle.Size = UDim2.new(1, -20, 0, 20)
    NTitle.Position = UDim2.fromOffset(12, 10)
    NTitle.BackgroundTransparency = 1
    NTitle.Font = THEME.FontBold
    NTitle.Text = nTitle
    NTitle.TextColor3 = THEME.AccentGlow
    NTitle.TextSize = 13
    NTitle.TextXAlignment = Enum.TextXAlignment.Left
    NTitle.ZIndex = 201
    NTitle.Parent = NotifFrame

    local NContent = Instance.new("TextLabel")
    NContent.Size = UDim2.new(1, -20, 0, 26)
    NContent.Position = UDim2.fromOffset(12, 30)
    NContent.BackgroundTransparency = 1
    NContent.Font = THEME.FontRegular
    NContent.Text = nContent
    NContent.TextColor3 = THEME.Text
    NContent.TextSize = 11.5
    NContent.TextWrapped = true
    NContent.TextXAlignment = Enum.TextXAlignment.Left
    NContent.ZIndex = 201
    NContent.Parent = NotifFrame

    CreateTween(NotifFrame, { Position = UDim2.new(1, -280, 1, -80) }, 0.25)

    task.delay(nDelay, function()
        CreateTween(NotifFrame, { Position = UDim2.new(1, 20, 1, -80), BackgroundTransparency = 1 }, 0.25).Completed:Connect(function()
            NotifFrame:Destroy()
        end)
    end)
end

function Library:Notify(config)
    Library:SetNotification(config)
end

function Library:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "CustomHub | Roblox UI"
    local windowIcon = config.Icon or "zap"
    local windowSize = config.Size or config.SizeUi or UDim2.fromOffset(680, 420)

    -- ScreenGui (Anti-Detect Protected GUI)
    if getgenv().__ShielD_ScreenGui then
        pcall(function() getgenv().__ShielD_ScreenGui:Destroy() end)
    end

    local ScreenGui = CreateProtectedScreenGui()
    getgenv().__ShielD_ScreenGui = ScreenGui

    -- Floating Dropdown Overlay Container
    local FloatingOverlay = Instance.new("Frame")
    FloatingOverlay.Name = "FloatingOverlay"
    FloatingOverlay.Size = UDim2.fromScale(1, 1)
    FloatingOverlay.BackgroundTransparency = 1
    FloatingOverlay.ZIndex = 100
    FloatingOverlay.Parent = ScreenGui

    -- Main Window Outer Frame (Adaptive & Responsive for Mobile & PC)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, -197)
    MainFrame.Size = UDim2.fromOffset(660, 395)
    MainFrame.BackgroundColor3 = THEME.Background
    MainFrame.BackgroundTransparency = THEME.BackgroundTransparency
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainUIScale = Instance.new("UIScale")
    MainUIScale.Name = "MainUIScale"
    MainUIScale.Parent = MainFrame

    local function updateResponsiveScale()
        local camera = workspace.CurrentCamera
        local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)

        local baseW = 660
        local baseH = 395

        -- Leave safe margin around screen boundaries
        local maxW = math.max(viewportSize.X - 32, 240)
        local maxH = math.max(viewportSize.Y - 32, 160)

        local scaleX = maxW / baseW
        local scaleY = maxH / baseH
        local fitScale = math.min(scaleX, scaleY, 1)

        -- If mobile touch screen or smaller resolution
        if UserInputService.TouchEnabled or viewportSize.X < 780 or viewportSize.Y < 480 then
            MainUIScale.Scale = math.clamp(fitScale, 0.45, 0.95)
        else
            MainUIScale.Scale = math.clamp(fitScale, 0.60, 1.0)
        end
    end

    updateResponsiveScale()

    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveScale)
    end

    -- Floating Mobile Toggle Button (Draggable)
    local MobileToggleBtn = Instance.new("ImageButton")
    MobileToggleBtn.Name = "MobileToggleBtn"
    MobileToggleBtn.Size = UDim2.fromOffset(40, 40)
    MobileToggleBtn.Position = UDim2.new(0, 14, 0, 60)
    MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
    MobileToggleBtn.BackgroundTransparency = 0.2
    MobileToggleBtn.AutoButtonColor = false
    MobileToggleBtn.ZIndex = 250
    MobileToggleBtn.Parent = ScreenGui

    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(0, 12)
    MobileCorner.Parent = MobileToggleBtn

    local MobileStroke = Instance.new("UIStroke")
    MobileStroke.Color = THEME.Accent
    MobileStroke.Thickness = 1.5
    MobileStroke.Parent = MobileToggleBtn

    local MobileIcon = Instance.new("ImageLabel")
    MobileIcon.Size = UDim2.fromOffset(22, 22)
    MobileIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    MobileIcon.Position = UDim2.fromScale(0.5, 0.5)
    MobileIcon.BackgroundTransparency = 1
    MobileIcon.Image = GetIconAsset("zap")
    MobileIcon.ImageColor3 = THEME.Accent
    MobileIcon.Parent = MobileToggleBtn

    MakeDraggable(MobileToggleBtn, MobileToggleBtn)

    local isUiVisible = true
    MobileToggleBtn.MouseButton1Click:Connect(function()
        isUiVisible = not isUiVisible
        MainFrame.Visible = isUiVisible
    end)

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = THEME.WindowBorder
    MainStroke.Transparency = THEME.WindowBorderTransparency
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- Outer Ambient Drop Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.fromScale(0.5, 0.5)
    Shadow.Size = UDim2.new(1, 48, 1, 48)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://6014261993"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.4
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    Shadow.ZIndex = MainFrame.ZIndex - 1
    Shadow.Parent = MainFrame

    -- Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 46)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.Parent = MainFrame

    MakeDraggable(HeaderBar, MainFrame)

    -- Left Header (Purple Bolt + Title)
    local TitleContainer = Instance.new("Frame")
    TitleContainer.Name = "TitleContainer"
    TitleContainer.Size = UDim2.new(1, -120, 1, 0)
    TitleContainer.Position = UDim2.fromOffset(18, 0)
    TitleContainer.BackgroundTransparency = 1
    TitleContainer.Parent = HeaderBar

    local TitleLayout = Instance.new("UIListLayout")
    TitleLayout.FillDirection = Enum.FillDirection.Horizontal
    TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TitleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TitleLayout.Padding = UDim.new(0, 8)
    TitleLayout.Parent = TitleContainer

    local HeaderIcon = CreateIconImage(windowIcon, TitleContainer, UDim2.fromOffset(18, 18), THEME.Accent)
    if HeaderIcon then HeaderIcon.LayoutOrder = 1 end

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 360, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = THEME.FontBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = THEME.Text
    TitleLabel.TextSize = 14.5
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.LayoutOrder = 2
    TitleLabel.Parent = TitleContainer

    -- Window Controls (Minimize, Maximize, Close)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.fromOffset(82, 46)
    Controls.Position = UDim2.new(1, -96, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.Parent = HeaderBar

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 5)
    ControlsLayout.Parent = Controls

    local function CreateControlButton(iconName, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(22, 22)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = Controls

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local btnIcon = CreateIconImage(iconName, btn, UDim2.fromOffset(12, 12), THEME.TextMuted)
        if btnIcon then
            btnIcon.AnchorPoint = Vector2.new(0.5, 0.5)
            btnIcon.Position = UDim2.fromScale(0.5, 0.5)
        end

        btn.MouseEnter:Connect(function()
            CreateTween(btn, { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(55, 55, 65) }, 0.15)
            if btnIcon then CreateTween(btnIcon, { ImageColor3 = THEME.Text }, 0.15) end
        end)
        btn.MouseLeave:Connect(function()
            CreateTween(btn, { BackgroundTransparency = 1 }, 0.15)
            if btnIcon then CreateTween(btnIcon, { ImageColor3 = THEME.TextMuted }, 0.15) end
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- Body Container
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, -28, 1, -56)
    Body.Position = UDim2.fromOffset(14, 46)
    Body.BackgroundTransparency = 1
    Body.ClipsDescendants = false
    Body.Parent = MainFrame

    local isMinimized = false
    CreateControlButton("minus", function()
        isMinimized = not isMinimized
        if isMinimized then
            Body.Visible = false
            MainFrame.ClipsDescendants = true
            CreateTween(MainFrame, { Size = UDim2.fromOffset(660, 46) }, 0.2)
        else
            local tw = CreateTween(MainFrame, { Size = UDim2.fromOffset(660, 395) }, 0.2)
            tw.Completed:Connect(function()
                if not isMinimized then
                    Body.Visible = true
                    MainFrame.ClipsDescendants = false
                end
            end)
        end
    end)

    CreateControlButton("maximize", function() end)

    CreateControlButton("close", function()
        CreateTween(MainFrame, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, 0.2).Completed:Connect(function()
            ScreenGui:Destroy()
        end)
    end)

    -- Left Sidebar (Tabs)
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 120, 1, 0)
    Sidebar.BackgroundTransparency = 1
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 0
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.Parent = Body

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.FillDirection = Enum.FillDirection.Vertical
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 5)
    SidebarLayout.Parent = Sidebar

    -- Right Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -132, 1, 0)
    ContentContainer.Position = UDim2.fromOffset(128, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.ClipsDescendants = false
    ContentContainer.Parent = Body

    local WindowObj = {
        Tabs = {},
        CurrentTab = nil,
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        FloatingOverlay = FloatingOverlay,
    }

    local function isPointInFrame(guiObj, point)
        if not (guiObj and guiObj.Parent and guiObj.Visible) then return false end
        local absPos = guiObj.AbsolutePosition
        local absSize = guiObj.AbsoluteSize
        return point.X >= absPos.X and point.X <= (absPos.X + absSize.X)
           and point.Y >= absPos.Y and point.Y <= (absPos.Y + absSize.Y)
    end

    -- Close floating dropdown ONLY when clicking outside of the dropdown menu and button
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local active = Library.ActiveDropdown
            if active and active.Menu and active.Menu.Visible then
                local point = Vector2.new(input.Position.X, input.Position.Y)
                local inMenu = isPointInFrame(active.Menu, point)
                local inBtn = isPointInFrame(active.Btn, point)
                if not inMenu and not inBtn then
                    active.Close()
                end
            end
        end
    end)

    -- TAB CREATION
    function WindowObj:CreateTab(tabConfig)
        if type(tabConfig) == "table" and tabConfig[1] then
            tabConfig = {
                Name = tabConfig[1],
                Icon = tabConfig[2] or "settings",
                Description = tabConfig[3] or ""
            }
        end

        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIcon = tabConfig.Icon
        if not tabIcon or tabIcon == "" or tabIcon == "settings" then
            local lowerName = tabName:lower()
            if lowerName:find("info") then tabIcon = "info"
            elseif lowerName:find("fish") then tabIcon = "zap"
            elseif lowerName:find("shop") or lowerName:find("merlin") or lowerName:find("rod") then tabIcon = "shop"
            elseif lowerName:find("vip") or lowerName:find("server") then tabIcon = "crown"
            elseif lowerName:find("exclus") or lowerName:find("mine") then tabIcon = "gem"
            elseif lowerName:find("auto") or lowerName:find("farm") then tabIcon = "gear"
            elseif lowerName:find("area") or lowerName:find("tp") or lowerName:find("teleport") then tabIcon = "map"
            elseif lowerName:find("esp") or lowerName:find("visual") then tabIcon = "eye"
            elseif lowerName:find("misc") or lowerName:find("player") then tabIcon = "user"
            elseif lowerName:find("setting") then tabIcon = "settings"
            else tabIcon = "settings"
            end
        end

        local TabButton = Instance.new("TextButton")
        TabButton.Name = "Tab_" .. tabName
        TabButton.Size = UDim2.new(1, -6, 0, 36)
        TabButton.BackgroundColor3 = THEME.TabActive
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.Parent = Sidebar

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 10)
        TabBtnCorner.Parent = TabButton

        local TabBtnLayout = Instance.new("UIListLayout")
        TabBtnLayout.FillDirection = Enum.FillDirection.Horizontal
        TabBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        TabBtnLayout.Padding = UDim.new(0, 9)
        TabBtnLayout.Parent = TabButton

        local TabPadding = Instance.new("UIPadding")
        TabPadding.PaddingLeft = UDim.new(0, 10)
        TabPadding.Parent = TabButton

        local TabIconImg = CreateIconImage(tabIcon, TabButton, UDim2.fromOffset(16, 16), THEME.TextMuted)

        local TabTextLabel = Instance.new("TextLabel")
        TabTextLabel.Name = "Label"
        TabTextLabel.Size = UDim2.new(1, -34, 1, 0)
        TabTextLabel.BackgroundTransparency = 1
        TabTextLabel.Font = THEME.FontBold
        TabTextLabel.Text = tabName
        TabTextLabel.TextColor3 = THEME.TextMuted
        TabTextLabel.TextSize = 13
        TabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabTextLabel.Parent = TabButton

        -- Content Page Frame
        local TabPage = Instance.new("Frame")
        TabPage.Name = "Page_" .. tabName
        TabPage.Size = UDim2.fromScale(1, 1)
        TabPage.BackgroundTransparency = 1
        TabPage.Visible = false
        TabPage.ClipsDescendants = false
        TabPage.Parent = ContentContainer

        -- 2-Column Side-by-Side Container
        local ColumnsContainer = Instance.new("Frame")
        ColumnsContainer.Name = "ColumnsContainer"
        ColumnsContainer.Size = UDim2.fromScale(1, 1)
        ColumnsContainer.BackgroundTransparency = 1
        ColumnsContainer.Parent = TabPage

        local ColLayout = Instance.new("UIListLayout")
        ColLayout.FillDirection = Enum.FillDirection.Horizontal
        ColLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ColLayout.Padding = UDim.new(0, 8)
        ColLayout.Parent = ColumnsContainer

        -- Left Independent Scrolling Column
        local LeftColumn = Instance.new("ScrollingFrame")
        LeftColumn.Name = "LeftColumn"
        LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
        LeftColumn.BackgroundTransparency = 1
        LeftColumn.BorderSizePixel = 0
        LeftColumn.ScrollBarThickness = 2
        LeftColumn.ScrollBarImageColor3 = THEME.Accent
        LeftColumn.ScrollBarImageTransparency = 0.4
        LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
        LeftColumn.ClipsDescendants = true
        LeftColumn.LayoutOrder = 1
        LeftColumn.Parent = ColumnsContainer

        local LeftPadding = Instance.new("UIPadding")
        LeftPadding.PaddingRight = UDim.new(0, 4)
        LeftPadding.PaddingBottom = UDim.new(0, 12)
        LeftPadding.Parent = LeftColumn

        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.FillDirection = Enum.FillDirection.Vertical
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Padding = UDim.new(0, 10)
        LeftLayout.Parent = LeftColumn

        -- Right Independent Scrolling Column
        local RightColumn = Instance.new("ScrollingFrame")
        RightColumn.Name = "RightColumn"
        RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
        RightColumn.BackgroundTransparency = 1
        RightColumn.BorderSizePixel = 0
        RightColumn.ScrollBarThickness = 2
        RightColumn.ScrollBarImageColor3 = THEME.Accent
        RightColumn.ScrollBarImageTransparency = 0.4
        RightColumn.CanvasSize = UDim2.new(0, 0, 0, 0)
        RightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
        RightColumn.ClipsDescendants = true
        RightColumn.LayoutOrder = 2
        RightColumn.Parent = ColumnsContainer

        local RightPadding = Instance.new("UIPadding")
        RightPadding.PaddingRight = UDim.new(0, 4)
        RightPadding.PaddingBottom = UDim.new(0, 12)
        RightPadding.Parent = RightColumn

        local RightLayout = Instance.new("UIListLayout")
        RightLayout.FillDirection = Enum.FillDirection.Vertical
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.Parent = RightColumn

        local TabObj = {
            Button = TabButton,
            Page = TabPage,
            LeftCol = LeftColumn,
            RightCol = RightColumn,
            Icon = TabIconImg,
            Label = TabTextLabel,
            Elements = {},
            Unlock = function() end,
            Lock = function() end,
        }

        local function ActivateTab()
            for _, t in pairs(WindowObj.Tabs) do
                t.Page.Visible = false
                CreateTween(t.Button, { BackgroundTransparency = 1 }, 0.2)
                if t.Icon then CreateTween(t.Icon, { ImageColor3 = THEME.TextMuted }, 0.2) end
                CreateTween(t.Label, { TextColor3 = THEME.TextMuted }, 0.2)
            end
            TabPage.Visible = true
            CreateTween(TabButton, { BackgroundTransparency = 0 }, 0.2)
            if TabIconImg then CreateTween(TabIconImg, { ImageColor3 = THEME.Text }, 0.2) end
            CreateTween(TabTextLabel, { TextColor3 = THEME.Text }, 0.2)
            WindowObj.CurrentTab = TabObj
        end

        TabButton.MouseEnter:Connect(function()
            if WindowObj.CurrentTab ~= TabObj then
                CreateTween(TabButton, { BackgroundTransparency = 0.5, BackgroundColor3 = THEME.TabHover }, 0.15)
                if TabIconImg then CreateTween(TabIconImg, { ImageColor3 = THEME.Text }, 0.15) end
                CreateTween(TabTextLabel, { TextColor3 = THEME.Text }, 0.15)
            end
        end)

        TabButton.MouseLeave:Connect(function()
            if WindowObj.CurrentTab ~= TabObj then
                CreateTween(TabButton, { BackgroundTransparency = 1 }, 0.15)
                if TabIconImg then CreateTween(TabIconImg, { ImageColor3 = THEME.TextMuted }, 0.15) end
                CreateTween(TabTextLabel, { TextColor3 = THEME.TextMuted }, 0.15)
            end
        end)

        TabButton.MouseButton1Click:Connect(ActivateTab)
        table.insert(WindowObj.Tabs, TabObj)

        if #WindowObj.Tabs == 1 then
            ActivateTab()
        end

        -- SECTION / CARD CREATION (Flat 2D Rounded Card)
        function TabObj:CreateSection(secConfig, _open, _side)
            if type(secConfig) == "string" then
                secConfig = { Title = secConfig }
            end
            secConfig = secConfig or {}
            local secTitle = secConfig.Title or "Section"
            local secIcon = secConfig.Icon
            if not secIcon or secIcon == "" or secIcon == "settings" or secIcon == "swords" then
                local lowerTitle = secTitle:lower()
                if lowerTitle:find("exclusive") or lowerTitle:find("cosmic") then secIcon = "sparkles"
                elseif lowerTitle:find("mine") or lowerTitle:find("dripstone") then secIcon = "hammer"
                elseif lowerTitle:find("save") or lowerTitle:find("config") then secIcon = "save"
                elseif lowerTitle:find("fish") or lowerTitle:find("cast") or lowerTitle:find("reel") or lowerTitle:find("bobber") then secIcon = "zap"
                elseif lowerTitle:find("shop") or lowerTitle:find("bait") or lowerTitle:find("rod") or lowerTitle:find("merlin") or lowerTitle:find("item") then secIcon = "shop"
                elseif lowerTitle:find("esp") or lowerTitle:find("visual") or lowerTitle:find("character") then secIcon = "eye"
                elseif lowerTitle:find("quest") or lowerTitle:find("task") or lowerTitle:find("shady") then secIcon = "scroll"
                elseif lowerTitle:find("treasure") or lowerTitle:find("chest") or lowerTitle:find("appraise") or lowerTitle:find("enchant") or lowerTitle:find("fav") then secIcon = "gem"
                elseif lowerTitle:find("sell") or lowerTitle:find("money") then secIcon = "coins"
                elseif lowerTitle:find("totem") or lowerTitle:find("aura") then secIcon = "zap"
                elseif lowerTitle:find("teleport") or lowerTitle:find("area") or lowerTitle:find("zone") or lowerTitle:find("npc") or lowerTitle:find("ballon") or lowerTitle:find("main") or lowerTitle:find("positon") then secIcon = "map"
                elseif lowerTitle:find("server") or lowerTitle:find("vip") then secIcon = "crown"
                elseif lowerTitle:find("info") or lowerTitle:find("event") or lowerTitle:find("credit") then secIcon = "info"
                elseif lowerTitle:find("player") or lowerTitle:find("misc") or lowerTitle:find("walkspeed") then secIcon = "user"
                else secIcon = "settings"
                end
            end
            local secDesc = secConfig.Description or nil
            local rightText = secConfig.RightText or nil

            local targetSide = _side or (type(secConfig) == "table" and (secConfig.Side or secConfig[3]))
            local isRight = false
            if targetSide then
                if type(targetSide) == "string" and targetSide:lower():find("right") then
                    isRight = true
                end
            else
                local leftCount = #LeftColumn:GetChildren() - 1
                local rightCount = #RightColumn:GetChildren() - 1
                if rightCount < leftCount then
                    isRight = true
                end
            end

            local parentCol = isRight and RightColumn or LeftColumn

            local SectionCard = Instance.new("Frame")
            SectionCard.Name = "Card_" .. secTitle
            SectionCard.Size = UDim2.new(1, 0, 0, 0)
            SectionCard.AutomaticSize = Enum.AutomaticSize.Y
            SectionCard.BackgroundColor3 = THEME.Card
            SectionCard.BackgroundTransparency = THEME.CardTransparency
            SectionCard.BorderSizePixel = 0
            SectionCard.ClipsDescendants = false
            SectionCard.Parent = parentCol

            local CardCorner = Instance.new("UICorner")
            CardCorner.CornerRadius = UDim.new(0, 12)
            CardCorner.Parent = SectionCard

            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = THEME.CardBorder
            CardStroke.Transparency = THEME.CardBorderTransparency
            CardStroke.Thickness = 1
            CardStroke.Parent = SectionCard

            local CardPadding = Instance.new("UIPadding")
            CardPadding.PaddingTop = UDim.new(0, 11)
            CardPadding.PaddingBottom = UDim.new(0, 12)
            CardPadding.PaddingLeft = UDim.new(0, 12)
            CardPadding.PaddingRight = UDim.new(0, 12)
            CardPadding.Parent = SectionCard

            local CardLayout = Instance.new("UIListLayout")
            CardLayout.FillDirection = Enum.FillDirection.Vertical
            CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
            CardLayout.Padding = UDim.new(0, 9)
            CardLayout.Parent = SectionCard

            -- Section Header Bar
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Name = "Header"
            HeaderFrame.Size = UDim2.new(1, 0, 0, 20)
            HeaderFrame.BackgroundTransparency = 1
            HeaderFrame.LayoutOrder = 1
            HeaderFrame.Parent = SectionCard

            local LeftHeader = Instance.new("Frame")
            LeftHeader.Size = UDim2.new(1, -90, 1, 0)
            LeftHeader.BackgroundTransparency = 1
            LeftHeader.Parent = HeaderFrame

            local HeaderLayout = Instance.new("UIListLayout")
            HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
            HeaderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            HeaderLayout.Padding = UDim.new(0, 7)
            HeaderLayout.Parent = LeftHeader

            CreateIconImage(secIcon, LeftHeader, UDim2.fromOffset(15, 15), THEME.TextMuted)

            local SecTitleLabel = Instance.new("TextLabel")
            SecTitleLabel.Size = UDim2.new(1, -25, 1, 0)
            SecTitleLabel.BackgroundTransparency = 1
            SecTitleLabel.Font = THEME.FontBold
            SecTitleLabel.Text = secTitle
            SecTitleLabel.TextColor3 = THEME.Text
            SecTitleLabel.TextSize = 13.5
            SecTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            SecTitleLabel.Parent = LeftHeader

            local RightTextLabel = nil
            if rightText then
                RightTextLabel = Instance.new("TextLabel")
                RightTextLabel.Name = "RightText"
                RightTextLabel.Size = UDim2.fromOffset(110, 20)
                RightTextLabel.Position = UDim2.new(1, -110, 0, 0)
                RightTextLabel.BackgroundTransparency = 1
                RightTextLabel.Font = THEME.FontBold
                RightTextLabel.Text = rightText
                RightTextLabel.TextColor3 = THEME.Text
                RightTextLabel.TextSize = 13
                RightTextLabel.TextXAlignment = Enum.TextXAlignment.Right
                RightTextLabel.Parent = HeaderFrame
            end

            -- Description text (if provided)
            if secDesc then
                local DescLabel = Instance.new("TextLabel")
                DescLabel.Name = "Description"
                DescLabel.Size = UDim2.new(1, 0, 0, 0)
                DescLabel.AutomaticSize = Enum.AutomaticSize.Y
                DescLabel.BackgroundTransparency = 1
                DescLabel.Font = THEME.FontRegular
                DescLabel.Text = secDesc
                DescLabel.TextColor3 = THEME.TextMuted
                DescLabel.TextSize = 11.5
                DescLabel.TextWrapped = true
                DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                DescLabel.LayoutOrder = 2
                DescLabel.Parent = SectionCard
            end

            local SecObj = {
                Card = SectionCard,
                RightLabel = RightTextLabel,
            }

            -- ROW: LIVE SEARCH & DROPDOWN SIDE-BY-SIDE
            function SecObj:CreateSearchAndDropdown(rowConfig)
                rowConfig = rowConfig or {}
                local searchPlaceholder = rowConfig.SearchPlaceholder or "Search options..."
                local dropName = rowConfig.DropdownName or "Pilih Mode"
                local dropOptions = rowConfig.Options or { "Default" }
                local dropDefault = rowConfig.Default or dropOptions[1]
                local onSearch = rowConfig.OnSearch or function() end
                local onSelect = rowConfig.OnSelect or function() end

                local RowFrame = Instance.new("Frame")
                RowFrame.Name = "Row_SearchDropdown"
                RowFrame.Size = UDim2.new(1, 0, 0, 34)
                RowFrame.BackgroundTransparency = 1
                RowFrame.LayoutOrder = 10
                RowFrame.Parent = SectionCard

                -- Left Search Input (52% width)
                local InputBoxFrame = Instance.new("Frame")
                InputBoxFrame.Name = "InputBox"
                InputBoxFrame.Size = UDim2.new(0.52, -6, 1, 0)
                InputBoxFrame.BackgroundColor3 = THEME.InputBackground
                InputBoxFrame.BackgroundTransparency = THEME.InputBackgroundTransparency
                InputBoxFrame.Parent = RowFrame

                local IBCorner = Instance.new("UICorner")
                IBCorner.CornerRadius = UDim.new(0, 8)
                IBCorner.Parent = InputBoxFrame

                local IBStroke = Instance.new("UIStroke")
                IBStroke.Color = THEME.InputBorder
                IBStroke.Transparency = THEME.InputBorderTransparency
                IBStroke.Thickness = 1
                IBStroke.Parent = InputBoxFrame

                local SearchIcon = CreateIconImage("search", InputBoxFrame, UDim2.fromOffset(15, 15), THEME.Placeholder)
                if SearchIcon then
                    SearchIcon.AnchorPoint = Vector2.new(1, 0.5)
                    SearchIcon.Position = UDim2.new(1, -10, 0.5, 0)
                end

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -38, 1, 0)
                TextBox.Position = UDim2.fromOffset(10, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Font = THEME.FontRegular
                TextBox.PlaceholderText = searchPlaceholder
                TextBox.PlaceholderColor3 = THEME.Placeholder
                TextBox.Text = ""
                TextBox.TextColor3 = THEME.Text
                TextBox.TextSize = 12.5
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.Parent = InputBoxFrame

                -- LIVE SEARCH FILTERING ACROSS ALL COMPONENTS
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local query = TextBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
                    for _, elem in ipairs(TabObj.Elements) do
                        if elem.Frame and elem.Frame.Parent then
                            if query == "" then
                                elem.Frame.Visible = true
                            else
                                local match = (elem.Name and elem.Name:lower():find(query, 1, true)) ~= nil
                                elem.Frame.Visible = match
                            end
                        end
                    end
                    pcall(onSearch, TextBox.Text)
                end)

                -- Right Dropdown (48% width)
                local currentOption = dropDefault

                local DropContainer = Instance.new("Frame")
                DropContainer.Name = "Dropdown"
                DropContainer.Size = UDim2.new(0.48, 0, 1, 0)
                DropContainer.Position = UDim2.new(0.52, 6, 0, 0)
                DropContainer.BackgroundTransparency = 1
                DropContainer.Parent = RowFrame

                local DropLayout = Instance.new("UIListLayout")
                DropLayout.FillDirection = Enum.FillDirection.Horizontal
                DropLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                DropLayout.Padding = UDim.new(0, 6)
                DropLayout.Parent = DropContainer

                local LabelText = Instance.new("TextLabel")
                LabelText.Size = UDim2.new(0, 68, 1, 0)
                LabelText.BackgroundTransparency = 1
                LabelText.Font = THEME.FontBold
                LabelText.Text = dropName .. ":"
                LabelText.TextColor3 = THEME.Text
                LabelText.TextSize = 12
                LabelText.TextXAlignment = Enum.TextXAlignment.Left
                LabelText.Parent = DropContainer

                local DropBtn = Instance.new("TextButton")
                DropBtn.Name = "DropBtn"
                DropBtn.Size = UDim2.new(1, -74, 0, 32)
                DropBtn.BackgroundColor3 = THEME.InputBackground
                DropBtn.BackgroundTransparency = THEME.InputBackgroundTransparency
                DropBtn.Text = ""
                DropBtn.AutoButtonColor = false
                DropBtn.Parent = DropContainer

                local DropCorner = Instance.new("UICorner")
                DropCorner.CornerRadius = UDim.new(0, 8)
                DropCorner.Parent = DropBtn

                local DropStroke = Instance.new("UIStroke")
                DropStroke.Color = THEME.InputBorder
                DropStroke.Transparency = THEME.InputBorderTransparency
                DropStroke.Thickness = 1
                DropStroke.Parent = DropBtn

                local DropBtnText = Instance.new("TextLabel")
                DropBtnText.Size = UDim2.new(1, -26, 1, 0)
                DropBtnText.Position = UDim2.fromOffset(8, 0)
                DropBtnText.BackgroundTransparency = 1
                DropBtnText.Font = THEME.FontBold
                DropBtnText.Text = tostring(currentOption)
                DropBtnText.TextColor3 = THEME.Text
                DropBtnText.TextSize = 12
                DropBtnText.TextXAlignment = Enum.TextXAlignment.Left
                DropBtnText.Parent = DropBtn

                local ChevronIcon = CreateIconImage("chevron-down", DropBtn, UDim2.fromOffset(13, 13), THEME.Placeholder)
                if ChevronIcon then
                    ChevronIcon.AnchorPoint = Vector2.new(1, 0.5)
                    ChevronIcon.Position = UDim2.new(1, -8, 0.5, 0)
                end

                -- Spacious Floating Dropdown Menu (Parented to FloatingOverlay)
                local FloatingMenu = Instance.new("Frame")
                FloatingMenu.Name = "FloatingDropList_" .. dropName
                FloatingMenu.Size = UDim2.fromOffset(160, 0)
                FloatingMenu.BackgroundColor3 = THEME.DropdownMenuBg
                FloatingMenu.Visible = false
                FloatingMenu.ClipsDescendants = true
                FloatingMenu.ZIndex = 150
                FloatingMenu.Parent = FloatingOverlay

                local FMCorner = Instance.new("UICorner")
                FMCorner.CornerRadius = UDim.new(0, 8)
                FMCorner.Parent = FloatingMenu

                local FMStroke = Instance.new("UIStroke")
                FMStroke.Color = THEME.InputBorder
                FMStroke.Transparency = 0.35
                FMStroke.Thickness = 1.2
                FMStroke.Parent = FloatingMenu

                local FMPadding = Instance.new("UIPadding")
                FMPadding.PaddingTop = UDim.new(0, 6)
                FMPadding.PaddingBottom = UDim.new(0, 6)
                FMPadding.PaddingLeft = UDim.new(0, 6)
                FMPadding.PaddingRight = UDim.new(0, 6)
                FMPadding.Parent = FloatingMenu

                local FMLayout = Instance.new("UIListLayout")
                FMLayout.FillDirection = Enum.FillDirection.Vertical
                FMLayout.SortOrder = Enum.SortOrder.LayoutOrder
                FMLayout.Padding = UDim.new(0, 4)
                FMLayout.Parent = FloatingMenu

                -- Search Box Inside Dropdown
                local DropSearchFrame = Instance.new("Frame")
                DropSearchFrame.Name = "DropSearchFrame"
                DropSearchFrame.Size = UDim2.new(1, 0, 0, 26)
                DropSearchFrame.BackgroundColor3 = THEME.InputBackground
                DropSearchFrame.LayoutOrder = 1
                DropSearchFrame.ZIndex = 151
                DropSearchFrame.Parent = FloatingMenu

                local DSCorner = Instance.new("UICorner")
                DSCorner.CornerRadius = UDim.new(0, 6)
                DSCorner.Parent = DropSearchFrame

                local DSStroke = Instance.new("UIStroke")
                DSStroke.Color = THEME.InputBorder
                DSStroke.Transparency = 0.5
                DSStroke.Thickness = 1
                DSStroke.Parent = DropSearchFrame

                local DSSearchIcon = CreateIconImage("search", DropSearchFrame, UDim2.fromOffset(12, 12), THEME.Placeholder)
                if DSSearchIcon then
                    DSSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    DSSearchIcon.Position = UDim2.new(0, 6, 0.5, 0)
                    DSSearchIcon.ZIndex = 152
                end

                local DropSearchBox = Instance.new("TextBox")
                DropSearchBox.Size = UDim2.new(1, -26, 1, 0)
                DropSearchBox.Position = UDim2.fromOffset(22, 0)
                DropSearchBox.BackgroundTransparency = 1
                DropSearchBox.Font = THEME.FontRegular
                DropSearchBox.PlaceholderText = "Search..."
                DropSearchBox.PlaceholderColor3 = THEME.Placeholder
                DropSearchBox.Text = ""
                DropSearchBox.TextColor3 = THEME.Text
                DropSearchBox.TextSize = 11.5
                DropSearchBox.TextXAlignment = Enum.TextXAlignment.Left
                DropSearchBox.ZIndex = 152
                DropSearchBox.Parent = DropSearchFrame

                -- Scroll Container for Options
                local OptionsScroll = Instance.new("ScrollingFrame")
                OptionsScroll.Name = "OptionsScroll"
                OptionsScroll.Size = UDim2.new(1, 0, 0, 0)
                OptionsScroll.BackgroundTransparency = 1
                OptionsScroll.BorderSizePixel = 0
                OptionsScroll.ScrollBarThickness = 2
                OptionsScroll.ScrollBarImageColor3 = THEME.Accent
                OptionsScroll.ScrollBarImageTransparency = 0.4
                OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                OptionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                OptionsScroll.LayoutOrder = 2
                OptionsScroll.ZIndex = 151
                OptionsScroll.Parent = FloatingMenu

                local OSLayout = Instance.new("UIListLayout")
                OSLayout.FillDirection = Enum.FillDirection.Vertical
                OSLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OSLayout.Padding = UDim.new(0, 2)
                OSLayout.Parent = OptionsScroll

                local optionButtons = {}

                local isOpen = false
                local function RecalculateHeight()
                    local visibleCount = 0
                    for _, item in ipairs(optionButtons) do
                        if item.Btn.Visible then
                            visibleCount = visibleCount + 1
                        end
                    end
                    local scrollHeight = math.min(visibleCount * 30, 150)
                    OptionsScroll.Size = UDim2.new(1, 0, 0, scrollHeight)
                    local totalHeight = 36 + scrollHeight + 4
                    return totalHeight
                end

                local function CloseDrop()
                    if not isOpen then return end
                    isOpen = false
                    Library.ActiveDropdown = nil
                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(FloatingMenu.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                        if not isOpen then FloatingMenu.Visible = false end
                    end)
                end

                local function OpenDrop()
                    if Library.ActiveDropdown and Library.ActiveDropdown.Close then
                        pcall(function() Library.ActiveDropdown.Close() end)
                    end
                    isOpen = true
                    Library.ActiveDropdown = { Close = CloseDrop, Menu = FloatingMenu, Btn = DropBtn }

                    -- Reset search query
                    DropSearchBox.Text = ""
                    for _, item in ipairs(optionButtons) do
                        item.Btn.Visible = true
                    end

                    local btnPos = DropBtn.AbsolutePosition
                    local btnSize = DropBtn.AbsoluteSize
                    local menuWidth = math.max(btnSize.X + 24, 150)
                    local totalHeight = RecalculateHeight()

                    FloatingMenu.Position = UDim2.fromOffset(btnPos.X - 12, btnPos.Y + btnSize.Y + 4)
                    FloatingMenu.Size = UDim2.fromOffset(menuWidth, 0)
                    FloatingMenu.Visible = true

                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(menuWidth, totalHeight) }, 0.2)
                end

                DropSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local query = DropSearchBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
                    for _, item in ipairs(optionButtons) do
                        if query == "" then
                            item.Btn.Visible = true
                        else
                            item.Btn.Visible = (item.Name:lower():find(query, 1, true) ~= nil)
                        end
                    end
                    local menuWidth = FloatingMenu.AbsoluteSize.X
                    local totalHeight = RecalculateHeight()
                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(menuWidth, totalHeight) }, 0.15)
                end)

                DropBtn.MouseButton1Click:Connect(function()
                    if isOpen then CloseDrop() else OpenDrop() end
                end)

                local function BuildOptions(opts)
                    for _, child in ipairs(OptionsScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    optionButtons = {}

                    for _, opt in ipairs(opts) do
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 28)
                        optBtn.BackgroundColor3 = THEME.DropdownMenuBg
                        optBtn.BackgroundTransparency = 1
                        optBtn.Font = THEME.FontSemiBold
                        optBtn.Text = "   " .. tostring(opt)
                        optBtn.TextColor3 = (opt == currentOption) and THEME.Accent or THEME.Text
                        optBtn.TextSize = 12
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.AutoButtonColor = false
                        optBtn.ZIndex = 153
                        optBtn.Parent = OptionsScroll

                        local BtnCorner = Instance.new("UICorner")
                        BtnCorner.CornerRadius = UDim.new(0, 6)
                        BtnCorner.Parent = optBtn

                        local CheckIcon = CreateIconImage("check", optBtn, UDim2.fromOffset(12, 12), THEME.Accent)
                        if CheckIcon then
                            CheckIcon.AnchorPoint = Vector2.new(1, 0.5)
                            CheckIcon.Position = UDim2.new(1, -8, 0.5, 0)
                            CheckIcon.ZIndex = 154
                            CheckIcon.Visible = (opt == currentOption)
                        end

                        optBtn.MouseEnter:Connect(function()
                            CreateTween(optBtn, { BackgroundTransparency = 0, BackgroundColor3 = THEME.DropdownItemHover }, 0.1)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            CreateTween(optBtn, { BackgroundTransparency = 1 }, 0.1)
                        end)

                        local itemData = { Btn = optBtn, Name = tostring(opt), Check = CheckIcon }
                        table.insert(optionButtons, itemData)

                        optBtn.MouseButton1Click:Connect(function()
                            currentOption = opt
                            DropBtnText.Text = tostring(currentOption)
                            for _, item in ipairs(optionButtons) do
                                local isSelected = (item.Name == tostring(currentOption))
                                item.Btn.TextColor3 = isSelected and THEME.Accent or THEME.Text
                                if item.Check then
                                    item.Check.Visible = isSelected
                                end
                            end
                            CloseDrop()
                            pcall(onSelect, currentOption)
                        end)
                    end
                end

                BuildOptions(dropOptions)

                return {
                    Set = function(val)
                        currentOption = val
                        DropBtnText.Text = tostring(currentOption)
                        for _, item in ipairs(optionButtons) do
                            local isSelected = (item.Name == tostring(currentOption))
                            item.Btn.TextColor3 = isSelected and THEME.Accent or THEME.Text
                            if item.Check then
                                item.Check.Visible = isSelected
                            end
                        end
                        pcall(onSelect, currentOption)
                    end,
                    Refresh = function(newOpts)
                        dropOptions = newOpts or {}
                        BuildOptions(dropOptions)
                    end
                }
            end

            -- FULL-WIDTH DROPDOWN (Supports Single & Multi Select)
            function SecObj:AddDropdown(dropConfig)
                dropConfig = dropConfig or {}
                local dTitle = dropConfig.Title or dropConfig.Name or "Dropdown"
                local dOptions = dropConfig.Options or {}
                local dMulti = dropConfig.Multi or false
                local dDefault = dropConfig.Default or (dMulti and {} or dOptions[1] or "")
                local dCallback = dropConfig.Callback or function() end

                local selectedValues = dMulti and (type(dDefault) == "table" and dDefault or {}) or (type(dDefault) == "table" and (dDefault[1] or "") or dDefault)

                local DropFrame = Instance.new("Frame")
                DropFrame.Name = "Dropdown_" .. dTitle
                DropFrame.Size = UDim2.new(1, 0, 0, 48)
                DropFrame.BackgroundTransparency = 1
                DropFrame.LayoutOrder = 10
                DropFrame.Parent = SectionCard

                table.insert(TabObj.Elements, { Frame = DropFrame, Name = dTitle })

                local Title = Instance.new("TextLabel")
                Title.Size = UDim2.new(1, 0, 0, 16)
                Title.BackgroundTransparency = 1
                Title.Font = THEME.FontBold
                Title.Text = dTitle
                Title.TextColor3 = THEME.Text
                Title.TextSize = 13
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.Parent = DropFrame

                local DropBtn = Instance.new("TextButton")
                DropBtn.Name = "DropBtn"
                DropBtn.Size = UDim2.new(1, 0, 0, 30)
                DropBtn.Position = UDim2.fromOffset(0, 18)
                DropBtn.BackgroundColor3 = THEME.InputBackground
                DropBtn.BackgroundTransparency = THEME.InputBackgroundTransparency
                DropBtn.Text = ""
                DropBtn.AutoButtonColor = false
                DropBtn.Parent = DropFrame

                local DropCorner = Instance.new("UICorner")
                DropCorner.CornerRadius = UDim.new(0, 8)
                DropCorner.Parent = DropBtn

                local DropStroke = Instance.new("UIStroke")
                DropStroke.Color = THEME.InputBorder
                DropStroke.Transparency = THEME.InputBorderTransparency
                DropStroke.Thickness = 1
                DropStroke.Parent = DropBtn

                local function FormatDisplay()
                    if dMulti then
                        if type(selectedValues) == "table" and #selectedValues > 0 then
                            return table.concat(selectedValues, ", ")
                        else
                            return "None selected"
                        end
                    else
                        if type(selectedValues) == "table" then
                            if #selectedValues > 0 then
                                return tostring(selectedValues[1])
                            else
                                return ""
                            end
                        end
                        return tostring(selectedValues or "")
                    end
                end

                local DropBtnText = Instance.new("TextLabel")
                DropBtnText.Size = UDim2.new(1, -26, 1, 0)
                DropBtnText.Position = UDim2.fromOffset(10, 0)
                DropBtnText.BackgroundTransparency = 1
                DropBtnText.Font = THEME.FontSemiBold
                DropBtnText.Text = FormatDisplay()
                DropBtnText.TextColor3 = THEME.Text
                DropBtnText.TextSize = 12
                DropBtnText.TextXAlignment = Enum.TextXAlignment.Left
                DropBtnText.TextTruncate = Enum.TextTruncate.AtEnd
                DropBtnText.Parent = DropBtn

                local ChevronIcon = CreateIconImage("chevron-down", DropBtn, UDim2.fromOffset(13, 13), THEME.Placeholder)
                if ChevronIcon then
                    ChevronIcon.AnchorPoint = Vector2.new(1, 0.5)
                    ChevronIcon.Position = UDim2.new(1, -8, 0.5, 0)
                end

                -- Floating Dropdown Menu
                local FloatingMenu = Instance.new("Frame")
                FloatingMenu.Name = "FloatingMenu_" .. dTitle
                FloatingMenu.Size = UDim2.fromOffset(200, 0)
                FloatingMenu.BackgroundColor3 = THEME.DropdownMenuBg
                FloatingMenu.Visible = false
                FloatingMenu.ClipsDescendants = true
                FloatingMenu.ZIndex = 150
                FloatingMenu.Parent = FloatingOverlay

                local FMCorner = Instance.new("UICorner")
                FMCorner.CornerRadius = UDim.new(0, 8)
                FMCorner.Parent = FloatingMenu

                local FMStroke = Instance.new("UIStroke")
                FMStroke.Color = THEME.InputBorder
                FMStroke.Transparency = 0.35
                FMStroke.Thickness = 1.2
                FMStroke.Parent = FloatingMenu

                local FMPadding = Instance.new("UIPadding")
                FMPadding.PaddingTop = UDim.new(0, 6)
                FMPadding.PaddingBottom = UDim.new(0, 6)
                FMPadding.PaddingLeft = UDim.new(0, 6)
                FMPadding.PaddingRight = UDim.new(0, 6)
                FMPadding.Parent = FloatingMenu

                local FMLayout = Instance.new("UIListLayout")
                FMLayout.FillDirection = Enum.FillDirection.Vertical
                FMLayout.SortOrder = Enum.SortOrder.LayoutOrder
                FMLayout.Padding = UDim.new(0, 4)
                FMLayout.Parent = FloatingMenu

                -- Search inside dropdown
                local DropSearchFrame = Instance.new("Frame")
                DropSearchFrame.Name = "DropSearchFrame"
                DropSearchFrame.Size = UDim2.new(1, 0, 0, 26)
                DropSearchFrame.BackgroundColor3 = THEME.InputBackground
                DropSearchFrame.LayoutOrder = 1
                DropSearchFrame.ZIndex = 151
                DropSearchFrame.Parent = FloatingMenu

                local DSCorner = Instance.new("UICorner")
                DSCorner.CornerRadius = UDim.new(0, 6)
                DSCorner.Parent = DropSearchFrame

                local DSStroke = Instance.new("UIStroke")
                DSStroke.Color = THEME.InputBorder
                DSStroke.Transparency = 0.5
                DSStroke.Thickness = 1
                DSStroke.Parent = DropSearchFrame

                local DSSearchIcon = CreateIconImage("search", DropSearchFrame, UDim2.fromOffset(12, 12), THEME.Placeholder)
                if DSSearchIcon then
                    DSSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    DSSearchIcon.Position = UDim2.new(0, 6, 0.5, 0)
                    DSSearchIcon.ZIndex = 152
                end

                local DropSearchBox = Instance.new("TextBox")
                DropSearchBox.Size = UDim2.new(1, -26, 1, 0)
                DropSearchBox.Position = UDim2.fromOffset(22, 0)
                DropSearchBox.BackgroundTransparency = 1
                DropSearchBox.Font = THEME.FontRegular
                DropSearchBox.PlaceholderText = "Search..."
                DropSearchBox.PlaceholderColor3 = THEME.Placeholder
                DropSearchBox.Text = ""
                DropSearchBox.TextColor3 = THEME.Text
                DropSearchBox.TextSize = 11.5
                DropSearchBox.TextXAlignment = Enum.TextXAlignment.Left
                DropSearchBox.ZIndex = 152
                DropSearchBox.Parent = DropSearchFrame

                local OptionsScroll = Instance.new("ScrollingFrame")
                OptionsScroll.Name = "OptionsScroll"
                OptionsScroll.Size = UDim2.new(1, 0, 0, 0)
                OptionsScroll.BackgroundTransparency = 1
                OptionsScroll.BorderSizePixel = 0
                OptionsScroll.ScrollBarThickness = 2
                OptionsScroll.ScrollBarImageColor3 = THEME.Accent
                OptionsScroll.ScrollBarImageTransparency = 0.4
                OptionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                OptionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                OptionsScroll.LayoutOrder = 2
                OptionsScroll.ZIndex = 151
                OptionsScroll.Parent = FloatingMenu

                local OSLayout = Instance.new("UIListLayout")
                OSLayout.FillDirection = Enum.FillDirection.Vertical
                OSLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OSLayout.Padding = UDim.new(0, 2)
                OSLayout.Parent = OptionsScroll

                local optionButtons = {}

                local isOpen = false
                local function RecalculateHeight()
                    local visibleCount = 0
                    for _, item in ipairs(optionButtons) do
                        if item.Btn.Visible then
                            visibleCount = visibleCount + 1
                        end
                    end
                    local scrollHeight = math.min(visibleCount * 30, 160)
                    OptionsScroll.Size = UDim2.new(1, 0, 0, scrollHeight)
                    local totalHeight = 36 + scrollHeight + 4
                    return totalHeight
                end

                local function CloseDrop()
                    if not isOpen then return end
                    isOpen = false
                    Library.ActiveDropdown = nil
                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(FloatingMenu.AbsoluteSize.X, 0) }, 0.15).Completed:Connect(function()
                        if not isOpen then FloatingMenu.Visible = false end
                    end)
                end

                local function OpenDrop()
                    if Library.ActiveDropdown and Library.ActiveDropdown.Close then
                        pcall(function() Library.ActiveDropdown.Close() end)
                    end
                    isOpen = true
                    Library.ActiveDropdown = { Close = CloseDrop, Menu = FloatingMenu, Btn = DropBtn }

                    DropSearchBox.Text = ""
                    for _, item in ipairs(optionButtons) do
                        item.Btn.Visible = true
                    end

                    local btnPos = DropBtn.AbsolutePosition
                    local btnSize = DropBtn.AbsoluteSize
                    local menuWidth = math.max(btnSize.X, 180)
                    local totalHeight = RecalculateHeight()

                    FloatingMenu.Position = UDim2.fromOffset(btnPos.X, btnPos.Y + btnSize.Y + 4)
                    FloatingMenu.Size = UDim2.fromOffset(menuWidth, 0)
                    FloatingMenu.Visible = true

                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(menuWidth, totalHeight) }, 0.2)
                end

                DropSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local query = DropSearchBox.Text:lower():gsub("^%s*(.-)%s*$", "%1")
                    for _, item in ipairs(optionButtons) do
                        if query == "" then
                            item.Btn.Visible = true
                        else
                            item.Btn.Visible = (item.Name:lower():find(query, 1, true) ~= nil)
                        end
                    end
                    local menuWidth = FloatingMenu.AbsoluteSize.X
                    local totalHeight = RecalculateHeight()
                    CreateTween(FloatingMenu, { Size = UDim2.fromOffset(menuWidth, totalHeight) }, 0.15)
                end)

                DropBtn.MouseButton1Click:Connect(function()
                    if isOpen then CloseDrop() else OpenDrop() end
                end)

                local function IsOptionSelected(opt)
                    if dMulti then
                        if type(selectedValues) == "table" then
                            return table.find(selectedValues, opt) ~= nil
                        end
                        return false
                    else
                        return selectedValues == opt
                    end
                end

                local function BuildOptions(opts)
                    for _, child in ipairs(OptionsScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    optionButtons = {}

                    for _, opt in ipairs(opts) do
                        local isSel = IsOptionSelected(opt)
                        local optBtn = Instance.new("TextButton")
                        optBtn.Size = UDim2.new(1, 0, 0, 28)
                        optBtn.BackgroundColor3 = THEME.DropdownMenuBg
                        optBtn.BackgroundTransparency = 1
                        optBtn.Font = THEME.FontSemiBold
                        optBtn.Text = "   " .. tostring(opt)
                        optBtn.TextColor3 = isSel and THEME.Accent or THEME.Text
                        optBtn.TextSize = 12
                        optBtn.TextXAlignment = Enum.TextXAlignment.Left
                        optBtn.AutoButtonColor = false
                        optBtn.ZIndex = 153
                        optBtn.Parent = OptionsScroll

                        local BtnCorner = Instance.new("UICorner")
                        BtnCorner.CornerRadius = UDim.new(0, 6)
                        BtnCorner.Parent = optBtn

                        local CheckIcon = CreateIconImage("check", optBtn, UDim2.fromOffset(12, 12), THEME.Accent)
                        if CheckIcon then
                            CheckIcon.AnchorPoint = Vector2.new(1, 0.5)
                            CheckIcon.Position = UDim2.new(1, -8, 0.5, 0)
                            CheckIcon.ZIndex = 154
                            CheckIcon.Visible = isSel
                        end

                        optBtn.MouseEnter:Connect(function()
                            CreateTween(optBtn, { BackgroundTransparency = 0, BackgroundColor3 = THEME.DropdownItemHover }, 0.1)
                        end)
                        optBtn.MouseLeave:Connect(function()
                            CreateTween(optBtn, { BackgroundTransparency = 1 }, 0.1)
                        end)

                        local itemData = { Btn = optBtn, Name = tostring(opt), Check = CheckIcon }
                        table.insert(optionButtons, itemData)

                        optBtn.MouseButton1Click:Connect(function()
                            if dMulti then
                                if type(selectedValues) ~= "table" then selectedValues = {} end
                                local idx = table.find(selectedValues, opt)
                                if idx then
                                    table.remove(selectedValues, idx)
                                else
                                    table.insert(selectedValues, opt)
                                end
                                local nowSel = IsOptionSelected(opt)
                                optBtn.TextColor3 = nowSel and THEME.Accent or THEME.Text
                                if CheckIcon then CheckIcon.Visible = nowSel end
                                DropBtnText.Text = FormatDisplay()
                                pcall(dCallback, selectedValues)
                            else
                                selectedValues = opt
                                DropBtnText.Text = FormatDisplay()
                                for _, it in ipairs(optionButtons) do
                                    local matched = (it.Name == tostring(selectedValues))
                                    it.Btn.TextColor3 = matched and THEME.Accent or THEME.Text
                                    if it.Check then it.Check.Visible = matched end
                                end
                                CloseDrop()
                                pcall(dCallback, selectedValues)
                            end
                        end)
                    end
                end

                BuildOptions(dOptions)

                local dropdownObj = {}
                local function SetDropdownValue(self_or_val, maybeVal)
                    local newVal = (maybeVal ~= nil) and maybeVal or self_or_val
                    if type(newVal) == "table" and newVal.Set then return end
                    selectedValues = newVal
                    DropBtnText.Text = FormatDisplay()
                    for _, it in ipairs(optionButtons) do
                        local matched = IsOptionSelected(it.Name)
                        it.Btn.TextColor3 = matched and THEME.Accent or THEME.Text
                        if it.Check then it.Check.Visible = matched end
                    end
                    pcall(dCallback, selectedValues)
                end
                dropdownObj.Set = SetDropdownValue
                dropdownObj.SetValue = SetDropdownValue
                dropdownObj.Refresh = function(self_or_opts, maybeOpts, clearSelected)
                    local newOpts = (type(self_or_opts) == "table" and not self_or_opts.Set) and self_or_opts or maybeOpts
                    dOptions = newOpts or {}
                    if clearSelected then
                        selectedValues = dMulti and {} or ""
                        DropBtnText.Text = FormatDisplay()
                    end
                    BuildOptions(dOptions)
                end
                return dropdownObj
            end
            SecObj.CreateDropdown = SecObj.AddDropdown

            -- STANDALONE INPUT COMPONENT
            function SecObj:AddInput(inputConfig)
                inputConfig = inputConfig or {}
                local iTitle = inputConfig.Title or inputConfig.Name or nil
                local placeholder = inputConfig.Placeholder or "Search options..."
                local defaultText = inputConfig.Default or ""
                local iconName = inputConfig.Icon or "search"
                local iCallback = inputConfig.Callback or function() end

                local ContainerFrame = Instance.new("Frame")
                ContainerFrame.Name = "Input_" .. (iTitle or "Field")
                ContainerFrame.Size = UDim2.new(1, 0, 0, iTitle and 48 or 34)
                ContainerFrame.BackgroundTransparency = 1
                ContainerFrame.LayoutOrder = 10
                ContainerFrame.Parent = SectionCard

                if iTitle then
                    table.insert(TabObj.Elements, { Frame = ContainerFrame, Name = iTitle })
                    local Title = Instance.new("TextLabel")
                    Title.Size = UDim2.new(1, 0, 0, 16)
                    Title.BackgroundTransparency = 1
                    Title.Font = THEME.FontBold
                    Title.Text = iTitle
                    Title.TextColor3 = THEME.Text
                    Title.TextSize = 13
                    Title.TextXAlignment = Enum.TextXAlignment.Left
                    Title.Parent = ContainerFrame
                end

                local InputBoxFrame = Instance.new("Frame")
                InputBoxFrame.Name = "InputBox"
                InputBoxFrame.Size = UDim2.new(1, 0, 0, 30)
                InputBoxFrame.Position = UDim2.fromOffset(0, iTitle and 18 or 0)
                InputBoxFrame.BackgroundColor3 = THEME.InputBackground
                InputBoxFrame.BackgroundTransparency = THEME.InputBackgroundTransparency
                InputBoxFrame.Parent = ContainerFrame

                local IBCorner = Instance.new("UICorner")
                IBCorner.CornerRadius = UDim.new(0, 8)
                IBCorner.Parent = InputBoxFrame

                local IBStroke = Instance.new("UIStroke")
                IBStroke.Color = THEME.InputBorder
                IBStroke.Transparency = THEME.InputBorderTransparency
                IBStroke.Thickness = 1
                IBStroke.Parent = InputBoxFrame

                local SearchIcon = CreateIconImage(iconName, InputBoxFrame, UDim2.fromOffset(14, 14), THEME.Placeholder)
                if SearchIcon then
                    SearchIcon.AnchorPoint = Vector2.new(1, 0.5)
                    SearchIcon.Position = UDim2.new(1, -10, 0.5, 0)
                end

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -38, 1, 0)
                TextBox.Position = UDim2.fromOffset(10, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Font = THEME.FontRegular
                TextBox.PlaceholderText = placeholder
                TextBox.PlaceholderColor3 = THEME.Placeholder
                TextBox.Text = defaultText
                TextBox.TextColor3 = THEME.Text
                TextBox.TextSize = 12.5
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.Parent = InputBoxFrame

                TextBox.FocusLost:Connect(function(enterPressed)
                    pcall(iCallback, TextBox.Text, enterPressed)
                end)

                local inputObj = {}
                local function SetInputText(self_or_val, maybeVal)
                    local newVal = (maybeVal ~= nil) and maybeVal or self_or_val
                    if type(newVal) == "table" and newVal.Set then return end
                    TextBox.Text = tostring(newVal or "")
                    pcall(iCallback, TextBox.Text, true)
                end
                inputObj.Set = SetInputText
                inputObj.SetValue = SetInputText
                return inputObj
            end
            SecObj.CreateInput = SecObj.AddInput

            -- SLIDER COMPONENT
            function SecObj:AddSlider(sliderConfig)
                sliderConfig = sliderConfig or {}
                local sName = sliderConfig.Title or sliderConfig.Name or "Slider"
                local sMin = sliderConfig.Min or 0
                local sMax = sliderConfig.Max or 100
                local sDefault = sliderConfig.Default or sliderConfig.Value or sMin
                local sCallback = sliderConfig.Callback or function() end

                local value = sDefault

                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = "Slider_" .. sName
                SliderFrame.Size = UDim2.new(1, 0, 0, 36)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.LayoutOrder = 5
                SliderFrame.Parent = SectionCard

                table.insert(TabObj.Elements, { Frame = SliderFrame, Name = sName })

                local Title = Instance.new("TextLabel")
                Title.Size = UDim2.new(1, -60, 0, 16)
                Title.BackgroundTransparency = 1
                Title.Font = THEME.FontBold
                Title.Text = sName
                Title.TextColor3 = THEME.Text
                Title.TextSize = 13
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.Parent = SliderFrame

                local ValLabel = Instance.new("TextLabel")
                ValLabel.Size = UDim2.fromOffset(60, 16)
                ValLabel.Position = UDim2.new(1, -60, 0, 0)
                ValLabel.BackgroundTransparency = 1
                ValLabel.Font = THEME.FontBold
                ValLabel.Text = tostring(value)
                ValLabel.TextColor3 = THEME.AccentGlow
                ValLabel.TextSize = 13
                ValLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValLabel.Parent = SliderFrame

                local Track = Instance.new("Frame")
                Track.Name = "Track"
                Track.Size = UDim2.new(1, 0, 0, 8)
                Track.Position = UDim2.fromOffset(0, 22)
                Track.BackgroundColor3 = THEME.InputBackground
                Track.BorderSizePixel = 0
                Track.Parent = SliderFrame

                local TrackCorner = Instance.new("UICorner")
                TrackCorner.CornerRadius = UDim.new(1, 0)
                TrackCorner.Parent = Track

                local TrackStroke = Instance.new("UIStroke")
                TrackStroke.Color = THEME.InputBorder
                TrackStroke.Transparency = THEME.InputBorderTransparency
                TrackStroke.Thickness = 1
                TrackStroke.Parent = Track

                local initRatio = math.clamp((value - sMin) / (sMax - sMin), 0, 1)

                local Fill = Instance.new("Frame")
                Fill.Name = "Fill"
                Fill.Size = UDim2.fromScale(initRatio, 1)
                Fill.BackgroundColor3 = THEME.Accent
                Fill.BorderSizePixel = 0
                Fill.Parent = Track

                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = Fill

                local Knob = Instance.new("Frame")
                Knob.Name = "Knob"
                Knob.Size = UDim2.fromOffset(16, 16)
                Knob.AnchorPoint = Vector2.new(0.5, 0.5)
                Knob.Position = UDim2.new(initRatio, 0, 0.5, 0)
                Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Knob.BorderSizePixel = 0
                Knob.Parent = Track

                local KnobCorner = Instance.new("UICorner")
                KnobCorner.CornerRadius = UDim.new(1, 0)
                KnobCorner.Parent = Knob

                local function UpdateSlider(inputPos)
                    local trackAbsPos = Track.AbsolutePosition.X
                    local trackAbsSize = Track.AbsoluteSize.X
                    local ratio = math.clamp((inputPos.X - trackAbsPos) / trackAbsSize, 0, 1)
                    value = math.floor(sMin + ((sMax - sMin) * ratio))
                    ValLabel.Text = tostring(value)
                    if SecObj.RightLabel and (SecObj.RightLabel.Text:find(sName) or SecObj.RightLabel.Text:find("Walkspeed")) then
                        SecObj.RightLabel.Text = sName .. ": " .. tostring(value)
                    end
                    CreateTween(Fill, { Size = UDim2.fromScale(ratio, 1) }, 0.05)
                    CreateTween(Knob, { Position = UDim2.new(ratio, 0, 0.5, 0) }, 0.05)
                    pcall(sCallback, value)
                end

                local dragging = false
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(input.Position)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input.Position)
                    end
                end)

                local sliderObj = {}
                local function SetSliderValue(self_or_val, maybeVal)
                    local newVal = (maybeVal ~= nil) and maybeVal or self_or_val
                    if type(newVal) == "table" and newVal.Set then return end
                    newVal = tonumber(newVal) or sMin
                    value = math.clamp(newVal, sMin, sMax)
                    local ratio = (value - sMin) / (sMax - sMin)
                    ValLabel.Text = tostring(value)
                    if SecObj.RightLabel and (SecObj.RightLabel.Text:find(sName) or SecObj.RightLabel.Text:find("Walkspeed")) then
                        SecObj.RightLabel.Text = sName .. ": " .. tostring(value)
                    end
                    Fill.Size = UDim2.fromScale(ratio, 1)
                    Knob.Position = UDim2.new(ratio, 0, 0.5, 0)
                    pcall(sCallback, value)
                end
                sliderObj.Set = SetSliderValue
                sliderObj.SetValue = SetSliderValue
                return sliderObj
            end
            SecObj.CreateSlider = SecObj.AddSlider

            -- TOGGLE COMPONENT
            function SecObj:AddToggle(toggleConfig)
                toggleConfig = toggleConfig or {}
                local tName = toggleConfig.Title or toggleConfig.Name or "Toggle"
                local tDesc = toggleConfig.Description or toggleConfig.Desc or nil
                local tDefault = toggleConfig.Default or false
                local tCallback = toggleConfig.Callback or function() end

                local state = tDefault

                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Name = "Toggle_" .. tName
                ToggleFrame.Size = UDim2.new(1, 0, 0, tDesc and 40 or 28)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.LayoutOrder = 10
                ToggleFrame.Parent = SectionCard

                table.insert(TabObj.Elements, { Frame = ToggleFrame, Name = tName })

                local TextContainer = Instance.new("Frame")
                TextContainer.Size = UDim2.new(1, -48, 1, 0)
                TextContainer.BackgroundTransparency = 1
                TextContainer.ClipsDescendants = true
                TextContainer.Parent = ToggleFrame

                local TextLayout = Instance.new("UIListLayout")
                TextLayout.FillDirection = Enum.FillDirection.Vertical
                TextLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                TextLayout.Padding = UDim.new(0, 2)
                TextLayout.Parent = TextContainer

                local Title = Instance.new("TextLabel")
                Title.Size = UDim2.new(1, 0, 0, 16)
                Title.BackgroundTransparency = 1
                Title.Font = THEME.FontBold
                Title.Text = tName
                Title.TextColor3 = THEME.Text
                Title.TextSize = 12.5
                Title.TextTruncate = Enum.TextTruncate.AtEnd
                Title.ClipsDescendants = true
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.Parent = TextContainer

                if tDesc then
                    local DescLabel = Instance.new("TextLabel")
                    DescLabel.Size = UDim2.new(1, 0, 0, 14)
                    DescLabel.BackgroundTransparency = 1
                    DescLabel.Font = THEME.FontRegular
                    DescLabel.Text = tDesc
                    DescLabel.TextColor3 = THEME.TextMuted
                    DescLabel.TextSize = 11
                    DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
                    DescLabel.Parent = TextContainer
                end

                local Switch = Instance.new("TextButton")
                Switch.Name = "Switch"
                Switch.Size = UDim2.fromOffset(42, 22)
                Switch.Position = UDim2.new(1, -42, 0.5, -11)
                Switch.BackgroundColor3 = state and THEME.Accent or THEME.ToggleTrackOff
                Switch.Text = ""
                Switch.AutoButtonColor = false
                Switch.Parent = ToggleFrame

                local SwitchCorner = Instance.new("UICorner")
                SwitchCorner.CornerRadius = UDim.new(1, 0)
                SwitchCorner.Parent = Switch

                local Circle = Instance.new("Frame")
                Circle.Name = "Circle"
                Circle.Size = UDim2.fromOffset(16, 16)
                Circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.BorderSizePixel = 0
                Circle.Parent = Switch

                local CircleCorner = Instance.new("UICorner")
                CircleCorner.CornerRadius = UDim.new(1, 0)
                CircleCorner.Parent = Circle

                local function SetState(self_or_val, maybeVal)
                    local newState = (maybeVal ~= nil) and maybeVal or self_or_val
                    if type(newState) == "table" and newState.Set then return end
                    state = (newState == true)
                    CreateTween(Switch, { BackgroundColor3 = state and THEME.Accent or THEME.ToggleTrackOff }, 0.2)
                    CreateTween(Circle, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.2)
                    pcall(tCallback, state)
                end

                Switch.MouseButton1Click:Connect(function()
                    SetState(not state)
                end)

                if state then
                    task.spawn(function()
                        pcall(tCallback, state)
                    end)
                end

                local toggleObj = {
                    Set = SetState,
                    SetValue = SetState,
                }
                return toggleObj
            end
            SecObj.CreateToggle = SecObj.AddToggle

            -- BUTTON COMPONENT
            function SecObj:AddButton(btnConfig)
                btnConfig = btnConfig or {}
                local bTitle = btnConfig.Title or btnConfig.Name or btnConfig.Text or "Button"
                local bDesc = btnConfig.Description or btnConfig.Desc or nil
                local bCallback = btnConfig.Callback or function() end

                local BtnFrame = Instance.new("Frame")
                BtnFrame.Name = "BtnFrame_" .. bTitle
                BtnFrame.Size = UDim2.new(1, 0, 0, bDesc and 48 or 34)
                BtnFrame.BackgroundTransparency = 1
                BtnFrame.LayoutOrder = 10
                BtnFrame.Parent = SectionCard

                table.insert(TabObj.Elements, { Frame = BtnFrame, Name = bTitle })

                local ActionBtn = Instance.new("TextButton")
                ActionBtn.Size = UDim2.new(1, 0, 0, 32)
                ActionBtn.Position = UDim2.fromOffset(0, bDesc and 14 or 1)
                ActionBtn.BackgroundColor3 = THEME.InputBackground
                ActionBtn.Font = THEME.FontBold
                ActionBtn.Text = bTitle
                ActionBtn.TextColor3 = THEME.Text
                ActionBtn.TextSize = 12.5
                ActionBtn.AutoButtonColor = false
                ActionBtn.Parent = BtnFrame

                local BtnCorner = Instance.new("UICorner")
                BtnCorner.CornerRadius = UDim.new(0, 8)
                BtnCorner.Parent = ActionBtn

                local BtnStroke = Instance.new("UIStroke")
                BtnStroke.Color = THEME.InputBorder
                BtnStroke.Transparency = THEME.InputBorderTransparency
                BtnStroke.Thickness = 1
                BtnStroke.Parent = ActionBtn

                ActionBtn.MouseEnter:Connect(function()
                    CreateTween(ActionBtn, { BackgroundColor3 = THEME.AccentDark, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15)
                end)
                ActionBtn.MouseLeave:Connect(function()
                    CreateTween(ActionBtn, { BackgroundColor3 = THEME.InputBackground, TextColor3 = THEME.Text }, 0.15)
                end)
                ActionBtn.MouseButton1Click:Connect(function()
                    CreateTween(ActionBtn, { Size = UDim2.new(1, -4, 0, 30) }, 0.08).Completed:Connect(function()
                        CreateTween(ActionBtn, { Size = UDim2.new(1, 0, 0, 32) }, 0.08)
                    end)
                    pcall(bCallback)
                end)

                return { Fire = bCallback }
            end
            SecObj.CreateButton = SecObj.AddButton

            -- PARAGRAPH COMPONENT
            function SecObj:AddParagraph(pConfig)
                pConfig = pConfig or {}
                local pTitle = pConfig.Title or "Info"
                local pContent = pConfig.Content or pConfig.Description or ""

                local ParaFrame = Instance.new("Frame")
                ParaFrame.Name = "Paragraph"
                ParaFrame.Size = UDim2.new(1, 0, 0, 0)
                ParaFrame.AutomaticSize = Enum.AutomaticSize.Y
                ParaFrame.BackgroundColor3 = THEME.InputBackground
                ParaFrame.BackgroundTransparency = 0.5
                ParaFrame.LayoutOrder = 10
                ParaFrame.Parent = SectionCard

                local PCorner = Instance.new("UICorner")
                PCorner.CornerRadius = UDim.new(0, 8)
                PCorner.Parent = ParaFrame

                local PStroke = Instance.new("UIStroke")
                PStroke.Color = THEME.InputBorder
                PStroke.Transparency = 0.6
                PStroke.Thickness = 1
                PStroke.Parent = ParaFrame

                local PPadding = Instance.new("UIPadding")
                PPadding.PaddingTop = UDim.new(0, 8)
                PPadding.PaddingBottom = UDim.new(0, 8)
                PPadding.PaddingLeft = UDim.new(0, 10)
                PPadding.PaddingRight = UDim.new(0, 10)
                PPadding.Parent = ParaFrame

                local PLayout = Instance.new("UIListLayout")
                PLayout.FillDirection = Enum.FillDirection.Vertical
                PLayout.Padding = UDim.new(0, 3)
                PLayout.Parent = ParaFrame

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Size = UDim2.new(1, 0, 0, 16)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Font = THEME.FontBold
                TitleLabel.Text = pTitle
                TitleLabel.TextColor3 = THEME.AccentGlow
                TitleLabel.TextSize = 12.5
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = ParaFrame

                local ContentLabel = Instance.new("TextLabel")
                ContentLabel.Size = UDim2.new(1, 0, 0, 0)
                ContentLabel.AutomaticSize = Enum.AutomaticSize.Y
                ContentLabel.BackgroundTransparency = 1
                ContentLabel.Font = THEME.FontRegular
                ContentLabel.Text = pContent
                ContentLabel.TextColor3 = THEME.TextMuted
                ContentLabel.TextSize = 11.5
                ContentLabel.TextWrapped = true
                ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
                ContentLabel.Parent = ParaFrame

                table.insert(TabObj.Elements, { Frame = ParaFrame, Name = pTitle })

                return {
                    SetTitle = function(self_or_t, maybeT)
                        local t = (maybeT ~= nil) and maybeT or self_or_t
                        TitleLabel.Text = tostring(t or "")
                    end,
                    SetContent = function(self_or_c, maybeC)
                        local c = (maybeC ~= nil) and maybeC or self_or_c
                        ContentLabel.Text = tostring(c or "")
                    end,
                    Set = function(self_or_c, maybeC)
                        local c = (maybeC ~= nil) and maybeC or self_or_c
                        if type(c) == "table" then
                            if c.Title then TitleLabel.Text = tostring(c.Title) end
                            if c.Content then ContentLabel.Text = tostring(c.Content) end
                        else
                            ContentLabel.Text = tostring(c or "")
                        end
                    end,
                    SetDesc = function(self_or_c, maybeC)
                        local c = (maybeC ~= nil) and maybeC or self_or_c
                        ContentLabel.Text = tostring(c or "")
                    end,
                }
            end

            -- SEPARATOR COMPONENT
            function SecObj:AddSeperator(sepConfig)
                sepConfig = sepConfig or {}
                local sepTitle = sepConfig.Title or ""

                local SepFrame = Instance.new("Frame")
                SepFrame.Name = "Separator"
                SepFrame.Size = UDim2.new(1, 0, 0, sepTitle ~= "" and 22 or 10)
                SepFrame.BackgroundTransparency = 1
                SepFrame.LayoutOrder = 10
                SepFrame.Parent = SectionCard

                local SepLine = Instance.new("Frame")
                SepLine.Size = UDim2.new(1, 0, 0, 1)
                SepLine.Position = UDim2.new(0, 0, 0.5, 0)
                SepLine.BackgroundColor3 = THEME.InputBorder
                SepLine.BackgroundTransparency = 0.5
                SepLine.BorderSizePixel = 0
                SepLine.Parent = SepFrame

                if sepTitle ~= "" then
                    local TitleLabel = Instance.new("TextLabel")
                    TitleLabel.Size = UDim2.fromOffset(0, 16)
                    TitleLabel.AutomaticSize = Enum.AutomaticSize.X
                    TitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    TitleLabel.Position = UDim2.fromScale(0.5, 0.5)
                    TitleLabel.BackgroundColor3 = THEME.Card
                    TitleLabel.Font = THEME.FontBold
                    TitleLabel.Text = "  " .. sepTitle .. "  "
                    TitleLabel.TextColor3 = THEME.AccentGlow
                    TitleLabel.TextSize = 11
                    TitleLabel.Parent = SepFrame
                end
            end
            SecObj.AddSeparator = SecObj.AddSeperator

            -- ROW: INPUT BOX + TOGGLE SWITCH (Bottom Row inside Card)
            function SecObj:CreateInputAndToggle(rowConfig)
                rowConfig = rowConfig or {}
                local placeholder = rowConfig.Placeholder or ""
                local defaultText = rowConfig.DefaultText or ""
                local defaultState = rowConfig.DefaultState or false
                local onInput = rowConfig.OnInput or function() end
                local onToggle = rowConfig.OnToggle or function() end

                local state = defaultState

                local RowFrame = Instance.new("Frame")
                RowFrame.Name = "Row_InputToggle"
                RowFrame.Size = UDim2.new(1, 0, 0, 32)
                RowFrame.BackgroundTransparency = 1
                RowFrame.LayoutOrder = 15
                RowFrame.Parent = SectionCard

                -- Left Input Box
                local InputBoxFrame = Instance.new("Frame")
                InputBoxFrame.Name = "InputBox"
                InputBoxFrame.Size = UDim2.new(1, -50, 1, 0)
                InputBoxFrame.BackgroundColor3 = THEME.InputBackground
                InputBoxFrame.BackgroundTransparency = THEME.InputBackgroundTransparency
                InputBoxFrame.Parent = RowFrame

                local IBCorner = Instance.new("UICorner")
                IBCorner.CornerRadius = UDim.new(0, 8)
                IBCorner.Parent = InputBoxFrame

                local IBStroke = Instance.new("UIStroke")
                IBStroke.Color = THEME.InputBorder
                IBStroke.Transparency = THEME.InputBorderTransparency
                IBStroke.Thickness = 1
                IBStroke.Parent = InputBoxFrame

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -16, 1, 0)
                TextBox.Position = UDim2.fromOffset(8, 0)
                TextBox.BackgroundTransparency = 1
                TextBox.Font = THEME.FontRegular
                TextBox.PlaceholderText = placeholder
                TextBox.PlaceholderColor3 = THEME.Placeholder
                TextBox.Text = defaultText
                TextBox.TextColor3 = THEME.Text
                TextBox.TextSize = 12.5
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.Parent = InputBoxFrame

                TextBox.FocusLost:Connect(function(enter)
                    pcall(onInput, TextBox.Text, enter)
                end)

                -- Right Toggle Switch
                local Switch = Instance.new("TextButton")
                Switch.Name = "Switch"
                Switch.Size = UDim2.fromOffset(42, 22)
                Switch.Position = UDim2.new(1, -42, 0.5, -11)
                Switch.BackgroundColor3 = state and THEME.Accent or THEME.ToggleTrackOff
                Switch.Text = ""
                Switch.AutoButtonColor = false
                Switch.Parent = RowFrame

                local SwitchCorner = Instance.new("UICorner")
                SwitchCorner.CornerRadius = UDim.new(1, 0)
                SwitchCorner.Parent = Switch

                local Circle = Instance.new("Frame")
                Circle.Name = "Circle"
                Circle.Size = UDim2.fromOffset(16, 16)
                Circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.BorderSizePixel = 0
                Circle.Parent = Switch

                local CircleCorner = Instance.new("UICorner")
                CircleCorner.CornerRadius = UDim.new(1, 0)
                CircleCorner.Parent = Circle

                local function SetState(val)
                    state = val
                    CreateTween(Switch, { BackgroundColor3 = state and THEME.Accent or THEME.ToggleTrackOff }, 0.2)
                    CreateTween(Circle, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.2)
                    pcall(onToggle, state)
                end

                Switch.MouseButton1Click:Connect(function()
                    SetState(not state)
                end)
            end

            return SecObj
        end
        TabObj.AddSection = TabObj.CreateSection

        -- MAIN ACTION BUTTON (Standalone at the bottom)
        function TabObj:CreateActionButton(btnConfig)
            btnConfig = btnConfig or {}
            local bText = btnConfig.Text or "Jalankan Aksi"
            local bCallback = btnConfig.Callback or function() end

            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Name = "ActionBtn_" .. bText
            ActionBtn.Size = UDim2.new(1, 0, 0, 38)
            ActionBtn.BackgroundColor3 = THEME.Accent
            ActionBtn.Font = THEME.FontBold
            ActionBtn.Text = bText
            ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.TextSize = 14.5
            ActionBtn.AutoButtonColor = false
            ActionBtn.LayoutOrder = 100
            ActionBtn.Parent = TabPage

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 10)
            BtnCorner.Parent = ActionBtn

            ActionBtn.MouseEnter:Connect(function()
                CreateTween(ActionBtn, { BackgroundColor3 = THEME.AccentDark }, 0.15)
            end)
            ActionBtn.MouseLeave:Connect(function()
                CreateTween(ActionBtn, { BackgroundColor3 = THEME.Accent }, 0.15)
            end)
            ActionBtn.MouseButton1Click:Connect(function()
                CreateTween(ActionBtn, { Size = UDim2.new(1, -4, 0, 36) }, 0.08).Completed:Connect(function()
                    CreateTween(ActionBtn, { Size = UDim2.new(1, 0, 0, 38) }, 0.08)
                end)
                pcall(bCallback)
            end)
        end

        return TabObj
    end

    -- Group support (for Speed_Library / Fluent CreateGroup compatibility)
    function WindowObj:CreateGroup(groupConfig)
        local gName = (type(groupConfig) == "table" and groupConfig[1]) or tostring(groupConfig)
        local gIcon = (type(groupConfig) == "table" and groupConfig[2]) or "settings"

        local GroupObj = {}
        function GroupObj:CreateTab(tabData)
            local tName = (type(tabData) == "table" and tabData[1]) or tostring(tabData)
            local tIcon = (type(tabData) == "table" and tabData[2]) or gIcon
            local tDesc = (type(tabData) == "table" and tabData[3]) or ""
            return WindowObj:CreateTab({ Name = tName, Icon = tIcon, Description = tDesc })
        end
        return GroupObj
    end

    return WindowObj
end

return Library
