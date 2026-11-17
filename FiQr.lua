-- FiQr | Roblox Studio local testing panel
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- NPC ESP scans Workspace > PracticeTargets.
-- These are client-side testing controls for your own Roblox experience.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

-- Remove an older copy of the panel if the script is run again.
local oldGui = playerGui:FindFirstChild("FiQrPanel")
if oldGui then
    oldGui:Destroy()
end

-- Theme
local COLORS = {
    Background = Color3.fromRGB(17, 19, 28),
    Panel = Color3.fromRGB(29, 32, 45),
    PanelHover = Color3.fromRGB(39, 42, 58),
    Purple = Color3.fromRGB(145, 90, 255),
    White = Color3.fromRGB(245, 245, 255),
    Muted = Color3.fromRGB(155, 160, 180),
    PlayerESP = Color3.fromRGB(70, 170, 255),
    NPCESP = Color3.fromRGB(175, 100, 255),
}

-- Feature state
local speedEnabled = false
local jumpEnabled = false
local flyEnabled = false
local playerESPEnabled = false
local npcESPEnabled = false
local clickTeleportEnabled = false
local noclipEnabled = false
local fullbrightEnabled = false

local speedValue = 50
local jumpValue = 50
local flyValue = 50
local fovValue = 70
local selectedPlayer = nil

-- Character state
local character
local humanoid
local rootPart
local originalWalkSpeed
local originalJumpPower
local originalJumpHeight
local originalUseJumpPower
local originalAutoRotate
local originalPlatformStand

-- Fly objects
local flyAttachment
local flyVelocity
local flyOrientation

-- Noclip state
local originalCollisions = {}

-- ESP state
local espHighlights = {}

-- Save original camera and lighting values for restoration.
local originalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
}

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "FiQrPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(330, 535)
main.Position = UDim2.new(0.5, -165, 0.5, -267)
main.BackgroundColor3 = COLORS.Background
main.BorderSizePixel = 0
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.Purple
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.2
mainStroke.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = COLORS.Panel
header.BorderSizePixel = 0
header.Active = true
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 0)
title.Size = UDim2.new(1, -28, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "FiQr  |  CONTROL PANEL"
title.TextColor3 = COLORS.White
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Content"
scroll.Position = UDim2.fromOffset(0, 48)
scroll.Size = UDim2.new(1, 0, 1, -54)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLORS.Purple
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
scroll.Parent = main

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 9)
padding.PaddingRight = UDim.new(0, 9)
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = scroll

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 7)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local layoutOrder = 0
local function registerRow(row)
    layoutOrder += 1
    row.LayoutOrder = layoutOrder
    row.Parent = scroll
    return row
end

local function updateCanvasSize()
    scroll.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 20)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

local function makeCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end

local function createSection(text)
    local label = Instance.new("TextLabel")
    label.Name = "Section_" .. text
    label.Size = UDim2.new(1, 0, 0, 23)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = COLORS.Purple
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    return registerRow(label)
end

local function createButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = COLORS.Panel
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    button.Text = text
    button.TextColor3 = COLORS.White
    button.TextSize = 12
    makeCorner(button, 8)
    registerRow(button)
    button.Activated:Connect(callback)
    return button
end

local function createToggle(text, callback, initialState)
    local state = initialState == true
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 36)
    button.BackgroundColor3 = state and COLORS.Purple or COLORS.Panel
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    button.TextColor3 = COLORS.White
    button.TextSize = 12
    makeCorner(button, 8)

    local function render()
        button.Text = text .. (state and "  |  ON" or "  |  OFF")
        button.BackgroundColor3 = state and COLORS.Purple or COLORS.Panel
    end

    render()
    registerRow(button)

    button.Activated:Connect(function()
        state = not state
        render()
        callback(state)
    end)

    return button, function(newState)
        state = newState == true
        render()
        callback(state)
    end
end

local function createSlider(text, minValue, maxValue, defaultValue, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 61)
    row.BackgroundColor3 = COLORS.Panel
    row.BorderSizePixel = 0
    makeCorner(row, 8)
    registerRow(row)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.fromOffset(10, 5)
    nameLabel.Size = UDim2.new(1, -75, 0, 20)
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.Text = text
    nameLabel.TextColor3 = COLORS.White
    nameLabel.TextSize = 11
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -62, 0, 5)
    valueLabel.Size = UDim2.fromOffset(52, 20)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = COLORS.Purple
    valueLabel.TextSize = 11
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local track = Instance.new("TextButton")
    track.Name = "SliderTrack"
    track.Position = UDim2.new(0, 10, 0, 36)
    track.Size = UDim2.new(1, -20, 0, 9)
    track.BackgroundColor3 = COLORS.Background
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row
    makeCorner(track, 5)

    local initialPercent = (defaultValue - minValue) / (maxValue - minValue)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(initialPercent, 0, 1, 0)
    fill.BackgroundColor3 = COLORS.Purple
    fill.BorderSizePixel = 0
    fill.Parent = track
    makeCorner(fill, 5)

    local draggingSlider = false

    local function updateFromX(x)
        local width = track.AbsoluteSize.X
        if width <= 0 then
            return
        end

        local percent = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        local value = math.floor(minValue + percent * (maxValue - minValue) + 0.5)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value)
        callback(value)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    callback(defaultValue)
    return row
