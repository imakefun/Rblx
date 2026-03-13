--!strict
-- MainHUD (client)
-- Manages all HUD elements: stat bars, sol counter, inventory hotbar, fuel gauge,
-- full inventory panel, crafting panel, ship part tracker, combat feedback.
--
-- STAT READING PATTERN:
--   Stats are replicated via Player ATTRIBUTES (auto-sync from server).
--   Bulk data (inventory, notifications) uses NetworkClient RemoteEvent routing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterPlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemData"))
local NetworkClient = require(StarterPlayerScripts:WaitForChild("NetworkClient"))

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

------------------------------------------------------------------------
-- HELPER: create rounded frame
------------------------------------------------------------------------
local function makePanel(name: string, size: UDim2, pos: UDim2, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	f.BackgroundTransparency = 0.3
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = f
	return f
end

------------------------------------------------------------------------
-- STAT BARS (top-left)
------------------------------------------------------------------------
local statsFrame = makePanel("StatsFrame", UDim2.new(0, 220, 0, 140), UDim2.new(0, 15, 0, 15), screenGui)

local statsPadding = Instance.new("UIPadding")
statsPadding.PaddingLeft = UDim.new(0, 10)
statsPadding.PaddingTop = UDim.new(0, 8)
statsPadding.PaddingRight = UDim.new(0, 10)
statsPadding.Parent = statsFrame

local statsLayout = Instance.new("UIListLayout")
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 4)
statsLayout.Parent = statsFrame

local function createStatBar(name: string, color: Color3, order: number): { label: TextLabel, fill: Frame }
	local container = Instance.new("Frame")
	container.Name = name .. "Container"
	container.Size = UDim2.new(1, 0, 0, 26)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = statsFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 55, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -60, 0, 16)
	barBg.Position = UDim2.new(0, 60, 0.5, -8)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	barBg.Parent = container
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "100"
	valueLabel.TextColor3 = Color3.new(1, 1, 1)
	valueLabel.TextSize = 11
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Parent = barBg

	return { label = valueLabel, fill = fill }
end

local healthBar = createStatBar("HP", Color3.fromRGB(220, 50, 50), 1)
local hungerBar = createStatBar("Food", Color3.fromRGB(200, 160, 40), 2)
local oxygenBar = createStatBar("O2", Color3.fromRGB(80, 160, 255), 3)
local staminaBar = createStatBar("Run", Color3.fromRGB(80, 220, 80), 4)

------------------------------------------------------------------------
-- SOL COUNTER (top-center)
------------------------------------------------------------------------
local solFrame = makePanel("SolFrame", UDim2.new(0, 160, 0, 50), UDim2.new(0.5, -80, 0, 10), screenGui)

local solLabel = Instance.new("TextLabel")
solLabel.Name = "SolLabel"
solLabel.Size = UDim2.new(1, 0, 0.5, 0)
solLabel.BackgroundTransparency = 1
solLabel.Text = "SOL 1"
solLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
solLabel.TextSize = 22
solLabel.Font = Enum.Font.GothamBold
solLabel.Parent = solFrame

