-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Library init / globals
getgenv().Valley = getgenv().Valley or {}
local Valley = getgenv().Valley

Valley.Directory    = "Valley_Loader"
Valley.Folders      = {"/configs"}
Valley.Flags        = {}
Valley.ConfigFlags  = {}
Valley.Connections  = {}
Valley.Notifications= {Notifs = {}}
Valley.__index      = Valley

local Flags          = Valley.Flags
local ConfigFlags    = Valley.ConfigFlags
local Notifications  = Valley.Notifications

local themes = {
    preset = {
        accent       = rgb(0, 255, 255),     -- Cyan
        
        background   = rgb(8, 8, 8),         -- Deep Black
        section      = rgb(10, 10, 10),      -- Slightly lifted black
        element      = rgb(20, 20, 20),      -- Dark grey for rows
        
        outline      = rgb(40, 40, 40),      -- Subtle outline
        text         = rgb(255, 255, 255),   -- White
        subtext      = rgb(170, 170, 170),   -- Light grey
        
        tab_active   = rgb(25, 25, 25),      -- Active Tab
        tab_inactive = rgb(10, 10, 10),
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

for _, path in Valley.Folders do
    pcall(function() makefolder(Valley.Directory .. path) end)
end

-- misc helpers
function Valley:Tween(Object, Properties, Info)
    if not Object then return end
    local tween = TweenService:Create(Object, Info or TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
    tween:Play()
    return tween
end

function Valley:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

function Valley:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function Valley:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
end

function Valley:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = Valley:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 24, 0, 24),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Valley:Create("ImageLabel", {
        Parent = Resizing, AnchorPoint = vec2(1, 1), Position = dim2(1, -6, 1, -6), Size = dim2(0, 14, 0, 14),
        BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=6153965706&w=150&h=150", ImageColor3 = themes.preset.subtext, ImageTransparency = 0.5
    })

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(640, 480)
    local MAX_SIZE = vec2(1100, 850)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true; StartInputPos = input.Position; StartSize = Parent.AbsoluteSize
        end
    end)
    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsResizing = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X), math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y))
        end
    end)
end

