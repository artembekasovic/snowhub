--[[
    ❄️ SnowHub — Working Edition (Fixed)
    Конфиги сохраняются в рабочую папку Delta
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

local GLASS = {
    bgTop = Color3.fromRGB(45, 65, 110),
    bgBottom = Color3.fromRGB(25, 35, 60),
    glass = Color3.fromRGB(60, 85, 130),
    glassLight = Color3.fromRGB(75, 105, 160),
    accent = Color3.fromRGB(120, 200, 255),
    accentPurple = Color3.fromRGB(160, 120, 255),
    text = Color3.fromRGB(255, 255, 255),
    textMuted = Color3.fromRGB(180, 200, 230),
    good = Color3.fromRGB(80, 230, 160),
    bad = Color3.fromRGB(255, 90, 130),
    warn = Color3.fromRGB(255, 200, 100),
    glow = Color3.fromRGB(100, 180, 255),
}

local function Tween(obj, props, dur, style, dir)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

local function Round(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(120, 160, 220)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.85
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function GlassGradient(obj, light)
    local g = Instance.new("UIGradient")
    if light then
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 110, 160)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 75, 120))
        }
    else
        g.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 65, 110)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 35, 60))
        }
    end
    g.Rotation = 135
    g.Parent = obj
    return g
end

local function GlassGlow(obj, color)
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 0.6, 0)
    glow.Position = UDim2.new(0, 0, 0, 0)
    glow.BackgroundColor3 = color or GLASS.accent
    glow.BackgroundTransparency = 0.97
    glow.BorderSizePixel = 0
    glow.ZIndex = 0
    glow.Parent = obj
    local g = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    g.Rotation = 90
    g.Parent = glow
    Round(glow, 12)
    return glow
end

local function MakeButton(btn, baseColor, hoverColor)
    btn.AutoButtonColor = false
    baseColor = baseColor or btn.BackgroundColor3
    hoverColor = hoverColor or baseColor:Lerp(Color3.new(1,1,1), 0.25)
    
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = hoverColor}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = baseColor}, 0.2) end)
    btn.MouseButton1Down:Connect(function() Tween(btn, {BackgroundColor3 = hoverColor:Lerp(Color3.new(0,0,0), 0.1)}, 0.05) end)
    btn.MouseButton1Up:Connect(function() Tween(btn, {BackgroundColor3 = hoverColor}, 0.08) end)
    
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, {BackgroundColor3 = hoverColor}, 0.1)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            Tween(btn, {BackgroundColor3 = baseColor}, 0.15)
        end
    end)
end

for _, g in pairs(player.PlayerGui:GetChildren()) do
    if g.Name:find("SnowHub") or g.Name:find("KazelLost") then g:Destroy() end
end

-- ============================================================
-- ФАЙЛЫ
-- ============================================================
print("===== SNOWHUB =====")
print("writefile: " .. tostring(writefile ~= nil))
print("readfile: " .. tostring(readfile ~= nil))
print("isfile: " .. tostring(isfile ~= nil))
print("listfiles: " .. tostring(listfiles ~= nil))

local FILE_OK = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
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
    if not FILE_OK then return false end
    if not isfile(filename) then 
        print("Файл не найден: " .. filename)
        return false 
    end
    local ok, content = pcall(function() return readfile(filename) end)
    if not ok or not content then return false end
    local ok2, data = pcall(function() return http:JSONDecode(content) end)
    if not ok2 or not data then return false end
    for k, v in pairs(defaultSettings) do
        Settings[k] = data[k] ~= nil and data[k] or v
    end
    print("✅ Конфиг загружен: " .. filename)
    return true
end

local function saveConfigToFile(filename)
    if not FILE_OK then return false end
    filename = filename or MAIN_CONFIG
    local ok, err = pcall(function()
        writefile(filename, http:JSONEncode(Settings))
    end)
    if not ok then
        warn("Ошибка сохранения: " .. tostring(err))
        return false
    end
    print("✅ Сохранено: " .. filename)
    return true
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
        local btn = toggleButtons[key]
        if value then
            btn.BackgroundColor3 = GLASS.good
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(45, 55, 80)
            btn.Text = "OFF"
        end
    end
end