end

-- Draggable window
local draggingWindow = false
local dragInput
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        startPosition = main.Position
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = false
    end
end)

--==================================================
-- CHARACTER / MOVEMENT
--==================================================

local function restoreNoclip()
    for part, wasCollidable in pairs(originalCollisions) do
        if part and part.Parent then
            part.CanCollide = wasCollidable
        end
    end
    table.clear(originalCollisions)
end

local function stopFly()
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyOrientation then
        flyOrientation:Destroy()
        flyOrientation = nil
    end
    if flyAttachment then
        flyAttachment:Destroy()
        flyAttachment = nil
    end

    if humanoid and humanoid.Parent then
        humanoid.PlatformStand = originalPlatformStand == true
        if originalAutoRotate ~= nil then
            humanoid.AutoRotate = originalAutoRotate
        end
        if not humanoid.PlatformStand then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function startFly()
    if not humanoid or not rootPart or not rootPart.Parent then
        return
    end

    stopFly()
    originalPlatformStand = humanoid.PlatformStand
    originalAutoRotate = humanoid.AutoRotate
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false

    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "FiQrFlyAttachment"
    flyAttachment.Parent = rootPart

    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "FiQrFlyVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.MaxForce = 1000000
    flyVelocity.Parent = rootPart

    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "FiQrFlyOrientation"
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.MaxTorque = 1000000
    flyOrientation.Responsiveness = 25
    flyOrientation.CFrame = workspace.CurrentCamera.CFrame.Rotation
    flyOrientation.Parent = rootPart
end

local function applyMovement()
    if not humanoid or not humanoid.Parent then
        return
    end

    if speedEnabled then
        humanoid.WalkSpeed = speedValue
    elseif originalWalkSpeed ~= nil then
        humanoid.WalkSpeed = originalWalkSpeed
    end

    if jumpEnabled then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = jumpValue
    else
        if originalUseJumpPower ~= nil then
            humanoid.UseJumpPower = originalUseJumpPower
        end
        if originalJumpPower ~= nil then
            humanoid.JumpPower = originalJumpPower
        end
        if originalJumpHeight ~= nil then
            humanoid.JumpHeight = originalJumpHeight
        end
    end
end

local function setupCharacter(newCharacter)
    stopFly()
    restoreNoclip()

    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower
    originalJumpHeight = humanoid.JumpHeight
    originalUseJumpPower = humanoid.UseJumpPower
    originalAutoRotate = humanoid.AutoRotate
    originalPlatformStand = humanoid.PlatformStand

    applyMovement()

    if flyEnabled then
        startFly()
    end
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
    task.spawn(setupCharacter, player.Character)
end

--==================================================
-- FOV
--==================================================

createSection("CAMERA")
createSlider("FOV", 70, 150, 70, function(value)
    fovValue = value
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = value
    end
end)

--==================================================
-- MOVEMENT SLIDERS / TOGGLES
--==================================================

createSection("MOVEMENT  |  50–300")

createSlider("WALK SPEED", 50, 300, 50, function(value)
    speedValue = value
    if speedEnabled then
        applyMovement()
    end
end)

createToggle("SPEED", function(state)
    speedEnabled = state
    applyMovement()
end)

createSlider("JUMP POWER", 50, 300, 50, function(value)
    jumpValue = value
    if jumpEnabled then
        applyMovement()
    end
end)

createToggle("JUMP BOOST", function(state)
    jumpEnabled = state
    applyMovement()
end)

createSlider("FLY SPEED", 50, 300, 50, function(value)
    flyValue = value
end)

createToggle("FLY  |  WASD + SPACE / LEFT CTRL", function(state)
    flyEnabled = state
    if state then
        startFly()
    else
        stopFly()
    end
end)

RunService.RenderStepped:Connect(function()
    if not flyEnabled or not flyVelocity or not flyOrientation then
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local direction = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        direction += camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        direction -= camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        direction += camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        direction -= camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction += Vector3.yAxis
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        direction -= Vector3.yAxis
    end

    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    flyVelocity.VectorVelocity = direction * flyValue
    flyOrientation.CFrame = camera.CFrame.Rotation
end)

--==================================================
-- FULLBRIGHT
--==================================================

createSection("VISUALS")

local function setFullbright(state)
    fullbrightEnabled = state
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.ExposureCompensation = 0
    else
        for property, value in pairs(originalLighting) do
            Lighting[property] = value
        end
    end
end

createToggle("FULLBRIGHT", setFullbright)

--==================================================
-- ESP: OTHER PLAYERS + NPCs
--==================================================

local function addHighlight(model, color, activeModels)
    if not model or not model:IsA("Model") then
        return
    end

    local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        return
    end

    activeModels[model] = true

    local highlight = espHighlights[model]
    if not highlight or not highlight.Parent then
        highlight = Instance.new("Highlight")
        highlight.Name = "FiQrESP"
        highlight.Adornee = model
        highlight.FillTransparency = 0.65
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = model
        espHighlights[model] = highlight
    end

    highlight.FillColor = color
    highlight.OutlineColor = COLORS.White
