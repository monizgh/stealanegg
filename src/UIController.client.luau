local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotes then
    return
end

local actionEvent = remotes:WaitForChild("Action", 30)
if not actionEvent then
    return
end

local redeemEvent = remotes:WaitForChild("Redeem", 30)
if not redeemEvent then
    return
end

local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("StealAnEggHUD", 30)
if not gui then
    return
end

local ContentProvider = game:GetService("ContentProvider")

local function preloadAsset(asset)
    if typeof(asset) == "string" and #asset > 0 then
        pcall(function()
            ContentProvider:PreloadAsync({ asset })
        end)
    end
end

local clickSound = Instance.new("Sound")
clickSound.Name = "UIClick"
clickSound.SoundId = "rbxassetid://122835655736085"
clickSound.Volume = 0.35
clickSound.Parent = gui

local hookedButtons = {}

local function hookButton(button)
    if hookedButtons[button] then
        return
    end
    hookedButtons[button] = true

    local pulse = Instance.new("UIScale")
    pulse.Name = "ClickPulse"
    pulse.Parent = button

    button.MouseEnter:Connect(function()
        if button.Active then
            TweenService:Create(pulse, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.06 }):Play()
        end
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(pulse, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    end)

    button.Activated:Connect(function()
        local action = button:GetAttribute("Action")
        if typeof(action) == "string" and #action > 0 then
            if action == "redeem" then
                local box = gui:FindFirstChild("CodeBox", true)
                local code = box and box.Text or ""
                local ok, message = pcall(function()
                    return redeemEvent:InvokeServer(code)
                end)
                if box and ok and typeof(message) == "string" and #message > 0 then
                    box.Text = ""
                    box.PlaceholderText = message
                end
            else
                actionEvent:FireServer(action)
            end
        end

        clickSound:Play()

        local down = TweenService:Create(pulse, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.9 })
        down.Completed:Connect(function()
            TweenService:Create(pulse, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        end)
        down:Play()
    end)
end

for _, descendant in ipairs(gui:GetDescendants()) do
    if descendant:IsA("GuiButton") then
        hookButton(descendant)
    end
end

gui.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("GuiButton") then
        task.defer(hookButton, descendant)
    end
    if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
        task.defer(preloadAsset, descendant.Image)
    end
end)

task.defer(function()
    preloadAsset(clickSound.SoundId)
    for _, descendant in ipairs(gui:GetDescendants()) do
        if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            preloadAsset(descendant.Image)
        end
    end
end)

local rootScale = Instance.new("UIScale")
rootScale.Name = "RootScale"
rootScale.Parent = gui

local function panelFit()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local net = math.clamp(viewport.X / 940, 0.52, 1)
    return net / math.max(rootScale.Scale, 0.05)
end

local function updateScale()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X < 760 then
        rootScale.Scale = 0.72
    elseif viewport.X < 1100 then
        rootScale.Scale = 0.85
    else
        rootScale.Scale = 1
    end
end

updateScale()

local overlay = gui:WaitForChild("PanelOverlay", 20)
if overlay then
    local function panelScaleOf(panel)
        local scale = panel:FindFirstChild("PanelScale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "PanelScale"
            scale.Scale = 1
            scale.Parent = panel
        end
        return scale
    end

    local function animatePanel(panel)
        local scale = panelScaleOf(panel)
        scale.Scale = panelFit() * 0.88
        TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = panelFit() }):Play()
    end

    local function hookPanel(panel)
        panelScaleOf(panel)
        if overlay.Visible then
            animatePanel(panel)
        end
    end

    overlay:GetPropertyChangedSignal("Visible"):Connect(function()
        if overlay.Visible then
            overlay.BackgroundTransparency = 0.78
            TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.45 }):Play()
            for _, child in ipairs(overlay:GetChildren()) do
                if child.Name == "Panel" then
                    animatePanel(child)
                end
            end
        end
    end)

    for _, child in ipairs(overlay:GetChildren()) do
        if child.Name == "Panel" then
            hookPanel(child)
        end
    end
    overlay.DescendantAdded:Connect(function(child)
        if child.Name == "Panel" then
            hookPanel(child)
        end
    end)

    local camera = Workspace.CurrentCamera
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            updateScale()
            for _, child in ipairs(overlay:GetChildren()) do
                if child.Name == "Panel" then
                    local scale = panelScaleOf(child)
                    scale.Scale = panelFit()
                end
            end
        end)
    end