local function syncAllToggles()
    for key, _ in pairs(toggleButtons) do
        syncToggle(key, Settings[key])
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
    local lastDelta = Vector2.new(0, 0)
    local velocity = Vector2.new(0, 0)
    local inertiaActive = false
    
    handle.InputBegan:Connect(function(input)
        if Settings.FreezeButtons then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            inertiaActive = false
            velocity = Vector2.new(0, 0)
            lastDelta = Vector2.new(0, 0)
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
            if velocity.Magnitude > 3 then inertiaActive = true end
        end
    end)
    runService.RenderStepped:Connect(function()
        if Settings.FreezeButtons then dragging = false; inertiaActive = false; return end
        if dragging and dragInput then
            local delta = dragInput.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            velocity = delta - lastDelta
            lastDelta = delta
        elseif inertiaActive then
            velocity = velocity * 0.92
            if velocity.Magnitude < 0.5 then
                inertiaActive = false
            else
                frame.Position = UDim2.new(
                    frame.Position.X.Scale, frame.Position.X.Offset + velocity.X,
                    frame.Position.Y.Scale, frame.Position.Y.Offset + velocity.Y
                )
            end
        end
    end)
end

-- ========== GUI ==========
local gui = Instance.new("ScreenGui")
gui.Name = "SnowHub_Main"
gui.Parent = player.PlayerGui
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2147483647
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.None
gui.Archivable = false

local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "SnowHub_FPS"
fpsGui.Parent = player.PlayerGui
fpsGui.IgnoreGuiInset = true
fpsGui.ResetOnSpawn = false
fpsGui.DisplayOrder = 2147483646
fpsGui.ScreenInsets = Enum.ScreenInsets.None
fpsGui.Archivable = false

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(0, 95, 0, 32)
fpsFrame.BackgroundColor3 = GLASS.glass
fpsFrame.BackgroundTransparency = 0.35
fpsFrame.BorderSizePixel = 0
fpsFrame.Parent = fpsGui
Round(fpsFrame, 12)
GlassGradient(fpsFrame)
local fpsStroke = Stroke(fpsFrame, GLASS.accent, 1.5, 0.6)
GlassGlow(fpsFrame, GLASS.glow)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = GLASS.good
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
                fpsLabel.TextColor3 = GLASS.good
                fpsStroke.Color = GLASS.good
            elseif v >= 25 then
                fpsLabel.TextColor3 = GLASS.warn
                fpsStroke.Color = GLASS.warn
            else
                fpsLabel.TextColor3 = GLASS.bad
                fpsStroke.Color = GLASS.bad
            end
        end
    end
end)

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 55, 0, 55)
openBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
openBtn.BackgroundTransparency = 0.15
openBtn.Text = "❄"
openBtn.TextColor3 = Color3.fromRGB(200, 230, 255)
openBtn.TextStrokeColor3 = Color3.fromRGB(120, 190, 255)
openBtn.TextStrokeTransparency = 0.3
openBtn.TextScaled = true
openBtn.Font = Enum.Font.GothamBold
openBtn.BorderSizePixel = 0
openBtn.Parent = gui
Round(openBtn, 999)
local os = Stroke(openBtn, Color3.fromRGB(150, 200, 255), 2, 0.3)
GlassGlow(openBtn, GLASS.glow)
MakeButton(openBtn, Color3.fromRGB(60, 130, 220), Color3.fromRGB(80, 150, 240))
makeDraggable(openBtn, nil, "Pos_OpenBtn")
restorePosition(openBtn, "Pos_OpenBtn")

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 440, 0, 360)
menu.BackgroundColor3 = GLASS.glass
menu.BackgroundTransparency = 0.25
menu.BorderSizePixel = 0
menu.Visible = false
menu.ClipsDescendants = true
menu.Parent = gui
Round(menu, 20)
GlassGradient(menu)
local ms = Stroke(menu, GLASS.accent, 1.5, 0.5)
GlassGlow(menu, GLASS.glow)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 42)
topBar.BackgroundColor3 = GLASS.bgTop
topBar.BackgroundTransparency = 0.4
topBar.BorderSizePixel = 0
topBar.Parent = menu
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 20)

local topBarFix = Instance.new("Frame")
topBarFix.Size = UDim2.new(1, 0, 0, 10)
topBarFix.Position = UDim2.new(0, 0, 1, -10)
topBarFix.BackgroundColor3 = GLASS.bgTop
topBarFix.BackgroundTransparency = 0.4
topBarFix.BorderSizePixel = 0
topBarFix.Parent = topBar

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 34, 0, 34)
logoIcon.Position = UDim2.new(0, 10, 0, 4)
logoIcon.BackgroundTransparency = 1
logoIcon.Text = "❄"
logoIcon.TextColor3 = GLASS.accent
logoIcon.TextScaled = true
logoIcon.Font = Enum.Font.GothamBold
logoIcon.Parent = topBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 150, 0, 18)
titleLbl.Position = UDim2.new(0, 50, 0, 6)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SnowHub"
titleLbl.TextColor3 = GLASS.text
titleLbl.TextScaled = true
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Font = Enum.Font.GothamBold
titleLbl.Parent = topBar

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(0, 150, 0, 14)
subLbl.Position = UDim2.new(0, 50, 0, 22)
subLbl.BackgroundTransparency = 1
subLbl.Text = IS_MOBILE and "Glass Mobile" or "Glass PC"
subLbl.TextColor3 = GLASS.textMuted
subLbl.TextScaled = true
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Font = Enum.Font.Gotham
subLbl.Parent = topBar

