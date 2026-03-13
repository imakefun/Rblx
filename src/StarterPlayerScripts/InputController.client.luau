--!strict
-- InputController.client.luau
-- Handles player input: sprinting, resource gathering, fuel adding, eating,
-- combat, hotbar equipping, crafting toggle, ship part collection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkClient = require(script.Parent:WaitForChild("NetworkClient"))

-- Sprint state
local isSprinting = false

-- Hotbar state (synced from server inventory updates)
local hotbarItems: { { id: string, count: number } } = {}
local selectedSlot: number = 1

-- Update hotbar mapping from inventory
local function rebuildHotbar(inventory: { [string]: number })
	hotbarItems = {}
	for itemId, count in inventory do
		if count > 0 then
			table.insert(hotbarItems, { id = itemId, count = count })
		end
	end
	table.sort(hotbarItems, function(a, b) return a.id < b.id end)
end

-- Listen for inventory updates to keep hotbar in sync
NetworkClient.OnServerEvent("InventoryUpdated", function(inventory: any)
	if typeof(inventory) == "table" then
		rebuildHotbar(inventory)
	end
end)

-- Load initial inventory
task.spawn(function()
	local inv = NetworkClient.InvokeServerAsync("GetInventory")
	if inv then
		rebuildHotbar(inv)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Shift to sprint
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
	end

	-- Left click to melee attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		NetworkClient.FireServer("MeleeAttack")
	end

	-- E to interact (gather resource / add fuel / collect ship part)
	if input.KeyCode == Enum.KeyCode.E then
		local character = player.Character
		if not character then return end
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		-- Check ship parts first
		local shipParts = workspace:FindFirstChild("ShipParts")
		if shipParts then
			local nearestShipPart: BasePart? = nil
			local nearestShipDist = 8
			for _, part in shipParts:GetChildren() do
				if not part:IsA("BasePart") then continue end
				local dist = (rootPart.Position - (part :: BasePart).Position).Magnitude
				if dist < nearestShipDist then
					nearestShipDist = dist
					nearestShipPart = part :: BasePart
				end
			end
			if nearestShipPart then
				local partId = nearestShipPart:GetAttribute("ShipPartId")
				if partId then
					NetworkClient.FireServer("CollectShipPart", partId)
					return
				end
			end
		end

		-- Check Signal Fire (for fueling)
		local signalFire = workspace:FindFirstChild("SignalFire")
		if signalFire then
			local dist = (rootPart.Position - signalFire.Position).Magnitude
			if dist < 10 then
				local fuelPriority = { "PlasmaCore", "BatteryCell", "Coal", "Wood" }
				for _, fuelId in fuelPriority do
					NetworkClient.FireServer("AddFuel", fuelId)
					break
				end
				return
			end
		end

		-- Check resources
		local nearestDist = 15
		local nearestTarget: Instance? = nil
		local resources = workspace:FindFirstChild("Resources")
		if resources then
			for _, resource in resources:GetChildren() do
				if resource:GetAttribute("Depleted") then continue end
				if not resource:IsA("BasePart") then continue end

				local dist = (rootPart.Position - (resource :: BasePart).Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestTarget = resource
				end
			end
		end

		if nearestTarget then
			NetworkClient.FireServer("GatherResource", nearestTarget.Name)
		end
	end

	-- F to eat food
	if input.KeyCode == Enum.KeyCode.F then
		local foodPriority = { "CookedMeat", "Berries", "RawMeat" }
		for _, foodId in foodPriority do
			NetworkClient.FireServer("EatFood", foodId)
			break
		end
	end

	-- C to toggle crafting UI
	if input.KeyCode == Enum.KeyCode.C then
		local screenGui = player.PlayerGui:FindFirstChild("MainHUD")
		if screenGui then
			local craftPanel = screenGui:FindFirstChild("CraftingPanel")
			if craftPanel then
				craftPanel.Visible = not craftPanel.Visible
			end
		end
	end

	-- Tab to toggle full inventory
	if input.KeyCode == Enum.KeyCode.Tab then
		local screenGui = player.PlayerGui:FindFirstChild("MainHUD")
		if screenGui then
			local invPanel = screenGui:FindFirstChild("InventoryPanel")
			if invPanel then
				invPanel.Visible = not invPanel.Visible
			end
		end
	end

	-- Number keys for hotbar selection (1-8)
	local keyNumber = tonumber(input.KeyCode.Name)
	if keyNumber and keyNumber >= 1 and keyNumber <= 8 then
		selectedSlot = keyNumber

		local item = hotbarItems[keyNumber]
		if item then
			local itemDef = Config.ITEMS[item.id]
			if itemDef and itemDef.category == "Tool" then
				NetworkClient.FireServer("EquipTool", item.id)
			end
		end
	end

	-- Q to unequip current tool
	if input.KeyCode == Enum.KeyCode.Q then
		NetworkClient.FireServer("UnequipTool")
	end
end)

UserInputService.InputEnded:Connect(function(input, _gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
	end
end)

-- Sprint handling: notify server of sprint state changes.
local lastSprintState = false

RunService.Heartbeat:Connect(function(_dt)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local wantSprint = isSprinting and humanoid.MoveDirection.Magnitude > 0

	if wantSprint ~= lastSprintState then
		lastSprintState = wantSprint
		NetworkClient.FireServer("SetSprinting", wantSprint)
	end

	-- Client-side prediction for instant responsiveness
	if wantSprint then
		humanoid.WalkSpeed = 16 * Config.SPRINT_SPEED_MULT
	else
		humanoid.WalkSpeed = 16
	end
end)

------------------------------------------------------------------------
-- INTERACTION PROMPT (shows context-sensitive prompt near interactables)
------------------------------------------------------------------------
local promptGui = Instance.new("BillboardGui")
promptGui.Name = "InteractPrompt"
promptGui.Size = UDim2.new(0, 140, 0, 30)
promptGui.StudsOffset = Vector3.new(0, 3, 0)
promptGui.AlwaysOnTop = true
promptGui.Enabled = false

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, 0, 1, 0)
promptLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
promptLabel.BackgroundTransparency = 0.3
promptLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
promptLabel.TextSize = 14
promptLabel.Font = Enum.Font.GothamBold
promptLabel.Text = "[E] Gather"

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = UDim.new(0, 6)
promptCorner.Parent = promptLabel

promptLabel.Parent = promptGui
promptGui.Parent = player.PlayerGui

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then
		promptGui.Enabled = false
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		promptGui.Enabled = false
		return
	end

	local nearestDist = 12
	local nearestTarget: BasePart? = nil
	local promptText = "[E] Gather"

	-- Check ship parts
	local shipParts = workspace:FindFirstChild("ShipParts")
	if shipParts then
		for _, part in shipParts:GetChildren() do
			if not part:IsA("BasePart") then continue end
			local dist = (rootPart.Position - (part :: BasePart).Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestTarget = part :: BasePart
				local dName = part:GetAttribute("DisplayName") or "Ship Part"
				promptText = `[E] Collect {dName}`
			end
		end
	end

	-- Check Signal Fire
	local signalFire = workspace:FindFirstChild("SignalFire")
	if signalFire and signalFire:IsA("BasePart") then
		local dist = (rootPart.Position - signalFire.Position).Magnitude
		if dist < 10 and dist < nearestDist then
			nearestDist = dist
			nearestTarget = signalFire
			promptText = "[E] Add Fuel"
		end
	end

	-- Check resources
	local resources = workspace:FindFirstChild("Resources")
	if resources then
		for _, resource in resources:GetChildren() do
			if resource:GetAttribute("Depleted") then continue end
			if not resource:IsA("BasePart") then continue end

			local dist = (rootPart.Position - (resource :: BasePart).Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestTarget = resource :: BasePart

				local resType = resource:GetAttribute("ResourceType")
				if resType == "Tree" then
					promptText = "[E] Chop Tree"
				elseif resType == "Rock" then
					promptText = "[E] Mine Rock"
				elseif resType == "Bush" then
					promptText = "[E] Pick Berries"
				elseif resType == "CrashDebris" then
					promptText = "[E] Salvage"
				end
			end
		end
	end

	if nearestTarget then
		promptGui.Adornee = nearestTarget
		promptLabel.Text = promptText
		promptGui.Enabled = true
	else
		promptGui.Enabled = false
	end
end)

print("[InputController] Input system initialized")
