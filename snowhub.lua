--[[
    ❄️ SnowHub — Universal (Mobile + PC)
    Fixed: чёрный градиент на кнопках убран
]]

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local http = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local IS_MOBILE = uis.TouchEnabled and not uis.KeyboardEnabled
local IS_PC = uis.KeyboardEnabled and not uis.TouchEnabled
local IS_HYBRID = uis.TouchEnabled and uis.KeyboardEnabled

local VIS = {
    bg = Color3.fromRGB(8, 11, 18),
    panel = Color3.fromRGB(13, 17, 27),
    panel2 = Color3.fromRGB(18, 23, 35),
    card = Color3.fromRGB(22, 28, 42),
    cardHover = Color3.fromRGB(29, 37, 55),
    text = Color3.fromRGB(245, 248, 255),
    muted = Color3.fromRGB(145, 157, 181),
    accent = Color3.fromRGB(96, 190, 255),
    accent2 = Color3.fromRGB(126, 102, 255),
    good = Color3.fromRGB(67, 224, 145),
    bad = Color3.fromRGB(255, 82, 110),
    warn = Color3.fromRGB(255, 190, 78),
}

local function V_Tween(obj, props, duration, style, direction)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(
        duration or 0.18,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

local function V_Round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = obj
    return c
end

local function V_Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or VIS.accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.25
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function V_Gradient(obj, a, b, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(a or VIS.panel2, b or VIS.panel)
    g.Rotation = rotation or 135
    g.Parent = obj
    return g
end

local function V_Button(btn, normal, hover, active)
    btn.AutoButtonColor = false
    local base = normal or btn.BackgroundColor3
    local over = hover or VIS.cardHover
    local down = active or over

    btn.MouseEnter:Connect(function()
        V_Tween(btn, {BackgroundColor3 = over}, 0.10)
    end)
    btn.MouseLeave:Connect(function()
        V_Tween(btn, {BackgroundColor3 = base}, 0.14)
    end)
    btn.MouseButton1Down:Connect(function()
        V_Tween(btn, {BackgroundColor3 = down}, 0.05)
    end)
    btn.MouseButton1Up:Connect(function()
        V_Tween(btn, {BackgroundColor3 = over}, 0.07)
    end)
end

for _, g in pairs(player.PlayerGui:GetChildren()) do
    if g.Name:find("SnowHub") or g.Name:find("KazelLost") then g:Destroy() end
end

local MAIN_CONFIG = "SnowHub_Main.json"
local defaultSettings = {
    ESPKiller = true, ESPKillerColor = {255,0,0},
    ESPSurvivor = true, ESPSurvivorColor = {0,255,0},
    ESPGenerator = true, ESPGeneratorColor = {150,0,255},
    ESPPallet = true, ESPPalletColor = {255,200,0},
    ESPHook = true, ESPHookColor = {255,100,255},
    ShowDistance = true, ShowNames = true,
    AutoSkillCheck = true,
    GodMode = false, NoStun = false,
    Speed = 16, VaultSpeed = 1,
    NoClip = false, Fly = false, FlySpeed = 50,
    FullBright = false, NoFog = false, FOV = 70,
    ESPEnabled = true,
    ShowFPS = true,
    FreezeButtons = false,
    Pos_OpenBtn = {0, 15, 0.5, -25},
    Pos_FPS = {0.5, -45, 0, 10},
    Pos_Menu = {0.5, -210, 0.5, -160},
    Pos_FlyUp = {1, -130, 0.6, 0},
    Pos_FlyDown = {1, -130, 0.6, 65},
    Pos_Floats = {},
    Keybind_Fly = "G",
    Keybind_NoClip = "N",
    Keybind_SkillCheck = "H",
    Keybind_GodMode = "B",
    Keybind_ESP = "V",
    Keybind_TP_Nearest = "T",
    Keybind_TP_Killer = "K",
}

local Settings = {}

local function loadConfigFromFile(filename)
    if not (isfile and readfile and isfile(filename)) then return false end
    local ok, data = pcall(function() return http:JSONDecode(readfile(filename)) end)
    if not ok or not data then return false end
    for k, v in pairs(defaultSettings) do
        Settings[k] = data[k] ~= nil and data[k] or v
    end
    return true
end

local function saveConfigToFile(filename)
    if not writefile then return false end
    local ok = pcall(function() writefile(filename, http:JSONEncode(Settings)) end)
    return ok
end

if not loadConfigFromFile(MAIN_CONFIG) then
    for k, v in pairs(defaultSettings) do Settings[k] = v end
end

local function getColor(key)
    local v = Settings[key]
    if type(v) == "table" then return Color3.fromRGB(v[1], v[2], v[3]) end
    return v or Color3.fromRGB(255,255,255)
end

local function restorePosition(frame, saveKey)
    local pos = Settings[saveKey]
    if pos and type(pos) == "table" and #pos == 4 then
        frame.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
    end
end

local function strToKeyCode(str)
    if not str then return nil end
    for _, kc in pairs(Enum.KeyCode:GetEnumItems()) do
        if kc.Name:upper() == str:upper() then return kc end
    end
    return nil
end

local killerList = {}
local espObjects = {}
local lastESPUpdate = 0
local lastObjectCache = 0
local cachedObjects = {}
local flyUpFlag = false
local flyDownFlag = false
local toggleButtons = {}
local waitingForKey = nil

local function syncToggle(key, value)
    if toggleButtons[key] and toggleButtons[key].Parent then
        toggleButtons[key].BackgroundColor3 = value and VIS.good or Color3.fromRGB(42, 49, 67)
        toggleButtons[key].Text = value and "ON" or "OFF"
    end
end

local function syncAllToggles()
    for key, btn in pairs(toggleButtons) do
        if btn and btn.Parent then
            local value = Settings[key]
            btn.BackgroundColor3 = value and VIS.good or Color3.fromRGB(42, 49, 67)
            btn.Text = value and "ON" or "OFF"
        end
    end
end

local function setProperCollision(enable)
    for _, p in pairs(character:GetDescendants()) do
        if p:IsA("BasePart") then
            if enable then
                local name = p.Name
                if name == "HumanoidRootPart" or name == "Torso" or name == "UpperTorso" or name == "LowerTorso" or name == "Head" then
                    p.CanCollide = true
                else
                    p.CanCollide = false
                end
            else
                p.CanCollide = false
            end
        end
    end
end

local function tpToNearestPlayer()
    local nearest, minDist = nil, math.huge
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = v.Character.HumanoidRootPart
            end
        end
    end
    if nearest then rootPart.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 3, 0)) end
end

local function tpToFarthestPlayer()
    local farthest, maxDist = nil, 0
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if dist > maxDist then
                maxDist = dist
                farthest = v.Character.HumanoidRootPart
            end
        end
    end
    if farthest then rootPart.CFrame = CFrame.new(farthest.Position + Vector3.new(0, 3, 0)) end
end

