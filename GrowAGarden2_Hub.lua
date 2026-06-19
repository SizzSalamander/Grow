-- ================================================
--   Grow a Garden 2 -- Script Hub v3 (Tabbed)
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local lpgui = lp:WaitForChild("PlayerGui")
local Networking = require(ReplicatedStorage.SharedModules.Networking)

local USER_PREFIX = tostring(lp.UserId) .. "_"

local SEEDS = {
    { name = "Carrot",          price = 1,          rarity = "Common",    restocks = true  },
    { name = "Strawberry",      price = 10,         rarity = "Common",    restocks = true  },
    { name = "Blueberry",       price = 25,         rarity = "Common",    restocks = true  },
    { name = "Tulip",           price = 40,         rarity = "Uncommon",  restocks = true  },
    { name = "Tomato",          price = 200,        rarity = "Uncommon",  restocks = true  },
    { name = "Apple",           price = 400,        rarity = "Uncommon",  restocks = true  },
    { name = "Bamboo",          price = 700,        rarity = "Rare",      restocks = true  },
    { name = "Corn",            price = 2500,       rarity = "Rare",      restocks = true  },
    { name = "Cactus",          price = 5000,       rarity = "Rare",      restocks = true  },
    { name = "Pineapple",       price = 10000,      rarity = "Rare",      restocks = true  },
    { name = "Mushroom",        price = 15000,      rarity = "Epic",      restocks = true  },
    { name = "Green Bean",      price = 20000,      rarity = "Epic",      restocks = true  },
    { name = "Banana",          price = 30000,      rarity = "Epic",      restocks = true  },
    { name = "Grape",           price = 50000,      rarity = "Epic",      restocks = true  },
    { name = "Coconut",         price = 140000,     rarity = "Epic",      restocks = true  },
    { name = "Mango",           price = 300000,     rarity = "Epic",      restocks = true  },
    { name = "Dragon Fruit",    price = 120000,     rarity = "Legendary", restocks = true  },
    { name = "Acorn",           price = 700000,     rarity = "Legendary", restocks = true  },
    { name = "Cherry",          price = 1200000,    rarity = "Legendary", restocks = true  },
    { name = "Sunflower",       price = 5000000,    rarity = "Legendary", restocks = true  },
    { name = "Venus Fly Trap",  price = 7000000,    rarity = "Mythic",    restocks = true  },
    { name = "Pomegranate",     price = 12000000,   rarity = "Mythic",    restocks = true  },
    { name = "Poison Apple",    price = 25000000,   rarity = "Mythic",    restocks = true  },
    { name = "Moon Bloom",      price = 65000000,   rarity = "Super",     restocks = true  },
    { name = "Dragon's Breath", price = 90000000,   rarity = "Super",     restocks = true  },
    { name = "Ghost Pepper",    price = 2800000,    rarity = "Mythic",    restocks = false },
    { name = "Poison Ivy",      price = 2800000,    rarity = "Legendary", restocks = false },
    { name = "Romanesco",       price = 1,          rarity = "Mythic",    restocks = false },
    { name = "Horned Melon",    price = 1,          rarity = "Rare",      restocks = false },
}

local GEAR = {
    { name = "Trowel",               price = 1000,     rarity = "Rare"      },
    { name = "Common Watering Can",  price = 2000,     rarity = "Common"   },
    { name = "Speed Mushroom",       price = 1500,     rarity = "Rare"      },
    { name = "Common Sprinkler",     price = 3000,     rarity = "Common"   },
    { name = "Uncommon Sprinkler",   price = 10000,    rarity = "Uncommon"  },
    { name = "Rare Sprinkler",       price = 80000,    rarity = "Rare"      },
    { name = "Legendary Sprinkler",  price = 1200000,  rarity = "Legendary"},
    { name = "Super Sprinkler",      price = 300000,   rarity = "Super"     },
    { name = "Teleporter",           price = 60000,    rarity = "Legendary"},
}

local RARITY_COLORS = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(100, 210, 100),
    Rare      = Color3.fromRGB(80,  140, 255),
    Epic      = Color3.fromRGB(180, 80,  255),
    Legendary = Color3.fromRGB(255, 200, 50),
    Mythic    = Color3.fromRGB(255, 80,  80),
    Super     = Color3.fromRGB(255, 120, 200),
}

local TABS = {
    { id = "Farm",   label = "Farm"   },
    { id = "Shop",   label = "Shop"   },
    { id = "Travel", label = "Travel" },
    { id = "PvP",    label = "PvP"    },
    { id = "Player", label = "Player" },
}

-- ================================================
-- STATE
-- ================================================
local selectedSeeds      = {}
local selectedGear       = {}
local autoBuyEnabled     = false
local autoGearEnabled    = false
local autoHarvestEnabled = false
local autoStealEnabled   = false
local autoSellFullEnabled     = false
local autoSellIntervalEnabled = false
local antiAfkEnabled     = false
local infJumpEnabled     = false
local walkFlingEnabled      = false
local walkSpeed             = 16
local infJumpConn           = nil
local walkFlingLoopActive   = false
local walkFlingNoclipConn   = nil
local walkFlingDiedConn     = nil

local SEED_BUY_COOLDOWN  = 0.03
local SEED_BUY_DELAY     = 0.005
local GEAR_BUY_COOLDOWN  = 0.03
local GEAR_BUY_DELAY     = 0.005
local HARVEST_COOLDOWN   = 0.03
local HARVEST_DELAY      = 0.005
local HARVEST_BATCH      = 50
local STEAL_COOLDOWN     = 0.03
local STEAL_BURST        = 8
local AUTO_SELL_COOLDOWN = 0.03
local autoSellIntervalSecs = 60