end

local function refreshESP()
    local activeModels = {}

    if playerESPEnabled then
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                addHighlight(targetPlayer.Character, COLORS.PlayerESP, activeModels)
            end
        end
    end

    if npcESPEnabled then
        local npcFolder = workspace:FindFirstChild("PracticeTargets")
        if npcFolder then
            for _, npc in ipairs(npcFolder:GetChildren()) do
                if npc:IsA("Model") and not Players:GetPlayerFromCharacter(npc) then
                    addHighlight(npc, COLORS.NPCESP, activeModels)
                end
            end
        end
    end

    for model, highlight in pairs(espHighlights) do
        if not activeModels[model] or not model.Parent then
            highlight:Destroy()
            espHighlights[model] = nil
        end
    end
end

local espAccumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
    espAccumulator += deltaTime
    if espAccumulator >= 0.4 then
        espAccumulator = 0
        refreshESP()
    end
end)

createToggle("PLAYER ESP", function(state)
    playerESPEnabled = state
    refreshESP()
end)

createToggle("NPC ESP  |  PracticeTargets FOLDER", function(state)
    npcESPEnabled = state
    refreshESP()
end)

--==================================================
-- TELEPORT
--==================================================

createSection("TELEPORT")

local playerSelectButton
local function getOtherPlayers()
    local available = {}
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            table.insert(available, targetPlayer)
        end
    end
    table.sort(available, function(a, b)
        return a.Name < b.Name
    end)
    return available
end

local function refreshPlayerSelection()
    local available = getOtherPlayers()
    local stillAvailable = false

    for _, targetPlayer in ipairs(available) do
        if targetPlayer == selectedPlayer then
            stillAvailable = true
            break
        end
    end

    if not stillAvailable then
        selectedPlayer = available[1]
    end

    if playerSelectButton then
        playerSelectButton.Text = selectedPlayer
            and ("SELECT PLAYER  |  " .. selectedPlayer.Name)
            or "SELECT PLAYER  |  NONE"
    end
end

playerSelectButton = createButton("SELECT PLAYER  |  NONE", function()
    local available = getOtherPlayers()
    if #available == 0 then
        selectedPlayer = nil
        refreshPlayerSelection()
        return
    end

    local currentIndex = 0
    for index, targetPlayer in ipairs(available) do
        if targetPlayer == selectedPlayer then
            currentIndex = index
            break
        end
    end

    selectedPlayer = available[(currentIndex % #available) + 1]
    refreshPlayerSelection()
end)

Players.PlayerAdded:Connect(refreshPlayerSelection)
Players.PlayerRemoving:Connect(refreshPlayerSelection)
refreshPlayerSelection()

createButton("TELEPORT TO SELECTED PLAYER", function()
    if not selectedPlayer then
        warn("FiQr: Select a player first.")
        return
    end

    local targetCharacter = selectedPlayer.Character
    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    local myCharacter = player.Character

    if targetRoot and myCharacter then
        myCharacter:PivotTo(targetRoot.CFrame * CFrame.new(4, 0, 0))
    end
end)

createToggle("CLICK TELEPORT  |  CLICK WORLD", function(state)
    clickTeleportEnabled = state
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not clickTeleportEnabled or gameProcessed then
        return
    end
    if UserInputService:GetFocusedTextBox() then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    local target = mouse.Target
    local myCharacter = player.Character
    if target and myCharacter then
        local destination = mouse.Hit.Position + Vector3.new(0, 4, 0)
        myCharacter:PivotTo(CFrame.new(destination))
    end
end)

--==================================================
-- NOCLIP
--==================================================

createSection("OTHER")

createToggle("NOCLIP", function(state)
    noclipEnabled = state
    if not state then
        restoreNoclip()
    end
end)

RunService.Stepped:Connect(function()
    if not noclipEnabled or not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            if originalCollisions[object] == nil then
                originalCollisions[object] = object.CanCollide
            end
            object.CanCollide = false
        end
    end
end)

-- Restore settings when the GUI is destroyed.
gui.Destroying:Connect(function()
    speedEnabled = false
    jumpEnabled = false
    flyEnabled = false
    noclipEnabled = false
    playerESPEnabled = false
    npcESPEnabled = false

    stopFly()
    restoreNoclip()
    setFullbright(false)

    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = originalFOV
    end

    for _, highlight in pairs(espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    table.clear(espHighlights)

    if humanoid and humanoid.Parent then
        if originalWalkSpeed ~= nil then
            humanoid.WalkSpeed = originalWalkSpeed
        end
        if originalJumpPower ~= nil then
            humanoid.JumpPower = originalJumpPower
        end
        if originalJumpHeight ~= nil then
            humanoid.JumpHeight = originalJumpHeight
        end
        if originalUseJumpPower ~= nil then
            humanoid.UseJumpPower = originalUseJumpPower
        end
    end
end)

task.defer(updateCanvasSize)
print("FiQr loaded. Features: Speed, Jump, Fly, Player/NPC ESP, Teleport, Fullbright, FOV, Noclip.")