local function tpBehindKiller()
    local killer, minDist = nil, math.huge
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local role = getRole(v.Character)
            local isK = (role == "Killer") or killerList[v.Name]
            if isK then
                local dist = (v.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    killer = v.Character.HumanoidRootPart
                end
            end
        end
    end
    if killer then rootPart.CFrame = killer.CFrame * CFrame.new(0, 2, 3) end
end

local function tpToLobby()
    local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChild("Spawn")
    if spawn and spawn:IsA("BasePart") then
        rootPart.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
    end
end

local ESP_INTERVAL = 0.5
local CACHE_INTERVAL = 2

local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"
local HeartbeatConnection = nil
local VisibilityConnection = nil

local function GetActionTarget()
    local current = player.PlayerGui
    for segment in string.gmatch(ActionPath, "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

local function TriggerMobileButton()
    local b = GetActionTarget()
    if b and b:IsA("GuiObject") then
        local p, s, i = b.AbsolutePosition, b.AbsoluteSize, GuiService:GetGuiInset()
        local cx, cy = p.X + (s.X/2) + i.X, p.Y + (s.Y/2) + i.Y
        pcall(function()
            VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy)
        end)
    end
end

local function InitializeSkillCheck()
    task.spawn(function()
        local prompt = player.PlayerGui:WaitForChild("SkillCheckPromptGui", 15)
        if not prompt then return end
        local check = prompt:WaitForChild("Check", 10)
        if not check then return end
        local line = check:WaitForChild("Line", 10)
        local goal = check:WaitForChild("Goal", 10)
        if not line or not goal then return end
        
        if VisibilityConnection then VisibilityConnection:Disconnect() end
        VisibilityConnection = check:GetPropertyChangedSignal("Visible"):Connect(function()
            if not Settings.AutoSkillCheck then return end
            local myTeam = player.Team and player.Team.Name or ""
            if not myTeam:lower():find("surviv") then return end
            
            if check.Visible then
                if HeartbeatConnection then HeartbeatConnection:Disconnect() end
                HeartbeatConnection = runService.Heartbeat:Connect(function()
                    if not Settings.AutoSkillCheck then
                        if HeartbeatConnection then HeartbeatConnection:Disconnect() end
                        return
                    end
                    local lr = line.Rotation % 360
                    local gr = goal.Rotation % 360
                    local ss, se = (gr + 101) % 360, (gr + 115) % 360
                    local inZone = (ss > se and (lr >= ss or lr <= se)) or (lr >= ss and lr <= se)
                    if inZone then
                        TriggerMobileButton()
                        if HeartbeatConnection then
                            HeartbeatConnection:Disconnect()
                            HeartbeatConnection = nil
                        end
                    end
                end)
            else
                if HeartbeatConnection then
                    HeartbeatConnection:Disconnect()
                    HeartbeatConnection = nil
                end
            end
        end)
    end)
end

InitializeSkillCheck()

players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        c:WaitForChild("Humanoid").Died:Connect(function()
            local k = c.Humanoid:FindFirstChild("LastAttacker")
            if k and k:IsA("Instance") then
                local kp = players:GetPlayerFromCharacter(k.Parent)
                if kp then killerList[kp.Name] = tick() end
            end
        end)
    end)
end)

function getRole(char)
    local plr = players:GetPlayerFromCharacter(char)
    if plr and plr.Team then
        local tn = plr.Team.Name:lower()
        if tn:find("kill") or tn:find("murder") then return "Killer" end
        if tn:find("surviv") or tn:find("innocent") then return "Survivor" end
    end
    return "Survivor"
end

local function makeDraggable(frame, handle, saveKey)
    handle = handle or frame
    local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
    
    handle.InputBegan:Connect(function(input)
        if Settings.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
        end
    end)
    handle.InputChanged:Connect(function(input)
        if Settings.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging and saveKey then
                Settings[saveKey] = {
                    frame.Position.X.Scale, frame.Position.X.Offset,
                    frame.Position.Y.Scale, frame.Position.Y.Offset
                }
                saveConfigToFile(MAIN_CONFIG)
            end
            dragging = false
        end
    end)
    runService.RenderStepped:Connect(function()
        if Settings.FreezeButtons then dragging = false; return end
        if dragging and dragInput then
            local delta = dragInput.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SnowHub_Main"
gui.Parent = player.PlayerGui
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.None

local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "SnowHub_FPS"
fpsGui.Parent = player.PlayerGui
fpsGui.IgnoreGuiInset = true
fpsGui.ResetOnSpawn = false
fpsGui.DisplayOrder = 2147483646
fpsGui.ScreenInsets = Enum.ScreenInsets.None

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(0, 90, 0, 30)
fpsFrame.BackgroundColor3 = VIS.panel
fpsFrame.BackgroundTransparency = 0.04
fpsFrame.BorderSizePixel = 0
fpsFrame.Parent = fpsGui
V_Round(fpsFrame, 10)
V_Gradient(fpsFrame, Color3.fromRGB(23, 34, 54), VIS.panel, 135)
local fpsStroke = V_Stroke(fpsFrame, VIS.good, 1.5, 0.15)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Parent = fpsFrame

makeDraggable(fpsFrame, nil, "Pos_FPS")
restorePosition(fpsFrame, "Pos_FPS")

local fpsCount, fpsTime = 0, 0
runService.RenderStepped:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsTime = fpsTime + dt
    if fpsTime >= 0.5 then
        local v = math.floor(fpsCount / fpsTime)
        fpsCount, fpsTime = 0, 0
        if fpsLabel then
            fpsLabel.Text = "FPS: " .. v
            if v >= 45 then
                fpsLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
                fpsStroke.Color = Color3.fromRGB(60, 180, 100)
            elseif v >= 25 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
                fpsStroke.Color = Color3.fromRGB(200, 180, 60)
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                fpsStroke.Color = Color3.fromRGB(200, 60, 60)
            end
        end
    end
end)

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.BackgroundColor3 = VIS.panel2
openBtn.Text = "❄"
openBtn.TextColor3 = VIS.text
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.BorderSizePixel = 0
openBtn.Parent = gui
V_Round(openBtn, 999)
V_Gradient(openBtn, Color3.fromRGB(35, 57, 88), Color3.fromRGB(14, 18, 29), 135)
local os = V_Stroke(openBtn, VIS.accent, 2, 0.12)
V_Button(openBtn, VIS.panel2, Color3.fromRGB(31, 43, 65))
makeDraggable(openBtn, nil, "Pos_OpenBtn")
restorePosition(openBtn, "Pos_OpenBtn")

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 420, 0, 320)
menu.BackgroundColor3 = VIS.panel
menu.BackgroundTransparency = 0.02
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = gui
V_Round(menu, 16)
V_Gradient(menu, Color3.fromRGB(20, 27, 42), Color3.fromRGB(9, 12, 20), 135)
local ms = V_Stroke(menu, Color3.fromRGB(74, 105, 155), 1.2, 0.15)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(11, 16, 26)
topBar.BorderSizePixel = 0
topBar.Parent = menu
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)
local tbf = Instance.new("Frame", topBar)
tbf.Size = UDim2.new(1, 0, 0, 10)
tbf.Position = UDim2.new(0, 0, 1, -10)
tbf.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
tbf.BorderSizePixel = 0

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 30, 0, 30)
logoIcon.Position = UDim2.new(0, 8, 0, 4)
logoIcon.BackgroundTransparency = 1
logoIcon.Text = "❄"
logoIcon.TextColor3 = Color3.fromRGB(255,255,255)
logoIcon.TextScaled = true
logoIcon.Font = Enum.Font.GothamBold
logoIcon.Parent = topBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 130, 0, 16)
titleLbl.Position = UDim2.new(0, 44, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SnowHub"
titleLbl.TextColor3 = Color3.fromRGB(255,255,255)
titleLbl.TextScaled = true
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = topBar

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0, 130, 0, 14)
subLbl.Position = UDim2.new(0, 44, 0, 20)
subLbl.BackgroundTransparency = 1
subLbl.Text = IS_MOBILE and "Mobile" or (IS_PC and "PC" or "Hybrid")
subLbl.TextColor3 = Color3.fromRGB(130, 130, 150)
subLbl.TextScaled = true
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Font = Enum.Font.Gotham
subLbl.Parent = topBar