local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(1, 0, 0.5, 0)
timeLabel.Position = UDim2.new(0, 0, 0.5, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "Day"
timeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
timeLabel.TextSize = 14
timeLabel.Font = Enum.Font.Gotham
timeLabel.Parent = solFrame

------------------------------------------------------------------------
-- SHIP PART TRACKER (below sol counter)
------------------------------------------------------------------------
local shipFrame = Instance.new("TextLabel")
shipFrame.Name = "ShipTracker"
shipFrame.Size = UDim2.new(0, 160, 0, 20)
shipFrame.Position = UDim2.new(0.5, -80, 0, 65)
shipFrame.BackgroundTransparency = 1
shipFrame.Text = "Ship Parts: 0/6"
shipFrame.TextColor3 = Color3.fromRGB(140, 180, 220)
shipFrame.TextSize = 12
shipFrame.Font = Enum.Font.Gotham
shipFrame.Parent = screenGui

------------------------------------------------------------------------
-- SIGNAL FIRE FUEL (top-right)
------------------------------------------------------------------------
local fuelFrame = makePanel("FuelFrame", UDim2.new(0, 180, 0, 50), UDim2.new(1, -195, 0, 15), screenGui)

local fuelTitle = Instance.new("TextLabel")
fuelTitle.Size = UDim2.new(1, 0, 0, 16)
fuelTitle.Position = UDim2.new(0, 0, 0, 4)
fuelTitle.BackgroundTransparency = 1
fuelTitle.Text = "Signal Fire"
fuelTitle.TextColor3 = Color3.fromRGB(255, 170, 80)
fuelTitle.TextSize = 12
fuelTitle.Font = Enum.Font.GothamBold
fuelTitle.Parent = fuelFrame

local fuelBarBg = Instance.new("Frame")
fuelBarBg.Size = UDim2.new(0.85, 0, 0, 14)
fuelBarBg.Position = UDim2.new(0.075, 0, 0, 26)
fuelBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
fuelBarBg.Parent = fuelFrame
Instance.new("UICorner", fuelBarBg).CornerRadius = UDim.new(0, 4)

local fuelFill = Instance.new("Frame")
fuelFill.Name = "Fill"
fuelFill.Size = UDim2.new(0.5, 0, 1, 0)
fuelFill.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
fuelFill.Parent = fuelBarBg
Instance.new("UICorner", fuelFill).CornerRadius = UDim.new(0, 4)

------------------------------------------------------------------------
-- INVENTORY HOTBAR (bottom-center)
------------------------------------------------------------------------
local hotbarFrame = makePanel("Hotbar", UDim2.new(0, 440, 0, 55), UDim2.new(0.5, -220, 1, -70), screenGui)

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 4)
hotbarLayout.Parent = hotbarFrame

local hotbarSlots = {}
for i = 1, 8 do
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.Size = UDim2.new(0, 48, 0, 48)
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	slot.Parent = hotbarFrame
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)

	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemLabel"
	itemLabel.Size = UDim2.new(1, 0, 0.65, 0)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Text = ""
	itemLabel.TextColor3 = Color3.new(1, 1, 1)
	itemLabel.TextSize = 10
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextWrapped = true
	itemLabel.Parent = slot

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "CountLabel"
	countLabel.Size = UDim2.new(1, -4, 0, 14)
	countLabel.Position = UDim2.new(0, 2, 1, -16)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	countLabel.TextSize = 10
	countLabel.Font = Enum.Font.Gotham
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Parent = slot

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(0, 14, 0, 14)
	keyLabel.Position = UDim2.new(0, 2, 0, 2)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = tostring(i)
	keyLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
	keyLabel.TextSize = 10
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Parent = slot

	hotbarSlots[i] = { frame = slot, itemLabel = itemLabel, countLabel = countLabel }
end

------------------------------------------------------------------------
-- NOTIFICATION AREA (center screen)
------------------------------------------------------------------------
local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Notification"
notifLabel.Size = UDim2.new(0, 400, 0, 50)
notifLabel.Position = UDim2.new(0.5, -200, 0.3, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
notifLabel.TextSize = 24
notifLabel.Font = Enum.Font.GothamBold
notifLabel.TextTransparency = 1
notifLabel.Parent = screenGui

------------------------------------------------------------------------
-- DAMAGE FEEDBACK (red flash on screen edges)
------------------------------------------------------------------------
local damageFlash = Instance.new("Frame")
damageFlash.Name = "DamageFlash"
damageFlash.Size = UDim2.new(1, 0, 1, 0)
damageFlash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
damageFlash.BackgroundTransparency = 1
damageFlash.ZIndex = 100
damageFlash.Parent = screenGui

------------------------------------------------------------------------
-- FULL INVENTORY PANEL (Tab to toggle)
------------------------------------------------------------------------
local invPanel = makePanel("InventoryPanel", UDim2.new(0, 340, 0, 400), UDim2.new(0.5, -380, 0.5, -200), screenGui)
invPanel.Visible = false

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 30)
invTitle.BackgroundTransparency = 1
invTitle.Text = "Inventory [Tab]"
invTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
invTitle.TextSize = 16
invTitle.Font = Enum.Font.GothamBold
invTitle.Parent = invPanel