local titleAccent = Instance.new("Frame")
titleAccent.Size = UDim2.new(0, 80, 0, 2)
titleAccent.Position = UDim2.new(0, 50, 1, -3)
titleAccent.BackgroundColor3 = GLASS.accent
titleAccent.BorderSizePixel = 0
titleAccent.Parent = topBar
Round(titleAccent, 999)
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new(GLASS.accent, GLASS.accentPurple)
titleGradient.Parent = titleAccent

task.spawn(function()
    while titleAccent.Parent do
        titleGradient.Offset = Vector2.new(-1, 0)
        Tween(titleGradient, {Offset = Vector2.new(1, 0)}, 2, Enum.EasingStyle.Linear)
        task.wait(2)
    end
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -76, 0, 5)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = GLASS.textMuted
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = topBar
MakeButton(minimizeBtn, GLASS.bgTop, GLASS.glassLight)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = GLASS.textMuted
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar
MakeButton(closeBtn, GLASS.bgTop, GLASS.bad)

closeBtn.Activated:Connect(function()
    gui.Enabled = false
    fpsGui.Enabled = false
    floatGui.Enabled = false
end)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 140, 1, -42)
sidebar.Position = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundColor3 = GLASS.bgBottom
sidebar.BackgroundTransparency = 0.5
sidebar.BorderSizePixel = 0
sidebar.Parent = menu
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 20)

local sideList = Instance.new("Frame")
sideList.Size = UDim2.new(1, -12, 1, -85)
sideList.Position = UDim2.new(0, 6, 0, 6)
sideList.BackgroundTransparency = 1
sideList.Parent = sidebar
local sideLayout = Instance.new("UIListLayout", sideList)
sideLayout.Padding = UDim.new(0, 5)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -155, 1, -60)
content.Position = UDim2.new(0, 150, 0, 50)
content.BackgroundTransparency = 1
content.Parent = menu

local pages = {}
local pageButtons = {}

local function createPage(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = GLASS.glass
    btn.BackgroundTransparency = 0.5
    btn.Text = "  " .. name
    btn.TextColor3 = GLASS.textMuted
    btn.TextScaled = true
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = sideList
    Round(btn, 10)
    MakeButton(btn, GLASS.glass, GLASS.glassLight)
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = GLASS.accent
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    table.insert(pageButtons, btn)
    table.insert(pages, page)
    
    btn.Activated:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
        for _, b in pairs(pageButtons) do
            b.BackgroundColor3 = GLASS.glass
            b.TextColor3 = GLASS.textMuted
        end
        btn.BackgroundColor3 = GLASS.glassLight
        btn.TextColor3 = GLASS.text
    end)
    
    return page
end

local combatPage = createPage("Combat")
local tpPage = createPage("Teleport")
local espPage = createPage("ESP")
local movePage = createPage("Movement")
local visualPage = createPage("Visual")
local keybindPage = createPage("Keybinds")
local configPage = createPage("Configs")

if pageButtons[1] then
    pageButtons[1].BackgroundColor3 = GLASS.glassLight
    pageButtons[1].TextColor3 = GLASS.text
    pages[1].Visible = true
end

local function addToggle(page, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 36)
    row.BackgroundColor3 = GLASS.glass
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    row.Parent = page
    Round(row, 10)
    Stroke(row, Color3.fromRGB(120, 160, 220), 1, 0.85)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = GLASS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = row
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 24)
    btn.Position = UDim2.new(1, -58, 0.5, -12)
    
    local isOn = Settings[key] == true
    btn.BackgroundColor3 = isOn and GLASS.good or Color3.fromRGB(45, 55, 80)
    btn.Text = isOn and "ON" or "OFF"
    btn.TextColor3 = GLASS.text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = row
    Round(btn, 12)
    Stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.8)
    
    toggleButtons[key] = btn
    
    btn.Activated:Connect(function()
        Settings[key] = not Settings[key]
        syncToggle(key, Settings[key])
        saveConfigToFile(MAIN_CONFIG)
    end)