-- window
function Valley:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "NYX", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or "UI",
        Size = properties.Size or properties.size or dim2(0, 720, 0, 500), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    if Valley.Gui then Valley.Gui:Destroy() end
    if Valley.Other then Valley.Other:Destroy() end
    if Valley.ToggleGui then Valley.ToggleGui:Destroy() end

    Valley.Gui = Valley:Create("ScreenGui", { Parent = CoreGui, Name = "ORGGUI", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Valley.Other = Valley:Create("ScreenGui", { Parent = CoreGui, Name = "ORGOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = Valley:Create("Frame", {
        Parent = Valley.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    -- Main Window Setup (Base Background)
    Items.Window = Valley:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1
    })
    Valley:Themify(Items.Window, "background", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 14) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")


    -- [CREATIVE SWITCH]: Floating Sidebar
    Items.Sidebar = Valley:Create("Frame", {
        Parent = Items.Window, Position = dim2(0, 12, 0, 12), Size = dim2(0, 58, 1, -24),
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ZIndex = 2
    })
    Valley:Themify(Items.Sidebar, "section", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Sidebar, CornerRadius = dim(0, 12) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Sidebar, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    -- Scrolling Tab Holder
    Items.TabHolder = Valley:Create("ScrollingFrame", {
        Parent = Items.Sidebar, Size = dim2(1, 0, 1, 0), CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, ScrollBarThickness = 0, ZIndex = 4
    })
    Valley:Create("UIListLayout", { 
        Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Vertical, 
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, Padding = dim(0, 10) 
    })
    Valley:Create("UIPadding", { Parent = Items.TabHolder, PaddingTop = dim(0, 14), PaddingBottom = dim(0, 14) })

    -- [CREATIVE SWITCH]: Floating Header
    Items.Header = Valley:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 82, 0, 12), Size = dim2(1, -94, 0, 50), 
        BackgroundColor3 = themes.preset.section, Active = true, ZIndex = 2 
    })
    Valley:Themify(Items.Header, "section", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Header, CornerRadius = dim(0, 12) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Header, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.LogoText = Valley:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20, 0.5, 0),
        Size = dim2(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Valley:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Valley:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle:upper(), TextColor3 = themes.preset.accent,
        AnchorPoint = vec2(0, 0.5), Position = dim2(0, 24 + Items.LogoText.TextBounds.X, 0.5, 0),
        Size = dim2(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Valley:Themify(Items.SubLogoText, "accent", "TextColor3")
    
    Items.LogoText:GetPropertyChangedSignal("TextBounds"):Connect(function()
        Items.SubLogoText.Position = dim2(0, 24 + Items.LogoText.TextBounds.X, 0.5, 0)
    end)

    -- User Profile
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.AvatarFrame = Valley:Create("Frame", {
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -16, 0.5, 0), 
        Size = dim2(0, 32, 0, 32), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 5
    })
    Valley:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(1, 0) }) 
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.AvatarFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
    
    Items.Avatar = Valley:Create("ImageLabel", { 
        Parent = Items.AvatarFrame, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), 
        Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot, ZIndex = 6 
    })
    Valley:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.Username = Valley:Create("TextLabel", {
        Parent = Items.Header, Text = lp.Name, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(1, 0.5), Position = dim2(1, -60, 0.5, 0), Size = dim2(0, 150, 0, 14),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5
    })
    Valley:Themify(Items.Username, "text", "TextColor3")

    Items.SettingsBtn = Valley:Create("ImageButton", {
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -225, 0.5, 0),
        Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, Image = "rbxassetid://10734950309", ImageColor3 = themes.preset.subtext, ZIndex = 5
    })
    Valley:Themify(Items.SettingsBtn, "subtext", "ImageColor3")
    
    Items.Username:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Items.SettingsBtn.Position = dim2(1, -85 - Items.Username.TextBounds.X, 0.5, 0)
    end)
    Items.SettingsBtn.Position = dim2(1, -85 - Items.Username.TextBounds.X, 0.5, 0)

    Items.SettingsBtn.MouseButton1Click:Connect(function()
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    -- Page Container
    Items.PageHolder = Valley:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 82, 0, 74), Size = dim2(1, -94, 1, -86), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Universal Window Dragging
    local Dragging, DragInput, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    Valley:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        Items.Wrapper.Visible = uiVisible
    end

    if InputService.TouchEnabled then
        Valley.ToggleGui = Valley:Create("ScreenGui", { Parent = CoreGui, Name = "ORGToggle", IgnoreGuiInset = true })
        local ToggleButton = Valley:Create("ImageButton", {
            Name = "ToggleButton", Parent = Valley.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 55, 0, 55),
            BackgroundTransparency = 0.2, BackgroundColor3 = themes.preset.element, Image = "rbxthumb://type=Asset&id=117777120335047&w=150&h=150", ZIndex = 10000,
        })
        Valley:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 16) })
        Valley:Themify(ToggleButton, "element", "BackgroundColor3")
        Valley:Themify(Valley:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, Valley)
end