local invScroll = Instance.new("ScrollingFrame")
invScroll.Size = UDim2.new(1, -16, 1, -38)
invScroll.Position = UDim2.new(0, 8, 0, 34)
invScroll.BackgroundTransparency = 1
invScroll.ScrollBarThickness = 4
invScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
invScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
invScroll.Parent = invPanel

local invLayout = Instance.new("UIListLayout")
invLayout.SortOrder = Enum.SortOrder.LayoutOrder
invLayout.Padding = UDim.new(0, 3)
invLayout.Parent = invScroll

------------------------------------------------------------------------
-- CRAFTING PANEL (C to toggle)
------------------------------------------------------------------------
local craftPanel = makePanel("CraftingPanel", UDim2.new(0, 340, 0, 420), UDim2.new(0.5, 40, 0.5, -210), screenGui)
craftPanel.Visible = false

local craftTitle = Instance.new("TextLabel")
craftTitle.Size = UDim2.new(1, 0, 0, 30)
craftTitle.BackgroundTransparency = 1
craftTitle.Text = "Crafting [C]"
craftTitle.TextColor3 = Color3.fromRGB(255, 170, 80)
craftTitle.TextSize = 16
craftTitle.Font = Enum.Font.GothamBold
craftTitle.Parent = craftPanel

local craftScroll = Instance.new("ScrollingFrame")
craftScroll.Size = UDim2.new(1, -16, 1, -38)
craftScroll.Position = UDim2.new(0, 8, 0, 34)
craftScroll.BackgroundTransparency = 1
craftScroll.ScrollBarThickness = 4
craftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
craftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
craftScroll.Parent = craftPanel

local craftLayout = Instance.new("UIListLayout")
craftLayout.SortOrder = Enum.SortOrder.LayoutOrder
craftLayout.Padding = UDim.new(0, 3)
craftLayout.Parent = craftScroll

------------------------------------------------------------------------
-- CRAFTING PROGRESS BAR (visible during crafting)
------------------------------------------------------------------------
local craftProgressFrame = makePanel("CraftProgress", UDim2.new(0, 200, 0, 30), UDim2.new(0.5, -100, 0.75, 0), screenGui)
craftProgressFrame.Visible = false

local craftProgressFill = Instance.new("Frame")
craftProgressFill.Size = UDim2.new(0, 0, 1, 0)
craftProgressFill.BackgroundColor3 = Color3.fromRGB(255, 170, 80)
craftProgressFill.Parent = craftProgressFrame
Instance.new("UICorner", craftProgressFill).CornerRadius = UDim.new(0, 8)

local craftProgressLabel = Instance.new("TextLabel")
craftProgressLabel.Size = UDim2.new(1, 0, 1, 0)
craftProgressLabel.BackgroundTransparency = 1
craftProgressLabel.Text = "Crafting..."
craftProgressLabel.TextColor3 = Color3.new(1, 1, 1)
craftProgressLabel.TextSize = 13
craftProgressLabel.Font = Enum.Font.GothamBold
craftProgressLabel.ZIndex = 2
craftProgressLabel.Parent = craftProgressFrame

------------------------------------------------------------------------
-- RAID WARNING BANNER
------------------------------------------------------------------------
local raidBanner = Instance.new("TextLabel")
raidBanner.Name = "RaidBanner"
raidBanner.Size = UDim2.new(0.4, 0, 0, 35)
raidBanner.Position = UDim2.new(0.3, 0, 0.12, 0)
raidBanner.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
raidBanner.BackgroundTransparency = 0.3
raidBanner.Text = "KETHARI RAID IN PROGRESS"
raidBanner.TextColor3 = Color3.fromRGB(255, 100, 100)
raidBanner.TextSize = 16
raidBanner.Font = Enum.Font.GothamBold
raidBanner.Visible = false
raidBanner.Parent = screenGui
Instance.new("UICorner", raidBanner).CornerRadius = UDim.new(0, 8)