end

local function addSlider(page, label, key, min, max)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 52)
    row.BackgroundColor3 = GLASS.glass
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    row.Parent = page
    Round(row, 10)
    Stroke(row, Color3.fromRGB(120, 160, 220), 1, 0.85)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 0.45, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = GLASS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = row
    
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0.4, 0, 0.45, 0)
    val.Position = UDim2.new(0.6, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(Settings[key] or min)
    val.TextColor3 = GLASS.accent
    val.TextScaled = true
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Font = Enum.Font.GothamBold
    val.Parent = row
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.9, 0, 0.2, 0)
    slider.Position = UDim2.new(0.05, 0, 0.7, 0)
    slider.BackgroundColor3 = Color3.fromRGB(45, 60, 90)
    slider.BorderSizePixel = 0
    slider.Parent = row
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0.5, 0)
    
    local range = math.max(1, (max - min))
    local initialPct = ((Settings[key] or min) - min) / range
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initialPct, 0, 1, 0)
    fill.BackgroundColor3 = GLASS.accent
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.5, 0)
    
    local drag = Instance.new("TextButton")
    drag.Size = UDim2.new(0, 18, 0, 18)
    drag.Position = UDim2.new(initialPct, -9, 0.5, -9)
    drag.BackgroundColor3 = GLASS.text
    drag.Text = ""
    drag.BorderSizePixel = 0
    drag.Parent = slider
    Instance.new("UICorner", drag).CornerRadius = UDim.new(0.5, 0)
    Stroke(drag, GLASS.accent, 2, 0.4)
    
    local d = false
    drag.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
            d = true 
        end
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
            local v = math.floor(min + pos * (max - min) + 0.5)
            Settings[key] = v
            val.Text = tostring(v)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            drag.Position = UDim2.new(pos, -9, 0.5, -9)
        end
    end)
end

local function addColorPicker(page, label, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 42)
    row.BackgroundColor3 = GLASS.glass
    row.BackgroundTransparency = 0.35
    row.BorderSizePixel = 0
    row.Parent = page
    Round(row, 10)
    Stroke(row, Color3.fromRGB(120, 160, 220), 1, 0.85)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.35, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = GLASS.text
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
        b.Size = UDim2.new(0, 22, 0, 22)
        b.Position = UDim2.new(0.38 + (i-1)*0.077, 0, 0.5, -11)
        b.BackgroundColor3 = col
        b.Text = ""
        b.BorderSizePixel = 0
        b.Parent = row
        Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
        Stroke(b, Color3.new(1,1,1), 1, 0.6)
        b.Activated:Connect(function()
            Settings[key] = {math.floor(col.R*255), math.floor(col.G*255), math.floor(col.B*255)}
            saveConfigToFile(MAIN_CONFIG)
        end)
    end
end

local function addButton(page, label, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -6, 0, 40)
    btn.BackgroundColor3 = color or GLASS.glass
    btn.BackgroundTransparency = 0.35
    btn.Text = label
    btn.TextColor3 = GLASS.text
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = page
    Round(btn, 10)
    Stroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.75)
    MakeButton(btn, color or GLASS.glass, (color or GLASS.accent):Lerp(Color3.new(1,1,1), 0.2))
    btn.Activated:Connect(callback)
    return btn
end

addToggle(combatPage, "Auto Skill Check", "AutoSkillCheck")
addToggle(combatPage, "God Mode", "GodMode")
addToggle(combatPage, "No Stun", "NoStun")

addButton(tpPage, "TP к ближайшему игроку", tpToNearestPlayer, Color3.fromRGB(90, 140, 230))
addButton(tpPage, "TP за спину киллера", tpBehindKiller, Color3.fromRGB(230, 90, 110))
addButton(tpPage, "TP к дальнему игроку", tpToFarthestPlayer, Color3.fromRGB(210, 150, 60))
addButton(tpPage, "TP в лобби (спавн)", tpToLobby, Color3.fromRGB(140, 140, 160))

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

-- FLOATS
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "SnowHub_Floats"
floatGui.Parent = player.PlayerGui
floatGui.IgnoreGuiInset = true
floatGui.ResetOnSpawn = false
floatGui.DisplayOrder = 2147483645
floatGui.ScreenInsets = Enum.ScreenInsets.None
floatGui.Archivable = false

local activeFloats = {}