function Valley:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "",
        Hidden = properties.Hidden or properties.hidden or false, 
        Items = {} 
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        -- [CREATIVE SWITCH]: Pill-shaped tab buttons
        Items.Button = Valley:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(0, 38, 0, 38), 
            BackgroundColor3 = themes.preset.tab_active, 
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5 
        })
        Valley:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Valley:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0.5, 0) })

        Items.IconImg = Valley:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 6 
        })
        Valley:Themify(Items.IconImg, "subtext", "ImageColor3")
    end

    Items.Pages = Valley:Create("CanvasGroup", { Parent = Valley.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Valley:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 14) })
    -- Extra padding for floating look
    Valley:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 2), PaddingBottom = dim(0, 14), PaddingRight = dim(0, 2), PaddingLeft = dim(0, 2) })

    Items.Left = Valley:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Valley:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 14) })
    Valley:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 10) })

    Items.Right = Valley:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -7, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Valley:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 14) })
    Valley:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 10) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        -- Deactivate old tab
        if oldTab and oldTab.Button then
            Valley:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween)
            Valley:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
        end

        -- Activate new tab
        if Items.Button then 
            Valley:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            Valley:Tween(Items.IconImg, {ImageColor3 = rgb(255,255,255)}, buttonTween) -- Pops white against the accent background
        end
        
        task.spawn(function()
            if oldTab then
                Valley:Tween(oldTab.Pages, {GroupTransparency = 1, Size = dim2(0.95, 0, 0.95, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Valley.Other
            end

            Items.Pages.Size = dim2(0.95, 0, 0.95, 0)
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Valley:Tween(Items.Pages, {GroupTransparency = 0, Size = dim2(1, 0, 1, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            task.wait(0.35)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Valley)
end

function Valley:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        Icon = properties.Icon or properties.icon or "rbxassetid://10723415903", 
        RightIcon = properties.RightIcon or properties.righticon or "", 
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Valley:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Valley:Themify(Items.Section, "section", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 12) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Section, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    -- Clean Header Design
    Items.Header = Valley:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 38), BackgroundTransparency = 1 })
    
    -- [CREATIVE SWITCH]: Dot Indicator for sections
    Items.Dot = Valley:Create("Frame", { 
        Parent = Items.Header, Position = dim2(0, 14, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 6, 0, 6), 
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0 
    })
    Valley:Themify(Items.Dot, "accent", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Dot, CornerRadius = dim(1, 0) })

    Items.Title = Valley:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 28, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -44, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Valley:Themify(Items.Title, "text", "TextColor3")

    Items.Container = Valley:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 38), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Valley:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    Valley:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 12), PaddingLeft = dim(0, 14), PaddingRight = dim(0, 14) })

    return setmetatable(Cfg, Valley)
end

function Valley:ScriptCard(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Script", 
        Description = properties.Description or properties.description or "Utility", 
        Icon = properties.Icon or properties.icon or "rbxassetid://10723343306", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Valley:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 56), BackgroundColor3 = themes.preset.element, 
        BorderSizePixel = 0 
    })
    Valley:Themify(Items.Container, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Container, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Container, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.IconFrame = Valley:Create("Frame", {
        Parent = Items.Container, Position = dim2(0, 12, 0.5, 0), AnchorPoint = vec2(0, 0.5),
        Size = dim2(0, 34, 0, 34), BackgroundColor3 = themes.preset.background, BorderSizePixel = 0
    })
    Valley:Themify(Items.IconFrame, "background", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.IconFrame, CornerRadius = dim(0, 8) })

    Items.Icon = Valley:Create("ImageLabel", {
        Parent = Items.IconFrame, Position = dim2(0.5, 0, 0.5, 0), AnchorPoint = vec2(0.5, 0.5),
        Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, Image = Cfg.Icon, ImageColor3 = themes.preset.accent
    })
    Valley:Themify(Items.Icon, "accent", "ImageColor3")

    Items.Title = Valley:Create("TextLabel", {
        Parent = Items.Container, Position = dim2(0, 58, 0, 12), Size = dim2(1, -130, 0, 16),
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
    })
    Valley:Themify(Items.Title, "text", "TextColor3")

    Items.Desc = Valley:Create("TextLabel", {
        Parent = Items.Container, Position = dim2(0, 58, 0, 30), Size = dim2(1, -130, 0, 14),
        BackgroundTransparency = 1, Text = Cfg.Description, TextColor3 = themes.preset.subtext,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
    })
    Valley:Themify(Items.Desc, "subtext", "TextColor3")

    Items.LoadBtn = Valley:Create("TextButton", {
        Parent = Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -12, 0.5, 0),
        Size = dim2(0, 60, 0, 30), BackgroundColor3 = themes.preset.accent, Text = "RUN",
        TextColor3 = rgb(255, 255, 255), FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 12, AutoButtonColor = false
    })
    Valley:Themify(Items.LoadBtn, "accent", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.LoadBtn, CornerRadius = dim(0, 6) })

    Items.LoadBtn.MouseButton1Click:Connect(function()
        Valley:Tween(Items.LoadBtn, {BackgroundTransparency = 0.4, Size = dim2(0, 56, 0, 28)}, TweenInfo.new(0.1))
        task.wait(0.1)
        Valley:Tween(Items.LoadBtn, {BackgroundTransparency = 0, Size = dim2(0, 60, 0, 30)}, TweenInfo.new(0.2))
        Cfg.Callback()
    end)

    return setmetatable(Cfg, Valley)