------------------------------------------------------------------------
-- CONTROLS HINT (bottom-left, shows keybindings)
------------------------------------------------------------------------
local controlsLabel = Instance.new("TextLabel")
controlsLabel.Name = "Controls"
controlsLabel.Size = UDim2.new(0, 200, 0, 100)
controlsLabel.Position = UDim2.new(0, 15, 1, -115)
controlsLabel.BackgroundTransparency = 1
controlsLabel.Text = "[E] Interact  [F] Eat\n[C] Craft  [Tab] Inventory\n[1-8] Hotbar  [Q] Unequip\n[Shift] Sprint  [Click] Attack"
controlsLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
controlsLabel.TextSize = 11
controlsLabel.Font = Enum.Font.Gotham
controlsLabel.TextXAlignment = Enum.TextXAlignment.Left
controlsLabel.TextYAlignment = Enum.TextYAlignment.Bottom
controlsLabel.Parent = screenGui

------------------------------------------------------------------------
-- UPDATE FUNCTIONS
------------------------------------------------------------------------

local function updateStatBar(bar: { label: TextLabel, fill: Frame }, value: number, maxValue: number)
	local pct = math.clamp(value / maxValue, 0, 1)
	bar.fill.Size = UDim2.new(pct, 0, 1, 0)
	bar.label.Text = tostring(math.floor(value))
end

local function showNotification(text: string, duration: number?)
	notifLabel.Text = text
	notifLabel.TextTransparency = 0
	task.delay(duration or 3, function()
		for i = 0, 10 do
			notifLabel.TextTransparency = i / 10
			task.wait(0.05)
		end
	end)
end

