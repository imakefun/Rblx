-- MainHUD (client)
-- Manages all HUD elements: stat bars, sol counter, inventory hotbar, fuel gauge

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StatsUpdated = Remotes:WaitForChild("StatsUpdated")
local SolUpdated = Remotes:WaitForChild("SolUpdated")
local TimeUpdated = Remotes:WaitForChild("TimeUpdated")
local InventoryUpdated = Remotes:WaitForChild("InventoryUpdated")
local SignalFireUpdated = Remotes:WaitForChild("SignalFireUpdated")
local NotifyClient = Remotes:WaitForChild("NotifyClient")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

------------------------------------------------------------------------
-- STAT BARS (top-left)
------------------------------------------------------------------------
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(0, 220, 0, 140)
statsFrame.Position = UDim2.new(0, 15, 0, 15)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
statsFrame.BackgroundTransparency = 0.3
statsFrame.Parent = screenGui

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

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
	label.Position = UDim2.new(0, 0, 0, 0)
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

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

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
local solFrame = Instance.new("Frame")
solFrame.Name = "SolFrame"
solFrame.Size = UDim2.new(0, 160, 0, 50)
solFrame.Position = UDim2.new(0.5, -80, 0, 10)
solFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
solFrame.BackgroundTransparency = 0.3
solFrame.Parent = screenGui

local solCorner = Instance.new("UICorner")
solCorner.CornerRadius = UDim.new(0, 8)
solCorner.Parent = solFrame

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
-- SIGNAL FIRE FUEL (top-right)
------------------------------------------------------------------------
local fuelFrame = Instance.new("Frame")
fuelFrame.Name = "FuelFrame"
fuelFrame.Size = UDim2.new(0, 180, 0, 50)
fuelFrame.Position = UDim2.new(1, -195, 0, 15)
fuelFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
fuelFrame.BackgroundTransparency = 0.3
fuelFrame.Parent = screenGui

local fuelCorner = Instance.new("UICorner")
fuelCorner.CornerRadius = UDim.new(0, 8)
fuelCorner.Parent = fuelFrame

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

local fuelBarCorner = Instance.new("UICorner")
fuelBarCorner.CornerRadius = UDim.new(0, 4)
fuelBarCorner.Parent = fuelBarBg

local fuelFill = Instance.new("Frame")
fuelFill.Name = "Fill"
fuelFill.Size = UDim2.new(0.5, 0, 1, 0)
fuelFill.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
fuelFill.Parent = fuelBarBg

local fuelFillCorner = Instance.new("UICorner")
fuelFillCorner.CornerRadius = UDim.new(0, 4)
fuelFillCorner.Parent = fuelFill

------------------------------------------------------------------------
-- INVENTORY HOTBAR (bottom-center)
------------------------------------------------------------------------
local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "Hotbar"
hotbarFrame.Size = UDim2.new(0, 440, 0, 55)
hotbarFrame.Position = UDim2.new(0.5, -220, 1, -70)
hotbarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hotbarFrame.BackgroundTransparency = 0.3
hotbarFrame.Parent = screenGui

local hotbarCorner = Instance.new("UICorner")
hotbarCorner.CornerRadius = UDim.new(0, 8)
hotbarCorner.Parent = hotbarFrame

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

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot

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
-- SHIP COMPONENT TRACKER (below sol counter)
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
-- UPDATE FUNCTIONS
------------------------------------------------------------------------

local function updateStatBar(bar, value: number, maxValue: number)
	local pct = math.clamp(value / maxValue, 0, 1)
	bar.fill.Size = UDim2.new(pct, 0, 1, 0)
	bar.label.Text = tostring(math.floor(value))
end

local function showNotification(text: string, duration: number?)
	notifLabel.Text = text
	notifLabel.TextTransparency = 0
	task.delay(duration or 3, function()
		-- Fade out
		for i = 0, 10 do
			notifLabel.TextTransparency = i / 10
			task.wait(0.05)
		end
	end)
end

local currentInventory = {}

local function updateHotbar(inventory: { [string]: number })
	currentInventory = inventory

	-- Convert inventory dict to array for hotbar display
	local items = {}
	for itemId, count in inventory do
		if count > 0 then
			table.insert(items, { id = itemId, count = count })
		end
	end

	-- Sort by category then name
	table.sort(items, function(a, b)
		return a.id < b.id
	end)

	for i = 1, 8 do
		local slot = hotbarSlots[i]
		local item = items[i]
		if item then
			slot.itemLabel.Text = item.id
			slot.countLabel.Text = "x" .. item.count
			slot.frame.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
		else
			slot.itemLabel.Text = ""
			slot.countLabel.Text = ""
			slot.frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end
	end
end

------------------------------------------------------------------------
-- EVENT CONNECTIONS
------------------------------------------------------------------------

StatsUpdated.OnClientEvent:Connect(function(stats)
	updateStatBar(healthBar, stats.Health, 100)
	updateStatBar(hungerBar, stats.Hunger, 100)
	updateStatBar(oxygenBar, stats.Oxygen, 100)
	updateStatBar(staminaBar, stats.Stamina, 100)
end)

SolUpdated.OnClientEvent:Connect(function(sol: number)
	solLabel.Text = "SOL " .. sol
	showNotification("Sol " .. sol, 4)
end)

TimeUpdated.OnClientEvent:Connect(function(phase: string, sol: number)
	if phase == "Night" then
		timeLabel.Text = "Night"
		timeLabel.TextColor3 = Color3.fromRGB(150, 100, 200)
		showNotification("Night falls...", 3)
	else
		timeLabel.Text = "Day"
		timeLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
	end
end)

InventoryUpdated.OnClientEvent:Connect(function(inventory)
	updateHotbar(inventory)
end)

SignalFireUpdated.OnClientEvent:Connect(function(fireState)
	local pct = fireState.fuel / fireState.maxFuel
	fuelFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)

	-- Color shift: green → yellow → red based on fuel
	if pct > 0.5 then
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
	elseif pct > 0.2 then
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 120, 30)
	else
		fuelFill.BackgroundColor3 = Color3.fromRGB(255, 50, 30)
	end

	fuelTitle.Text = "Signal Fire (Lv " .. fireState.level .. ")"
end)

NotifyClient.OnClientEvent:Connect(function(notifType: string, message: string)
	showNotification(message, 5)
end)

print("[MainHUD] HUD initialized")
