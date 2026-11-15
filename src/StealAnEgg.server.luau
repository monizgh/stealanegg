local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local actionEvent = remotesFolder:FindFirstChild("Action")
if not actionEvent then
    actionEvent = Instance.new("RemoteEvent")
    actionEvent.Name = "Action"
    actionEvent.Parent = remotesFolder
end

local redeemEvent = remotesFolder:FindFirstChild("Redeem")
if not redeemEvent then
    redeemEvent = Instance.new("RemoteFunction")
    redeemEvent.Name = "Redeem"
    redeemEvent.Parent = remotesFolder
end

local CONFIG = {
    BASE_COUNT = 8,
    BASE_RADIUS = 230,
    NEST_COUNT = 6,
    NEST_RADIUS = 110,
    NEST_EGG_RESPAWN = 12,
    HATCH_SECONDS = 5,
    STEAL_GRACE_SECONDS = 3,
    PODS_BASE = 6,
    PODS_PER_UPGRADE = 2,
    PODS_MAX = 10,
    UPGRADE_COST = 500,
    TRAIN_STEP = 0.5,
    TRAIN_CAP = 60,
    START_SPEED = 16,
}

local TIER_COLORS = {
    Common = Color3.fromRGB(200, 204, 214),
    Uncommon = Color3.fromRGB(84, 200, 130),
    Rare = Color3.fromRGB(84, 156, 255),
    Epic = Color3.fromRGB(178, 112, 255),
    Legendary = Color3.fromRGB(255, 198, 64),
}

local TIER_WEIGHTS = {
    { tier = "Common", weight = 45 },
    { tier = "Uncommon", weight = 30 },
    { tier = "Rare", weight = 15 },
    { tier = "Epic", weight = 8 },
    { tier = "Legendary", weight = 2 },
}

local SPECIES = {
    { name = "Chick", tier = "Common", income = 2, color = Color3.fromRGB(245, 213, 71) },
    { name = "Piglet", tier = "Common", income = 3, color = Color3.fromRGB(240, 163, 176) },
    { name = "Crab", tier = "Common", income = 4, color = Color3.fromRGB(224, 90, 78) },
    { name = "Dino", tier = "Uncommon", income = 8, color = Color3.fromRGB(91, 203, 119) },
    { name = "Scorpion", tier = "Uncommon", income = 10, color = Color3.fromRGB(201, 138, 75) },
    { name = "Penguin", tier = "Uncommon", income = 12, color = Color3.fromRGB(88, 120, 200) },
    { name = "T-Rex", tier = "Rare", income = 25, color = Color3.fromRGB(62, 155, 79) },
    { name = "Turtle", tier = "Rare", income = 30, color = Color3.fromRGB(99, 179, 107) },
    { name = "Axolotl", tier = "Rare", income = 35, color = Color3.fromRGB(242, 166, 216) },
    { name = "Dragon", tier = "Epic", income = 80, color = Color3.fromRGB(176, 76, 255) },
    { name = "Unicorn", tier = "Epic", income = 100, color = Color3.fromRGB(230, 194, 255) },
    { name = "Shark", tier = "Epic", income = 120, color = Color3.fromRGB(90, 143, 191) },
    { name = "Golden Rex", tier = "Legendary", income = 400, color = Color3.fromRGB(255, 184, 0) },
    { name = "Celestial Crab", tier = "Legendary", income = 500, color = Color3.fromRGB(127, 227, 255) },
    { name = "Cosmic Egg", tier = "Legendary", income = 600, color = Color3.fromRGB(255, 106, 213) },
}

local SIZES = {
    { name = "Small", scale = 0.8, multiplier = 1, weight = 20 },
    { name = "Normal", scale = 1, multiplier = 1, weight = 55 },
    { name = "Big", scale = 1.5, multiplier = 2, weight = 20 },
    { name = "Huge", scale = 2.2, multiplier = 4, weight = 5 },
}

local MUTATIONS = {
    { name = "Normal", multiplier = 1, weight = 80, color = nil },
    { name = "Golden", multiplier = 2, weight = 15, color = Color3.fromRGB(255, 200, 60) },
    { name = "Diamond", multiplier = 3.5, weight = 5, color = Color3.fromRGB(120, 230, 255) },
}

local BASE_COLORS = {
    Color3.fromRGB(224, 96, 96),
    Color3.fromRGB(92, 156, 255),
    Color3.fromRGB(104, 204, 128),
    Color3.fromRGB(240, 196, 84),
    Color3.fromRGB(196, 124, 255),
    Color3.fromRGB(96, 210, 214),
    Color3.fromRGB(244, 138, 196),
    Color3.fromRGB(160, 176, 96),
}

local PALETTE = {
    grass = Color3.fromRGB(122, 219, 58),
    grassDark = Color3.fromRGB(104, 196, 46),
    dirt = Color3.fromRGB(198, 96, 44),
    dirtDark = Color3.fromRGB(156, 72, 34),
    leaf = Color3.fromRGB(52, 156, 54),
    leafLight = Color3.fromRGB(86, 198, 74),
    trunk = Color3.fromRGB(126, 82, 48),
    wood = Color3.fromRGB(150, 96, 52),
    ink = Color3.fromRGB(24, 22, 30),
    white = Color3.fromRGB(247, 247, 250),
}

-- UIMegaPack (Workspace > UIMegaPack > UngroupStarterGUI > Free_UI_Pack > MegaPack).
-- Referenced by the real asset IDs inside the pack; nothing in the pack is renamed or moved.
local UI = {
    shop = "rbxassetid://79189567200992",
    pets = "rbxassetid://110467625627559",
    indexIcon = "rbxassetid://134443950151679",
    settings = "rbxassetid://79312800758069",
    daily = "rbxassetid://82293274582736",
    codes = "rbxassetid://74993576301387",
    rebirth = "rbxassetid://115325120904186",
    fuse = "rbxassetid://78098471983751",
    help = "rbxassetid://120918127409954",
    money = "rbxassetid://134033317054407",
    close = "rbxassetid://104731637166575",
    correct = "rbxassetid://116455359000189",
    wheel = "rbxassetid://108607068483395",
    trade = "rbxassetid://135952953888549",
    frame = "rbxassetid://123725587383568",
    click = "rbxassetid://122835655736085",
}

local UI_TIER_FRAMES = {
    Common = "rbxassetid://123725587383568",
    Uncommon = "rbxassetid://133725841617476",
    Rare = "rbxassetid://76886101386757",
    Epic = "rbxassetid://88163224055084",
    Legendary = "rbxassetid://85710516229772",
}

local FENCE_STYLES = {
    { color = Color3.fromRGB(172, 92, 255), material = Enum.Material.Neon },
    { color = Color3.fromRGB(246, 246, 250), material = Enum.Material.SmoothPlastic },
    { color = Color3.fromRGB(214, 78, 44), material = Enum.Material.WoodPlanks },
    { color = Color3.fromRGB(46, 46, 54), material = Enum.Material.SmoothPlastic },
}

local BIKES = {
    { name = "Starter Bike", price = 0, multiplier = 1, color = Color3.fromRGB(206, 74, 66), wheelSize = 3.2 },
    { name = "Cruiser", price = 1500, multiplier = 1.2, color = Color3.fromRGB(80, 170, 255), wheelSize = 3.5 },
    { name = "Turbo", price = 12000, multiplier = 1.45, color = Color3.fromRGB(255, 190, 60), wheelSize = 3.7, neon = true },
    { name = "Rocket", price = 90000, multiplier = 1.8, color = Color3.fromRGB(176, 96, 255), wheelSize = 4, neon = true },
}

local TRAILS = {
    { name = "Dust Trail", price = 0, color = Color3.fromRGB(210, 210, 215) },
    { name = "Crimson Trail", price = 2000, color = Color3.fromRGB(255, 70, 70) },
    { name = "Neon Trail", price = 15000, color = Color3.fromRGB(90, 255, 150) },
    { name = "Galaxy Trail", price = 80000, color = Color3.fromRGB(180, 100, 255) },
}

local REBIRTH_CASH = 25000
local REBIRTH_BONUS = 0.25

local DAILY_REWARDS = {
    { cash = 1000 },
    { cash = 2500 },
    { cash = 5000 },
    { cash = 10000 },
    { cash = 20000 },
    { cash = 40000 },
    { cash = 100000, pet = true },
}
local DAILY_COOLDOWN = 20 * 60 * 60

local CODES = {
    WELCOME = 1500,
    EGG2026 = 5000,
    STEAL100 = 10000,
}

local EggInfo = {}
local Carrying = {}
local State = {}
local HUDS = {}
local Bases = {}
local Nests = {}
local Guardians = {}

local pickup
local depositEgg
local applyEquipment

local function formatNumber(value)
    value = math.floor(value)
    if value >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif value >= 10000 then
        return string.format("%.1fK", value / 1000)
    end
    return tostring(value)
end

local function weightedPick(entries, weightKey)
    local total = 0
    for _, entry in ipairs(entries) do
        total += entry[weightKey]
    end

    local roll = math.random() * total
    for _, entry in ipairs(entries) do
        roll -= entry[weightKey]
        if roll <= 0 then
            return entry
        end
    end
    return entries[1]
end