local function flashDamage()
	damageFlash.BackgroundTransparency = 0.6
	TweenService:Create(damageFlash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()
end

local currentInventory: { [string]: number } = {}

local function updateHotbar(inventory: { [string]: number })
	currentInventory = inventory

	local items = {}
	for itemId, count in inventory do
		if count > 0 then
			table.insert(items, { id = itemId, count = count })
		end
	end

	table.sort(items, function(a, b) return a.id < b.id end)

	for i = 1, 8 do
		local slot = hotbarSlots[i]
		local item = items[i]
		if item then
			local itemDef = Config.ITEMS[item.id]
			slot.itemLabel.Text = if itemDef then itemDef.displayName else item.id
			slot.countLabel.Text = "x" .. item.count
			slot.frame.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
		else
			slot.itemLabel.Text = ""
			slot.countLabel.Text = ""
			slot.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end
	end
end

-- Update full inventory panel
local function updateInventoryPanel(inventory: { [string]: number })
	for _, child in invScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local items = {}
	for itemId, count in inventory do
		if count > 0 then
			table.insert(items, { id = itemId, count = count })
		end
	end
	table.sort(items, function(a, b) return a.id < b.id end)

	for idx, item in items do
		local itemDef = Config.ITEMS[item.id]
		local row = Instance.new("Frame")
		row.Name = "Item_" .. item.id
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = if idx % 2 == 0 then Color3.fromRGB(35, 35, 50) else Color3.fromRGB(28, 28, 42)
		row.BackgroundTransparency = 0.3
		row.LayoutOrder = idx
		row.Parent = invScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = if itemDef then itemDef.displayName else item.id
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 12
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local catLabel = Instance.new("TextLabel")
		catLabel.Size = UDim2.new(0.25, 0, 1, 0)
		catLabel.Position = UDim2.new(0.5, 0, 0, 0)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = if itemDef then itemDef.category else ""
		catLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
		catLabel.TextSize = 11
		catLabel.Font = Enum.Font.Gotham
		catLabel.Parent = row

		local countLbl = Instance.new("TextLabel")
		countLbl.Size = UDim2.new(0.2, -8, 1, 0)
		countLbl.Position = UDim2.new(0.8, 0, 0, 0)
		countLbl.BackgroundTransparency = 1
		countLbl.Text = "x" .. item.count
		countLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		countLbl.TextSize = 12
		countLbl.Font = Enum.Font.GothamBold
		countLbl.TextXAlignment = Enum.TextXAlignment.Right
		countLbl.Parent = row

		-- Use button for consumables
		if itemDef and (itemDef.hungerRestore or itemDef.category == "Food") then
			local useBtn = Instance.new("TextButton")
			useBtn.Size = UDim2.new(0, 40, 0, 22)
			useBtn.Position = UDim2.new(0.72, 0, 0.5, -11)
			useBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
			useBtn.Text = "Use"
			useBtn.TextColor3 = Color3.new(1, 1, 1)
			useBtn.TextSize = 10
			useBtn.Font = Enum.Font.GothamBold
			useBtn.Parent = row
			Instance.new("UICorner", useBtn).CornerRadius = UDim.new(0, 4)
			useBtn.MouseButton1Click:Connect(function()
				NetworkClient.FireServer("UseItem", item.id)
			end)
		end
	end
end

-- Update crafting panel recipes
local function updateCraftingPanel(inventory: { [string]: number })
	for _, child in craftScroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for idx, recipe in ItemData.Recipes do
		local row = Instance.new("Frame")
		row.Name = "Recipe_" .. recipe.id
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		row.BackgroundTransparency = 0.2
		row.LayoutOrder = idx
		row.Parent = craftScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		-- Tier badge
		local tierBadge = Instance.new("TextLabel")
		tierBadge.Size = UDim2.new(0, 18, 0, 18)
		tierBadge.Position = UDim2.new(0, 4, 0, 4)
		tierBadge.BackgroundColor3 = if recipe.tier == 1 then Color3.fromRGB(80, 160, 80)
			elseif recipe.tier == 2 then Color3.fromRGB(80, 120, 200)
			else Color3.fromRGB(180, 80, 200)
		tierBadge.Text = tostring(recipe.tier)
		tierBadge.TextColor3 = Color3.new(1, 1, 1)
		tierBadge.TextSize = 11
		tierBadge.Font = Enum.Font.GothamBold
		tierBadge.Parent = row
		Instance.new("UICorner", tierBadge).CornerRadius = UDim.new(0, 4)

		-- Recipe name
		local recipeName = Instance.new("TextLabel")
		recipeName.Size = UDim2.new(0.55, 0, 0, 20)
		recipeName.Position = UDim2.new(0, 28, 0, 2)
		recipeName.BackgroundTransparency = 1
		recipeName.Text = recipe.displayName
		recipeName.TextColor3 = Color3.new(1, 1, 1)
		recipeName.TextSize = 13
		recipeName.Font = Enum.Font.GothamBold
		recipeName.TextXAlignment = Enum.TextXAlignment.Left
		recipeName.Parent = row

		-- Ingredients list
		local ingredientParts = {}
		local canMake = true
		for _, ing in recipe.ingredients do
			local have = inventory[ing.item] or 0
			local need = ing.count
			local color = if have >= need then "white" else "red"
			local ingDef = Config.ITEMS[ing.item]
			local ingName = if ingDef then ingDef.displayName else ing.item
			table.insert(ingredientParts, `<font color="{color}">{ingName} {have}/{need}</font>`)
			if have < need then canMake = false end
		end

		local ingLabel = Instance.new("TextLabel")
		ingLabel.Size = UDim2.new(0.85, 0, 0, 16)
		ingLabel.Position = UDim2.new(0, 28, 0, 22)
		ingLabel.BackgroundTransparency = 1
		ingLabel.RichText = true
		ingLabel.Text = table.concat(ingredientParts, " | ")
		ingLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
		ingLabel.TextSize = 10
		ingLabel.Font = Enum.Font.Gotham
		ingLabel.TextXAlignment = Enum.TextXAlignment.Left
		ingLabel.TextWrapped = true
		ingLabel.Parent = row

		-- Craft time
		local timeInfo = Instance.new("TextLabel")
		timeInfo.Size = UDim2.new(0, 30, 0, 14)
		timeInfo.Position = UDim2.new(0, 28, 0, 40)
		timeInfo.BackgroundTransparency = 1
		timeInfo.Text = `{recipe.craftTime}s`
		timeInfo.TextColor3 = Color3.fromRGB(120, 120, 140)
		timeInfo.TextSize = 10
		timeInfo.Font = Enum.Font.Gotham
		timeInfo.TextXAlignment = Enum.TextXAlignment.Left
		timeInfo.Parent = row

		-- Craft button
		local craftBtn = Instance.new("TextButton")
		craftBtn.Size = UDim2.new(0, 55, 0, 26)
		craftBtn.Position = UDim2.new(1, -62, 0.5, -13)
		craftBtn.Text = "Craft"
		craftBtn.TextColor3 = Color3.new(1, 1, 1)
		craftBtn.TextSize = 12
		craftBtn.Font = Enum.Font.GothamBold
		craftBtn.Parent = row
		Instance.new("UICorner", craftBtn).CornerRadius = UDim.new(0, 4)

		if canMake then
			craftBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
			craftBtn.MouseButton1Click:Connect(function()
				NetworkClient.FireServer("StartCraft", recipe.id)
			end)
		else
			craftBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			craftBtn.AutoButtonColor = false
		end
	end
end

------------------------------------------------------------------------
-- STAT UPDATES VIA ATTRIBUTES
------------------------------------------------------------------------

local function readMaxStat(name: string): number
	return (player:GetAttribute("Max" .. name) :: number?) or 100
end

local function refreshStat(statName: string, bar: { label: TextLabel, fill: Frame })
	local value: number = (player:GetAttribute(statName) :: number?) or 0
	local maxValue: number = readMaxStat(statName)
	updateStatBar(bar, value, maxValue)
end

player:GetAttributeChangedSignal("Health"):Connect(function()
	refreshStat("Health", healthBar)
end)
player:GetAttributeChangedSignal("Hunger"):Connect(function()
	refreshStat("Hunger", hungerBar)
end)
player:GetAttributeChangedSignal("Oxygen"):Connect(function()
	refreshStat("Oxygen", oxygenBar)
end)
player:GetAttributeChangedSignal("Stamina"):Connect(function()
	refreshStat("Stamina", staminaBar)
end)

-- Read initial values
refreshStat("Health", healthBar)
refreshStat("Hunger", hungerBar)
refreshStat("Oxygen", oxygenBar)
refreshStat("Stamina", staminaBar)

------------------------------------------------------------------------
-- EVENT-BASED UPDATES VIA NetworkClient
------------------------------------------------------------------------

NetworkClient.OnServerEvent("SolUpdated", function(sol: any)
	if typeof(sol) ~= "number" then return end
	solLabel.Text = "SOL " .. sol
	showNotification("Sol " .. sol, 4)
end)

NetworkClient.OnServerEvent("TimePhaseChanged", function(phase: any, _sol: any)
	if typeof(phase) ~= "string" then return end
	if phase == "Night" then
		timeLabel.Text = "Night"
		timeLabel.TextColor3 = Color3.fromRGB(150, 100, 200)
		showNotification("Night falls...", 3)
	else
		timeLabel.Text = "Day"
		timeLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
	end
end)

NetworkClient.OnServerEvent("InventoryUpdated", function(inventory: any)
	if typeof(inventory) ~= "table" then return end
	updateHotbar(inventory)
	updateInventoryPanel(inventory)
	if craftPanel.Visible then
		updateCraftingPanel(inventory)
	end
end)

NetworkClient.OnServerEventUnreliable("SignalFireUpdated", function(fireState: any)
	if typeof(fireState) ~= "table" then return end
	local pct = fireState.fuel / fireState.maxFuel
	fuelFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)

	if pct > 0.5 then
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
	elseif pct > 0.2 then
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 120, 30)
	else
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
	end

	fuelTitle.Text = `Signal Fire (Lv {fireState.level})`