local titleAccent = Instance.new("Frame")
titleAccent.Size = UDim2.new(0, 72, 0, 2)
titleAccent.Position = UDim2.new(0, 44, 1, -3)
titleAccent.BackgroundColor3 = VIS.accent
titleAccent.BorderSizePixel = 0
titleAccent.Parent = topBar
V_Round(titleAccent, 999)
local titleGradient = V_Gradient(titleAccent, VIS.accent, VIS.accent2, 0)

task.spawn(function()
    while titleAccent.Parent do
        titleGradient.Offset = Vector2.new(-1, 0)
        V_Tween(titleGradient, {Offset = Vector2.new(1, 0)}, 1.6, Enum.EasingStyle.Linear)
        task.wait(1.6)
    end
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -70, 0, 4)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = topBar
V_Button(minimizeBtn, Color3.fromRGB(11,16,26), Color3.fromRGB(32,42,58))

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -36, 0, 4)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar
V_Button(closeBtn, Color3.fromRGB(11,16,26), Color3.fromRGB(75,35,48))

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 130, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
sidebar.BorderSizePixel = 0
sidebar.Parent = menu
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local sideList = Instance.new("Frame")
sideList.Size = UDim2.new(1, -10, 1, -50)
sideList.Position = UDim2.new(0, 5, 0, 5)
sideList.BackgroundTransparency = 1
sideList.Parent = sidebar
local sideLayout = Instance.new("UIListLayout", sideList)
sideLayout.Padding = UDim.new(0, 4)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -140, 1, -50)
content.Position = UDim2.new(0, 135, 0, 44)
content.BackgroundTransparency = 1
content.Parent = menu

local pages = {}
local pageButtons = {}

local function createPage(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = VIS.panel2
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = VIS.muted
    btn.TextScaled = true
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = sideList
    V_Round(btn, 8)
    V_Button(btn, VIS.panel2, VIS.cardHover)
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 6)
    Instance.new("UIListLayout", page).SortOrder = Enum.SortOrder.LayoutOrder
    
    table.insert(pageButtons, btn)
    table.insert(pages, page)
    
    btn.Activated:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
        for _, b in pairs(pageButtons) do
            b.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            b.TextColor3 = Color3.fromRGB(200, 200, 215)
        end
        btn.BackgroundColor3 = Color3.fromRGB(31, 55, 82)
        btn.TextColor3 = VIS.text
    end)
    
    return page
end

local combatPage = createPage("Combat", "⚔")
local tpPage = createPage("Teleport", "🌐")
local espPage = createPage("ESP", "👁")
local movePage = createPage("Movement", "🏃")
local visualPage = createPage("Visual", "🎨")
local keybindPage = createPage("Keybinds", "⌨️")
local configPage = createPage("Configs", "💾")

pageButtons[1].BackgroundColor3 = Color3.fromRGB(35, 35, 50)
pageButtons[1].TextColor3 = Color3.fromRGB(255,255,255)
pages[1].Visible = true

local function addToggle(page, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 34)
    row.BackgroundColor3 = VIS.card
    row.BorderSizePixel = 0
    row.Parent = page
    V_Round(row, 9)
    V_Stroke(row, Color3.fromRGB(48, 61, 84), 1, 0.45)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = VIS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = row
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(1, -55, 0.5, -11)
    btn.BackgroundColor3 = Settings[key] and VIS.good or Color3.fromRGB(42, 49, 67)
    btn.Text = Settings[key] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    toggleButtons[key] = btn
    
    btn.Activated:Connect(function()
        Settings[key] = not Settings[key]
        btn.BackgroundColor3 = Settings[key] and VIS.good or Color3.fromRGB(42, 49, 67)
        btn.Text = Settings[key] and "ON" or "OFF"
        saveConfigToFile(MAIN_CONFIG)
    end)
end

local function addSlider(page, label, key, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 50)
    row.BackgroundColor3 = VIS.card
    row.BorderSizePixel = 0
    row.Parent = page
    V_Round(row, 9)
    V_Stroke(row, Color3.fromRGB(48, 61, 84), 1, 0.45)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 0.45, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = VIS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = row
    
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.4, 0, 0.45, 0)
    val.Position = UDim2.new(0.6, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(Settings[key])
    val.TextColor3 = Color3.fromRGB(100, 200, 255)
    val.TextScaled = true
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Font = Enum.Font.GothamBold
    val.Parent = row
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.9, 0, 0.2, 0)
    slider.Position = UDim2.new(0.05, 0, 0.65, 0)
    slider.BackgroundColor3 = Color3.fromRGB(39, 47, 66)
    slider.BorderSizePixel = 0
    slider.Parent = row
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0.5, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Settings[key]-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = VIS.accent
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)
    
    local drag = Instance.new("TextButton")
    drag.Size = UDim2.new(0, 16, 0, 16)
    drag.Position = UDim2.new((Settings[key]-min)/(max-min), -8, 0.5, -8)
    drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    drag.Text = ""
    drag.BorderSizePixel = 0
    drag.Parent = slider
    Instance.new("UICorner", drag).CornerRadius = UDim.new(0.5, 0)
    
    local d = false
    drag.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then d = true end
    end)
    uis.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if d then saveConfigToFile(MAIN_CONFIG) end
            d = false
        end
    end)
    uis.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local pos = math.clamp((i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local v = math.round(min + pos*(max-min))
            Settings[key] = v
            val.Text = tostring(v)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            drag.Position = UDim2.new(pos, -8, 0.5, -8)
        end
    end)
end

local function addColorPicker(page, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 40)
    row.BackgroundColor3 = VIS.card
    row.BorderSizePixel = 0
    row.Parent = page
    V_Round(row, 9)
    V_Stroke(row, Color3.fromRGB(48, 61, 84), 1, 0.45)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.35, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = VIS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = row
    
    local colors = {
        Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255),
        Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255),
        Color3.fromRGB(255,255,255), Color3.fromRGB(255,165,0),
    }
    
    for i, col in ipairs(colors) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 20, 0, 20)
        b.Position = UDim2.new(0.38 + (i-1)*0.075, 0, 0.5, -10)
        b.BackgroundColor3 = col
        b.Text = ""
        b.BorderSizePixel = 0
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
        b.Activated:Connect(function()
            Settings[key] = {math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255)}
            saveConfigToFile(MAIN_CONFIG)
        end)
    end