local function pickSpecies()
    local tier = weightedPick(TIER_WEIGHTS, "weight").tier
    local pool = {}
    for _, species in ipairs(SPECIES) do
        if species.tier == tier then
            table.insert(pool, species)
        end
    end
    return pool[math.random(#pool)]
end

local function findSpecies(name)
    for _, species in ipairs(SPECIES) do
        if species.name == name then
            return species
        end
    end
    return nil
end

local function findEntryByName(entries, name)
    for _, entry in ipairs(entries) do
        if entry.name == name then
            return entry
        end
    end
    return nil
end

local function makePart(size, cframe, color, parent, material)
    local part = Instance.new("Part")
    part.Anchored = true
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function playerFromCharacter(character)
    return Players:GetPlayerFromCharacter(character)
end

local function burst(position, color)
    local fx = Instance.new("Part")
    fx.Anchored = true
    fx.CanCollide = false
    fx.Transparency = 1
    fx.Size = Vector3.new(1, 1, 1)
    fx.CFrame = CFrame.new(position)
    fx.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(color)
    emitter.Size = NumberSequence.new(2.6)
    emitter.Lifetime = NumberRange.new(0.4, 0.9)
    emitter.Speed = NumberRange.new(9, 17)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rate = 0
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Parent = fx
    emitter:Emit(26)
    task.delay(1.5, function()
        fx:Destroy()
    end)
end

local function countIndex(state)
    local count = 0
    for _ in pairs(state.index) do
        count += 1
    end
    return count
end

local function bikeMultiplier(state)
    local bike = state and BIKES[state.equippedBike or 1]
    return bike and bike.multiplier or 1
end

local function rebirthMultiplier(state)
    return 1 + REBIRTH_BONUS * (state and state.rebirths or 0)
end

local function updateHUD(player)
    local hud = HUDS[player]
    if not hud then
        return
    end

    local stats = player:FindFirstChild("leaderstats")
    local state = State[player]
    if not stats or not state then
        return
    end

    local cash = stats:FindFirstChild("Cash")
    local speed = stats:FindFirstChild("Speed")
    local pets = stats:FindFirstChild("Pets")
    if cash then
        hud.cash.Text = "$" .. formatNumber(cash.Value)
    end
    if pets and hud.petsBadge then
        hud.petsBadge.Text = tostring(pets.Value)
    end
    if speed and hud.info then
        hud.info.Text = string.format(
            "SPEED %.1f  •  PETS %d  •  REBIRTH %d  •  INDEX %d/%d",
            speed.Value,
            pets and pets.Value or 0,
            state.rebirths or 0,
            countIndex(state),
            #SPECIES
        )
    end
end

local function addCash(player, amount)
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")
    if cash then
        cash.Value = math.max(0, cash.Value + amount)
        updateHUD(player)
    end
end

local function addPetStat(player, amount)
    local stats = player:FindFirstChild("leaderstats")
    local pets = stats and stats:FindFirstChild("Pets")
    if pets then
        pets.Value = math.max(0, pets.Value + amount)
        updateHUD(player)
    end
end

local function setSpeed(player, speed)
    local state = State[player]
    if not state then
        return
    end

    state.speed = math.clamp(speed, CONFIG.START_SPEED, CONFIG.TRAIN_CAP)
    local stats = player:FindFirstChild("leaderstats")
    local stat = stats and stats:FindFirstChild("Speed")
    if stat then
        stat.Value = state.speed
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = math.min(100, state.speed * bikeMultiplier(state))
    end
    updateHUD(player)
end

local function notify(player, message)
    local hud = HUDS[player]
    if not hud then
        return
    end

    local state = State[player]
    if state and state.settings and state.settings.notifications == false then
        return
    end

    hud.token += 1
    local token = hud.token
    hud.toast.Text = message
    task.delay(3, function()
        if hud.token == token and hud.toast.Parent then
            hud.toast.Text = ""
        end
    end)
end

local function createHUD(player)
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "StealAnEggHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 20
    gui.Parent = playerGui

    local function rounded(instance, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = instance
    end

    local function outlined(instance, thickness)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thickness
        stroke.Color = PALETTE.ink
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = instance
    end

    local function textLabel(parent, text, size, position, textSize, color, align, font)
        local textLabel = Instance.new("TextLabel")
        textLabel.BackgroundTransparency = 1
        textLabel.Size = size
        textLabel.Position = position
        textLabel.Font = font or Enum.Font.FredokaOne
        textLabel.TextSize = textSize
        textLabel.TextColor3 = color or PALETTE.white
        textLabel.TextXAlignment = align or Enum.TextXAlignment.Center
        textLabel.TextStrokeTransparency = 1
        textLabel.TextStrokeColor3 = PALETTE.ink
        local outline = Instance.new("UIStroke")
        outline.Thickness = math.clamp((textSize or 18) * 0.08, 1.2, 4)
        outline.Color = PALETTE.ink
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        outline.Parent = textLabel
        textLabel.Text = text
        textLabel.Parent = parent
        return textLabel
    end

    local title = textLabel(gui, "STEAL AN EGG!", UDim2.new(0, 900, 0, 62), UDim2.new(0.5, 0, 0, 12), 54, PALETTE.white, nil, Enum.Font.LuckiestGuy)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.TextStrokeTransparency = 1

    local subtitle = textLabel(gui, "STEAL EGGS  •  HATCH PETS  •  UPGRADE YOUR PEN", UDim2.new(0, 900, 0, 24), UDim2.new(0.5, 0, 0, 74), 18, Color3.fromRGB(255, 234, 150))
    subtitle.AnchorPoint = Vector2.new(0.5, 0)

    local infoPanel = Instance.new("Frame")
    infoPanel.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
    infoPanel.BackgroundTransparency = 0.3
    infoPanel.BorderSizePixel = 0
    infoPanel.Position = UDim2.fromOffset(16, 100)
    infoPanel.Size = UDim2.fromOffset(420, 40)
    infoPanel.Parent = gui
    rounded(infoPanel, 10)

    local speedIcon = Instance.new("ImageLabel")
    speedIcon.BackgroundTransparency = 1
    speedIcon.Image = UI.wheel
    speedIcon.ScaleType = Enum.ScaleType.Fit
    speedIcon.Position = UDim2.fromOffset(6, 7)
    speedIcon.Size = UDim2.fromOffset(26, 26)
    speedIcon.Parent = infoPanel

    local info = textLabel(infoPanel, "SPEED 16.0  •  PETS 0  •  REBIRTH 0  •  INDEX 0/15", UDim2.new(1, -44, 1, 0), UDim2.fromOffset(38, 0), 14, PALETTE.white, Enum.TextXAlignment.Left)

    local function packButton(action, key, anchor, position, caption)
        local button = Instance.new("ImageButton")
        button.Name = key .. "Button"
        button.Image = UI[key]
        button.ScaleType = Enum.ScaleType.Fit
        button.BackgroundTransparency = 1
        button.AutoButtonColor = false
        button.AnchorPoint = anchor
        button.Position = position
        button.Size = UDim2.fromOffset(60, 60)
        button.Parent = gui
        button:SetAttribute("Action", action)
        local label = textLabel(button, caption, UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 60), 13, PALETTE.white)
        label.TextStrokeTransparency = 1
        return button
    end

    packButton("shop", "shop", Vector2.new(0, 0), UDim2.fromOffset(16, 152), "SHOP")
    packButton("index", "indexIcon", Vector2.new(0, 0), UDim2.fromOffset(16, 232), "INDEX")
    packButton("settings", "settings", Vector2.new(0, 0), UDim2.fromOffset(16, 312), "SETTINGS")

    packButton("daily", "daily", Vector2.new(1, 0), UDim2.new(1, -16, 0, 12), "DAILY")
    packButton("codes", "codes", Vector2.new(1, 0), UDim2.new(1, -16, 0, 92), "CODES")
    packButton("rebirth", "rebirth", Vector2.new(1, 0), UDim2.new(1, -16, 0, 172), "REBIRTH")
    packButton("fuse", "fuse", Vector2.new(1, 0), UDim2.new(1, -16, 0, 252), "FUSE")

    local pawButton = packButton("pets", "pets", Vector2.new(0, 0), UDim2.fromOffset(16, 392), "PETS")
    pawButton.Name = "PetsButton"
    local eggButton = packButton("help", "help", Vector2.new(0, 0), UDim2.fromOffset(16, 472), "HELP")
    eggButton.Name = "HelpButton"

    local petsBadge = textLabel(pawButton, "0", UDim2.fromOffset(26, 24), UDim2.fromOffset(32, 32), 16, PALETTE.white, Enum.TextXAlignment.Center)
    petsBadge.BackgroundColor3 = Color3.fromRGB(20, 16, 28)
    petsBadge.BackgroundTransparency = 0.15
    petsBadge.TextStrokeTransparency = 1
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 8)
    badgeCorner.Parent = petsBadge

    local cashPill = Instance.new("Frame")
    cashPill.AnchorPoint = Vector2.new(0, 1)
    cashPill.Position = UDim2.new(0, 16, 1, -96)
    cashPill.Size = UDim2.fromOffset(340, 64)
    cashPill.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
    cashPill.BackgroundTransparency = 0.12
    cashPill.BorderSizePixel = 0
    cashPill.Parent = gui
    rounded(cashPill, 14)
    outlined(cashPill, 3)

    local coin = Instance.new("ImageLabel")
    coin.BackgroundTransparency = 1
    coin.Image = UI.money
    coin.ScaleType = Enum.ScaleType.Fit
    coin.Position = UDim2.fromOffset(8, 8)
    coin.Size = UDim2.fromOffset(48, 48)
    coin.Parent = cashPill

    local cash = textLabel(gui, "$0", UDim2.fromOffset(266, 64), UDim2.new(0, 78, 1, -96), 34, Color3.fromRGB(98, 238, 64), Enum.TextXAlignment.Left, Enum.Font.LuckiestGuy)
    cash.Name = "CashLabel"
    cash.AnchorPoint = Vector2.new(0, 1)
    cash.TextStrokeTransparency = 1
    cash.TextStrokeColor3 = PALETTE.ink

    local function makeSlot(offsetX, number, iconBuilder)
        local slot = Instance.new("Frame")
        slot.AnchorPoint = Vector2.new(0.5, 1)
        slot.Position = UDim2.new(0.5, offsetX, 1, -16)
        slot.Size = UDim2.fromOffset(64, 64)
        slot.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
        slot.BackgroundTransparency = 0.15
        slot.BorderSizePixel = 0
        slot.Parent = gui
        rounded(slot, 12)
        outlined(slot, 3)

        textLabel(slot, tostring(number), UDim2.fromOffset(24, 22), UDim2.fromOffset(5, 2), 17, PALETTE.white, Enum.TextXAlignment.Left)
        iconBuilder(slot)
    end

    makeSlot(-38, 1, function(parent)
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position = UDim2.fromScale(0.5, 0.56)
        bar.Size = UDim2.fromOffset(34, 7)
        bar.BackgroundColor3 = Color3.fromRGB(206, 142, 84)
        bar.BorderSizePixel = 0
        bar.Rotation = -35
        bar.Parent = parent
        rounded(bar, 3)
    end)

    makeSlot(38, 2, function(parent)
        local potion = Instance.new("Frame")
        potion.AnchorPoint = Vector2.new(0.5, 0.5)
        potion.Position = UDim2.fromScale(0.5, 0.58)
        potion.Size = UDim2.fromOffset(22, 26)
        potion.BackgroundColor3 = Color3.fromRGB(168, 96, 255)
        potion.BorderSizePixel = 0
        potion.Parent = parent
        rounded(potion, 10)
    end)

    local moon = Instance.new("Frame")
    moon.AnchorPoint = Vector2.new(1, 1)
    moon.Position = UDim2.new(1, -142, 1, -24)
    moon.Size = UDim2.fromOffset(22, 22)
    moon.BackgroundColor3 = Color3.fromRGB(236, 226, 255)
    moon.BorderSizePixel = 0
    moon.Parent = gui
    rounded(moon, 11)

    local night = textLabel(gui, "NIGHT", UDim2.fromOffset(110, 34), UDim2.new(1, -18, 1, -22), 24, Color3.fromRGB(220, 190, 255), Enum.TextXAlignment.Right)
    night.AnchorPoint = Vector2.new(1, 1)

    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -216)
    hint.Size = UDim2.new(0, 780, 0, 20)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.FredokaOne
    hint.TextSize = 15
    hint.TextColor3 = PALETTE.white
    hint.TextTransparency = 0.25
    hint.TextStrokeTransparency = 0.5
    hint.Text = "Hold E at a nest to grab an egg • Drop it on your glowing pad • Upgrade your pen to hold more pets"
    hint.Parent = gui
    task.delay(30, function()
        if hint.Parent then
            hint.TextTransparency = 1
        end
    end)

    local toast = textLabel(gui, "", UDim2.new(0, 760, 0, 40), UDim2.new(0.5, 0, 0, 150), 28, Color3.fromRGB(255, 228, 96))
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.TextStrokeTransparency = 1
    toast.ZIndex = 40

    local overlay = Instance.new("Frame")
    overlay.Name = "PanelOverlay"
    overlay.BackgroundColor3 = Color3.fromRGB(10, 8, 16)
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Visible = false
    overlay.ZIndex = 30
    overlay.Parent = gui

    HUDS[player] = {
        cash = cash,
        info = info,
        toast = toast,
        petsBadge = petsBadge,
        gui = gui,
        overlay = overlay,
        token = 0,
    }
    updateHUD(player)
end