local keybindFunctions = {
    {label = "Fly", key = "Fly", color = Color3.fromRGB(90, 180, 240)},
    {label = "NoClip", key = "NoClip", color = Color3.fromRGB(150, 180, 240)},
    {label = "Skill", key = "AutoSkillCheck", color = Color3.fromRGB(80, 230, 160)},
    {label = "God", key = "GodMode", color = Color3.fromRGB(240, 90, 110)},
    {label = "ESP", key = "ESPEnabled", color = Color3.fromRGB(100, 230, 140)},
    {label = "NoStun", key = "NoStun", color = Color3.fromRGB(240, 200, 100)},
    {label = "TP", key = "TP_Nearest", color = Color3.fromRGB(110, 160, 240), isAction = true},
    {label = "Killer", key = "TP_Killer", color = Color3.fromRGB(240, 110, 130), isAction = true},
}

local pcKeybindList = {
    {label = "Fly", settingKey = "Keybind_Fly", funcKey = "Fly", isAction = false},
    {label = "NoClip", settingKey = "Keybind_NoClip", funcKey = "NoClip", isAction = false},
    {label = "SkillCheck", settingKey = "Keybind_SkillCheck", funcKey = "AutoSkillCheck", isAction = false},
    {label = "GodMode", settingKey = "Keybind_GodMode", funcKey = "GodMode", isAction = false},
    {label = "ESP", settingKey = "Keybind_ESP", funcKey = "ESPEnabled", isAction = false},
    {label = "TP Nearest", settingKey = "Keybind_TP_Nearest", funcKey = "TP_Nearest", isAction = true},
    {label = "TP Killer", settingKey = "Keybind_TP_Killer", funcKey = "TP_Killer", isAction = true},
}

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
    
    local isAction = false
    for _, f in ipairs(keybindFunctions) do
        if f.key == key and f.isAction then isAction = true; break end
    end
    
    local isOn = isAction or (Settings[key] == true)
    
    if isOn then
        btn.BackgroundColor3 = color
        btn.BackgroundTransparency = 0.15
    else
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.BackgroundTransparency = 0.5
    end
    
    btn.Text = ""
    btn.TextColor3 = GLASS.text
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = floatGui
    Round(btn, 999)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0.6, 0)
    icon.Position = UDim2.new(0, 0, 0.05, 0)
    icon.BackgroundTransparency = 1
    icon.Text = label
    icon.TextColor3 = GLASS.text
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.ZIndex = 2
    icon.Parent = btn
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0.35, 0)
    status.Position = UDim2.new(0, 0, 0.6, 0)
    status.BackgroundTransparency = 1
    status.Text = isAction and "ACT" or (isOn and "ON" or "OFF")
    status.TextColor3 = isAction and Color3.fromRGB(255, 220, 100) or (isOn and Color3.fromRGB(180, 255, 210) or Color3.fromRGB(160, 160, 170))
    status.TextScaled = true
    status.Font = Enum.Font.GothamBold
    status.ZIndex = 2
    status.Parent = btn
    
    local s = Instance.new("UIStroke")
    s.Color = isOn and color or Color3.fromRGB(100, 100, 110)
    s.Thickness = isOn and 2 or 1
    s.Transparency = isOn and 0.3 or 0.6
    s.Parent = btn
    
    if isOn then GlassGlow(btn, color) end
    
    local function updateAppearance()
        if isAction then return end
        local nowOn = Settings[key] == true
        if nowOn then
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.15
            s.Color = color
            s.Thickness = 2
            s.Transparency = 0.3
            status.Text = "ON"
            status.TextColor3 = Color3.fromRGB(180, 255, 210)
        else
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            btn.BackgroundTransparency = 0.5
            s.Color = Color3.fromRGB(100, 100, 110)
            s.Thickness = 1
            s.Transparency = 0.6
            status.Text = "OFF"
            status.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
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
                    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    task.wait(0.1)
                    btn.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
                else
                    Settings[key] = not Settings[key]
                    saveConfigToFile(MAIN_CONFIG)
                    syncToggle(key, Settings[key])
                    updateAppearance()
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
                    createFloatBtn(func.label, func.key, func.color, UDim2.new(0, 58, 0, 58), UDim2.new(pos[1], pos[2], pos[3], pos[4]))
                    break
                end
            end
        end
    end
end)