end

function Valley:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Valley:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false
    })
    Valley:Themify(Items.Button, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    -- [CREATIVE SWITCH]: iOS Style Switch Pill
    Items.SwitchBG = Valley:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -12, 0.5, 0), Size = dim2(0, 36, 0, 20), 
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0 
    })
    Valley:Themify(Items.SwitchBG, "background", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.SwitchBG, CornerRadius = dim(1, 0) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.SwitchBG, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SwitchKnob = Valley:Create("Frame", {
        Parent = Items.SwitchBG, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 3, 0.5, 0), Size = dim2(0, 14, 0, 14),
        BackgroundColor3 = themes.preset.subtext, BorderSizePixel = 0
    })
    Valley:Themify(Items.SwitchKnob, "subtext", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.SwitchKnob, CornerRadius = dim(1, 0) })

    Items.Title = Valley:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 14, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -60, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Valley:Themify(Items.Title, "subtext", "TextColor3")

    local State = false
    function Cfg.set(bool)
        State = bool
        Valley:Tween(Items.SwitchBG, {BackgroundColor3 = State and themes.preset.accent or themes.preset.background}, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        Valley:Tween(Items.SwitchKnob, {Position = State and dim2(0, 19, 0.5, 0) or dim2(0, 3, 0.5, 0), BackgroundColor3 = State and rgb(255,255,255) or themes.preset.subtext}, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        Valley:Tween(Items.Title, {TextColor3 = State and themes.preset.text or themes.preset.subtext}, TweenInfo.new(0.2))
        
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Valley)
end

function Valley:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Valley:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), AutoButtonColor = false 
    })
    Valley:Themify(Items.Button, "element", "BackgroundColor3")
    Valley:Themify(Items.Button, "text", "TextColor3")
    Valley:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Button.MouseButton1Click:Connect(function()
        Valley:Tween(Items.Button, {Size = dim2(0.98, 0, 0, 34), BackgroundColor3 = themes.preset.accent}, TweenInfo.new(0.1))
        task.wait(0.1)
        Valley:Tween(Items.Button, {Size = dim2(1, 0, 0, 36), BackgroundColor3 = themes.preset.element}, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Valley)
end

function Valley:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or properties.Value or properties.value or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = Valley:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 52), 
        BackgroundColor3 = themes.preset.element 
    })
    Valley:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Title = Valley:Create("TextLabel", { Parent = Items.ContainerBox, Position = dim2(0, 14, 0, 6), Size = dim2(1, -28, 0, 20), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Valley:Themify(Items.Title, "text", "TextColor3")

    Items.Val = Valley:Create("TextLabel", { Parent = Items.ContainerBox, Position = dim2(0, 14, 0, 6), Size = dim2(1, -28, 0, 20), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.accent, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextXAlignment = Enum.TextXAlignment.Right })
    Valley:Themify(Items.Val, "accent", "TextColor3")

    -- [CREATIVE SWITCH]: Thicker modern slider track
    Items.Track = Valley:Create("TextButton", { Parent = Items.ContainerBox, Position = dim2(0, 14, 0, 34), Size = dim2(1, -28, 0, 8), BackgroundColor3 = themes.preset.background, Text = "", AutoButtonColor = false })
    Valley:Themify(Items.Track, "background", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })
    
    Items.Fill = Valley:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Valley:Themify(Items.Fill, "accent", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    -- Knob
    Items.Knob = Valley:Create("Frame", {Parent = Items.Fill, AnchorPoint = vec2(1, 0.5), Position = dim2(1, 4, 0.5, 0), Size = dim2(0, 14, 0, 14), BackgroundColor3 = rgb(255,255,255)})
    Valley:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    
    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        Valley:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.15))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = true; Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Valley)