end

local function addButton(page, label, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 38)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 130, 200)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = page
    V_Round(btn, 9)
    V_Stroke(btn, Color3.fromRGB(255,255,255), 1, 0.86)
    V_Button(btn, color or VIS.accent, color and color:Lerp(Color3.new(1,1,1), 0.12) or Color3.fromRGB(120, 210, 255))
    btn.Activated:Connect(callback)
    return btn
end

addToggle(combatPage, "Auto Skill Check", "AutoSkillCheck")
addToggle(combatPage, "God Mode", "GodMode")
addToggle(combatPage, "No Stun", "NoStun")

addButton(tpPage, "🎯 TP к ближайшему игроку", tpToNearestPlayer, Color3.fromRGB(100, 150, 255))
addButton(tpPage, "🔪 TP за спину киллера", tpBehindKiller, Color3.fromRGB(255, 100, 100))
addButton(tpPage, "📋 TP к дальнему игроку", tpToFarthestPlayer, Color3.fromRGB(200, 150, 50))
addButton(tpPage, "🏠 TP в лобби (спавн)", tpToLobby, Color3.fromRGB(150, 150, 150))

addToggle(espPage, "ESP Killers", "ESPKiller")
addToggle(espPage, "ESP Survivors", "ESPSurvivor")
addToggle(espPage, "ESP Generators", "ESPGenerator")
addToggle(espPage, "ESP Pallets", "ESPPallet")
addToggle(espPage, "ESP Hooks", "ESPHook")
addToggle(espPage, "Show Distance", "ShowDistance")
addToggle(espPage, "Show Names", "ShowNames")

addSlider(movePage, "Speed", "Speed", 10, 200)
addSlider(movePage, "Vault Speed", "VaultSpeed", 1, 10)
addSlider(movePage, "Fly Speed", "FlySpeed", 20, 200)
addToggle(movePage, "NoClip", "NoClip")
addToggle(movePage, "Fly", "Fly")

addToggle(visualPage, "Show FPS Counter", "ShowFPS")
addToggle(visualPage, "FullBright", "FullBright")
addToggle(visualPage, "No Fog", "NoFog")
addSlider(visualPage, "FOV", "FOV", 30, 120)
addColorPicker(visualPage, "Killer Color", "ESPKillerColor")
addColorPicker(visualPage, "Survivor Color", "ESPSurvivorColor")
addColorPicker(visualPage, "Gen Color", "ESPGeneratorColor")
addColorPicker(visualPage, "Pallet Color", "ESPPalletColor")

syncAllToggles()

local floatGui = Instance.new("ScreenGui")
floatGui.Name = "SnowHub_Floats"
floatGui.Parent = player.PlayerGui
floatGui.IgnoreGuiInset = true
floatGui.ResetOnSpawn = false
floatGui.DisplayOrder = 2147483645
floatGui.ScreenInsets = Enum.ScreenInsets.None

local activeFloats = {}

local keybindFunctions = {
    {label = "✈️ Fly", key = "Fly", color = Color3.fromRGB(100, 200, 255)},
    {label = "👻 NoClip", key = "NoClip", color = Color3.fromRGB(150, 200, 255)},
    {label = "✅ SkillCheck", key = "AutoSkillCheck", color = Color3.fromRGB(100, 255, 200)},
    {label = "🛡️ GodMode", key = "GodMode", color = Color3.fromRGB(255, 100, 100)},
    {label = "👁️ ESP", key = "ESPEnabled", color = Color3.fromRGB(100, 255, 100)},
    {label = "💥 NoStun", key = "NoStun", color = Color3.fromRGB(255, 200, 100)},
    {label = "🎯 TP", key = "TP_Nearest", color = Color3.fromRGB(100, 150, 255), isAction = true},
    {label = "🔪 TP Killer", key = "TP_Killer", color = Color3.fromRGB(255, 100, 100), isAction = true},
}

local pcKeybindList = {
    {label = "✈️ Fly", settingKey = "Keybind_Fly", funcKey = "Fly", isAction = false},
    {label = "👻 NoClip", settingKey = "Keybind_NoClip", funcKey = "NoClip", isAction = false},
    {label = "✅ SkillCheck", settingKey = "Keybind_SkillCheck", funcKey = "AutoSkillCheck", isAction = false},
    {label = "🛡️ GodMode", settingKey = "Keybind_GodMode", funcKey = "GodMode", isAction = false},
    {label = "👁️ ESP", settingKey = "Keybind_ESP", funcKey = "ESPEnabled", isAction = false},
    {label = "🎯 TP Nearest", settingKey = "Keybind_TP_Nearest", funcKey = "TP_Nearest", isAction = true},
    {label = "🔪 TP Killer", settingKey = "Keybind_TP_Killer", funcKey = "TP_Killer", isAction = true},
}