-- KEYBINDS MENU
local kbAddMenu = Instance.new("Frame")
kbAddMenu.Size = UDim2.new(0, 340, 0, 420)
kbAddMenu.Position = UDim2.new(0.5, -170, 0.5, -210)
kbAddMenu.BackgroundColor3 = GLASS.glass
kbAddMenu.BackgroundTransparency = 0.2
kbAddMenu.BorderSizePixel = 0
kbAddMenu.Visible = false
kbAddMenu.Parent = gui
kbAddMenu.ZIndex = 100
Round(kbAddMenu, 16)
GlassGradient(kbAddMenu)
Stroke(kbAddMenu, GLASS.accent, 1.5, 0.5)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(1, 0, 0, 36)
kbTitle.BackgroundTransparency = 1
kbTitle.Text = "Добавить кейбинд"
kbTitle.TextColor3 = GLASS.accent
kbTitle.TextScaled = true
kbTitle.Font = Enum.Font.GothamBold
kbTitle.Parent = kbAddMenu
kbTitle.ZIndex = 101

local kbClose = Instance.new("TextButton")
kbClose.Size = UDim2.new(0, 30, 0, 30)
kbClose.Position = UDim2.new(1, -34, 0, 5)
kbClose.BackgroundColor3 = GLASS.bad
kbClose.BackgroundTransparency = 0.3
kbClose.Text = "X"
kbClose.TextColor3 = GLASS.text
kbClose.TextScaled = true
kbClose.BorderSizePixel = 0
kbClose.Parent = kbAddMenu
kbClose.ZIndex = 101
Instance.new("UICorner", kbClose).CornerRadius = UDim.new(0.5, 0)
kbClose.Activated:Connect(function() kbAddMenu.Visible = false end)