-- UI refs populated during build
local shecklesLbl, sellStatusLbl, harvestStatusLbl, growStatusLbl, gardenStatusLbl
local stealStatusLbl, seedStatusLbl, gearStatusLbl, speedLbl, walkFlingBtn

-- ================================================
-- HELPERS
-- ================================================
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 7)
    c.Parent = parent
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 100)
    s.Thickness = thickness or 1
    s.Parent = parent
end

local function fmtPrice(p)
    if p >= 1000000 then return string.format("%.1fM", p / 1000000)
    elseif p >= 1000 then return string.format("%.1fK", p / 1000)
    else return tostring(p) end
end

local function fmtSheckles(n)
    if n >= 1000000000 then return string.format("%.2fB", n / 1000000000)
    elseif n >= 1000000 then return string.format("%.2fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return tostring(n) end
end

local function countSelected(map)
    local n = 0
    for _, v in pairs(map) do if v then n += 1 end end
    return n
end

local function isNight()
    local night = ReplicatedStorage:FindFirstChild("Night")
    return night and night.Value == true
end

local function teleportToShop(name)
    pcall(function() Networking.TeleportButton.Request:Fire(name) end)
end

local function getFruitCount()
    return lp:GetAttribute("FruitCount") or 0
end

local function getMaxFruitCapacity()
    return lp:GetAttribute("MaxFruitCapacity") or 100
end

local function isBackpackFull()
    return getFruitCount() >= getMaxFruitCapacity()
end

local function formatBagStatus()
    return string.format("Bag: %d/%d", getFruitCount(), getMaxFruitCapacity())
end

local function updateSellStatusLabel(extra)
    local preview = previewSell()
    if not sellStatusLbl then return end
    if preview then
        sellStatusLbl.Text = string.format(
            "%s  |  Preview: %d items worth %s Sheckles%s",
            formatBagStatus(),
            preview.FruitCount or 0,
            fmtSheckles(preview.TotalSellValue or 0),
            extra or ""
        )
    else
        sellStatusLbl.Text = formatBagStatus() .. (extra or "")
    end
end

-- ================================================
-- GAME LOGIC
-- ================================================
local function previewSell()
    local ok, result = pcall(function() return Networking.NPCS.PreviewSellAll:Fire() end)
    if ok and result then return result end
    return nil
end

local function sellAllInventory()
    local ok, result = pcall(function() return Networking.NPCS.SellAll:Fire() end)
    if ok and result and result.Success then
        return true, string.format("Sold %d items for %s Sheckles", result.SoldCount or 0, fmtSheckles(result.SellPrice or 0))
    end
    if ok and result then
        return false, result.Message or "Sell failed"
    end
    return false, "Sell remote error"
end

local function refreshGardenCrops()
    local cleared = 0
    for _, prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if prompt:GetAttribute("Collected") then
            local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
            if model and model.Name:find(USER_PREFIX, 1, true) then
                prompt:SetAttribute("Collected", nil)
                cleared += 1
            end
        end
    end
    pcall(function() Networking.Garden.RequestGardens:Fire() end)
    return cleared
end

local function tryGrowAll()
    local ok, data = pcall(function() return Networking.Garden.RequestGrowAllData:Fire() end)
    if not ok then return false, "Remote error" end
    if not data then return false, "Nothing ready (offline growth already claimed or unavailable)" end
    if data.oldPlants and data.newPlants and next(data.newPlants) then
        pcall(function() Networking.Garden.RequestGardens:Fire() end)
        return true, "Grow All applied — garden synced"
    end
    return false, "No pending offline growth found"
end

local function countHarvestable()
    local n = 0
    for _, prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if not prompt.Enabled or prompt:GetAttribute("Collected") then continue end
        local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
        if not model or not model.Name:find(USER_PREFIX, 1, true) then continue end
        if model:GetAttribute("PlantId") then n += 1 end
    end
    return n
end

local lastHarvest = 0
local function harvestBatch(maxCount)
    if isBackpackFull() then return 0 end
    local collected = 0
    for _, prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if collected >= maxCount then break end
        if not prompt.Enabled or prompt:GetAttribute("Collected") then continue end
        local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
        if not model or not model.Name:find(USER_PREFIX, 1, true) then continue end
        local plantId = model:GetAttribute("PlantId")
        if not plantId then continue end
        if isBackpackFull() then break end
        local fruitId = model:GetAttribute("FruitId")
        prompt:SetAttribute("Collected", true)
        pcall(function() Networking.Garden.CollectFruit:Fire(plantId, fruitId or "") end)
        task.delay(0.12, function()
            if prompt and prompt.Parent then
                prompt:SetAttribute("Collected", nil)
            end
        end)
        collected += 1
        task.wait(HARVEST_DELAY)
    end
    return collected
end

local function findInstantStealTarget()
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local bestPrompt, bestDist = nil, math.huge
    for _, prompt in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if not prompt.Enabled or prompt.HoldDuration > 0 then continue end
        if prompt:GetAttribute("Collected") then continue end
        local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
        if not model then continue end
        local ownerId = tonumber(model:GetAttribute("UserId"))
        if not ownerId or ownerId == lp.UserId then continue end
        local plantId = model:GetAttribute("PlantId")
        if not plantId then continue end
        local dist = (model:GetPivot().Position - myRoot.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPrompt = { ownerId = ownerId, plantId = plantId, fruitId = model:GetAttribute("FruitId") or "" }
        end
    end
    return bestPrompt
end

local function countStealTargets()
    local n = 0
    for _, prompt in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if not prompt.Enabled or prompt.HoldDuration > 0 then continue end
        local model = prompt.Parent and prompt.Parent:FindFirstAncestorWhichIsA("Model")
        if not model then continue end
        local ownerId = tonumber(model:GetAttribute("UserId"))
        if ownerId and ownerId ~= lp.UserId and model:GetAttribute("PlantId") then
            n += 1
        end
    end
    return n
end

local lastSteal = 0
local function tryStealOnce()
    if not isNight() then return false, "Daytime — stealing disabled" end
    local target = findInstantStealTarget()
    if not target then return false, "No instant-steal targets nearby" end
    pcall(function()
        Networking.Steal.BeginSteal:Fire(target.ownerId, target.plantId, target.fruitId)
        Networking.Steal.CompleteSteal:Fire()
    end)
    return true, "Stole 1 plant"
end

local function getRoot(char)
    if char and char:FindFirstChildOfClass("Humanoid") then
        return char:FindFirstChildOfClass("Humanoid").RootPart
    end
    return nil
end

local function setWalkFlingButtonState(enabled)
    if not walkFlingBtn then return end
    walkFlingBtn.Text = enabled and "Walk Fling: ON" or "Walk Fling: OFF"
    walkFlingBtn.BackgroundColor3 = enabled
        and Color3.fromRGB(160, 50, 50)
        or Color3.fromRGB(90, 35, 35)
end

local function startWalkFlingNoclip()
    if walkFlingNoclipConn then
        walkFlingNoclipConn:Disconnect()
        walkFlingNoclipConn = nil
    end
    walkFlingNoclipConn = RunService.Stepped:Connect(function()
        if not walkFlingLoopActive then return end
        local char = lp.Character
        if not char then return end
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide then
                child.CanCollide = false
            end
        end
    end)
end

local function stopWalkFlingNoclip()
    if walkFlingNoclipConn then
        walkFlingNoclipConn:Disconnect()
        walkFlingNoclipConn = nil
    end
end

local function stopWalkFling()
    walkFlingLoopActive = false
    stopWalkFlingNoclip()
    if walkFlingDiedConn then
        walkFlingDiedConn:Disconnect()
        walkFlingDiedConn = nil
    end
end

local function startWalkFling()
    stopWalkFling()
    if not walkFlingEnabled then return end

    local char = lp.Character
    if not char then return end

    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        walkFlingDiedConn = humanoid.Died:Connect(function()
            walkFlingEnabled = false
            setWalkFlingButtonState(false)
            stopWalkFling()
        end)
    end

    startWalkFlingNoclip()
    walkFlingLoopActive = true

    task.spawn(function()
        repeat
            RunService.Heartbeat:Wait()
            if not walkFlingLoopActive then break end

            local character = lp.Character
            local root = getRoot(character)
            local vel, movel = nil, 0.1

            while not (character and character.Parent and root and root.Parent) do
                if not walkFlingLoopActive then return end
                RunService.Heartbeat:Wait()
                character = lp.Character
                root = getRoot(character)
            end

            vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

            RunService.RenderStepped:Wait()
            if not walkFlingLoopActive then return end
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()
            if not walkFlingLoopActive then return end
            if character and character.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        until not walkFlingLoopActive
    end)
end

-- ================================================
-- BUILD GUI
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GAG2Hub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = lpgui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 370, 0, 540)
main.Position = UDim2.new(0.5, -185, 0.5, -270)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui
corner(main, 10)
stroke(main, Color3.fromRGB(80, 80, 140), 1.5)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
corner(titleBar, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "GAG2 Hub"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

shecklesLbl = Instance.new("TextLabel")
shecklesLbl.Size = UDim2.new(0.45, -40, 1, 0)
shecklesLbl.Position = UDim2.new(0.5, 0, 0, 0)
shecklesLbl.BackgroundTransparency = 1
shecklesLbl.Text = "0 Sheckles"
shecklesLbl.TextColor3 = Color3.fromRGB(180, 255, 130)
shecklesLbl.TextSize = 11
shecklesLbl.Font = Enum.Font.GothamBold
shecklesLbl.TextXAlignment = Enum.TextXAlignment.Right
shecklesLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "x"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
corner(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function()
    if infJumpConn then infJumpConn:Disconnect() end
    stopWalkFling()
    if antiAfkEnabled then lp:SetAttribute("AntiAfkIdleOverride", nil) end
    screenGui:Destroy()
end)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 30)
tabBar.Position = UDim2.new(0, 6, 0, 44)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
tabBar.BorderSizePixel = 0
tabBar.Parent = main
corner(tabBar, 6)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 2)
tabLayout.Parent = tabBar
local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0, 3)
tabPad.PaddingTop = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)
tabPad.Parent = tabBar