-- ФИКС: создание плавающей кнопки БЕЗ чёрного градиента
local function createFloatBtn(label, key, color, size, position)
    if activeFloats[key] and activeFloats[key].Parent then
        activeFloats[key]:Destroy()
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = size
    
    if Settings.Pos_Floats and Settings.Pos_Floats[key] then
        local p = Settings.Pos_Floats[key]
        btn.Position = UDim2.new(p[1], p[2], p[3], p[4])
    else
        btn.Position = position
    end
    
    btn.BackgroundColor3 = Settings[key] and color or Color3.fromRGB(80, 80, 80)
    btn.BackgroundTransparency = 0.06
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = floatGui
    V_Round(btn, 999)
    
    -- ГРАДИЕНТ: светлый → чуть темнее (НЕ чёрный!)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1,1,1), 0.25)),
        ColorSequenceKeypoint.new(1, color:Lerp(Color3.new(0,0,0), 0.15))
    }
    grad.Rotation = 135
    grad.Parent = btn
    
    -- Обводка без пульсации
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = 2
    s.Transparency = 0.3
    s.Parent = btn
    
    V_Button(btn, color, color:Lerp(Color3.new(1,1,1), 0.15))
    
    local isAction = false
    for _, f in ipairs(keybindFunctions) do
        if f.key == key and f.isAction then isAction = true; break end
    end
    
    local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
    local moved = false
    
    btn.InputBegan:Connect(function(input)
        if Settings.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            mousePos = input.Position
            framePos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if Settings.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not moved then
                if isAction then
                    if key == "TP_Nearest" then tpToNearestPlayer()
                    elseif key == "TP_Killer" then tpBehindKiller() end
                else
                    Settings[key] = not Settings[key]
                    btn.BackgroundColor3 = Settings[key] and color or Color3.fromRGB(80, 80, 80)
                    saveConfigToFile(MAIN_CONFIG)
                    syncToggle(key, Settings[key])
                end
            else
                if not Settings.Pos_Floats then Settings.Pos_Floats = {} end
                Settings.Pos_Floats[key] = {
                    btn.Position.X.Scale, btn.Position.X.Offset,
                    btn.Position.Y.Scale, btn.Position.Y.Offset
                }
                saveConfigToFile(MAIN_CONFIG)
            end
            dragging = false
            dragInput = nil
        end
    end)
    runService.RenderStepped:Connect(function()
        if Settings.FreezeButtons then dragging = false; return end
        if dragging and dragInput then
            local delta = dragInput.Position - mousePos
            if delta.Magnitude > 5 then moved = true end
            btn.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
    
    activeFloats[key] = btn
end

task.spawn(function()
    task.wait(1)
    if Settings.Pos_Floats then
        for key, pos in pairs(Settings.Pos_Floats) do
            for _, func in ipairs(keybindFunctions) do
                if func.key == key then
                    createFloatBtn(func.label, func.key, func.color, UDim2.new(0, 55, 0, 55), UDim2.new(pos[1], pos[2], pos[3], pos[4]))
                    break
                end
            end
        end
    end
end)

local kbAddMenu = Instance.new("Frame")
kbAddMenu.Size = UDim2.new(0, 340, 0, 400)
kbAddMenu.Position = UDim2.new(0.5, -170, 0.5, -200)
kbAddMenu.BackgroundColor3 = VIS.panel
kbAddMenu.BorderSizePixel = 0
kbAddMenu.Visible = false
kbAddMenu.Parent = gui
kbAddMenu.ZIndex = 100
Instance.new("UICorner", kbAddMenu).CornerRadius = UDim.new(0, 12)
V_Gradient(kbAddMenu, Color3.fromRGB(23, 31, 48), Color3.fromRGB(10, 13, 21), 135)
local kbs = V_Stroke(kbAddMenu, VIS.accent, 1.6, 0.12)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(1, 0, 0, 34)
kbTitle.BackgroundTransparency = 1
kbTitle.Text = "➕ Добавить кейбинд"
kbTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
kbTitle.TextScaled = true
kbTitle.Font = Enum.Font.GothamBold
kbTitle.Parent = kbAddMenu
kbTitle.ZIndex = 101

local kbClose = Instance.new("TextButton")
kbClose.Size = UDim2.new(0, 28, 0, 28)
kbClose.Position = UDim2.new(1, -32, 0, 4)
kbClose.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
kbClose.Text = "✕"
kbClose.TextColor3 = Color3.fromRGB(255,255,255)
kbClose.TextScaled = true
kbClose.BorderSizePixel = 0
kbClose.Parent = kbAddMenu
kbClose.ZIndex = 101
Instance.new("UICorner", kbClose).CornerRadius = UDim.new(0.5, 0)
kbClose.Activated:Connect(function() kbAddMenu.Visible = false end)

local kbScroll = Instance.new("ScrollingFrame")
kbScroll.Size = UDim2.new(1, -10, 1, -50)
kbScroll.Position = UDim2.new(0, 5, 0, 40)
kbScroll.BackgroundTransparency = 1
kbScroll.BorderSizePixel = 0
kbScroll.ScrollBarThickness = 3
kbScroll.CanvasSize = UDim2.new(0, 0, 0, #keybindFunctions * 100 + 20)
kbScroll.Parent = kbAddMenu
kbScroll.ZIndex = 101
Instance.new("UIListLayout", kbScroll).Padding = UDim.new(0, 6)

for _, func in ipairs(keybindFunctions) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 90)
    row.BackgroundColor3 = VIS.card
    row.BorderSizePixel = 0
    row.Parent = kbScroll
    row.ZIndex = 101
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 24)
    lbl.Position = UDim2.new(0, 8, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = func.label
    lbl.TextColor3 = VIS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = row
    lbl.ZIndex = 102
    
    local sizes = {
        {label = "S", size = UDim2.new(0, 40, 0, 40)},
        {label = "M", size = UDim2.new(0, 55, 0, 55)},
        {label = "L", size = UDim2.new(0, 75, 0, 75)},
    }
    
    for i, sz in ipairs(sizes) do
        local sizeBtn = Instance.new("TextButton")
        sizeBtn.Size = UDim2.new(0, 100, 0, 34)
        sizeBtn.Position = UDim2.new(0, 8 + (i-1)*104, 0, 34)
        sizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        sizeBtn.Text = sz.label .. " (" .. sz.size.X.Offset .. "px)"
        sizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
        sizeBtn.TextScaled = true
        sizeBtn.Font = Enum.Font.Gotham
        sizeBtn.BorderSizePixel = 0
        sizeBtn.Parent = row
        sizeBtn.ZIndex = 102
        Instance.new("UICorner", sizeBtn).CornerRadius = UDim.new(0, 6)
        
        sizeBtn.Activated:Connect(function()
            kbAddMenu.Visible = false
            menu.Visible = false
            
            local hint = Instance.new("TextLabel")
            hint.Size = UDim2.new(0, 300, 0, 60)
            hint.Position = UDim2.new(0.5, -150, 0.5, -30)
            hint.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
            hint.BackgroundTransparency = 0.1
            hint.Text = "Тапни там, где хочешь кнопку"
            hint.TextColor3 = Color3.fromRGB(100, 200, 255)
            hint.TextScaled = true
            hint.Font = Enum.Font.GothamBold
            hint.BorderSizePixel = 0
            hint.ZIndex = 200
            hint.Parent = gui
            Instance.new("UICorner", hint).CornerRadius = UDim.new(0, 10)
            
            local tapConn
            tapConn = uis.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local pos = UDim2.new(0, input.Position.X - sz.size.X.Offset/2, 0, input.Position.Y - sz.size.Y.Offset/2)
                    createFloatBtn(func.label, func.key, func.color, sz.size, pos)
                    hint:Destroy()
                    tapConn:Disconnect()
                end
            end)
        end)
    end
end

local pcKeybindMenu = Instance.new("Frame")
pcKeybindMenu.Size = UDim2.new(0, 340, 0, 400)
pcKeybindMenu.Position = UDim2.new(0.5, -170, 0.5, -200)
pcKeybindMenu.BackgroundColor3 = VIS.panel
pcKeybindMenu.BorderSizePixel = 0
pcKeybindMenu.Visible = false
pcKeybindMenu.Parent = gui
pcKeybindMenu.ZIndex = 100
Instance.new("UICorner", pcKeybindMenu).CornerRadius = UDim.new(0, 12)
V_Gradient(pcKeybindMenu, Color3.fromRGB(31, 29, 23), Color3.fromRGB(10, 13, 21), 135)
local pkbs = V_Stroke(pcKeybindMenu, VIS.warn, 1.6, 0.12)