local function createBillboard(part, size, offsetY, text, color, options)
    options = options or {}

    local distance = options.distance or 18
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WorldLabel"
    billboard.Size = size
    billboard.StudsOffset = Vector3.new(0, offsetY, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = distance + 8
    billboard.Parent = part

    -- Read by StarterPlayerScripts.UIController for distance fades and group caps.
    billboard:SetAttribute("WorldLabel", true)
    billboard:SetAttribute("ShowDistance", distance)
    billboard:SetAttribute("Group", options.group or text)
    billboard:SetAttribute("MaxLabels", options.maxLabels or 1)

    local shadow = Instance.new("TextLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.fromScale(1, 1)
    shadow.Position = UDim2.fromOffset(0, 2)
    shadow.Font = Enum.Font.FredokaOne
    shadow.TextScaled = true
    shadow.TextColor3 = Color3.fromRGB(12, 10, 16)
    shadow.TextTransparency = 0.55
    shadow.TextXAlignment = Enum.TextXAlignment.Center
    shadow.TextYAlignment = Enum.TextYAlignment.Center
    shadow.ZIndex = 1
    shadow.Text = options.uppercase and string.upper(text) or text
    shadow.Parent = billboard

    local sizeConstraint = Instance.new("UITextSizeConstraint")
    sizeConstraint.MinTextSize = 8
    sizeConstraint.MaxTextSize = options.maxTextSize or 20
    sizeConstraint.Parent = shadow

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 2
    label.Text = options.uppercase and string.upper(text) or text
    label.Parent = billboard

    local labelSize = Instance.new("UITextSizeConstraint")
    labelSize.MinTextSize = 8
    labelSize.MaxTextSize = options.maxTextSize or 20
    labelSize.Parent = label

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = options.stroke or 2.5
    stroke.Color = PALETTE.ink
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Parent = label

    return label
end

local function createPetModel(species, sizeEntry, mutationEntry, position, facing)
    local scale = sizeEntry.scale
    local primary = mutationEntry.color or species.color

    local model = Instance.new("Model")
    model.Name = species.name

    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(1, 1, 1) * scale
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = CFrame.new(position)
    root.Parent = model
    model.PrimaryPart = root

    local function buildPart(name, size, offset, color, material)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size * scale
        part.CFrame = root.CFrame * CFrame.new(offset * scale)
        part.Anchored = false
        part.CanCollide = false
        part.Color = color
        part.Material = material or Enum.Material.SmoothPlastic
        part.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = part
        return part
    end

    local darker = Color3.new(primary.R * 0.7, primary.G * 0.7, primary.B * 0.7)
    buildPart("Body", Vector3.new(3, 2, 5), Vector3.new(0, 2.6, 0), primary, Enum.Material.SmoothPlastic)
    buildPart("Head", Vector3.new(2.2, 2, 2.2), Vector3.new(0, 3, -2.9), primary, Enum.Material.SmoothPlastic)
    buildPart("Snout", Vector3.new(1.4, 0.8, 0.8), Vector3.new(0, 2.7, -4.1), darker, Enum.Material.SmoothPlastic)
    buildPart("Tail", Vector3.new(0.6, 0.6, 2), Vector3.new(0, 3.1, 3.4), darker, Enum.Material.SmoothPlastic)
    for _, x in ipairs({ -1, 1 }) do
        for _, z in ipairs({ -1.6, 1.6 }) do
            buildPart("Leg", Vector3.new(0.8, 1.8, 0.8), Vector3.new(x, 0.9, z), darker, Enum.Material.SmoothPlastic)
        end
    end
    for _, x in ipairs({ -0.55, 0.55 }) do
        buildPart("Eye", Vector3.new(0.35, 0.35, 0.2), Vector3.new(x, 3.3, -4.02), Color3.fromRGB(20, 20, 24), Enum.Material.Neon)
    end

    local glowLight = Instance.new("PointLight")
    glowLight.Color = mutationEntry.color or primary
    glowLight.Range = mutationEntry.color and 12 or 6
    glowLight.Brightness = mutationEntry.color and 1.6 or 0.5
    glowLight.Parent = root

    model:PivotTo(CFrame.new(position) * CFrame.Angles(0, facing or 0, 0))
    return model
end

local function petIncome(species, sizeEntry, mutationEntry)
    return math.floor(species.income * sizeEntry.multiplier * mutationEntry.multiplier)
end

local function ensurePodiums(base)
    local needed = base.podsUnlocked
    for index = #base.pods + 1, needed do
        local column = (index - 1) % 5
        local row = math.floor((index - 1) / 5)
        local offset = CFrame.new((column - 2) * 7, 1.4, 4 + row * 7)
        local stand = makePart(
            Vector3.new(0.8, 5.2, 5.2),
            base.cf * offset * CFrame.Angles(0, 0, math.rad(90)),
            Color3.fromRGB(70, 74, 92),
            Workspace,
            Enum.Material.Metal
        )
        stand.Shape = Enum.PartType.Cylinder
        stand.Name = "Podium"
        stand.CanCollide = true

        local ring = makePart(
            Vector3.new(0.28, 5.8, 5.8),
            base.cf * offset * CFrame.new(0, 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
            base.color,
            Workspace,
            Enum.Material.Neon
        )
        ring.Shape = Enum.PartType.Cylinder
        ring.Name = "PodiumRing"
        ring.CanCollide = false
        ring.Transparency = 0.2

        table.insert(base.pods, {
            part = stand,
            ring = ring,
            position = (base.cf * offset).Position + Vector3.new(0, 0.55, 0),
            model = nil,
        })
    end
end

local function findFreePod(base)
    for index = 1, base.podsUnlocked do
        local pod = base.pods[index]
        if pod and not pod.model then
            return pod, index
        end
    end
    return nil, nil
end

local function placePet(player, base, species, sizeEntry, mutationEntry, reward)
    local pod = findFreePod(base)
    if not pod then
        return false
    end

    local facing = math.atan2(base.cf.LookVector.X, base.cf.LookVector.Z) + math.pi
    local model = createPetModel(species, sizeEntry, mutationEntry, pod.position, facing)
    model.Parent = Workspace

    local income = petIncome(species, sizeEntry, mutationEntry)
    local mutationTag = mutationEntry.color and (" [" .. mutationEntry.name .. "]") or ""
    createBillboard(
        model.PrimaryPart,
        UDim2.fromOffset(190, 26),
        2.7 * sizeEntry.scale,
        species.name .. " (" .. sizeEntry.name .. ")" .. mutationTag .. "  $" .. formatNumber(income) .. "/s",
        mutationEntry.color or Color3.fromRGB(255, 255, 255),
        { distance = 15, group = "pet" .. base.index, maxLabels = 3, maxTextSize = 14, stroke = 2 }
    )

    pod.model = model
    base.pets[model] = { income = income, species = species.name }
    addPetStat(player, 1)

    local state = State[player]
    if state then
        table.insert(state.petData, { species = species.name, size = sizeEntry.name, mutation = mutationEntry.name, model = model })
        if reward and not state.index[species.name] then
            state.index[species.name] = true
            addCash(player, 100)
            notify(player, "New species discovered: " .. species.name .. " (+$100)")
        end
    end

    updateHUD(player)
    return true
end

local function createNestEgg(nest)
    if nest.egg and nest.egg.Parent then
        return
    end

    local species = pickSpecies()
    local tierColor = TIER_COLORS[species.tier]

    local egg = Instance.new("Part")
    egg.Name = species.name .. " Egg"
    egg.Shape = Enum.PartType.Ball
    egg.Size = Vector3.new(3.2, 4.3, 3.2)
    egg.CFrame = CFrame.new(nest.spawnPosition)
    egg.Anchored = true
    egg.CanCollide = false
    egg.Material = Enum.Material.SmoothPlastic
    egg.Color = tierColor
    egg.TopSurface = Enum.SurfaceType.Smooth
    egg.BottomSurface = Enum.SurfaceType.Smooth
    egg.Parent = Workspace

    EggInfo[egg] = {
        species = species,
        nest = nest,
        base = nil,
        grace = 0,
        weld = nil,
        prompt = nil,
    }

    local light = Instance.new("PointLight")
    light.Color = tierColor
    light.Range = 14
    light.Brightness = 1.6
    light.Parent = egg

    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    sparkles.Color = ColorSequence.new(tierColor)
    sparkles.Rate = 6
    sparkles.Lifetime = NumberRange.new(0.6, 1.2)
    sparkles.Speed = NumberRange.new(0.5, 1.5)
    sparkles.Size = NumberSequence.new(0.5)
    sparkles.Parent = egg

    createBillboard(egg, UDim2.fromOffset(160, 24), 2.7, species.name .. " Egg (" .. species.tier .. ")", tierColor, {
        distance = 14,
        group = "egg",
        maxLabels = 1,
        maxTextSize = 15,
        stroke = 2,
    })

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Take Egg"
    prompt.ObjectText = species.name .. " Egg"
    prompt.HoldDuration = 0.8
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Parent = egg
    EggInfo[egg].prompt = prompt

    prompt.Triggered:Connect(function(player)
        if EggInfo[egg] and EggInfo[egg].weld then
            return
        end
        if Carrying[player] then
            notify(player, "You are already carrying an egg.")
            return
        end
        pickup(player, egg)
    end)

    nest.egg = egg
end

local function createGuardianModel(nest)
    local model = Instance.new("Model")
    model.Name = "Guardian"

    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(2, 2, 2)
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = nest.homeCFrame
    root.Parent = model
    model.PrimaryPart = root

    local bodyColor = Color3.fromRGB(118, 74, 190)
    local eyeColor = Color3.fromRGB(255, 204, 64)

    local function buildPart(name, size, offset, color, material)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.CFrame = root.CFrame * CFrame.new(offset)
        part.Anchored = false
        part.CanCollide = false
        part.Color = color
        part.Material = material or Enum.Material.SmoothPlastic
        part.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = part
        return part
    end

    buildPart("Body", Vector3.new(5, 3.6, 7), Vector3.new(0, 3.2, 0), bodyColor)
    buildPart("Head", Vector3.new(3.6, 3, 3.2), Vector3.new(0, 3.8, -4.4), bodyColor)
    buildPart("Jaw", Vector3.new(2.6, 1, 2.2), Vector3.new(0, 2.4, -5), Color3.fromRGB(86, 52, 140))
    for _, x in ipairs({ -1.6, 1.6 }) do
        for _, z in ipairs({ -2, 2 }) do
            buildPart("Leg", Vector3.new(1.2, 2.4, 1.2), Vector3.new(x, 1.2, z), Color3.fromRGB(96, 60, 160))
        end
    end
    for _, x in ipairs({ -0.9, 0.9 }) do
        buildPart("Eye", Vector3.new(0.6, 0.6, 0.3), Vector3.new(x, 4.1, -6.02), eyeColor, Enum.Material.Neon)
    end

    model.Parent = Workspace

    return {
        model = model,
        nest = nest,
        homeCFrame = nest.homeCFrame,
        target = nil,
        chaseUntil = 0,
    }
end

local function spawnNestEgg(nest)
    task.delay(0.1, function()
        if nest.egg == nil or not nest.egg.Parent then
            createNestEgg(nest)
        end
    end)
end

local function createNests()
    for index = 1, CONFIG.NEST_COUNT do
        local angle = index * (2 * math.pi / CONFIG.NEST_COUNT)
        local x = math.sin(angle) * CONFIG.NEST_RADIUS
        local z = math.cos(angle) * CONFIG.NEST_RADIUS

        local patch = Instance.new("Part")
        patch.Name = "NestPatch"
        patch.Shape = Enum.PartType.Cylinder
        patch.Size = Vector3.new(0.6, 17, 17)
        patch.CFrame = CFrame.new(x, 0.35, z) * CFrame.Angles(0, 0, math.rad(90))
        patch.Anchored = true
        patch.CanCollide = false
        patch.Color = Color3.fromRGB(226, 196, 118)
        patch.Material = Enum.Material.Sand
        patch.Parent = Workspace

        local bowl = Instance.new("Part")
        bowl.Name = "NestBowl"
        bowl.Shape = Enum.PartType.Cylinder
        bowl.Size = Vector3.new(1.4, 10, 10)
        bowl.CFrame = CFrame.new(x, 1.1, z) * CFrame.Angles(0, 0, math.rad(90))
        bowl.Anchored = true
        bowl.Color = Color3.fromRGB(214, 176, 92)
        bowl.Material = Enum.Material.Grass
        bowl.Parent = Workspace

        local inner = Instance.new("Part")
        inner.Name = "NestInner"
        inner.Shape = Enum.PartType.Cylinder
        inner.Size = Vector3.new(0.5, 7.4, 7.4)
        inner.CFrame = CFrame.new(x, 1.85, z) * CFrame.Angles(0, 0, math.rad(90))
        inner.Anchored = true
        inner.CanCollide = false
        inner.Color = Color3.fromRGB(150, 108, 62)
        inner.Material = Enum.Material.Sand
        inner.Parent = Workspace

        local glow = Instance.new("PointLight")
        glow.Color = Color3.fromRGB(255, 226, 140)
        glow.Range = 20
        glow.Brightness = 1
        glow.Parent = bowl

        local nest = {
            index = index,
            center = Vector3.new(x, 0, z),
            spawnPosition = Vector3.new(x, 4.2, z),
            homeCFrame = CFrame.new(x, 0, z + 12),
            egg = nil,
        }

        local guardian = createGuardianModel(nest)
        nest.guardian = guardian
        table.insert(Guardians, guardian)
        table.insert(Nests, nest)

        createNestEgg(nest)
    end
end

local function createBase(index)
    local angle = (index - 1) * (2 * math.pi / CONFIG.BASE_COUNT)
    local position = Vector3.new(math.sin(angle) * CONFIG.BASE_RADIUS, 0, math.cos(angle) * CONFIG.BASE_RADIUS)
    local cf = CFrame.lookAt(position, Vector3.new(0, 0, 0))
    local baseColor = BASE_COLORS[((index - 1) % #BASE_COLORS) + 1]
    local fence = FENCE_STYLES[((index - 1) % #FENCE_STYLES) + 1]
    local half = 22

    local floor = makePart(Vector3.new(44, 0.3, 44), cf * CFrame.new(0, 0.16, 0), PALETTE.grassDark, Workspace, Enum.Material.Grass)
    floor.Name = "PenFloor"
    floor.CanCollide = false

    for _, height in ipairs({ 1.1, 2.2, 3.3 }) do
        makePart(Vector3.new(44, 0.36, 0.36), cf * CFrame.new(0, height, half), fence.color, Workspace, fence.material).Name = "FenceRail"
        makePart(Vector3.new(17, 0.36, 0.36), cf * CFrame.new(-13.5, height, -half), fence.color, Workspace, fence.material).Name = "FenceRail"
        makePart(Vector3.new(17, 0.36, 0.36), cf * CFrame.new(13.5, height, -half), fence.color, Workspace, fence.material).Name = "FenceRail"
        makePart(Vector3.new(44, 0.36, 0.36), cf * CFrame.new(-half, height, 0) * CFrame.Angles(0, math.pi / 2, 0), fence.color, Workspace, fence.material).Name = "FenceRail"
        makePart(Vector3.new(44, 0.36, 0.36), cf * CFrame.new(half, height, 0) * CFrame.Angles(0, math.pi / 2, 0), fence.color, Workspace, fence.material).Name = "FenceRail"
    end

    for step = 0, 6 do
        local offset = -half + step * (44 / 6)
        makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(offset, 2.2, half), fence.color, Workspace, fence.material).Name = "FencePost"
        makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(-half, 2.2, offset), fence.color, Workspace, fence.material).Name = "FencePost"
        makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(half, 2.2, offset), fence.color, Workspace, fence.material).Name = "FencePost"
        if math.abs(offset) > 6 then
            makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(offset, 2.2, -half), fence.color, Workspace, fence.material).Name = "FencePost"
        end
    end
    makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(-5, 2.2, -half), fence.color, Workspace, fence.material).Name = "GatePost"
    makePart(Vector3.new(0.7, 4.4, 0.7), cf * CFrame.new(5, 2.2, -half), fence.color, Workspace, fence.material).Name = "GatePost"

    local pad = Instance.new("Part")
    pad.Name = "IncubatorPad"
    pad.Shape = Enum.PartType.Ball
    pad.Size = Vector3.new(14, 0.5, 10)
    pad.CFrame = cf * CFrame.new(0, 0.34, -14)
    pad.Anchored = true
    pad.CanCollide = false
    pad.Color = baseColor
    pad.Material = Enum.Material.Neon
    pad.Transparency = 0.15
    pad.Parent = Workspace

    local padLight = Instance.new("PointLight")
    padLight.Color = baseColor
    padLight.Range = 22
    padLight.Brightness = 1.4
    padLight.Parent = pad

    local treadmill = makePart(Vector3.new(6, 1.4, 12), cf * CFrame.new(15, 0.7, -6), Color3.fromRGB(44, 46, 56), Workspace, Enum.Material.Metal)
    treadmill.Name = "Treadmill"
    local belt = makePart(Vector3.new(5, 0.3, 10), cf * CFrame.new(15, 1.52, -6), Color3.fromRGB(92, 214, 255), Workspace, Enum.Material.Neon)
    belt.Name = "Belt"
    belt.Transparency = 0.1

    local treadmillPrompt = Instance.new("ProximityPrompt")
    treadmillPrompt.ActionText = "Train Speed"
    treadmillPrompt.ObjectText = "Treadmill"
    treadmillPrompt.HoldDuration = 1.5
    treadmillPrompt.MaxActivationDistance = 10
    treadmillPrompt.RequiresLineOfSight = false
    treadmillPrompt.Parent = treadmill

    createBillboard(treadmill, UDim2.fromOffset(150, 30), 3.2, "TRAIN SPEED", Color3.fromRGB(120, 220, 255), {
        distance = 13,
        group = "pen" .. index,
        maxLabels = 1,
        maxTextSize = 18,
        uppercase = true,
    })

    local upgradePost = makePart(Vector3.new(0.9, 7, 0.9), cf * CFrame.new(-15, 3.5, -6), PALETTE.wood, Workspace, Enum.Material.WoodPlanks)
    upgradePost.Name = "UpgradePost"
    local upgradeBoard = makePart(Vector3.new(9, 4, 0.6), cf * CFrame.new(-15, 7.4, -6), PALETTE.wood, Workspace, Enum.Material.WoodPlanks)
    upgradeBoard.Name = "UpgradeBoard"
    createBillboard(upgradeBoard, UDim2.fromOffset(170, 40), 0.4, "UPGRADE PEN", Color3.fromRGB(255, 226, 130), {
        distance = 13,
        group = "pen" .. index,
        maxLabels = 1,
        maxTextSize = 18,
        uppercase = true,
    })

    local upgradePrompt = Instance.new("ProximityPrompt")
    upgradePrompt.ActionText = "Upgrade ($" .. CONFIG.UPGRADE_COST .. ")"
    upgradePrompt.ObjectText = "Pen podiums"
    upgradePrompt.HoldDuration = 0.5
    upgradePrompt.MaxActivationDistance = 10
    upgradePrompt.RequiresLineOfSight = false
    upgradePrompt.Parent = upgradePost

    local signBoard = makePart(Vector3.new(16, 3.4, 0.6), cf * CFrame.new(0, 7.6, -half), PALETTE.wood, Workspace, Enum.Material.WoodPlanks)
    signBoard.Name = "PenSign"
    local signLabel = createBillboard(signBoard, UDim2.fromOffset(190, 48), 0.4, "Open Pen", PALETTE.white, {
        distance = 24,
        group = "pen" .. index,
        maxLabels = 1,
        maxTextSize = 20,
        uppercase = true,
    })

    local base = {
        index = index,
        cf = cf,
        color = baseColor,
        pad = pad,
        pods = {},
        podsUnlocked = CONFIG.PODS_BASE,
        upgrades = 0,
        eggs = {},
        pets = {},
        petCount = 0,
        owner = nil,
        label = signLabel,
        incubatorEgg = nil,
        incubatorPosition = (cf * CFrame.new(0, 2.4, -14)).Position,
    }

    ensurePodiums(base)

    pad.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = character and playerFromCharacter(character)
        if not player or base.owner ~= player then
            return
        end

        local egg = Carrying[player]
        if egg then
            depositEgg(player, egg, base)
        end
    end)

    treadmillPrompt.Triggered:Connect(function(player)
        if base.owner ~= player then
            notify(player, "That treadmill belongs to another player.")
            return
        end

        local state = State[player]
        if not state then
            return
        end
        if os.clock() < state.trainCooldown then
            return
        end
        if state.speed >= CONFIG.TRAIN_CAP then
            notify(player, "Speed is maxed out.")
            return
        end

        state.trainCooldown = os.clock() + 1.5
        setSpeed(player, state.speed + CONFIG.TRAIN_STEP)
        notify(player, "Speed trained to " .. string.format("%.1f", state.speed) .. "!")
    end)

    upgradePrompt.Triggered:Connect(function(player)
        if base.owner ~= player then
            notify(player, "Only the base owner can upgrade this base.")
            return
        end
        if base.podsUnlocked >= CONFIG.PODS_MAX then
            notify(player, "Your base is fully upgraded.")
            return
        end

        local stats = player:FindFirstChild("leaderstats")
        local cash = stats and stats:FindFirstChild("Cash")
        local cost = CONFIG.UPGRADE_COST * (2 ^ base.upgrades)
        if not cash or cash.Value < cost then
            notify(player, "Need $" .. cost .. " to unlock more podiums.")
            return
        end

        cash.Value -= cost
        base.upgrades += 1
        base.podsUnlocked = math.min(CONFIG.PODS_MAX, base.podsUnlocked + CONFIG.PODS_PER_UPGRADE)
        ensurePodiums(base)
        upgradePrompt.ActionText = base.podsUnlocked >= CONFIG.PODS_MAX
            and "Max Podiums"
            or ("Upgrade ($" .. (CONFIG.UPGRADE_COST * (2 ^ base.upgrades)) .. ")")
        updateHUD(player)
        notify(player, "Base upgraded: " .. base.podsUnlocked .. " podiums!")
    end)

    table.insert(Bases, base)
end

local function createTree(position, scale)
    scale = scale or 1
    local trunk = makePart(Vector3.new(2.4, 9, 2.4) * scale, CFrame.new(position + Vector3.new(0, 4.5 * scale, 0)), PALETTE.trunk, Workspace, Enum.Material.WoodPlanks)
    trunk.Name = "TreeTrunk"

    local layers = {
        { Vector3.new(11, 4.2, 11), 9.6, PALETTE.leaf },
        { Vector3.new(8.2, 4.2, 8.2), 12.6, PALETTE.leaf },
        { Vector3.new(5.4, 4.2, 5.4), 15.6, PALETTE.leafLight },
    }
    for _, layer in ipairs(layers) do
        makePart(layer[1] * scale, CFrame.new(position + Vector3.new(0, layer[2] * scale, 0)), layer[3], Workspace, Enum.Material.Grass).Name = "TreeLeaves"
    end
end

local function cliffHeight(seed, t)
    return 18 + math.noise(t * 0.02, seed, 0.37) * 18 + math.noise(t * 0.09, seed * 2, 0.71) * 4
end

local function buildCanyon()
    local span = 470
    local step = 20
    local distance = 470

    local function buildSide(axis, sign, seed)
        local segment = 0
        for t = -span, span - step, step do
            local height = cliffHeight(seed, t)
            local x, z
            if axis == "x" then
                x = t + step / 2
                z = sign * distance
            else
                x = sign * distance
                z = t + step / 2
            end

            local wallSize = axis == "x" and Vector3.new(step + 1, height, 30) or Vector3.new(30, height, step + 1)
            makePart(wallSize, CFrame.new(x, height / 2 - 1, z), PALETTE.dirt, Workspace, Enum.Material.Brick).Name = "CanyonWall"

            local capSize = axis == "x" and Vector3.new(step + 2, 3.2, 31) or Vector3.new(31, 3.2, step + 2)
            makePart(capSize, CFrame.new(x, height + 0.6, z), PALETTE.leaf, Workspace, Enum.Material.Grass).Name = "CanyonGrass"

            segment += 1
            if segment % 4 == 2 then
                local treePosition = Vector3.new(x, height + 2.2, z)
                if axis == "x" then
                    treePosition += Vector3.new(0, 0, math.random(-3, 3))
                else
                    treePosition += Vector3.new(math.random(-3, 3), 0, 0)
                end
                createTree(treePosition, 0.85 + math.random() * 0.4)
            end
        end
    end

    buildSide("x", -1, 1.7)
    buildSide("x", 1, 4.2)
    buildSide("z", -1, 8.9)
    buildSide("z", 1, 13.4)
end

local function buildTerraces()
    local span = 450
    local step = 20
    for t = -span, span - step, step do
        for _, sign in ipairs({ -1, 1 }) do
            local height = 6 + math.noise(t * 0.03, sign * 2.7, 1.1) * 4
            makePart(Vector3.new(21, height, 18), CFrame.new(t + step / 2, height / 2 - 1, sign * 428), PALETTE.dirtDark, Workspace, Enum.Material.Brick).Name = "Terrace"
            makePart(Vector3.new(21.6, 2.4, 18.6), CFrame.new(t + step / 2, height + 0.3, sign * 428), PALETTE.leafLight, Workspace, Enum.Material.Grass).Name = "TerraceGrass"
            makePart(Vector3.new(18, height, 21), CFrame.new(sign * 428, height / 2 - 1, t + step / 2), PALETTE.dirtDark, Workspace, Enum.Material.Brick).Name = "Terrace"
            makePart(Vector3.new(18.6, 2.4, 21.6), CFrame.new(sign * 428, height + 0.3, t + step / 2), PALETTE.leafLight, Workspace, Enum.Material.Grass).Name = "TerraceGrass"
        end
    end
end

local function buildSky()
    Lighting.ClockTime = 0
    Lighting.Brightness = 2.4
    Lighting.Ambient = Color3.fromRGB(92, 84, 120)
    Lighting.OutdoorAmbient = Color3.fromRGB(126, 112, 162)
    Lighting.EnvironmentDiffuseScale = 0.6
    Lighting.EnvironmentSpecularScale = 0.4
    Lighting.FogStart = 600
    Lighting.FogEnd = 1400
    Lighting.FogColor = Color3.fromRGB(52, 38, 78)

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.32
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(150, 120, 200)
    atmosphere.Decay = Color3.fromRGB(80, 60, 120)
    atmosphere.Glare = 0.2
    atmosphere.Haze = 2.2
    atmosphere.Parent = Lighting

    for index = 1, 5 do
        local angle = index * (2 * math.pi / 5)
        local cloud = makePart(
            Vector3.new(560, 150, 400),
            CFrame.new(math.sin(angle) * 660, 320 + index * 18, math.cos(angle) * 660) * CFrame.Angles(0, angle, math.rad(10)),
            index % 2 == 0 and Color3.fromRGB(96, 52, 190) or Color3.fromRGB(168, 68, 214),
            Workspace,
            Enum.Material.Neon
        )
        cloud.Shape = Enum.PartType.Ball
        cloud.Transparency = 0.85
        cloud.CanCollide = false
        cloud.CastShadow = false
        cloud.Name = "Nebula"
    end
end

local function createDottedRing(radius, count, color)
    for index = 1, count do
        local angle = index * (2 * math.pi / count)
        makePart(Vector3.new(1.6, 0.18, 1.6), CFrame.new(math.sin(angle) * radius, 0.12, math.cos(angle) * radius), color, Workspace, Enum.Material.Neon).Name = "ZoneDot"
    end
end

local function createStall(position, title, awningColor)
    local cf = CFrame.lookAt(Vector3.new(position.X, 0, position.Z), Vector3.new(0, 0, 0))

    makePart(Vector3.new(16, 4, 7), cf * CFrame.new(0, 2, 0), PALETTE.wood, Workspace, Enum.Material.WoodPlanks).Name = "StallCounter"

    for _, corner in ipairs({ Vector3.new(-6.5, 9.4, -2.6), Vector3.new(6.5, 9.4, -2.6), Vector3.new(-6.5, 9.4, 2.6), Vector3.new(6.5, 9.4, 2.6) }) do
        makePart(Vector3.new(0.7, 9.4, 0.7), cf * CFrame.new(corner), PALETTE.trunk, Workspace, Enum.Material.WoodPlanks).Name = "StallPost"
    end

    for index = 0, 4 do
        local stripeColor = index % 2 == 0 and awningColor or PALETTE.white
        makePart(Vector3.new(3.4, 0.5, 8.6), cf * CFrame.new(-6.8 + index * 3.4, 10.8, 0) * CFrame.Angles(math.rad(-14), 0, 0), stripeColor, Workspace, Enum.Material.SmoothPlastic).Name = "Awning"
    end

    local board = makePart(Vector3.new(13, 3.2, 0.5), cf * CFrame.new(0, 13.2, 0), PALETTE.white, Workspace, Enum.Material.SmoothPlastic)
    board.Name = "ShopSign"
    createBillboard(board, UDim2.fromOffset(230, 56), 0, title, awningColor, {
        distance = 42,
        group = "shop",
        maxLabels = 1,
        maxTextSize = 24,
        uppercase = true,
    })
end

local function buildSafeZone()
    local spawnPad = makePart(
        Vector3.new(1.4, 34, 34),
        CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color3.fromRGB(226, 226, 236),
        Workspace,
        Enum.Material.SmoothPlastic
    )
    spawnPad.Shape = Enum.PartType.Cylinder
    spawnPad.Name = "SpawnPad"

    local spawnLocation = Instance.new("SpawnLocation")
    spawnLocation.Name = "SpawnLocation"
    spawnLocation.Size = Vector3.new(12, 0.6, 12)
    spawnLocation.CFrame = CFrame.new(0, 1.7, 0)
    spawnLocation.Anchored = true
    spawnLocation.Neutral = true
    spawnLocation.Color = Color3.fromRGB(120, 200, 255)
    spawnLocation.Material = Enum.Material.Neon
    spawnLocation.Transparency = 0.1
    spawnLocation.Parent = Workspace

    local safePart = makePart(Vector3.new(170, 0.2, 44), CFrame.new(0, 0.15, 74), PALETTE.white, Workspace, Enum.Material.SmoothPlastic)
    safePart.Name = "SafeZoneText"
    safePart.Transparency = 1
    safePart.CanCollide = false

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Top
    surface.CanvasSize = Vector2.new(1700, 440)
    surface.LightInfluence = 0
    surface.Parent = safePart

    local safeLabel = Instance.new("TextLabel")
    safeLabel.BackgroundTransparency = 1
    safeLabel.Size = UDim2.fromScale(1, 1)
    safeLabel.Font = Enum.Font.LuckiestGuy
    safeLabel.TextScaled = true
    safeLabel.Text = "SAFE ZONE"
    safeLabel.TextColor3 = PALETTE.white
    safeLabel.TextStrokeTransparency = 1
    safeLabel.TextStrokeColor3 = Color3.fromRGB(36, 30, 46)
    safeLabel.Parent = surface

    local safeLimit = Instance.new("UITextSizeConstraint")
    safeLimit.MinTextSize = 80
    safeLimit.MaxTextSize = 260
    safeLimit.Parent = safeLabel

    local safeStroke = Instance.new("UIStroke")
    safeStroke.Thickness = 10
    safeStroke.Color = Color3.fromRGB(24, 20, 30)
    safeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    safeStroke.Parent = safeLabel

    for _, offset in ipairs({ -60, 60 }) do
        local drop = makePart(Vector3.new(5, 1.6, 7), CFrame.new(offset, 0.8, 66), Color3.fromRGB(74, 172, 255), Workspace, Enum.Material.Neon)
        drop.Shape = Enum.PartType.Ball
        drop.Transparency = 0.2
        drop.CanCollide = false
        drop.Name = "ZoneMarker"
    end

    createDottedRing(150, 84, Color3.fromRGB(255, 44, 44))
end

local function buildWorld()
    buildSky()

    local ground = makePart(Vector3.new(1000, 4, 1000), CFrame.new(0, -2, 0), PALETTE.grass, Workspace, Enum.Material.Grass)
    ground.Name = "Ground"

    buildCanyon()
    buildTerraces()
    buildSafeZone()

    createStall(Vector3.new(-95, 0, 158), "TRAILS SHOP", Color3.fromRGB(54, 206, 190))
    createStall(Vector3.new(0, 0, 164), "BIKE SHOP", Color3.fromRGB(64, 122, 255))
    createStall(Vector3.new(95, 0, 158), "SELL", Color3.fromRGB(255, 116, 190))

    createNests()
    for index = 1, CONFIG.BASE_COUNT do
        createBase(index)
    end
end

function pickup(player, egg)
    local info = EggInfo[egg]
    if not info or info.weld or info.base then
        return
    end
    if Carrying[player] then
        notify(player, "You are already carrying an egg.")
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid or humanoid.Health <= 0 then
        return
    end

    if info.prompt then
        info.prompt:Destroy()
        info.prompt = nil
    end

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = egg
    egg.Anchored = false
    egg.CanCollide = false
    egg.CFrame = root.CFrame * CFrame.new(0, 3.4, 0)
    weld.Parent = egg

    info.weld = weld
    Carrying[player] = egg

    local nest = info.nest
    if nest then
        info.nest = nil
        nest.egg = nil
        if nest.guardian then
            nest.guardian.target = player
            nest.guardian.chaseUntil = os.clock() + 7
            notify(player, "The guardian is chasing you - run!")
        end
        task.delay(CONFIG.NEST_EGG_RESPAWN, function()
            spawnNestEgg(nest)
        end)
    end

    notify(player, "Carrying " .. egg.Name .. " - take it to your base!")
end

function depositEgg(player, egg, base)
    local info = EggInfo[egg]
    if not info or not info.weld or Carrying[player] ~= egg then
        return
    end
    if base.incubatorEgg then
        notify(player, "Your incubator is busy - wait for the current egg.")
        return
    end
    if base.petCount >= base.podsUnlocked then
        notify(player, "All podiums are full - upgrade your base first.")
        return
    end

    info.weld:Destroy()
    info.weld = nil
    Carrying[player] = nil

    info.base = base
    info.grace = os.clock() + CONFIG.STEAL_GRACE_SECONDS
    base.incubatorEgg = egg

    egg.Anchored = true
    egg.CanCollide = false
    egg.CFrame = CFrame.new(base.incubatorPosition)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Steal"
    prompt.ObjectText = egg.Name
    prompt.HoldDuration = 1
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = egg
    info.prompt = prompt

    prompt.Triggered:Connect(function(thief)
        local current = EggInfo[egg]
        if not current or current.base ~= base then
            return
        end
        if base.owner == thief then
            notify(thief, "That egg is already yours.")
            return
        end
        if Carrying[thief] then
            notify(thief, "You are already carrying an egg.")
            return
        end
        if os.clock() < current.grace then
            notify(thief, "Protected for " .. math.ceil(current.grace - os.clock()) .. " more seconds.")
            return
        end

        base.incubatorEgg = nil
        current.base = nil
        current.prompt = nil
        prompt:Destroy()
        notify(thief, "Stole " .. egg.Name .. "!")
        pickup(thief, egg)
    end)

    notify(player, "Incubating " .. egg.Name .. "...")

    task.delay(CONFIG.HATCH_SECONDS, function()
        local current = EggInfo[egg]
        if not current or current.base ~= base or base.incubatorEgg ~= egg then
            return
        end

        local sizeEntry = weightedPick(SIZES, "weight")
        local mutationEntry = weightedPick(MUTATIONS, "weight")
        if not placePet(player, base, current.species, sizeEntry, mutationEntry, true) then
            notify(player, "No free podium - the egg stays in the incubator.")
            return
        end

        base.incubatorEgg = nil
        EggInfo[egg] = nil
        local hatchPosition = egg.Position
        egg:Destroy()

        local state = State[player]
        if not (state and state.settings and state.settings.effects == false) then
            burst(hatchPosition, TIER_COLORS[current.species.tier])
        end

        local mutationTag = mutationEntry.color and (" " .. mutationEntry.name) or ""
        notify(player, "Hatched " .. sizeEntry.name .. " " .. current.species.name .. mutationTag .. "!")
    end)
end

local function dropCarried(player, egg)
    local info = EggInfo[egg]
    if not info then
        return
    end

    if info.weld then
        info.weld:Destroy()
        info.weld = nil
    end
    Carrying[player] = nil

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local position = root and (root.Position + Vector3.new(0, 2, 0)) or Vector3.new(0, 3, 0)

    egg.Anchored = true
    egg.CanCollide = false
    egg.CFrame = CFrame.new(position)

    info.base = nil
    info.grace = 0

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Take Egg"
    prompt.ObjectText = egg.Name
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9
    prompt.RequiresLineOfSight = false
    prompt.Parent = egg
    info.prompt = prompt

    prompt.Triggered:Connect(function(player)
        if EggInfo[egg] and EggInfo[egg].weld then
            return
        end
        pickup(player, egg)
    end)
end

local function guardianCatch(guardian)
    local target = guardian.target
    guardian.target = nil
    guardian.chaseUntil = 0

    if target and target.Parent then
        local egg = Carrying[target]
        if egg then
            local info = EggInfo[egg]
            if info then
                if info.weld then
                    info.weld:Destroy()
                end
                Carrying[target] = nil
                EggInfo[egg] = nil
                egg:Destroy()
                notify(target, "The guardian took the egg back!")
                local nest = guardian.nest
                if nest.egg == nil or not nest.egg.Parent then
                    nest.egg = nil
                    spawnNestEgg(nest)
                end
                return
            end
        end
        notify(target, "The guardian caught you!")
    end
end

local function assignBase(player)
    for _, base in ipairs(Bases) do
        if base.owner == nil then
            base.owner = player
            base.label.Text = string.upper(player.DisplayName .. "'s Pen")
            base.label.TextColor3 = base.color
            ensurePodiums(base)
            return base
        end
    end
    return nil
end

local function releaseBase(player)
    for _, base in ipairs(Bases) do
        if base.owner == player then
            if base.incubatorEgg then
                EggInfo[base.incubatorEgg] = nil
                base.incubatorEgg:Destroy()
                base.incubatorEgg = nil
            end
            for model in pairs(base.pets) do
                model:Destroy()
            end
            for _, pod in ipairs(base.pods) do
                pod.part:Destroy()
                if pod.ring then
                    pod.ring:Destroy()
                end
                pod.model = nil
            end
            base.pets = {}
            base.pods = {}
            base.petCount = 0
            base.owner = nil
            base.upgrades = 0
            base.podsUnlocked = CONFIG.PODS_BASE
            base.label.Text = "OPEN PEN"
            base.label.TextColor3 = PALETTE.white
            return
        end
    end
end

local function createBike(character, root, color, wheelSize, neon)
    local model = Instance.new("Model")
    model.Name = "Bike"
    local wheel = wheelSize or 3.2

    local function part(name, size, offset, partColor, shape)
        local piece = Instance.new("Part")
        piece.Name = name
        piece.Anchored = false
        piece.CanCollide = false
        piece.Massless = true
        piece.Size = size
        piece.CFrame = root.CFrame * offset
        piece.Color = partColor
        piece.Material = neon and Enum.Material.Neon or Enum.Material.Metal
        if shape then
            piece.Shape = shape
        end
        piece.Parent = model

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = piece
        weld.Parent = piece
        return piece
    end

    part("BackWheel", Vector3.new(0.7, wheel, wheel), CFrame.new(0, -1.6, 2.7), Color3.fromRGB(28, 28, 32), Enum.PartType.Cylinder)
    part("FrontWheel", Vector3.new(0.7, wheel, wheel), CFrame.new(0, -1.6, -2.7), Color3.fromRGB(28, 28, 32), Enum.PartType.Cylinder)
    part("Frame", Vector3.new(0.4, 0.4, 4.8), CFrame.new(0, -0.9, 0), color or Color3.fromRGB(206, 74, 66))
    part("Seat", Vector3.new(1, 0.4, 1.2), CFrame.new(0, -0.3, 1.2), Color3.fromRGB(25, 25, 28))
    part("Handlebar", Vector3.new(2.4, 0.3, 0.3), CFrame.new(0, -0.2, -2.4), Color3.fromRGB(40, 40, 46))

    model.Parent = character
end

local function createNameTag(player, character)
    local head = character:WaitForChild("Head", 5)
    if not head then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerTag"
    billboard.Size = UDim2.fromOffset(170, 74)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 220
    billboard.Parent = head

    local portrait = Instance.new("ImageLabel")
    portrait.AnchorPoint = Vector2.new(0.5, 0)
    portrait.Position = UDim2.new(0.5, 0, 0, 0)
    portrait.Size = UDim2.fromOffset(46, 46)
    portrait.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    portrait.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
    portrait.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = portrait

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = Color3.fromRGB(28, 24, 36)
    stroke.Parent = portrait

    local name = Instance.new("TextLabel")
    name.AnchorPoint = Vector2.new(0.5, 0)
    name.Position = UDim2.new(0.5, 0, 0, 48)
    name.Size = UDim2.new(1, 0, 0, 22)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.FredokaOne
    name.TextSize = 18
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextStrokeTransparency = 1
    name.TextStrokeColor3 = Color3.fromRGB(20, 18, 26)
    name.Text = player.DisplayName
    name.Parent = billboard

    local nameStroke = Instance.new("UIStroke")
    nameStroke.Thickness = 2.5
    nameStroke.Color = Color3.fromRGB(20, 18, 26)
    nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    nameStroke.Parent = name
end

local function applyTrail(player)
    local state = State[player]
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not state or not root then
        return
    end

    local existing = root:FindFirstChild("TrailFx")
    if existing then
        existing:Destroy()
    end

    local trail = TRAILS[state.equippedTrail or 1] or TRAILS[1]
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "TrailFx"
    emitter.Color = ColorSequence.new(trail.color)
    emitter.Size = NumberSequence.new(1.6)
    emitter.Lifetime = NumberRange.new(0.4, 0.75)
    emitter.Rate = 26
    emitter.Speed = NumberRange.new(0, 1.5)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LightEmission = 0.6
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Enabled = not (state.settings and state.settings.effects == false)
    emitter.Parent = root
end

local function setupCharacter(player, character)
    local root = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local state = State[player]
    local base = state and state.base
    if base then
        root.CFrame = base.cf * CFrame.new(0, 4, -14)
    end

    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    local bike = BIKES[state and state.equippedBike or 1] or BIKES[1]
    createBike(character, root, bike.color, bike.wheelSize, bike.neon)
    createNameTag(player, character)
    applyTrail(player)
    humanoid.WalkSpeed = math.min(100, (state and state.speed or CONFIG.START_SPEED) * bikeMultiplier(state))

    humanoid.Died:Connect(function()
        local egg = Carrying[player]
        if egg then
            dropCarried(player, egg)
        end
    end)
end

local cashStore = nil
do
    local ok = pcall(function()
        cashStore = DataStoreService:GetDataStore("BikeForEggSave_v1")
    end)
    if not ok then
        cashStore = nil
        warn("[BikeForEgg] DataStore unavailable; progress will not persist.")
    end
end

local function serializePlayer(player)
    local state = State[player]
    local stats = player:FindFirstChild("leaderstats")
    if not state or not stats then
        return nil
    end

    local cash = stats:FindFirstChild("Cash")
    local pets = {}
    for _, pet in ipairs(state.petData) do
        table.insert(pets, { species = pet.species, size = pet.size, mutation = pet.mutation })
    end

    local index = {}
    for name in pairs(state.index) do
        index[name] = true
    end

    local bikes = {}
    for bikeIndex in pairs(state.bikes) do
        table.insert(bikes, bikeIndex)
    end
    local trails = {}
    for trailIndex in pairs(state.trails) do
        table.insert(trails, trailIndex)
    end
    local codes = {}
    for code in pairs(state.codes) do
        table.insert(codes, code)
    end

    return {
        cash = cash and cash.Value or 0,
        speed = state.speed,
        podsUnlocked = state.base and state.base.podsUnlocked or CONFIG.PODS_BASE,
        upgrades = state.base and state.base.upgrades or 0,
        index = index,
        pets = pets,
        bikes = bikes,
        trails = trails,
        equippedBike = state.equippedBike,
        equippedTrail = state.equippedTrail,
        rebirths = state.rebirths,
        daily = { day = state.daily.day, last = state.daily.last },
        codes = codes,
        settings = { effects = state.settings.effects, notifications = state.settings.notifications },
    }
end

local function savePlayer(player)
    if not cashStore or not State[player] or not State[player].loaded then
        return
    end

    local data = serializePlayer(player)
    if not data then
        return
    end

    for attempt = 1, 3 do
        local ok, err = pcall(function()
            cashStore:SetAsync("u_" .. player.UserId, data)
        end)
        if ok then
            return
        end
        warn("[BikeForEgg] Save attempt " .. attempt .. " failed: " .. tostring(err))
        task.wait(attempt)
    end
end

local function applySave(player, data)
    local state = State[player]
    if not state or type(data) ~= "table" then
        return
    end
    local base = state.base

    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local cash = stats:FindFirstChild("Cash")
        if cash and type(data.cash) == "number" then
            cash.Value = math.max(0, math.floor(data.cash))
        end
    end

    if type(data.index) == "table" then
        for name in pairs(data.index) do
            if type(name) == "string" then
                state.index[name] = true
            end
        end
    end

    if type(data.speed) == "number" then
        setSpeed(player, data.speed)
    end

    if type(data.bikes) == "table" then
        for _, bikeIndex in ipairs(data.bikes) do
            if BIKES[bikeIndex] then
                state.bikes[bikeIndex] = true
            end
        end
    end
    if type(data.trails) == "table" then
        for _, trailIndex in ipairs(data.trails) do
            if TRAILS[trailIndex] then
                state.trails[trailIndex] = true
            end
        end
    end
    if type(data.equippedBike) == "number" and state.bikes[data.equippedBike] then
        state.equippedBike = data.equippedBike
    end
    if type(data.equippedTrail) == "number" and state.trails[data.equippedTrail] then
        state.equippedTrail = data.equippedTrail
    end
    if type(data.rebirths) == "number" then
        state.rebirths = math.max(0, math.floor(data.rebirths))
    end
    if type(data.daily) == "table" then
        state.daily.day = math.clamp(tonumber(data.daily.day) or 1, 1, #DAILY_REWARDS)
        state.daily.last = tonumber(data.daily.last) or 0
    end
    if type(data.codes) == "table" then
        for _, code in ipairs(data.codes) do
            if type(code) == "string" then
                state.codes[code] = true
            end
        end
    end
    if type(data.settings) == "table" then
        if type(data.settings.effects) == "boolean" then
            state.settings.effects = data.settings.effects
        end
        if type(data.settings.notifications) == "boolean" then
            state.settings.notifications = data.settings.notifications
        end
    end

    if base and type(data.podsUnlocked) == "number" then
        base.podsUnlocked = math.clamp(data.podsUnlocked, CONFIG.PODS_BASE, CONFIG.PODS_MAX)
        base.upgrades = type(data.upgrades) == "number" and data.upgrades or 0
        ensurePodiums(base)
    end

    if base and type(data.pets) == "table" then
        for _, saved in ipairs(data.pets) do
            local species = findSpecies(saved.species)
            local sizeEntry = findEntryByName(SIZES, saved.size)
            local mutationEntry = findEntryByName(MUTATIONS, saved.mutation)
            if species and sizeEntry and mutationEntry then
                if not placePet(player, base, species, sizeEntry, mutationEntry, false) then
                    break
                end
            end
        end
    end

    state.loaded = true
    if applyEquipment then
        applyEquipment(player)
    end
    updateHUD(player)
end

local function loadPlayer(player)
    local state = State[player]
    if not cashStore or not state then
        if state then
            state.loaded = true
        end
        return
    end

    local ok = false
    local data = nil
    for attempt = 1, 3 do
        local success, result = pcall(function()
            return cashStore:GetAsync("u_" .. player.UserId)
        end)
        if success then
            ok = true
            data = result
            break
        end
        warn("[BikeForEgg] Load attempt " .. attempt .. " failed: " .. tostring(result))
        task.wait(attempt)
    end

    if player.Parent == nil then
        return
    end

    if ok and type(data) == "table" then
        applySave(player, data)
    elseif ok then
        state.loaded = true
    else
        warn("[BikeForEgg] Could not load " .. player.Name .. "; saving disabled this session to protect their data.")
    end
end

-- ============================================================
-- INTERFACE PANELS
-- ============================================================

local CARD_BG = Color3.fromRGB(44, 38, 62)
local PANEL_TEXT = Color3.fromRGB(236, 232, 246)
local ACCENT = Color3.fromRGB(98, 238, 64)

local function uiRound(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
end

local function uiStroke(instance, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness
    stroke.Color = PALETTE.ink
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
end

local function uiTextOutline(instance, textSize)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = math.clamp((textSize or 18) * 0.08, 1.2, 4)
    stroke.Color = PALETTE.ink
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Parent = instance
    return stroke
end

local function packArt(parent, image, size, position, tint)
    local art = Instance.new("ImageLabel")
    art.BackgroundTransparency = 1
    art.Image = image
    art.ScaleType = Enum.ScaleType.Fit
    art.Size = UDim2.fromOffset(size, size)
    art.Position = position
    if tint then
        art.ImageColor3 = tint
    end
    art.Parent = parent
    return art
end

local function cardRow(parent, height)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, -26, 0, height or 226)
    holder.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = holder
    return holder
end

local function itemCard(holder, order, tint, title, subtitle, label, action, accent, badgeImage)
    local card = Instance.new("Frame")
    card.BackgroundTransparency = 1
    card.Size = UDim2.fromOffset(150, 222)
    card.LayoutOrder = order
    card.Parent = holder

    local art = Instance.new("ImageLabel")
    art.BackgroundTransparency = 1
    art.Image = UI.frame
    art.ImageColor3 = tint
    art.Size = UDim2.fromOffset(150, 150)
    art.Parent = card
    local ratio = Instance.new("UIAspectRatioConstraint")
    ratio.AspectRatio = 1
    ratio.Parent = art

    if badgeImage then
        local badge = Instance.new("ImageLabel")
        badge.AnchorPoint = Vector2.new(0.5, 0.5)
        badge.Position = UDim2.fromScale(0.5, 0.5)
        badge.Size = UDim2.fromOffset(64, 64)
        badge.BackgroundTransparency = 1
        badge.Image = badgeImage
        badge.ScaleType = Enum.ScaleType.Fit
        badge.Parent = art
    end

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Position = UDim2.fromOffset(0, 154)
    name.Size = UDim2.fromOffset(150, 22)
    name.Font = Enum.Font.FredokaOne
    name.TextSize = 17
    name.TextColor3 = PANEL_TEXT
    name.TextStrokeColor3 = PALETTE.ink
    name.TextStrokeTransparency = 1
    name.Text = title
    name.Parent = card
    uiTextOutline(name, 17)

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Position = UDim2.fromOffset(0, 176)
    info.Size = UDim2.fromOffset(150, 18)
    info.Font = Enum.Font.FredokaOne
    info.TextSize = 13
    info.TextColor3 = Color3.fromRGB(190, 184, 210)
    info.Text = subtitle
    info.Parent = card
    uiTextOutline(info, 13)

    local control
    if action then
        control = Instance.new("TextButton")
        control.BackgroundColor3 = accent or Color3.fromRGB(74, 196, 62)
        control.BorderSizePixel = 0
        control.AutoButtonColor = true
        control.Font = Enum.Font.FredokaOne
        control.TextSize = 15
        control.TextColor3 = PALETTE.white
        control.TextStrokeColor3 = PALETTE.ink
        control.TextStrokeTransparency = 1
        control.Text = label
        control.Position = UDim2.fromOffset(0, 192)
        control.Size = UDim2.fromOffset(150, 30)
        control.Parent = card
        control:SetAttribute("Action", action)
        uiTextOutline(control, 15)
        uiRound(control, 9)
        uiStroke(control, 2)
    else
        control = Instance.new("TextLabel")
        control.BackgroundColor3 = Color3.fromRGB(52, 46, 68)
        control.BorderSizePixel = 0
        control.Font = Enum.Font.FredokaOne
        control.TextSize = 15
        control.TextColor3 = accent or Color3.fromRGB(150, 146, 164)
        control.Text = label
        control.Position = UDim2.fromOffset(0, 192)
        control.Size = UDim2.fromOffset(150, 30)
        control.Parent = card
        uiTextOutline(control, 15)
        uiRound(control, 9)
    end
    return card
end

local function uiSection(body, text, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -26, 0, 38)
    label.Font = Enum.Font.LuckiestGuy
    label.TextSize = 24
    label.TextColor3 = color or Color3.fromRGB(255, 228, 96)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextStrokeColor3 = PALETTE.ink
    label.TextStrokeTransparency = 1
    label.Text = text
    label.Parent = body
    uiTextOutline(label, 24)
    return label
end

local function uiRow(body, height)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = CARD_BG
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, -26, 0, height or 58)
    row.Parent = body
    uiRound(row, 12)
    uiStroke(row, 2)
    return row
end

local function rowText(row, text, x, width, textSize, color, align)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(x, 0)
    label.Size = UDim2.new(0, width, 1, 0)
    label.Font = Enum.Font.FredokaOne
    label.TextSize = textSize or 20
    label.TextColor3 = color or PANEL_TEXT
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.TextStrokeColor3 = PALETTE.ink
    label.TextStrokeTransparency = 1
    label.Text = text
    label.Parent = row
    uiTextOutline(label, textSize or 20)
    return label
end

local function rowRight(row, text, width, textSize, color)
    local label = rowText(row, text, 0, width, textSize, color, Enum.TextXAlignment.Right)
    label.Position = UDim2.new(1, -width - 14, 0, 0)
    return label
end

local function rowButton(row, text, action, color, icon)
    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 0.5, 0)
    button.Size = UDim2.fromOffset(150, 38)
    button.BackgroundColor3 = color or Color3.fromRGB(74, 196, 62)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.FredokaOne
    button.TextSize = 19
    button.TextColor3 = PALETTE.white
    button.TextStrokeColor3 = PALETTE.ink
    button.TextStrokeTransparency = 1
    button.Text = text
    button.Parent = row
    uiTextOutline(button, 19)
    button:SetAttribute("Action", action)
    if icon then
        packArt(button, icon, 22, UDim2.fromOffset(8, 8))
        button.TextXAlignment = Enum.TextXAlignment.Center
    end
    uiRound(button, 10)
    uiStroke(button, 2)
    return button
end

local PANEL_ICONS = {
    shop = UI.shop,
    index = UI.indexIcon,
    pets = UI.pets,
    daily = UI.daily,
    rebirth = UI.rebirth,
    fuse = UI.fuse,
    settings = UI.settings,
    codes = UI.codes,
    help = UI.help,
}

local function openPanel(player, kind)

    local function buildBikes(body)
        local state = State[player]
        if not state then
            return
        end
        uiSection(body, "BIKES - FASTER TRAVEL", Color3.fromRGB(255, 190, 90))
        local bikes = cardRow(body)
        for index, bike in ipairs(BIKES) do
            local owned = state.bikes[index] == true
            local label, action, accent
            if owned then
                if state.equippedBike == index then
                    label, action, accent = "EQUIPPED", nil, ACCENT
                else
                    label, action, accent = "EQUIP", "equipbike:" .. index, Color3.fromRGB(54, 162, 226)
                end
            else
                label, action, accent = "$" .. formatNumber(bike.price), "buybike:" .. index, Color3.fromRGB(74, 196, 62)
            end
            itemCard(bikes, index, bike.color, bike.name, "Speed x" .. bike.multiplier, label, action, accent, UI.wheel)
        end

        uiSection(body, "TRAILS - RIDE IN STYLE", Color3.fromRGB(180, 140, 255))
        local trails = cardRow(body)
        for index, trail in ipairs(TRAILS) do
            local owned = state.trails[index] == true
            local label, action, accent
            if owned then
                if state.equippedTrail == index then
                    label, action, accent = "EQUIPPED", nil, ACCENT
                else
                    label, action, accent = "EQUIP", "equiptrail:" .. index, Color3.fromRGB(54, 162, 226)
                end
            else
                label, action, accent = "$" .. formatNumber(trail.price), "buytrail:" .. index, Color3.fromRGB(74, 196, 62)
            end
            itemCard(trails, index, trail.color, trail.name, "Particle trail", label, action, accent, UI.trade)
        end
    end

    local function buildIndex(body)
        local state = State[player]
        if not state then
            return
        end
        uiSection(body, string.format("ANIMAL INDEX - %d/%d DISCOVERED", countIndex(state), #SPECIES), Color3.fromRGB(120, 205, 255))
        for _, species in ipairs(SPECIES) do
            local found = state.index[species.name] == true
            local row = uiRow(body, 52)
            local tierArt = packArt(row, UI_TIER_FRAMES[species.tier] or UI.frame, 34, UDim2.fromOffset(12, 9))
            if not found then
                tierArt.ImageColor3 = Color3.fromRGB(70, 68, 82)
                tierArt.ImageTransparency = 0.35
            end
            rowText(row, found and species.name or "???", 58, 210, 20, found and species.color or Color3.fromRGB(84, 82, 98))
            rowText(row, species.tier, 272, 220, 18, TIER_COLORS[species.tier])
            rowRight(
                row,
                found and ("$" .. formatNumber(species.income) .. "/s") or "Undiscovered",
                200,
                18,
                found and Color3.fromRGB(120, 230, 130) or Color3.fromRGB(130, 126, 144)
            )
        end
    end

    local function buildPets(body)
        local state = State[player]
        local base = state and state.base
        if not state or not base then
            return
        end
        local total = 0
        for _, entry in ipairs(state.petData) do
            local species = findSpecies(entry.species)
            local sizeEntry = findEntryByName(SIZES, entry.size)
            local mutationEntry = findEntryByName(MUTATIONS, entry.mutation)
            if species and sizeEntry and mutationEntry then
                total += petIncome(species, sizeEntry, mutationEntry)
            end
        end
        uiSection(body, string.format("MY PETS %d/%d - $%s/s", #state.petData, base.podsUnlocked, formatNumber(total)), ACCENT)
        if #state.petData == 0 then
            uiSection(body, "No pets yet - steal eggs from the nests!", Color3.fromRGB(200, 200, 210))
            return
        end
        for index, entry in ipairs(state.petData) do
            local species = findSpecies(entry.species)
            local sizeEntry = findEntryByName(SIZES, entry.size)
            local mutationEntry = findEntryByName(MUTATIONS, entry.mutation)
            if species and sizeEntry and mutationEntry then
                local row = uiRow(body, 52)
                packArt(row, UI.pets, 34, UDim2.fromOffset(12, 9))
                rowText(row, tostring(index) .. ". " .. species.name, 58, 190, 20, species.color)
                rowText(row, entry.size, 246, 110, 18)
                rowText(row, entry.mutation, 356, 160, 18, mutationEntry.color or PANEL_TEXT)
                rowRight(
                    row,
                    "$" .. formatNumber(petIncome(species, sizeEntry, mutationEntry)) .. "/s",
                    200,
                    18,
                    Color3.fromRGB(120, 230, 130)
                )
            end
        end
    end

    local function buildDaily(body)
        local state = State[player]
        if not state then
            return
        end
        local now = os.time()
        local ready = (now - (state.daily.last or 0)) >= DAILY_COOLDOWN
        uiSection(body, "DAILY REWARDS", Color3.fromRGB(255, 205, 90))
        for day, reward in ipairs(DAILY_REWARDS) do
            local claimed = day < (state.daily.day or 1)
            local row = uiRow(body, 54)
            packArt(row, UI.daily, 34, UDim2.fromOffset(12, 10))
            rowText(row, "Day " .. day, 58, 100, 21, claimed and Color3.fromRGB(120, 200, 130) or PANEL_TEXT)
            rowText(row, "$" .. formatNumber(reward.cash) .. (reward.pet and " + bonus pet" or ""), 190, 280, 19)
            rowRight(
                row,
                claimed and "CLAIMED" or "",
                150,
                17,
                claimed and Color3.fromRGB(130, 200, 140) or PANEL_TEXT
            )
        end
        local footer = uiRow(body, 58)
        if ready then
            rowText(footer, "Next reward ready!", 16, 400, 20, ACCENT)
            rowButton(footer, "CLAIM", "dailyclaim", Color3.fromRGB(238, 168, 44), UI.daily)
        else
            local minutes = math.max(1, math.ceil((DAILY_COOLDOWN - (now - (state.daily.last or 0))) / 60))
            rowText(footer, "Next reward in " .. minutes .. " min", 16, 440, 19, Color3.fromRGB(200, 196, 210))
        end
    end

    local function buildRebirth(body)
        local state = State[player]
        local stats = player:FindFirstChild("leaderstats")
        if not state or not stats then
            return
        end
        local cash = stats:FindFirstChild("Cash")
        local value = cash and cash.Value or 0
        uiSection(body, "REBIRTH", Color3.fromRGB(230, 140, 255))
        local info = uiRow(body, 58)
        rowText(info, "Current rebirths", 16, 300, 20)
        rowRight(info, tostring(state.rebirths or 0), 150, 22, Color3.fromRGB(230, 140, 255))
        local bonus = uiRow(body, 58)
        rowText(bonus, "Permanent income multiplier", 16, 400, 20)
        rowRight(bonus, "x" .. string.format("%.2f", rebirthMultiplier(state)), 150, 22, ACCENT)
        local nextBonus = uiRow(body, 58)
        rowText(nextBonus, "Multiplier after rebirth", 16, 400, 20)
        rowRight(nextBonus, "x" .. string.format("%.2f", rebirthMultiplier(state) + REBIRTH_BONUS), 150, 22, Color3.fromRGB(255, 228, 96))
        local cost = uiRow(body, 58)
        rowText(cost, "Cash required", 16, 400, 20)
        rowRight(cost, "$" .. formatNumber(REBIRTH_CASH), 150, 22, Color3.fromRGB(255, 150, 90))
        uiSection(body, "Rebirth resets your cash and pets, but keeps the Animal Index, bikes, trails and codes.", Color3.fromRGB(200, 196, 210))
        local action = uiRow(body, 66)
        if value >= REBIRTH_CASH then
            rowText(action, "You can rebirth now!", 16, 400, 20, ACCENT)
            rowButton(action, "REBIRTH", "rebirthconfirm", Color3.fromRGB(196, 76, 196), UI.rebirth)
        else
            rowText(action, "Keep collecting cash.", 16, 440, 19, Color3.fromRGB(200, 196, 210))
        end
    end

    local function buildFuse(body)
        local state = State[player]
        if not state then
            return
        end
        uiSection(body, "FUSE LAB", Color3.fromRGB(140, 170, 255))
        uiSection(body, "Select 3 pets of the SAME species. They merge into 1 pet with a better mutation (or size at max mutation).", Color3.fromRGB(200, 196, 210))
        if #state.petData < 3 then
            uiSection(body, "You need at least 3 pets to fuse.", Color3.fromRGB(220, 160, 120))
        end
        local selected = {}
        for _, index in ipairs(state.fuseSelection) do
            selected[index] = true
        end
        for index, entry in ipairs(state.petData) do
            local row = uiRow(body, 52)
            rowText(row, tostring(index) .. ". " .. entry.species, 16, 240, 20)
            rowText(row, entry.size, 264, 120, 18)
            rowText(row, entry.mutation, 390, 160, 18, Color3.fromRGB(255, 210, 120))
            if selected[index] then
                rowButton(row, "SELECTED", "fusetoggle:" .. index, Color3.fromRGB(74, 196, 62))
            else
                rowButton(row, "Select", "fusetoggle:" .. index, Color3.fromRGB(88, 132, 236))
            end
        end
        local action = uiRow(body, 66)
        rowText(action, "Selected: " .. #state.fuseSelection .. "/3", 16, 400, 20)
        rowButton(action, "FUSE", "fusemerge", Color3.fromRGB(140, 90, 255), UI.correct)
    end

    local function buildSettings(body)
        local state = State[player]
        if not state then
            return
        end
        uiSection(body, "SETTINGS", Color3.fromRGB(190, 190, 205))
        local function toggleRow(title, key, enabled)
            local row = uiRow(body, 58)
            rowText(row, title, 16, 480, 20)
            if enabled then
                rowButton(row, "ON", "setting:" .. key, Color3.fromRGB(74, 196, 62))
            else
                rowButton(row, "OFF", "setting:" .. key, Color3.fromRGB(120, 90, 90))
            end
        end
        toggleRow("Special effects (trail particles)", "effects", state.settings.effects ~= false)
        toggleRow("Notifications", "notifications", state.settings.notifications ~= false)
        uiSection(body, "Settings are saved with your progress.", Color3.fromRGB(170, 166, 182))
    end

    local function buildCodes(body)
        uiSection(body, "REDEEM A CODE", Color3.fromRGB(120, 230, 150))
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, -26, 0, 56)
        holder.Parent = body

        local box = Instance.new("TextBox")
        box.Name = "CodeBox"
        box.Position = UDim2.fromOffset(0, 0)
        box.Size = UDim2.fromOffset(420, 54)
        box.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
        box.BorderSizePixel = 0
        box.Font = Enum.Font.FredokaOne
        box.TextSize = 24
        box.TextColor3 = PALETTE.white
        box.PlaceholderColor3 = Color3.fromRGB(150, 146, 164)
        box.PlaceholderText = "Enter code"
        box.Text = ""
        box.ClearTextOnFocus = false
        box.Parent = holder
        uiRound(box, 12)
        uiStroke(box, 2)

        local redeem = Instance.new("TextButton")
        redeem.Position = UDim2.fromOffset(440, 4)
        redeem.Size = UDim2.fromOffset(170, 46)
        redeem.BackgroundColor3 = Color3.fromRGB(74, 196, 62)
        redeem.BorderSizePixel = 0
        redeem.AutoButtonColor = true
        redeem.Font = Enum.Font.FredokaOne
        redeem.TextSize = 21
        redeem.TextColor3 = PALETTE.white
        redeem.TextStrokeColor3 = PALETTE.ink
        redeem.TextStrokeTransparency = 1
        redeem.Text = "REDEEM"
        redeem.Parent = holder
        redeem:SetAttribute("Action", "redeem")
        uiTextOutline(redeem, 21)
        packArt(redeem, UI.correct, 22, UDim2.fromOffset(10, 12))
        uiRound(redeem, 12)
        uiStroke(redeem, 2)

        uiSection(body, 'Try "WELCOME", "EGG2026" or "STEAL100". Each code works once per player.', Color3.fromRGB(200, 196, 210))
    end

    local function buildHelp(body)
        uiSection(body, "HOW TO PLAY", Color3.fromRGB(255, 228, 96))
        local box = Instance.new("Frame")
        box.BackgroundColor3 = CARD_BG
        box.BorderSizePixel = 0
        box.Size = UDim2.new(1, -26, 0, 340)
        box.Parent = body
        uiRound(box, 12)
        uiStroke(box, 2)

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Position = UDim2.fromOffset(18, 12)
        text.Size = UDim2.new(1, -36, 1, -24)
        text.Font = Enum.Font.FredokaOne
        text.TextSize = 19
        text.TextColor3 = PANEL_TEXT
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextYAlignment = Enum.TextYAlignment.Top
        text.TextWrapped = true
        text.TextStrokeTransparency = 1
        uiTextOutline(text, 19)
        text.Text = table.concat({
            "1. Hold E at a nest to grab an egg. Its guardian will chase you.",
            "2. Carry the egg back to your pen and drop it on the glowing incubator pad.",
            "3. After 5 seconds the egg hatches into a random pet on a podium.",
            "4. Hold E on the treadmill to train Speed, and on the UPGRADE sign to unlock more podiums.",
            "5. Other players can steal incubating eggs after 3 seconds - guard them!",
            "6. Buy bikes and trails in the Shop with your cash.",
            "7. Rebirth for a permanent income multiplier once you have enough cash.",
            "8. Fuse 3 identical pets in the Fuse Lab for a stronger mutation.",
        }, "\n\n")
        text.Parent = box
    end

    local BUILDERS = {
        shop = buildBikes,
        index = buildIndex,
        pets = buildPets,
        daily = buildDaily,
        rebirth = buildRebirth,
        fuse = buildFuse,
        settings = buildSettings,
        codes = buildCodes,
        help = buildHelp,
    }

    local builder = BUILDERS[kind]
    local hud = HUDS[player]
    local state = State[player]
    if not builder or not hud or not hud.overlay or not state then
        return
    end

    local overlay = hud.overlay
    local old = overlay:FindFirstChild("Panel")
    if old then
        old:Destroy()
    end

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0, 860, 0, 560)
    panel.BackgroundColor3 = Color3.fromRGB(30, 26, 44)
    panel.BorderSizePixel = 0
    panel.ZIndex = 31
    panel.Parent = overlay
    uiRound(panel, 20)
    uiStroke(panel, 4)

    local panelGradient = Instance.new("UIGradient")
    panelGradient.Rotation = 90
    panelGradient.Color = ColorSequence.new(Color3.fromRGB(52, 44, 74), Color3.fromRGB(24, 20, 34))
    panelGradient.Parent = panel

    local header = Instance.new("Frame")
    header.BackgroundColor3 = Color3.fromRGB(38, 32, 56)
    header.BorderSizePixel = 0
    header.Position = UDim2.fromOffset(18, 16)
    header.Size = UDim2.new(1, -36, 0, 64)
    header.ZIndex = 31
    header.Parent = panel
    uiRound(header, 14)

    packArt(header, PANEL_ICONS[kind] or UI.help, 46, UDim2.fromOffset(10, 9))

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(68, 0)
    title.Size = UDim2.new(1, -150, 1, 0)
    title.Font = Enum.Font.LuckiestGuy
    title.TextSize = 30
    title.TextColor3 = PALETTE.white
    title.TextStrokeColor3 = PALETTE.ink
    title.TextStrokeTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.upper(kind)
    title.ZIndex = 31
    title.Parent = header
    uiTextOutline(title, 30)

    local close = Instance.new("ImageButton")
    close.Name = "CloseButton"
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -10, 0.5, 0)
    close.Size = UDim2.fromOffset(46, 46)
    close.BackgroundTransparency = 1
    close.Image = UI.close
    close.ScaleType = Enum.ScaleType.Fit
    close.AutoButtonColor = false
    close.ZIndex = 32
    close.Parent = header
    close:SetAttribute("Action", "close")

    local body = Instance.new("ScrollingFrame")
    body.Name = "Body"
    body.Position = UDim2.fromOffset(24, 96)
    body.Size = UDim2.new(1, -48, 1, -120)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 8
    body.ScrollBarImageColor3 = Color3.fromRGB(98, 238, 64)
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ZIndex = 31
    body.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = body

    state.panel = kind
    overlay.Visible = true
    builder(body)
end

local function closePanel(player)
    local hud = HUDS[player]
    if not hud or not hud.overlay then
        return
    end
    local panel = hud.overlay:FindFirstChild("Panel")
    if panel then
        panel:Destroy()
    end
    hud.overlay.Visible = false
    local state = State[player]
    if state then
        state.panel = nil
    end
end

local function applyBike(player)
    local state = State[player]
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not state or not root then
        return
    end
    local old = character:FindFirstChild("Bike")
    if old then
        old:Destroy()
    end
    local bike = BIKES[state.equippedBike or 1] or BIKES[1]
    createBike(character, root, bike.color, bike.wheelSize, bike.neon)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = math.min(100, state.speed * bikeMultiplier(state))
    end
end

applyEquipment = function(player)
    applyBike(player)
    applyTrail(player)
end

local function equipBike(player, index)
    local state = State[player]
    if not state or not BIKES[index] or not state.bikes[index] then
        return
    end
    state.equippedBike = index
    applyBike(player)
    notify(player, "Equipped " .. BIKES[index].name .. ".")
    openPanel(player, "shop")
end

local function buyBike(player, index)
    local state = State[player]
    local bike = BIKES[index]
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")
    if not state or not bike or not cash then
        return
    end
    if state.bikes[index] then
        notify(player, "You already own the " .. bike.name .. ".")
        return
    end
    if cash.Value < bike.price then
        notify(player, "Not enough cash for the " .. bike.name .. ".")
        return
    end
    addCash(player, -bike.price)
    state.bikes[index] = true
    state.equippedBike = index
    applyBike(player)
    notify(player, "Bought and equipped " .. bike.name .. "!")
    openPanel(player, "shop")
end

local function equipTrail(player, index)
    local state = State[player]
    if not state or not TRAILS[index] or not state.trails[index] then
        return
    end
    state.equippedTrail = index
    applyTrail(player)
    notify(player, "Equipped " .. TRAILS[index].name .. ".")
    openPanel(player, "shop")
end

local function buyTrail(player, index)
    local state = State[player]
    local trail = TRAILS[index]
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")
    if not state or not trail or not cash then
        return
    end
    if state.trails[index] then
        notify(player, "You already own the " .. trail.name .. ".")
        return
    end
    if cash.Value < trail.price then
        notify(player, "Not enough cash for the " .. trail.name .. ".")
        return
    end
    addCash(player, -trail.price)
    state.trails[index] = true
    state.equippedTrail = index
    applyTrail(player)
    notify(player, "Bought and equipped " .. trail.name .. "!")
    openPanel(player, "shop")
end

local function claimDaily(player)
    local state = State[player]
    if not state then
        return
    end
    local now = os.time()
    if now - (state.daily.last or 0) < DAILY_COOLDOWN then
        notify(player, "Daily reward is not ready yet.")
        openPanel(player, "daily")
        return
    end

    state.daily.last = now
    local day = math.clamp(state.daily.day or 1, 1, #DAILY_REWARDS)
    local reward = DAILY_REWARDS[day]
    state.daily.day = day % #DAILY_REWARDS + 1

    local payout = math.floor(reward.cash * rebirthMultiplier(state))
    addCash(player, payout)
    if reward.pet and state.base and placePet(player, state.base, pickSpecies(), SIZES[2], MUTATIONS[1], true) then
        notify(player, "Day " .. day .. " reward: $" .. formatNumber(payout) .. " and a bonus pet!")
    else
        notify(player, "Day " .. day .. " reward: $" .. formatNumber(payout) .. "!")
    end
    openPanel(player, "daily")
end

local function doRebirth(player)
    local state = State[player]
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")
    if not state or not cash then
        return
    end
    if cash.Value < REBIRTH_CASH then
        notify(player, "You need $" .. formatNumber(REBIRTH_CASH) .. " to rebirth.")
        return
    end

    local base = state.base
    if base then
        for model in pairs(base.pets) do
            model:Destroy()
        end
        for _, pod in ipairs(base.pods) do
            pod.model = nil
        end
        base.pets = {}
    end
    state.petData = {}
    state.fuseSelection = {}
    local pets = stats:FindFirstChild("Pets")
    if pets then
        pets.Value = 0
    end
    cash.Value = 0
    state.rebirths = (state.rebirths or 0) + 1
    setSpeed(player, CONFIG.START_SPEED)
    notify(player, "Rebirth #" .. state.rebirths .. " complete! Income x" .. string.format("%.2f", rebirthMultiplier(state)))
    updateHUD(player)
    openPanel(player, "rebirth")
end

local function toggleFuse(player, index)
    local state = State[player]
    if not state or not state.petData[index] then
        return
    end
    local selected = state.fuseSelection
    for position, value in ipairs(selected) do
        if value == index then
            table.remove(selected, position)
            openPanel(player, "fuse")
            return
        end
    end
    if #selected >= 3 then
        notify(player, "You can select at most 3 pets.")
    else
        table.insert(selected, index)
    end
    openPanel(player, "fuse")
end

local function fusePets(player)
    local state = State[player]
    local base = state and state.base
    if not state or not base then
        return
    end
    local selected = state.fuseSelection
    if #selected < 3 then
        notify(player, "Select 3 pets of the same species first.")
        return
    end

    local species = findSpecies(state.petData[selected[1]] and state.petData[selected[1]].species)
    if not species then
        return
    end
    for _, index in ipairs(selected) do
        local entry = state.petData[index]
        if not entry or entry.species ~= species.name then
            notify(player, "All fused pets must be the same species.")
            return
        end
    end

    local first = state.petData[selected[1]]
    local sizeIndex = 1
    for position, entry in ipairs(SIZES) do
        if entry.name == first.size then
            sizeIndex = position
        end
    end
    local mutationIndex = 1
    for position, entry in ipairs(MUTATIONS) do
        if entry.name == first.mutation then
            mutationIndex = position
        end
    end

    local canUpgradeMutation = mutationIndex < #MUTATIONS
    if not canUpgradeMutation and sizeIndex >= #SIZES then
        notify(player, "Those pets are already at maximum power.")
        return
    end
    local resultMutation = canUpgradeMutation and MUTATIONS[mutationIndex + 1] or MUTATIONS[#MUTATIONS]
    local resultSize = canUpgradeMutation and SIZES[sizeIndex] or SIZES[sizeIndex + 1]

    table.sort(selected)
    for _, index in ipairs(selected) do
        local entry = state.petData[index]
        if entry and entry.model then
            base.pets[entry.model] = nil
            for _, pod in ipairs(base.pods) do
                if pod.model == entry.model then
                    pod.model = nil
                end
            end
            entry.model:Destroy()
            addPetStat(player, -1)
        end
    end
    for position = #selected, 1, -1 do
        table.remove(state.petData, selected[position])
    end
    state.fuseSelection = {}

    if placePet(player, base, species, resultSize, resultMutation, false) then
        local tag = resultMutation.color and resultMutation.name or resultSize.name
        notify(player, "Fusion complete: " .. tag .. " " .. species.name .. "!")
    else
        notify(player, "Fusion failed - no free podium.")
    end
    updateHUD(player)
    openPanel(player, "fuse")
end

local function toggleSetting(player, key)
    local state = State[player]
    if not state or not key then
        return
    end
    if key == "effects" then
        state.settings.effects = not (state.settings.effects ~= false)
        applyTrail(player)
    elseif key == "notifications" then
        state.settings.notifications = not (state.settings.notifications ~= false)
    else
        return
    end
    openPanel(player, "settings")
    notify(player, "Setting updated.")
end

redeemEvent.OnServerInvoke = function(player, code)
    local state = State[player]
    if not state then
        return "Not ready yet."
    end
    if typeof(code) ~= "string" then
        return "Enter a code."
    end
    code = string.upper((string.gsub(code, "%s", "")))
    local reward = CODES[code]
    if not reward then
        return "Invalid code."
    end
    if state.codes[code] then
        return "Code already redeemed."
    end
    state.codes[code] = true
    addCash(player, reward)
    notify(player, "Code redeemed: +$" .. formatNumber(reward))
    return "Redeemed! +$" .. formatNumber(reward)
end

local PANEL_KINDS = {
    shop = true,
    index = true,
    pets = true,
    daily = true,
    rebirth = true,
    fuse = true,
    settings = true,
    codes = true,
    help = true,
}

actionEvent.OnServerEvent:Connect(function(player, action)
    if typeof(action) ~= "string" then
        return
    end
    local command, argument = string.match(action, "^(%w+):?(.*)$")
    if not command then
        return
    end
    local state = State[player]
    if not state then
        return
    end

    if PANEL_KINDS[command] then
        openPanel(player, command)
    elseif command == "close" then
        closePanel(player)
    elseif command == "buybike" then
        buyBike(player, tonumber(argument) or 0)
    elseif command == "equipbike" then
        equipBike(player, tonumber(argument) or 0)
    elseif command == "buytrail" then
        buyTrail(player, tonumber(argument) or 0)
    elseif command == "equiptrail" then
        equipTrail(player, tonumber(argument) or 0)
    elseif command == "dailyclaim" then
        claimDaily(player)
    elseif command == "rebirthconfirm" then
        doRebirth(player)
    elseif command == "fusetoggle" then
        toggleFuse(player, tonumber(argument) or 0)
    elseif command == "fusemerge" then
        fusePets(player)
    elseif command == "setting" then
        toggleSetting(player, argument)
    end
end)

buildWorld()

Players.PlayerAdded:Connect(function(player)
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"

    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = 0
    cash.Parent = stats

    local speed = Instance.new("NumberValue")
    speed.Name = "Speed"
    speed.Value = CONFIG.START_SPEED
    speed.Parent = stats

    local pets = Instance.new("IntValue")
    pets.Name = "Pets"
    pets.Value = 0
    pets.Parent = stats

    stats.Parent = player

    local base = assignBase(player)
    State[player] = {
        base = base,
        speed = CONFIG.START_SPEED,
        index = {},
        petData = {},
        bikes = { [1] = true },
        trails = { [1] = true },
        equippedBike = 1,
        equippedTrail = 1,
        rebirths = 0,
        daily = { day = 1, last = 0 },
        codes = {},
        fuseSelection = {},
        settings = { effects = true, notifications = true },
        panel = nil,
        loaded = false,
        trainCooldown = 0,
    }

    task.spawn(createHUD, player)
    task.spawn(loadPlayer, player)

    if not base then
        task.spawn(function()
            player:WaitForChild("PlayerGui")
            task.wait(1)
            notify(player, "All bases are taken - spectate and steal!")
        end)
    end

    if player.Character then
        setupCharacter(player, player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)

    local egg = Carrying[player]
    if egg then
        EggInfo[egg] = nil
        egg:Destroy()
    end
    Carrying[player] = nil

    releaseBase(player)
    HUDS[player] = nil
    State[player] = nil
end)

RunService.Heartbeat:Connect(function(dt)
    for _, guardian in ipairs(Guardians) do
        local target = guardian.target
        local model = guardian.model
        local root = model.PrimaryPart

        if target then
            local character = target.Character
            local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
            if not targetRoot or target.Parent == nil then
                guardian.target = nil
            else
                local goal = targetRoot.Position + Vector3.new(0, 2, 0)
                local delta = goal - root.Position
                local distance = delta.Magnitude
                if distance > 0.5 then
                    local step = math.min(14 * dt, distance)
                    model:PivotTo(CFrame.lookAt(root.Position + delta.Unit * step, goal))
                end
                if distance < 6.5 then
                    guardianCatch(guardian)
                elseif os.clock() > guardian.chaseUntil then
                    guardian.target = nil
                end
            end
        else
            local delta = guardian.homeCFrame.Position - root.Position
            local distance = delta.Magnitude
            if distance > 0.5 then
                local step = math.min(26 * dt, distance)
                model:PivotTo(CFrame.lookAt(root.Position + delta.Unit * step, guardian.homeCFrame.Position))
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        for _, base in ipairs(Bases) do
            local owner = base.owner
            if owner and owner.Parent then
                local total = 0
                for model, info in pairs(base.pets) do
                    if model.Parent then
                        total += info.income
                    end
                end
                if total > 0 then
                    addCash(owner, math.floor(total * rebirthMultiplier(State[owner])))
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            updateHUD(player)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            savePlayer(player)
        end
    end
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayer(player)
    end
end)