local tabPanels = {}
local tabContents = {}
local tabButtons = {}
local activeTab = "Farm"

local function switchTab(id)
    activeTab = id
    for tabId, panel in pairs(tabPanels) do
        panel.Visible = tabId == id
    end
    for tabId, btn in pairs(tabButtons) do
        local active = tabId == id
        btn.BackgroundColor3 = active and Color3.fromRGB(70, 70, 120) or Color3.fromRGB(32, 32, 50)
        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 190)
    end
end

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 68, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
    btn.Text = tab.label
    btn.TextColor3 = Color3.fromRGB(150, 150, 190)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = i
    btn.Parent = tabBar
    corner(btn, 4)
    tabButtons[tab.id] = btn

    local panel = Instance.new("ScrollingFrame")
    panel.Size = UDim2.new(1, -8, 1, -118)
    panel.Position = UDim2.new(0, 4, 0, 78)
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 4
    panel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 180)
    panel.Visible = tab.id == "Farm"
    panel.Parent = main

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -4, 0, 600)
    content.BackgroundTransparency = 1
    content.Parent = panel

    tabPanels[tab.id] = panel
    tabContents[tab.id] = content

    btn.MouseButton1Click:Connect(function() switchTab(tab.id) end)
end

local function getContent(tabId)
    return tabContents[tabId]