local pkbTitle = Instance.new("TextLabel")
pkbTitle.Size = UDim2.new(1, 0, 0, 34)
pkbTitle.BackgroundTransparency = 1
pkbTitle.Text = "⌨️ ПК Кейбинды"
pkbTitle.TextColor3 = Color3.fromRGB(255, 180, 100)
pkbTitle.TextScaled = true
pkbTitle.Font = Enum.Font.GothamBold
pkbTitle.Parent = pcKeybindMenu
pkbTitle.ZIndex = 101

local pkbClose = Instance.new("TextButton")
pkbClose.Size = UDim2.new(0, 28, 0, 28)
pkbClose.Position = UDim2.new(1, -32, 0, 4)
pkbClose.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
pkbClose.Text = "✕"
pkbClose.TextColor3 = Color3.fromRGB(255,255,255)
pkbClose.TextScaled = true
pkbClose.BorderSizePixel = 0
pkbClose.Parent = pcKeybindMenu
pkbClose.ZIndex = 101
Instance.new("UICorner", pkbClose).CornerRadius = UDim.new(0.5, 0)
pkbClose.Activated:Connect(function() pcKeybindMenu.Visible = false end)

local pkbScroll = Instance.new("ScrollingFrame")
pkbScroll.Size = UDim2.new(1, -10, 1, -50)
pkbScroll.Position = UDim2.new(0, 5, 0, 40)
pkbScroll.BackgroundTransparency = 1
pkbScroll.BorderSizePixel = 0
pkbScroll.ScrollBarThickness = 3
pkbScroll.CanvasSize = UDim2.new(0, 0, 0, #pcKeybindList * 50 + 20)
pkbScroll.Parent = pcKeybindMenu
pkbScroll.ZIndex = 101
Instance.new("UIListLayout", pkbScroll).Padding = UDim.new(0, 6)

local pkbButtons = {}

local function refreshPcKeybindList()
    for _, btn in pairs(pkbButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    pkbButtons = {}
    
    for i, kb in ipairs(pcKeybindList) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 42)
        row.BackgroundColor3 = VIS.card
        row.BorderSizePixel = 0
        row.Parent = pkbScroll
        row.ZIndex = 101
        V_Round(row, 9)
        V_Stroke(row, Color3.fromRGB(48, 61, 84), 1, 0.45)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = kb.label
        lbl.TextColor3 = VIS.text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham
        lbl.Parent = row
        lbl.ZIndex = 102
        
        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 60, 0, 28)
        keyBtn.Position = UDim2.new(1, -72, 0.5, -14)
        keyBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
        keyBtn.Text = Settings[kb.settingKey] or "?"
        keyBtn.TextColor3 = Color3.fromRGB(255,255,255)
        keyBtn.TextScaled = true
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.BorderSizePixel = 0
        keyBtn.Parent = row
        keyBtn.ZIndex = 102
        Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)
        
        table.insert(pkbButtons, keyBtn)
        
        keyBtn.Activated:Connect(function()
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 60)
            waitingForKey = {settingKey = kb.settingKey, btn = keyBtn}
        end)
    end
end

refreshPcKeybindList()

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            Settings[waitingForKey.settingKey] = keyName
            waitingForKey.btn.Text = keyName
            waitingForKey.btn.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
            saveConfigToFile(MAIN_CONFIG)
            waitingForKey = nil
        end
    end
end)

local addKbBtn = Instance.new("TextButton")
addKbBtn.Size = UDim2.new(1, -6, 0, 44)
addKbBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
addKbBtn.Text = "📱 Добавить кнопку на экран"
addKbBtn.TextColor3 = Color3.fromRGB(255,255,255)
addKbBtn.TextScaled = true
addKbBtn.Font = Enum.Font.GothamBold
addKbBtn.BorderSizePixel = 0
addKbBtn.Parent = keybindPage
Instance.new("UICorner", addKbBtn).CornerRadius = UDim.new(0, 6)
addKbBtn.Activated:Connect(function()
    kbAddMenu.Visible = not kbAddMenu.Visible
end)

if IS_PC or IS_HYBRID then
    local pcKbBtn = Instance.new("TextButton")
    pcKbBtn.Size = UDim2.new(1, -6, 0, 44)
    pcKbBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 60)
    pcKbBtn.Text = "⌨️ ПК Кейбинды"
    pcKbBtn.TextColor3 = Color3.fromRGB(255,255,255)
    pcKbBtn.TextScaled = true
    pcKbBtn.Font = Enum.Font.GothamBold
    pcKbBtn.BorderSizePixel = 0
    pcKbBtn.Parent = keybindPage
    Instance.new("UICorner", pcKbBtn).CornerRadius = UDim.new(0, 6)
    pcKbBtn.Activated:Connect(function()
        refreshPcKeybindList()
        pcKeybindMenu.Visible = not pcKeybindMenu.Visible
    end)
end

local clearFloatsBtn = Instance.new("TextButton")
clearFloatsBtn.Size = UDim2.new(1, -6, 0, 44)
clearFloatsBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearFloatsBtn.Text = "🗑 Убрать все кнопки"
clearFloatsBtn.TextColor3 = Color3.fromRGB(255,255,255)
clearFloatsBtn.TextScaled = true
clearFloatsBtn.Font = Enum.Font.GothamBold
clearFloatsBtn.BorderSizePixel = 0
clearFloatsBtn.Parent = keybindPage
Instance.new("UICorner", clearFloatsBtn).CornerRadius = UDim.new(0, 6)
clearFloatsBtn.Activated:Connect(function()
    for key, btn in pairs(activeFloats) do
        if btn and btn.Parent then btn:Destroy() end
    end
    activeFloats = {}
    Settings.Pos_Floats = {}
    saveConfigToFile(MAIN_CONFIG)
end)

local freezeBtn = Instance.new("TextButton")
freezeBtn.Size = UDim2.new(1, -6, 0, 44)
freezeBtn.BackgroundColor3 = Settings.FreezeButtons and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(80, 80, 100)
freezeBtn.Text = Settings.FreezeButtons and "🔒 Кнопки заморожены" or "🔓 Заморозить кнопки"
freezeBtn.TextColor3 = Color3.fromRGB(255,255,255)
freezeBtn.TextScaled = true
freezeBtn.Font = Enum.Font.GothamBold
freezeBtn.BorderSizePixel = 0
freezeBtn.Parent = keybindPage
Instance.new("UICorner", freezeBtn).CornerRadius = UDim.new(0, 6)
freezeBtn.Activated:Connect(function()
    Settings.FreezeButtons = not Settings.FreezeButtons
    freezeBtn.BackgroundColor3 = Settings.FreezeButtons and Color3.fromRGB(60, 180, 100) or Color3.fromRGB(80, 80, 100)
    freezeBtn.Text = Settings.FreezeButtons and "🔒 Кнопки заморожены" or "🔓 Заморозить кнопки"
    saveConfigToFile(MAIN_CONFIG)
end)