local kbScroll = Instance.new("ScrollingFrame")
kbScroll.Size = UDim2.new(1, -12, 1, -55)
kbScroll.Position = UDim2.new(0, 6, 0, 45)
kbScroll.BackgroundTransparency = 1
kbScroll.BorderSizePixel = 0
kbScroll.ScrollBarThickness = 6
kbScroll.ScrollBarImageColor3 = GLASS.accent
kbScroll.ScrollingDirection = Enum.ScrollingDirection.Y
kbScroll.CanvasSize = UDim2.new(0, 0, 0, #keybindFunctions * 100 + 20)
kbScroll.Parent = kbAddMenu
kbScroll.ZIndex = 101
Instance.new("UIListLayout", kbScroll).Padding = UDim.new(0, 7)

for _, func in ipairs(keybindFunctions) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 90)
    row.BackgroundColor3 = GLASS.glass
    row.BackgroundTransparency = 0.4
    row.BorderSizePixel = 0
    row.Parent = kbScroll
    row.ZIndex = 101
    Round(row, 10)
    Stroke(row, Color3.fromRGB(120, 160, 220), 1, 0.85)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 26)
    lbl.Position = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = func.label
    lbl.TextColor3 = GLASS.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = row
    lbl.ZIndex = 102
    
    local sizes = {
        {label = "S", size = UDim2.new(0, 42, 0, 42)},
        {label = "M", size = UDim2.new(0, 58, 0, 58)},
        {label = "L", size = UDim2.new(0, 78, 0, 78)},
    }
    
    for i, sz in ipairs(sizes) do
        local sizeBtn = Instance.new("TextButton")
        sizeBtn.Size = UDim2.new(0, 100, 0, 36)
        sizeBtn.Position = UDim2.new(0, 10 + (i-1)*106, 0, 36)
        sizeBtn.BackgroundColor3 = GLASS.glassLight
        sizeBtn.BackgroundTransparency = 0.3
        sizeBtn.Text = sz.label .. " (" .. sz.size.X.Offset .. "px)"
        sizeBtn.TextColor3 = GLASS.text
        sizeBtn.TextScaled = true
        sizeBtn.Font = Enum.Font.Gotham
        sizeBtn.BorderSizePixel = 0
        sizeBtn.Parent = row
        sizeBtn.ZIndex = 102
        Round(sizeBtn, 8)
        Stroke(sizeBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
        MakeButton(sizeBtn, GLASS.glassLight, GLASS.accent)
        
        sizeBtn.Activated:Connect(function()
            kbAddMenu.Visible = false
            menu.Visible = false
            
            local hint = Instance.new("TextLabel")
            hint.Size = UDim2.new(0, 320, 0, 60)
            hint.Position = UDim2.new(0.5, -160, 0.5, -30)
            hint.BackgroundColor3 = GLASS.glass
            hint.BackgroundTransparency = 0.15
            hint.Text = "Тапни там, где хочешь кнопку"
            hint.TextColor3 = GLASS.accent
            hint.TextScaled = true
            hint.Font = Enum.Font.GothamBold
            hint.BorderSizePixel = 0
            hint.ZIndex = 200
            hint.Parent = gui
            Round(hint, 14)
            Stroke(hint, GLASS.accent, 2, 0.4)
            
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

-- PC KEYBINDS MENU
local pcKeybindMenu = Instance.new("Frame")
pcKeybindMenu.Size = UDim2.new(0, 340, 0, 420)
pcKeybindMenu.Position = UDim2.new(0.5, -170, 0.5, -210)
pcKeybindMenu.BackgroundColor3 = GLASS.glass
pcKeybindMenu.BackgroundTransparency = 0.2
pcKeybindMenu.BorderSizePixel = 0
pcKeybindMenu.Visible = false
pcKeybindMenu.Parent = gui
pcKeybindMenu.ZIndex = 100
Round(pcKeybindMenu, 16)
GlassGradient(pcKeybindMenu)
Stroke(pcKeybindMenu, GLASS.warn, 1.5, 0.5)

local pkbTitle = Instance.new("TextLabel")
pkbTitle.Size = UDim2.new(1, 0, 0, 36)
pkbTitle.BackgroundTransparency = 1
pkbTitle.Text = "ПК Кейбинды"
pkbTitle.TextColor3 = GLASS.warn
pkbTitle.TextScaled = true
pkbTitle.Font = Enum.Font.GothamBold
pkbTitle.Parent = pcKeybindMenu
pkbTitle.ZIndex = 101

local pkbClose = Instance.new("TextButton")
pkbClose.Size = UDim2.new(0, 30, 0, 30)
pkbClose.Position = UDim2.new(1, -34, 0, 5)
pkbClose.BackgroundColor3 = GLASS.bad
pkbClose.BackgroundTransparency = 0.3
pkbClose.Text = "X"
pkbClose.TextColor3 = GLASS.text
pkbClose.TextScaled = true
pkbClose.BorderSizePixel = 0
pkbClose.Parent = pcKeybindMenu
pkbClose.ZIndex = 101
Instance.new("UICorner", pkbClose).CornerRadius = UDim.new(0.5, 0)
pkbClose.Activated:Connect(function() pcKeybindMenu.Visible = false end)

local pkbScroll = Instance.new("ScrollingFrame")
pkbScroll.Size = UDim2.new(1, -12, 1, -55)
pkbScroll.Position = UDim2.new(0, 6, 0, 45)
pkbScroll.BackgroundTransparency = 1
pkbScroll.BorderSizePixel = 0
pkbScroll.ScrollBarThickness = 6
pkbScroll.ScrollBarImageColor3 = GLASS.warn
pkbScroll.ScrollingDirection = Enum.ScrollingDirection.Y
pkbScroll.CanvasSize = UDim2.new(0, 0, 0, #pcKeybindList * 55 + 20)
pkbScroll.Parent = pcKeybindMenu
pkbScroll.ZIndex = 101
Instance.new("UIListLayout", pkbScroll).Padding = UDim.new(0, 7)

local pkbButtons = {}

local function refreshPcKeybindList()
    for _, btn in pairs(pkbButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    pkbButtons = {}
    
    for i, kb in ipairs(pcKeybindList) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 46)
        row.BackgroundColor3 = GLASS.glass
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.Parent = pkbScroll
        row.ZIndex = 101
        Round(row, 10)
        Stroke(row, Color3.fromRGB(120, 160, 220), 1, 0.85)
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = kb.label
        lbl.TextColor3 = GLASS.text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham
        lbl.Parent = row
        lbl.ZIndex = 102
        
        local keyBtn = Instance.new("TextButton")
        keyBtn.Size = UDim2.new(0, 65, 0, 30)
        keyBtn.Position = UDim2.new(1, -78, 0.5, -15)
        keyBtn.BackgroundColor3 = GLASS.glassLight
        keyBtn.BackgroundTransparency = 0.3
        keyBtn.Text = Settings[kb.settingKey] or "?"
        keyBtn.TextColor3 = GLASS.text
        keyBtn.TextScaled = true
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.BorderSizePixel = 0
        keyBtn.Parent = row
        keyBtn.ZIndex = 102
        Round(keyBtn, 8)
        Stroke(keyBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
        MakeButton(keyBtn, GLASS.glassLight, GLASS.accent)
        
        table.insert(pkbButtons, keyBtn)
        
        keyBtn.Activated:Connect(function()
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = GLASS.warn
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
            waitingForKey.btn.BackgroundColor3 = GLASS.glassLight
            saveConfigToFile(MAIN_CONFIG)
            waitingForKey = nil
        end
    end
end)

local addKbBtn = Instance.new("TextButton")
addKbBtn.Size = UDim2.new(1, -6, 0, 46)
addKbBtn.BackgroundColor3 = GLASS.glass
addKbBtn.BackgroundTransparency = 0.3
addKbBtn.Text = "Добавить кнопку на экран"
addKbBtn.TextColor3 = GLASS.text
addKbBtn.TextScaled = true
addKbBtn.Font = Enum.Font.GothamBold
addKbBtn.BorderSizePixel = 0
addKbBtn.Parent = keybindPage
Round(addKbBtn, 10)
Stroke(addKbBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
MakeButton(addKbBtn, GLASS.glass, GLASS.accent)
addKbBtn.Activated:Connect(function()
    kbAddMenu.Visible = not kbAddMenu.Visible
end)

if IS_PC or IS_HYBRID then
    local pcKbBtn = Instance.new("TextButton")
    pcKbBtn.Size = UDim2.new(1, -6, 0, 46)
    pcKbBtn.BackgroundColor3 = GLASS.glass
    pcKbBtn.BackgroundTransparency = 0.3
    pcKbBtn.Text = "ПК Кейбинды"
    pcKbBtn.TextColor3 = GLASS.text
    pcKbBtn.TextScaled = true
    pcKbBtn.Font = Enum.Font.GothamBold
    pcKbBtn.BorderSizePixel = 0
    pcKbBtn.Parent = keybindPage
    Round(pcKbBtn, 10)
    Stroke(pcKbBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
    MakeButton(pcKbBtn, GLASS.glass, GLASS.warn)
    pcKbBtn.Activated:Connect(function()
        refreshPcKeybindList()
        pcKeybindMenu.Visible = not pcKeybindMenu.Visible
    end)
end

local clearFloatsBtn = Instance.new("TextButton")
clearFloatsBtn.Size = UDim2.new(1, -6, 0, 46)
clearFloatsBtn.BackgroundColor3 = GLASS.glass
clearFloatsBtn.BackgroundTransparency = 0.3
clearFloatsBtn.Text = "Убрать все кнопки"
clearFloatsBtn.TextColor3 = GLASS.text
clearFloatsBtn.TextScaled = true
clearFloatsBtn.Font = Enum.Font.GothamBold
clearFloatsBtn.BorderSizePixel = 0
clearFloatsBtn.Parent = keybindPage
Round(clearFloatsBtn, 10)
Stroke(clearFloatsBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
MakeButton(clearFloatsBtn, GLASS.glass, GLASS.bad)
clearFloatsBtn.Activated:Connect(function()
    for key, btn in pairs(activeFloats) do
        if btn and btn.Parent then btn:Destroy() end
    end
    activeFloats = {}
    Settings.Pos_Floats = {}
    saveConfigToFile(MAIN_CONFIG)
end)

-- Кнопка "Заморозить кнопки"
local freezeBtn = Instance.new("TextButton")
freezeBtn.Size = UDim2.new(1, -6, 0, 46)
freezeBtn.BackgroundColor3 = Settings.FreezeButtons and GLASS.good or GLASS.glass
freezeBtn.BackgroundTransparency = 0.3
freezeBtn.Text = Settings.FreezeButtons and "Кнопки заморожены" or "Заморозить кнопки"
freezeBtn.TextColor3 = GLASS.text
freezeBtn.TextScaled = true
freezeBtn.Font = Enum.Font.GothamBold
freezeBtn.BorderSizePixel = 0
freezeBtn.Parent = keybindPage
Round(freezeBtn, 10)
Stroke(freezeBtn, Color3.fromRGB(255, 255, 255), 1, 0.75)
MakeButton(freezeBtn, GLASS.glass, GLASS.good)

freezeBtn.Activated:Connect(function()
    Settings.FreezeButtons = not Settings.FreezeButtons
    if Settings.FreezeButtons then
        freezeBtn.BackgroundColor3 = GLASS.good
        freezeBtn.Text = "Кнопки заморожены"
    else
        freezeBtn.BackgroundColor3 = GLASS.glass
        freezeBtn.Text = "Заморозить кнопки"
    end
    saveConfigToFile(MAIN_CONFIG)
end)

-- Открытие/Закрытие меню
openBtn.Activated:Connect(function()
    menu.Visible = not menu.Visible
    if menu.Visible then
        restorePosition(menu, "Pos_Menu")
    end
end)

minimizeBtn.Activated:Connect(function()
    menu.Visible = false
end)

-- Закрытие GUI полностью (если нужно вернуть)
-- closeBtn.Activated уже настроен выше для скрытия.

print("===== SNOWHUB LOADED =====")