end

function Valley:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = Valley:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), 
        BackgroundColor3 = themes.preset.element 
    })
    Valley:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Input = Valley:Create("TextBox", { 
        Parent = Items.ContainerBox, Position = dim2(0, 14, 0, 0), Size = dim2(1, -28, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Valley:Themify(Items.Input, "text", "TextColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Valley)
end

function Valley:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or properties.items or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.ContainerBox = Valley:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), 
        BackgroundColor3 = themes.preset.element 
    })
    Valley:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Main = Valley:Create("TextButton", { 
        Parent = Items.ContainerBox, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false 
    })

    Items.Title = Valley:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 14, 0, 0), Size = dim2(0, 100, 1, 0), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Valley:Themify(Items.Title, "subtext", "TextColor3")

    Items.SelectedText = Valley:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 114, 0, 0), Size = dim2(1, -142, 1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Right })
    Valley:Themify(Items.SelectedText, "text", "TextColor3")
    
    Items.Icon = Valley:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://10723415903", ImageColor3 = themes.preset.subtext, Rotation = -90 })

    Items.DropFrame = Valley:Create("Frame", { 
        Parent = Valley.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Valley:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Scroll = Valley:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -8), Position = dim2(0, 0, 0, 4), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, ZIndex = 201 
    })
    Valley:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false

    function Cfg.UpdatePosition()
        local absPos = Items.Main.AbsolutePosition
        local absSize = Items.Main.AbsoluteSize
        Items.DropFrame.Position = dim2(0, absPos.X, 0, absPos.Y + absSize.Y + 6)
        Items.Scroll.CanvasSize = dim2(0, 0, 0, #Cfg.Options * 28)
    end

    local function ToggleDropdown()
        if isTweening then return end
        Open = not Open
        isTweening = true

        if Open then
            Items.DropFrame.Visible = true
            Cfg.UpdatePosition()
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            local targetHeight = math.clamp(#Cfg.Options * 28 + 8, 0, 160)
            Valley:Tween(Items.Icon, {Rotation = 90}, TweenInfo.new(0.3))
            local tw = Valley:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            Valley:Tween(Items.Icon, {Rotation = -90}, TweenInfo.new(0.3))
            local tw = Valley:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
                
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
                   not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    ToggleDropdown()
                end
            end
        end
    end)

    local OptionBtns = {}
    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, btn in ipairs(OptionBtns) do btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = Valley:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 28), BackgroundTransparency = 1, 
                Text = "   " .. tostring(opt), TextColor3 = themes.preset.text, TextSize = 13, 
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
            })
            Valley:Themify(btn, "text", "TextColor3")
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, btn)
        end
    end

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    RunService.RenderStepped:Connect(function() 
        if Open or isTweening then 
            Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 6)
        end 
    end)
    return setmetatable(Cfg, Valley)
end