if IS_PC or IS_HYBRID then
    uis.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if waitingForKey then return end
        
        local function checkKeybind(settingKey, funcKey)
            local kc = strToKeyCode(Settings[settingKey])
            if kc and input.KeyCode == kc then
                if funcKey == "TP_Nearest" then tpToNearestPlayer()
                elseif funcKey == "TP_Killer" then tpBehindKiller()
                else
                    ToggleFeature(funcKey)
                end
                return true
            end
            return false
        end
        
        for _, kb in ipairs(pcKeybindList) do
            if checkKeybind(kb.settingKey, kb.funcKey) then return end
        end
        
        if input.KeyCode == Enum.KeyCode.F then
            menu.Visible = not menu.Visible
        elseif input.KeyCode == Enum.KeyCode.L then
            gui.Enabled = not gui.Enabled
            floatGui.Enabled = gui.Enabled
        end
    end)
end

local function ToggleFeature(key)
    Settings[key] = not Settings[key]
    saveConfigToFile(MAIN_CONFIG)
    syncToggle(key, Settings[key])
end

local configNameBox = Instance.new("TextBox")
configNameBox.Size = UDim2.new(1, -6, 0, 34)
configNameBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
configNameBox.PlaceholderText = "Название конфига..."
configNameBox.Text = ""
configNameBox.TextColor3 = Color3.fromRGB(255,255,255)
configNameBox.PlaceholderColor3 = Color3.fromRGB(130,130,150)
configNameBox.TextScaled = true
configNameBox.Font = Enum.Font.Gotham
configNameBox.BorderSizePixel = 0
configNameBox.Parent = configPage
Instance.new("UICorner", configNameBox).CornerRadius = UDim.new(0, 6)

addButton(configPage, "💾 Сохранить как...", function()
    local name = configNameBox.Text
    if name == "" or name == nil then name = "Config_" .. tostring(math.random(1000, 9999)) end
    saveConfigToFile("SnowHub_" .. name .. ".json")
end, Color3.fromRGB(60, 180, 100))

addButton(configPage, "📂 Загрузить", function()
    local name = configNameBox.Text
    if name == "" then return end
    if loadConfigFromFile("SnowHub_" .. name .. ".json") then
        saveConfigToFile(MAIN_CONFIG)
        syncAllToggles()
        if player.PlayerGui:FindFirstChild("SnowHub_Main") then
            player.PlayerGui.SnowHub_Main:Destroy()
        end
    end
end, Color3.fromRGB(60, 130, 200))

addButton(configPage, "🗑 Удалить", function()
    local name = configNameBox.Text
    if name == "" then return end
    local filename = "SnowHub_" .. name .. ".json"
    if isfile and isfile(filename) then delfile(filename) end
end, Color3.fromRGB(200, 60, 60))

for _, page in pairs(pages) do
    page.CanvasSize = UDim2.new(0, 0, 0, #page:GetChildren() * 50 + 20)
end

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0, 70, 0, 24)
saveBtn.Position = UDim2.new(0, 8, 1, -32)
saveBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
saveBtn.Text = "💾 Save"
saveBtn.TextColor3 = Color3.fromRGB(255,255,255)
saveBtn.TextScaled = true
saveBtn.Font = Enum.Font.GothamBold
saveBtn.BorderSizePixel = 0
saveBtn.Parent = sidebar
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
saveBtn.Activated:Connect(function()
    Settings.Pos_OpenBtn = {openBtn.Position.X.Scale, openBtn.Position.X.Offset, openBtn.Position.Y.Scale, openBtn.Position.Y.Offset}
    Settings.Pos_FPS = {fpsFrame.Position.X.Scale, fpsFrame.Position.X.Offset, fpsFrame.Position.Y.Scale, fpsFrame.Position.Y.Offset}
    Settings.Pos_Menu = {menu.Position.X.Scale, menu.Position.X.Offset, menu.Position.Y.Scale, menu.Position.Y.Offset}
    if flyUp then Settings.Pos_FlyUp = {flyUp.Position.X.Scale, flyUp.Position.X.Offset, flyUp.Position.Y.Scale, flyUp.Position.Y.Offset} end
    if flyDown then Settings.Pos_FlyDown = {flyDown.Position.X.Scale, flyDown.Position.X.Offset, flyDown.Position.Y.Scale, flyDown.Position.Y.Offset} end
    if saveConfigToFile(MAIN_CONFIG) then
        saveBtn.Text = "✓ Saved"
    else
        saveBtn.Text = "❌ Ошибка"
    end
    task.wait(1)
    saveBtn.Text = "💾 Save"
end)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 45, 0, 24)
resetBtn.Position = UDim2.new(1, -53, 1, -32)
resetBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
resetBtn.Text = "↺"
resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
resetBtn.TextScaled = true
resetBtn.Font = Enum.Font.GothamBold
resetBtn.BorderSizePixel = 0
resetBtn.Parent = sidebar
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 4)
resetBtn.Activated:Connect(function()
    for k, v in pairs(defaultSettings) do Settings[k] = v end
    saveConfigToFile(MAIN_CONFIG)
    if player.PlayerGui:FindFirstChild("SnowHub_Main") then
        player.PlayerGui.SnowHub_Main:Destroy()
    end
end)

local menuOpenSize = menu.Size

local function SetMenuVisible(state)
    if state then
        menu.Visible = true
        menu.Size = UDim2.new(0, 395, 0, 295)
        menu.BackgroundTransparency = 0.35
        V_Tween(menu, {Size = menuOpenSize, BackgroundTransparency = 0.02}, 0.22, Enum.EasingStyle.Back)
    else
        V_Tween(menu, {
            Size = UDim2.new(0, 395, 0, 295),
            BackgroundTransparency = 0.35
        }, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.14, function()
            if menu and menu.Parent and menu.BackgroundTransparency > 0.2 then
                menu.Visible = false
                menu.Size = menuOpenSize
                menu.BackgroundTransparency = 0.02
            end
        end)
    end
end

openBtn.Activated:Connect(function()
    SetMenuVisible(not menu.Visible)
end)
minimizeBtn.Activated:Connect(function()
    SetMenuVisible(false)
end)
closeBtn.Activated:Connect(function()
    SetMenuVisible(false)
end)

makeDraggable(menu, topBar, "Pos_Menu")
restorePosition(menu, "Pos_Menu")

local flyUp, flyDown