end

local function resizeTab(tabId, height)
    local panel = tabPanels[tabId]
    local content = tabContents[tabId]
    content.Size = UDim2.new(1, -4, 0, height)
    panel.CanvasSize = UDim2.new(0, 0, 0, height)
end

local function mkLabel(text, y, size, color, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, size or 20)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(130, 130, 160)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

local function mkSection(title, y, parent)
    local lbl = mkLabel(title, y, 20, Color3.fromRGB(140, 140, 200), parent)
    lbl.Font = Enum.Font.GothamBold
    return y + 22
end

local function mkDivider(y, parent)
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, -20, 0, 1)
    div.Position = UDim2.new(0, 10, 0, y)
    div.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    div.BorderSizePixel = 0
    div.Parent = parent
    return y + 10
end

local function mkBtn(text, y, parent, color, textColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = color or Color3.fromRGB(35, 55, 90)
    btn.Text = text
    btn.TextColor3 = textColor or Color3.fromRGB(220, 220, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    corner(btn)
    return btn
end

local function mkSmallBtn(text, x, y, w, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 30)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    corner(btn, 6)
    stroke(btn, Color3.fromRGB(55, 55, 90), 1)
    return btn
end

local function buildPicker(items, y, selectedMap, parent, onToggle, restockOnly)
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -20, 0, 32)
    dropBtn.Position = UDim2.new(0, 10, 0, y)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
    dropBtn.Text = "Select Items  v"
    dropBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
    dropBtn.TextSize = 12
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.BorderSizePixel = 0
    dropBtn.Parent = parent
    corner(dropBtn)
    stroke(dropBtn)

    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Size = UDim2.new(1, -20, 0, 0)
    dropdown.Position = UDim2.new(0, 10, 0, y + 36)
    dropdown.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 4
    dropdown.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 180)
    dropdown.ClipsDescendants = true
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = parent
    corner(dropdown)

    local ddLayout = Instance.new("UIListLayout")
    ddLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ddLayout.Padding = UDim.new(0, 2)
    ddLayout.Parent = dropdown
    local ddPad = Instance.new("UIPadding")
    ddPad.PaddingTop = UDim.new(0, 4)
    ddPad.PaddingLeft = UDim.new(0, 4)
    ddPad.PaddingRight = UDim.new(0, 4)
    ddPad.Parent = dropdown

    ddLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        dropdown.CanvasSize = UDim2.new(0, 0, 0, ddLayout.AbsoluteContentSize.Y + 8)
    end)

    local open = false
    for i, item in ipairs(items) do
        if restockOnly and item.restocks == false then continue end
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, -8, 0, 26)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 44)
        row.Text = ""
        row.LayoutOrder = i
        row.ZIndex = 11
        row.Parent = dropdown
        corner(row, 5)

        local checkBox = Instance.new("Frame")
        checkBox.Size = UDim2.new(0, 14, 0, 14)
        checkBox.Position = UDim2.new(0, 6, 0.5, -7)
        checkBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        checkBox.BorderSizePixel = 0
        checkBox.ZIndex = 12
        checkBox.Parent = row
        corner(checkBox, 3)

        local checkMark = Instance.new("TextLabel")
        checkMark.Size = UDim2.new(1, 0, 1, 0)
        checkMark.BackgroundTransparency = 1
        checkMark.Text = "v"
        checkMark.TextColor3 = Color3.fromRGB(100, 255, 120)
        checkMark.TextSize = 11
        checkMark.Font = Enum.Font.GothamBold
        checkMark.Visible = false
        checkMark.ZIndex = 13
        checkMark.Parent = checkBox

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 7, 0, 7)
        dot.Position = UDim2.new(0, 26, 0.5, -3)
        dot.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(180, 180, 180)
        dot.BorderSizePixel = 0
        dot.ZIndex = 12
        dot.Parent = row
        corner(dot, 999)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0, 155, 1, 0)
        nameLbl.Position = UDim2.new(0, 38, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = item.name
        nameLbl.TextColor3 = Color3.fromRGB(210, 210, 255)
        nameLbl.TextSize = 11
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.ZIndex = 12
        nameLbl.Parent = row

        local priceLbl = Instance.new("TextLabel")
        priceLbl.Size = UDim2.new(0, 80, 1, 0)
        priceLbl.Position = UDim2.new(1, -86, 0, 0)
        priceLbl.BackgroundTransparency = 1
        priceLbl.Text = fmtPrice(item.price) .. "S"
        priceLbl.TextColor3 = Color3.fromRGB(180, 255, 130)
        priceLbl.TextSize = 10
        priceLbl.Font = Enum.Font.Gotham
        priceLbl.TextXAlignment = Enum.TextXAlignment.Right
        priceLbl.ZIndex = 12
        priceLbl.Parent = row

        local sel = false
        row.MouseButton1Click:Connect(function()
            sel = not sel
            checkMark.Visible = sel
            checkBox.BackgroundColor3 = sel and Color3.fromRGB(40, 90, 50) or Color3.fromRGB(40, 40, 60)
            row.BackgroundColor3 = sel and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(28, 28, 44)
            selectedMap[item.name] = sel
            if onToggle then onToggle() end
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        open = not open
        dropdown.Visible = open
        dropdown.Size = open and UDim2.new(1, -20, 0, 150) or UDim2.new(1, -20, 0, 0)
        dropBtn.Text = open and "Select Items  ^" or "Select Items  v"
    end)
end

-- ================================================
-- TAB: FARM
-- ================================================
do
    local c = getContent("Farm")
    local y = 4

    y = mkSection("HARVEST", y, c)
    mkLabel("Collects ripe plants/fruits in your garden.", y, 18, nil, c)
    y += 22

    local harvestNowBtn = mkBtn("Harvest All Now", y, c, Color3.fromRGB(70, 55, 25), Color3.fromRGB(255, 230, 170))
    y += 40

    local autoHarvestBtn = mkBtn("Auto Harvest: OFF", y, c, Color3.fromRGB(70, 55, 25), Color3.fromRGB(255, 230, 170))
    y += 40
    harvestStatusLbl = mkLabel("Ready: 0  |  Status: Idle", y, 18, nil, c)
    y += 24
    y = mkDivider(y, c)

    y = mkSection("GARDEN SYNC", y, c)
    mkLabel("Clears stuck harvest flags and resyncs your garden crops from the server.", y, 36, nil, c)
    y += 38
    local refreshGardenBtn = mkBtn("Refresh Garden Crops", y, c, Color3.fromRGB(45, 70, 95), Color3.fromRGB(200, 230, 255))
    y += 40
    gardenStatusLbl = mkLabel("Status: Ready", y, 18, nil, c)
    y += 24
    y = mkDivider(y, c)

    y = mkSection("GROW ALL", y, c)
    mkLabel("Claims offline growth from the server.", y, 18, nil, c)
    y += 22
    local growAllBtn = mkBtn("Trigger Grow All", y, c, Color3.fromRGB(40, 80, 50), Color3.fromRGB(200, 255, 210))
    y += 40
    growStatusLbl = mkLabel("Status: Ready", y, 18, nil, c)
    y += 24
    y = mkDivider(y, c)

    y = mkSection("SELL INVENTORY", y, c)
    mkLabel("Sells all harvested fruit in your inventory to Steven.", y, 28, nil, c)
    y += 30
    local sellAllBtn = mkBtn("Sell All Inventory", y, c, Color3.fromRGB(80, 45, 25), Color3.fromRGB(255, 220, 180))
    y += 40
    local autoSellFullBtn = mkBtn("Auto Sell (Bag Full): OFF", y, c, Color3.fromRGB(80, 45, 25), Color3.fromRGB(255, 220, 180))
    y += 40
    local autoSellIntervalBtn = mkBtn("Auto Sell (Interval): OFF", y, c, Color3.fromRGB(80, 45, 25), Color3.fromRGB(255, 220, 180))
    y += 40
    mkLabel("Sell interval", y, 18, nil, c)
    y += 20
    local intervalLbl = mkLabel("Interval: 60s", y, 18, Color3.fromRGB(180, 180, 220), c)
    y += 18
    local int30Btn = mkSmallBtn("30s", 10, y, 55, c)
    local int60Btn = mkSmallBtn("60s", 75, y, 55, c)
    local int120Btn = mkSmallBtn("2m", 140, y, 55, c)
    local int300Btn = mkSmallBtn("5m", 205, y, 55, c)
    y += 38
    sellStatusLbl = mkLabel("Bag: 0/100  |  Preview: checking...", y, 18, nil, c)
    y += 24

    resizeTab("Farm", y + 10)

    autoHarvestBtn.MouseButton1Click:Connect(function()
        autoHarvestEnabled = not autoHarvestEnabled
        autoHarvestBtn.Text = autoHarvestEnabled and "Auto Harvest: ON" or "Auto Harvest: OFF"
        autoHarvestBtn.BackgroundColor3 = autoHarvestEnabled and Color3.fromRGB(130, 100, 40) or Color3.fromRGB(70, 55, 25)
    end)

    harvestNowBtn.MouseButton1Click:Connect(function()
        if isBackpackFull() then
            harvestStatusLbl.Text = string.format("Bag full (%s) — sell or refresh first", formatBagStatus())
            return
        end
        local n = harvestBatch(9999)
        harvestStatusLbl.Text = string.format("Collected %d items", n)
    end)

    refreshGardenBtn.MouseButton1Click:Connect(function()
        gardenStatusLbl.Text = "Status: Refreshing..."
        task.spawn(function()
            local cleared = refreshGardenCrops()
            task.wait(0.25)
            gardenStatusLbl.Text = string.format("Status: Refreshed — cleared %d stuck flag(s)", cleared)
        end)
    end)

    growAllBtn.MouseButton1Click:Connect(function()
        growStatusLbl.Text = "Status: Requesting..."
        task.spawn(function()
            local ok, msg = tryGrowAll()
            growStatusLbl.Text = "Status: " .. msg
        end)
    end)

    sellAllBtn.MouseButton1Click:Connect(function()
        sellStatusLbl.Text = "Status: Selling..."
        task.spawn(function()
            local ok, msg = sellAllInventory()
            sellStatusLbl.Text = ok and ("Success: " .. msg) or ("Failed: " .. msg)
            task.wait(0.5)
            updateSellStatusLabel()
        end)
    end)

    autoSellFullBtn.MouseButton1Click:Connect(function()
        autoSellFullEnabled = not autoSellFullEnabled
        autoSellFullBtn.Text = autoSellFullEnabled and "Auto Sell (Bag Full): ON" or "Auto Sell (Bag Full): OFF"
        autoSellFullBtn.BackgroundColor3 = autoSellFullEnabled and Color3.fromRGB(130, 75, 35) or Color3.fromRGB(80, 45, 25)
    end)

    autoSellIntervalBtn.MouseButton1Click:Connect(function()
        autoSellIntervalEnabled = not autoSellIntervalEnabled
        autoSellIntervalBtn.Text = autoSellIntervalEnabled and "Auto Sell (Interval): ON" or "Auto Sell (Interval): OFF"
        autoSellIntervalBtn.BackgroundColor3 = autoSellIntervalEnabled and Color3.fromRGB(130, 75, 35) or Color3.fromRGB(80, 45, 25)
        if autoSellIntervalEnabled then
            lastIntervalSell = tick()
        end
    end)

    local function setSellInterval(secs, label)
        autoSellIntervalSecs = secs
        intervalLbl.Text = "Interval: " .. label
        if autoSellIntervalEnabled then
            lastIntervalSell = tick()
        end
    end

    int30Btn.MouseButton1Click:Connect(function() setSellInterval(30, "30s") end)
    int60Btn.MouseButton1Click:Connect(function() setSellInterval(60, "60s") end)
    int120Btn.MouseButton1Click:Connect(function() setSellInterval(120, "2m") end)
    int300Btn.MouseButton1Click:Connect(function() setSellInterval(300, "5m") end)
end

-- ================================================
-- TAB: SHOP
-- ================================================
do
    local c = getContent("Shop")
    local y = 4

    y = mkSection("SHOP TELEPORTS", y, c)
    local tpGarden = mkSmallBtn("Garden", 10, y, 105, c)
    local tpSeeds  = mkSmallBtn("Seeds", 125, y, 105, c)
    local tpSell   = mkSmallBtn("Sell", 240, y, 105, c)
    y += 38
    tpGarden.MouseButton1Click:Connect(function() teleportToShop("Garden") end)
    tpSeeds.MouseButton1Click:Connect(function() teleportToShop("Seeds") end)
    tpSell.MouseButton1Click:Connect(function() teleportToShop("Sell") end)
    y = mkDivider(y, c)

    y = mkSection("AUTO SEED BUYER", y, c)
    local seedSelectedLbl = mkLabel("No seeds selected", y, 18, nil, c)
    y += 20
    buildPicker(SEEDS, y, selectedSeeds, c, function()
        seedSelectedLbl.Text = countSelected(selectedSeeds) == 0 and "No seeds selected" or countSelected(selectedSeeds) .. " seed(s) selected"
    end, true)
    y += 192
    local autoBuyBtn = mkBtn("Auto Buy Seeds: OFF", y, c, Color3.fromRGB(35, 90, 45), Color3.fromRGB(200, 255, 200))
    y += 40
    seedStatusLbl = mkLabel("Status: Idle", y, 18, nil, c)
    y += 24
    y = mkDivider(y, c)

    y = mkSection("AUTO GEAR BUYER", y, c)
    local gearSelectedLbl = mkLabel("No gear selected", y, 18, nil, c)
    y += 20
    buildPicker(GEAR, y, selectedGear, c, function()
        gearSelectedLbl.Text = countSelected(selectedGear) == 0 and "No gear selected" or countSelected(selectedGear) .. " gear item(s) selected"
    end, false)
    y += 192
    local autoGearBtn = mkBtn("Auto Buy Gear: OFF", y, c, Color3.fromRGB(35, 70, 90), Color3.fromRGB(200, 230, 255))
    y += 40
    gearStatusLbl = mkLabel("Status: Idle", y, 18, nil, c)
    y += 24

    resizeTab("Shop", y + 10)

    autoBuyBtn.MouseButton1Click:Connect(function()
        autoBuyEnabled = not autoBuyEnabled
        autoBuyBtn.Text = autoBuyEnabled and "Auto Buy Seeds: ON" or "Auto Buy Seeds: OFF"
        autoBuyBtn.BackgroundColor3 = autoBuyEnabled and Color3.fromRGB(60, 160, 70) or Color3.fromRGB(35, 90, 45)
        seedStatusLbl.Text = autoBuyEnabled and "Status: Watching shop..." or "Status: Idle"
    end)

    autoGearBtn.MouseButton1Click:Connect(function()
        autoGearEnabled = not autoGearEnabled
        autoGearBtn.Text = autoGearEnabled and "Auto Buy Gear: ON" or "Auto Buy Gear: OFF"
        autoGearBtn.BackgroundColor3 = autoGearEnabled and Color3.fromRGB(50, 130, 170) or Color3.fromRGB(35, 70, 90)
        gearStatusLbl.Text = autoGearEnabled and "Status: Watching shop..." or "Status: Idle"
    end)
end

-- ================================================
-- TAB: TRAVEL
-- ================================================
do
    local c = getContent("Travel")
    local y = 4

    y = mkSection("SHOP TELEPORTS", y, c)
    local qGarden = mkSmallBtn("Garden", 10, y, 105, c)
    local qSeeds  = mkSmallBtn("Seeds", 125, y, 105, c)
    local qSell   = mkSmallBtn("Sell", 240, y, 105, c)
    y += 38
    qGarden.MouseButton1Click:Connect(function() teleportToShop("Garden") end)
    qSeeds.MouseButton1Click:Connect(function() teleportToShop("Seeds") end)
    qSell.MouseButton1Click:Connect(function() teleportToShop("Sell") end)

    resizeTab("Travel", y + 10)
end

-- ================================================
-- TAB: PVP
-- ================================================
do
    local c = getContent("PvP")
    local y = 4

    y = mkSection("NIGHT STEAL HELPER", y, c)
    mkLabel("Auto-steals instant (no-hold) targets at night. Hold-steal still needs manual input.", y, 36, nil, c)
    y += 38

    local stealNowBtn = mkBtn("Steal Nearest Now", y, c, Color3.fromRGB(80, 30, 80), Color3.fromRGB(255, 200, 255))
    y += 40
    local autoStealBtn = mkBtn("Auto Steal: OFF", y, c, Color3.fromRGB(80, 30, 80), Color3.fromRGB(255, 200, 255))
    y += 40
    stealStatusLbl = mkLabel("Night: No  |  Targets: 0  |  Idle", y, 18, nil, c)
    y += 24
    y = mkDivider(y, c)

    y = mkSection("WALK FLING", y, c)
    mkLabel("Infinite Yield walkfling. Fling players on touch without spinning.", y, 36, nil, c)
    y += 38
    walkFlingBtn = mkBtn("Walk Fling: OFF", y, c, Color3.fromRGB(90, 35, 35), Color3.fromRGB(255, 180, 180))
    y += 40

    resizeTab("PvP", y + 10)

    autoStealBtn.MouseButton1Click:Connect(function()
        autoStealEnabled = not autoStealEnabled
        autoStealBtn.Text = autoStealEnabled and "Auto Steal: ON" or "Auto Steal: OFF"
        autoStealBtn.BackgroundColor3 = autoStealEnabled and Color3.fromRGB(140, 50, 140) or Color3.fromRGB(80, 30, 80)
    end)

    stealNowBtn.MouseButton1Click:Connect(function()
        local ok, msg = tryStealOnce()
        stealStatusLbl.Text = string.format("Night: %s  |  %s", isNight() and "Yes" or "No", msg)
    end)

    walkFlingBtn.MouseButton1Click:Connect(function()
        walkFlingEnabled = not walkFlingEnabled
        setWalkFlingButtonState(walkFlingEnabled)
        if walkFlingEnabled then
            startWalkFling()
        else
            stopWalkFling()
        end
    end)
end

-- ================================================
-- TAB: PLAYER
-- ================================================
do
    local c = getContent("Player")
    local y = 4

    y = mkSection("MOVEMENT", y, c)
    local antiAfkBtn = mkBtn("Anti-AFK: OFF", y, c, Color3.fromRGB(35, 55, 90), Color3.fromRGB(200, 220, 255))
    y += 40
    local infJumpBtn = mkBtn("Infinite Jump: OFF", y, c, Color3.fromRGB(35, 55, 90), Color3.fromRGB(200, 220, 255))
    y += 40
    mkLabel("Walk Speed", y, 18, nil, c)
    y += 20
    speedLbl = mkLabel("Speed: 16", y, 18, Color3.fromRGB(180, 180, 220), c)
    y += 18
    local speedSlow = mkSmallBtn("-", 10, y, 50, c)
    local speedFast = mkSmallBtn("+", 70, y, 50, c)
    local speedReset = mkSmallBtn("Reset", 130, y, 70, c)
    local speedBoost = mkSmallBtn("Fast (32)", 210, y, 130, c)
    y += 38

    resizeTab("Player", y + 10)

    local function applyWalkSpeed()
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = walkSpeed end
        speedLbl.Text = "Speed: " .. walkSpeed
    end

    antiAfkBtn.MouseButton1Click:Connect(function()
        antiAfkEnabled = not antiAfkEnabled
        antiAfkBtn.Text = antiAfkEnabled and "Anti-AFK: ON" or "Anti-AFK: OFF"
        antiAfkBtn.BackgroundColor3 = antiAfkEnabled and Color3.fromRGB(50, 100, 160) or Color3.fromRGB(35, 55, 90)
        lp:SetAttribute("AntiAfkIdleOverride", antiAfkEnabled and 999999 or nil)
    end)

    infJumpBtn.MouseButton1Click:Connect(function()
        infJumpEnabled = not infJumpEnabled
        infJumpBtn.Text = infJumpEnabled and "Infinite Jump: ON" or "Infinite Jump: OFF"
        infJumpBtn.BackgroundColor3 = infJumpEnabled and Color3.fromRGB(50, 100, 160) or Color3.fromRGB(35, 55, 90)
        if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
        if infJumpEnabled then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end)

    speedSlow.MouseButton1Click:Connect(function() walkSpeed = math.max(8, walkSpeed - 4) applyWalkSpeed() end)
    speedFast.MouseButton1Click:Connect(function() walkSpeed = math.min(100, walkSpeed + 4) applyWalkSpeed() end)
    speedReset.MouseButton1Click:Connect(function() walkSpeed = 16 applyWalkSpeed() end)
    speedBoost.MouseButton1Click:Connect(function() walkSpeed = 32 applyWalkSpeed() end)
    lp.CharacterAdded:Connect(function() task.wait(0.5) applyWalkSpeed() end)
    applyWalkSpeed()
end

-- ================================================
-- AUTO LOOPS
-- ================================================
local lastSeedBuy, lastGearBuy = 0, 0
local lastAutoSell = 0
local lastIntervalSell = 0

local function performAutoSell(reason)
    if tick() - lastAutoSell < AUTO_SELL_COOLDOWN then return end
    local preview = previewSell()
    if not preview or (preview.FruitCount or 0) <= 0 then return end
    lastAutoSell = tick()
    local ok, msg = sellAllInventory()
    if sellStatusLbl then
        sellStatusLbl.Text = ok and ("Auto (" .. reason .. "): " .. msg) or ("Auto sell failed: " .. msg)
    end
    if ok then
        if reason == "bag full" then
            refreshGardenCrops()
        end
        task.defer(updateSellStatusLabel)
    end
end

local function tryAutoSellFull()
    if not autoSellFullEnabled then return end
    if not isBackpackFull() then return end
    performAutoSell("bag full")
end

local function tryAutoSellInterval()
    if not autoSellIntervalEnabled then return end
    if tick() - lastIntervalSell < autoSellIntervalSecs then return end
    lastIntervalSell = tick()
    performAutoSell("interval")
end

local function tryAutoBuySeeds()
    if not autoBuyEnabled then return end
    if tick() - lastSeedBuy < SEED_BUY_COOLDOWN then return end
    lastSeedBuy = tick()
    if countSelected(selectedSeeds) == 0 then
        seedStatusLbl.Text = "Status: No seeds selected"
        return
    end
    seedStatusLbl.Text = "Status: Buying seeds..."
    for seedName, watching in pairs(selectedSeeds) do
        if watching then
            pcall(function() Networking.SeedShop.PurchaseSeed:Fire(seedName) end)
            task.wait(SEED_BUY_DELAY)
        end
    end
end

local function tryAutoBuyGear()
    if not autoGearEnabled then return end
    if tick() - lastGearBuy < GEAR_BUY_COOLDOWN then return end
    lastGearBuy = tick()
    if countSelected(selectedGear) == 0 then
        gearStatusLbl.Text = "Status: No gear selected"
        return
    end
    gearStatusLbl.Text = "Status: Buying gear..."
    for gearName, watching in pairs(selectedGear) do
        if watching then
            pcall(function() Networking.GearShop.PurchaseGear:Fire(gearName) end)
            task.wait(GEAR_BUY_DELAY)
        end
    end
end

local function tryAutoHarvest()
    if not autoHarvestEnabled then return end
    if tick() - lastHarvest < HARVEST_COOLDOWN then return end
    lastHarvest = tick()
    local ready = countHarvestable()
    if ready == 0 then
        harvestStatusLbl.Text = "Ready: 0  |  Status: Nothing to collect"
        return
    end
    if isBackpackFull() then
        harvestStatusLbl.Text = string.format("Ready: %d  |  Bag full (%s)", ready, formatBagStatus())
        return
    end
    local n = harvestBatch(HARVEST_BATCH)
    harvestStatusLbl.Text = string.format("Ready: %d  |  Collected %d", math.max(0, ready - n), n)
end

local function tryAutoSteal()
    if not autoStealEnabled then return end
    if tick() - lastSteal < STEAL_COOLDOWN then return end
    lastSteal = tick()
    if not isNight() then
        stealStatusLbl.Text = string.format("Night: No  |  Targets: %d  |  Waiting for night", countStealTargets())
        return
    end
    local stolen = 0
    for _ = 1, STEAL_BURST do
        local ok = tryStealOnce()
        if not ok then break end
        stolen += 1
    end
    local msg = stolen > 0 and ("Stole " .. stolen .. " plant(s)") or "No instant-steal targets nearby"
    stealStatusLbl.Text = string.format("Night: Yes  |  Targets: %d  |  %s", countStealTargets(), msg)
end

-- ================================================
-- MAIN LOOP
-- ================================================
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Position = UDim2.new(0, 0, 1, -24)
footer.BackgroundTransparency = 1
footer.Text = "GAG2 Hub v3"
footer.TextColor3 = Color3.fromRGB(60, 60, 90)
footer.TextSize = 10
footer.Font = Enum.Font.Gotham
footer.Parent = main

task.spawn(function()
    task.wait(0.5)
    updateSellStatusLabel()
end)

lp.CharacterAdded:Connect(function()
    if walkFlingEnabled then
        task.wait(0.5)
        startWalkFling()
    end
end)

RunService.Heartbeat:Connect(function()
    local stats = lp:FindFirstChild("leaderstats")
    local sheckles = stats and stats:FindFirstChild("Sheckles")
    if sheckles then
        shecklesLbl.Text = fmtSheckles(sheckles.Value) .. " Sheckles"
    end

    tryAutoBuySeeds()
    tryAutoBuyGear()
    tryAutoHarvest()
    tryAutoSteal()
    tryAutoSellFull()
    tryAutoSellInterval()

    if not autoHarvestEnabled and harvestStatusLbl then
        local ready = countHarvestable()
        if isBackpackFull() then
            harvestStatusLbl.Text = string.format("Ready: %d  |  Bag full (%s)", ready, formatBagStatus())
        else
            harvestStatusLbl.Text = string.format("Ready: %d  |  Status: Idle", ready)
        end
    end

    if not autoStealEnabled and stealStatusLbl then
        stealStatusLbl.Text = string.format("Night: %s  |  Targets: %d  |  Idle", isNight() and "Yes" or "No", countStealTargets())
    end
end)