end

local cashLabel = gui:WaitForChild("CashLabel", 15)
if cashLabel then
    local cashScale = Instance.new("UIScale")
    cashScale.Name = "CashPop"
    cashScale.Parent = cashLabel
    cashLabel:GetPropertyChangedSignal("Text"):Connect(function()
        cashScale.Scale = 1.18
        TweenService:Create(cashScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    end)
end

-- Proximity world labels --------------------------------------------------
-- Server tags every gameplay BillboardGui with WorldLabel/ShowDistance/Group/MaxLabels.
-- This loop only reads attributes and fades text locally; no server traffic.
local RunService = game:GetService("RunService")
local worldLabels = {}

local function collectLabel(billboard)
    if worldLabels[billboard] or not billboard:IsA("BillboardGui") then
        return
    end
    if billboard:GetAttribute("WorldLabel") ~= true then
        return
    end

    local entry = {
        distance = billboard:GetAttribute("ShowDistance") or 18,
        group = billboard:GetAttribute("Group") or "misc",
        maxLabels = billboard:GetAttribute("MaxLabels") or 1,
        alpha = 0,
        target = 0,
        parts = {},
    }

    for _, item in ipairs(billboard:GetDescendants()) do
        if item:IsA("TextLabel") then
            table.insert(entry.parts, { object = item, base = item.TextTransparency, text = true })
            item.TextTransparency = 1
        elseif item:IsA("UIStroke") then
            table.insert(entry.parts, { object = item, base = item.Transparency, text = false })
            item.Transparency = 1
        end
    end

    billboard.Enabled = false
    worldLabels[billboard] = entry
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant:IsA("BillboardGui") then
        collectLabel(descendant)
    end
end

Workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BillboardGui") then
        collectLabel(descendant)
    end
end)

local checkTimer = 0

local function updateLabelTargets()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local camPos = camera.CFrame.Position
    local groups = {}

    for billboard, entry in pairs(worldLabels) do
        entry.target = 0
        if not billboard.Parent then
            worldLabels[billboard] = nil
        else
            local adornee = billboard.Adornee or billboard.Parent
            local position
            if adornee and adornee:IsA("BasePart") then
                position = adornee.Position
            elseif adornee and adornee:IsA("Model") then
                position = adornee:GetPivot().Position
            end
            if position then
                local dx = position.X - camPos.X
                local dy = position.Y - camPos.Y
                local dz = position.Z - camPos.Z
                local distanceSq = dx * dx + dy * dy + dz * dz
                if distanceSq <= entry.distance * entry.distance then
                    local list = groups[entry.group]
                    if not list then
                        list = {}
                        groups[entry.group] = list
                    end
                    table.insert(list, { billboard = billboard, distanceSq = distanceSq })
                end
            end
        end
    end

    for _, list in pairs(groups) do
        table.sort(list, function(a, b)
            return a.distanceSq < b.distanceSq
        end)
        for index, item in ipairs(list) do
            local entry = worldLabels[item.billboard]
            if entry and index <= entry.maxLabels then
                entry.target = 1
            end
        end
    end
end

RunService.RenderStepped:Connect(function(deltaTime)
    checkTimer += deltaTime
    if checkTimer >= 0.12 then
        checkTimer = 0
        updateLabelTargets()
    end

    for billboard, entry in pairs(worldLabels) do
        if entry.alpha ~= entry.target then
            local alpha = entry.alpha + (entry.target - entry.alpha) * math.min(1, deltaTime * 7)
            if math.abs(entry.target - alpha) < 0.01 then
                alpha = entry.target
            end
            entry.alpha = alpha
            local transparency = 1 - alpha
            for _, part in ipairs(entry.parts) do
                local value = part.base + (1 - part.base) * transparency
                if part.text then
                    part.object.TextTransparency = value
                else
                    part.object.Transparency = value
                end
            end
            billboard.Enabled = alpha > 0.005
        end
    end
end)