end)

NetworkClient.OnServerEvent("Notify", function(_notifType: any, message: any)
	if typeof(message) ~= "string" then return end
	showNotification(message, 5)
end)

NetworkClient.OnServerEvent("ToolEquipped", function(itemId: any)
	if typeof(itemId) ~= "string" then return end
	showNotification(`Equipped: {itemId}`, 2)
end)

NetworkClient.OnServerEvent("ToolUnequipped", function()
	showNotification("Unequipped tool", 2)
end)

-- Combat feedback
NetworkClient.OnServerEvent("DamageFeedback", function(_source: any, _damage: any)
	flashDamage()
end)

NetworkClient.OnServerEvent("HitConfirm", function(damage: any)
	if typeof(damage) ~= "number" then return end
	showNotification(`Hit! ({damage} dmg)`, 1.5)
end)

NetworkClient.OnServerEvent("AttackSwing", function(_tool: any)
	-- Visual feedback placeholder
end)

-- Crafting feedback
NetworkClient.OnServerEvent("CraftStarted", function(recipeId: any, craftTime: any)
	if typeof(recipeId) ~= "string" or typeof(craftTime) ~= "number" then return end
	craftProgressFrame.Visible = true
	craftProgressLabel.Text = `Crafting {recipeId}...`
	craftProgressFill.Size = UDim2.new(0, 0, 1, 0)

	TweenService:Create(craftProgressFill, TweenInfo.new(craftTime, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()
end)

NetworkClient.OnServerEvent("CraftCompleted", function(_recipeId: any)
	craftProgressFrame.Visible = false
	if craftPanel.Visible then
		updateCraftingPanel(currentInventory)
	end
end)

NetworkClient.OnServerEvent("CraftFailed", function(reason: any)
	if typeof(reason) ~= "string" then return end
	showNotification(`Craft failed: {reason}`, 3)
	craftProgressFrame.Visible = false
end)

NetworkClient.OnServerEvent("CraftCancelled", function()
	craftProgressFrame.Visible = false
end)

-- Ship parts
NetworkClient.OnServerEvent("ShipPartCollected", function(_partId: any, collected: any, total: any)
	if typeof(collected) ~= "number" or typeof(total) ~= "number" then return end
	shipFrame.Text = `Ship Parts: {collected}/{total}`
end)

-- Raid events
NetworkClient.OnServerEvent("RaidStarted", function(_count: any)
	raidBanner.Visible = true
end)

NetworkClient.OnServerEvent("RaidEnded", function()
	raidBanner.Visible = false
end)

-- Game won
NetworkClient.OnServerEvent("GameWon", function(_parts: any)
	showNotification("YOU ESCAPED! Congratulations!", 10)
end)

-- Pickup collected
NetworkClient.OnServerEvent("PickupCollected", function(itemId: any, count: any)
	if typeof(itemId) ~= "string" then return end
	local itemDef = Config.ITEMS[itemId]
	local dName = if itemDef then itemDef.displayName else itemId
	local cnt = if typeof(count) == "number" then count else 1
	showNotification(`Picked up: {dName} x{cnt}`, 2)
end)

-- Request initial data on startup
task.spawn(function()
	local inv = NetworkClient.InvokeServerAsync("GetInventory")
	if inv then
		updateHotbar(inv)
		updateInventoryPanel(inv)
	end

	local shipProgress = NetworkClient.InvokeServerAsync("GetShipProgress")
	if shipProgress and typeof(shipProgress) == "table" then
		shipFrame.Text = `Ship Parts: {shipProgress.collected or 0}/{shipProgress.total or 6}`
	end
end)

-- Refresh crafting panel when toggled visible
craftPanel:GetPropertyChangedSignal("Visible"):Connect(function()
	if craftPanel.Visible then
		updateCraftingPanel(currentInventory)
	end
end)

print("[MainHUD] HUD initialized")