if IS_MOBILE or IS_HYBRID then
    flyUp = Instance.new("TextButton")
    flyUp.Size = UDim2.new(0, 55, 0, 55)
    flyUp.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    flyUp.Text = "⬆"
    flyUp.TextColor3 = Color3.fromRGB(255,255,255)
    flyUp.TextScaled = true
    flyUp.Font = Enum.Font.GothamBold
    flyUp.BorderSizePixel = 0
    flyUp.Parent = gui
    flyUp.Visible = false
    Instance.new("UICorner", flyUp).CornerRadius = UDim.new(1, 0)
    makeDraggable(flyUp, nil, "Pos_FlyUp")
    restorePosition(flyUp, "Pos_FlyUp")

    flyDown = Instance.new("TextButton")
    flyDown.Size = UDim2.new(0, 55, 0, 55)
    flyDown.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    flyDown.Text = "⬇"
    flyDown.TextColor3 = Color3.fromRGB(255,255,255)
    flyDown.TextScaled = true
    flyDown.Font = Enum.Font.GothamBold
    flyDown.BorderSizePixel = 0
    flyDown.Parent = gui
    flyDown.Visible = false
    Instance.new("UICorner", flyDown).CornerRadius = UDim.new(1, 0)
    makeDraggable(flyDown, nil, "Pos_FlyDown")
    restorePosition(flyDown, "Pos_FlyDown")

    flyUp.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then flyUpFlag = true end
    end)
    flyUp.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then flyUpFlag = false end
    end)
    flyDown.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then flyDownFlag = true end
    end)
    flyDown.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then flyDownFlag = false end
    end)
end

runService.Heartbeat:Connect(function()
    local now = tick()
    
    if Settings.ESPEnabled ~= false and (now - lastESPUpdate >= ESP_INTERVAL) then
        lastESPUpdate = now
        for _, o in pairs(espObjects) do if o and o.Parent then o:Destroy() end end
        espObjects = {}
        
        for _, v in pairs(players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local role = getRole(v.Character)
                local isKiller = (role == "Killer") or killerList[v.Name]
                local dist = (v.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                
                if (isKiller and Settings.ESPKiller) or (not isKiller and Settings.ESPSurvivor) then
                    local h = Instance.new("Highlight")
                    h.Adornee = v.Character
                    local col = isKiller and getColor("ESPKillerColor") or getColor("ESPSurvivorColor")
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = 0.4
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = v.Character
                    table.insert(espObjects, h)
                    
                    if Settings.ShowDistance or Settings.ShowNames then
                        local bg = Instance.new("BillboardGui")
                        bg.Size = UDim2.new(0, 160, 0, 26)
                        bg.Adornee = v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("HumanoidRootPart")
                        bg.AlwaysOnTop = true
                        bg.Parent = v.Character
                        local txt = Settings.ShowNames and v.Name or ""
                        if Settings.ShowDistance then txt = txt .. " [" .. math.floor(dist) .. "m]" end
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = txt
                        lbl.TextColor3 = col
                        lbl.TextScaled = true
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        lbl.TextStrokeTransparency = 0.3
                        lbl.Parent = bg
                        table.insert(espObjects, bg)
                    end
                end
            end
        end
        
        for _, item in ipairs(cachedObjects) do
            if item and item.Parent then
                local n = item.Name:lower()
                local col = nil
                if (n:find("generator") or n:find("gen")) and Settings.ESPGenerator then col = getColor("ESPGeneratorColor")
                elseif (n:find("pallet") or n:find("pall")) and Settings.ESPPallet then col = getColor("ESPPalletColor")
                elseif (n:find("hook") or n:find("unhook")) and Settings.ESPHook then col = getColor("ESPHookColor")
                end
                if col then
                    local h = Instance.new("Highlight")
                    h.Adornee = item
                    h.FillColor = col
                    h.OutlineColor = col
                    h.FillTransparency = 0.4
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = item
                    table.insert(espObjects, h)
                end
            end
        end
    end
    
    if now - lastObjectCache >= CACHE_INTERVAL then
        lastObjectCache = now
        cachedObjects = {}
        for _, item in pairs(workspace:GetDescendants()) do
            if item:IsA("Model") then
                local n = item.Name:lower()
                if n:find("generator") or n:find("gen") or n:find("pallet") or n:find("pall") 
                   or n:find("hook") or n:find("unhook") then
                    table.insert(cachedObjects, item)
                end
            end
        end
    end
    
    if humanoid and humanoid.Parent then
        local state = humanoid:GetState()
        local onLadder = (state == Enum.HumanoidStateType.Climbing) or (state == Enum.HumanoidStateType.PlatformStanding)
        if onLadder then humanoid.WalkSpeed = 16
        else humanoid.WalkSpeed = Settings.Speed or 16 end
    end
    
    if rootPart then
        if Settings.NoClip then setProperCollision(false)
        else setProperCollision(true) end
    end
    
    if Settings.Fly and rootPart then
        if flyUp then flyUp.Visible = true end
        if flyDown then flyDown.Visible = true end
        
        local fly = rootPart:FindFirstChild("SnowHubFly")
        if not fly then
            fly = Instance.new("BodyVelocity")
            fly.Name = "SnowHubFly"
            fly.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            fly.Velocity = Vector3.new(0, 0, 0)
            fly.Parent = rootPart
        end
        
        local moveDir = Vector3.new(0, 0, 0)
        if IS_PC or IS_HYBRID then
            if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
        end
        if IS_MOBILE then
            moveDir = humanoid.MoveDirection
            if flyUpFlag then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if flyDownFlag then moveDir = moveDir + Vector3.new(0, -1, 0) end
        end
        if IS_HYBRID then
            moveDir = humanoid.MoveDirection
            if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
            if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
            if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
            if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end
            if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir + Vector3.new(0, -1, 0) end
            if flyUpFlag then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if flyDownFlag then moveDir = moveDir + Vector3.new(0, -1, 0) end
        end
        
        if moveDir.Magnitude > 0 then
            fly.Velocity = moveDir.Unit * (Settings.FlySpeed or 50)
        else
            fly.Velocity = Vector3.new(0, 0, 0)
        end
    else
        if flyUp then flyUp.Visible = false end
        if flyDown then flyDown.Visible = false end
        if rootPart then
            local oldFly = rootPart:FindFirstChild("SnowHubFly")
            if oldFly then 
                oldFly.Velocity = Vector3.new(0, 0, 0)
                oldFly:Destroy() 
            end
        end
    end
    
    if fpsFrame then fpsFrame.Visible = Settings.ShowFPS end
    
    if Settings.GodMode then humanoid.Health = humanoid.MaxHealth end
    if Settings.NoStun then humanoid:SetStateEnabled(Enum.HumanoidStateType.Stunned, false) end
    
    if Settings.FullBright then
        lighting.Brightness = 10
        lighting.Ambient = Color3.fromRGB(255, 255, 255)
        lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        lighting.GlobalShadows = false
    end
    if Settings.NoFog then lighting.FogEnd = 999999 end
    workspace.CurrentCamera.FieldOfView = Settings.FOV or 70
end)

player.CharacterAdded:Connect(function(c)
    character = c
    humanoid = c:WaitForChild("Humanoid")
    rootPart = c:WaitForChild("HumanoidRootPart")
    if gui and gui.Parent then
        gui.Parent = player.PlayerGui
        gui.DisplayOrder = 2147483647
    end
    if floatGui and floatGui.Parent then
        floatGui.Parent = player.PlayerGui
        floatGui.DisplayOrder = 2147483645
    end
    InitializeSkillCheck()
end)