function Valley:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.ContainerBox = Valley:Create("Frame", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 40 or 36), 
        BackgroundColor3 = themes.preset.element 
    })
    Valley:Themify(Items.ContainerBox, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.ContainerBox, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.ContainerBox, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Title = Valley:Create("TextLabel", { 
        Parent = Items.ContainerBox, Position = dim2(0, 14, 0, 0), Size = dim2(1, -28, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Enum.TextYAlignment.Center 
    })
    Valley:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = tostring(val) end

    Cfg.Items.Container = Items.ContainerBox 
    return setmetatable(Cfg, Valley)
end

function Valley:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local attachParent = self.Items.ContainerBox or self.Items.Button or self.Items.Container
    
    local btn = Valley:Create("TextButton", { 
        Parent = attachParent, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -12, 0.5, 0), 
        Size = dim2(0, 44, 0, 20), BackgroundColor3 = Cfg.Color, Text = "" 
    })
    Valley:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 6)})
    Valley:Create("UIStroke", {Parent = btn, Color = rgb(0,0,0), Thickness = 1, Transparency = 0.5})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = Valley:Create("Frame", { Parent = Valley.Gui, Size = dim2(0, 160, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Valley:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SVMap = Valley:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 0, 8), Size = dim2(1, -16, 1, -38), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Valley:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 6) })
    Items.SVImage = Valley:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    Valley:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 6) })
    
    Items.SVKnob = Valley:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 8, 0, 8), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Valley:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    Valley:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0) })

    Items.HueBar = Valley:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 8, 1, -22), Size = dim2(1, -16, 0, 14), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Valley:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 6) })
    Valley:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = Valley:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 6, 1, 4), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Valley:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })
    Valley:Create("UICorner", { Parent = Items.HueKnob, CornerRadius = dim(0, 3) })

    local Open = false
    local isTweening = false

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
            local tw = Valley:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 150)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = Valley:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, dim2(0, 160, 0, 150)
                local p1, s1 = btn.AbsolutePosition, btn.AbsoluteSize
                if not (mx >= p0.X and mx <= p0.X + s0.X.Offset and my >= p0.Y and my <= p0.Y + s0.Y.Offset) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    Toggle()
                end
            end
        end
    end)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local svDragging, hueDragging = false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Items.SVKnob.Position = dim2(x, 0, y, 0)
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Items.HueKnob.Position = dim2(x, 0, 0.5, 0)
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if Open or isTweening then Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X - 160 + btn.AbsoluteSize.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 8) end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Valley)
end

function Valley:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local attachParent = self.Items.ContainerBox or self.Items.Button or self.Items.Container
    local KeyBtn = Valley:Create("TextButton", { Parent = attachParent, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -12, 0.5, 0), Size = dim2(0, 44, 0, 22), BackgroundColor3 = themes.preset.background, TextColor3 = themes.preset.text, Text = Keys[Cfg.Default] or "None", TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), })
    Valley:Themify(KeyBtn, "background", "BackgroundColor3")
    Valley:Themify(KeyBtn, "text", "TextColor3")

    Valley:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 6)})
    Valley:Themify(Valley:Create("UIStroke", { Parent = KeyBtn, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Valley)
end

function Notifications:RefreshNotifications()
    local offset = 50
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 36)
        Valley:Tween(v, {Position = dim_offset(20, offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 10)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Notification"; 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = Valley:Create("Frame", { Parent = Valley.Gui; Position = dim_offset(-500, 50); Size = dim2(0, 300, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.element; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true })
    Valley:Themify(Items.Outline, "element", "BackgroundColor3")
    Valley:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 8) })
    Valley:Themify(Valley:Create("UIStroke", { Parent = Items.Outline, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")
   
    Items.Name = Valley:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Valley:Themify(Items.Name, "text", "TextColor3")
   
    Valley:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 12); PaddingBottom = dim(0, 12); PaddingRight = dim(0, 14); PaddingLeft = dim(0, 14); })
   
    Items.TimeBar = Valley:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 3), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Valley:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 50)
        Notifications:RefreshNotifications()
        Valley:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 3)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        Valley:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.4)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        task.wait(0.05)
        Notifications:RefreshNotifications()
    end)
end

function Valley:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

function Valley:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

local ConfigHolder
function Valley:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(Valley.Directory .. "/configs") do
        local Name = file:gsub(Valley.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Valley.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function Valley:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left", Icon = "rbxassetid://10723415903"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    Valley:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Valley.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Valley:GetConfig())
            Valley:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            Valley:LoadConfig(readfile(Valley.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Valley:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Valley.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Valley:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Theme Settings", Side = "Right", Icon = "rbxassetid://10734950309"})

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Valley:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) Valley:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) Valley:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) Valley:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) Valley:RefreshTheme("text", color3) end, Color = themes.preset.text })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right", Icon = "rbxassetid://10734944415"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })
end
return Valley
