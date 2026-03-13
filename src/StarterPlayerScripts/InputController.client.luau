-- InputController.client.luau
-- Handles player input: sprinting, resource gathering, fuel adding, eating

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GatherResource = Remotes:WaitForChild("GatherResource")
local AddFuel = Remotes:WaitForChild("AddFuel")
local EatFood = Remotes:WaitForChild("EatFood")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Sprint state
local isSprinting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Shift to sprint
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
	end

	-- E to interact (gather resource / add fuel)
	if input.KeyCode == Enum.KeyCode.E then
		local character = player.Character
		if not character then return end
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		-- Find nearest interactable
		local nearestDist = 15
		local nearestTarget = nil

		-- Check Signal Fire (for fueling)
		local signalFire = workspace:FindFirstChild("SignalFire")
		if signalFire then
			local dist = (rootPart.Position - signalFire.Position).Magnitude
			if dist < 10 then
				-- Add fuel: use first available fuel item
				local fuelPriority = { "PlasmaCore", "BatteryCell", "Coal", "Wood" }
				for _, fuelId in fuelPriority do
					-- We'll try adding fuel — the server validates
					AddFuel:FireServer(fuelId)
					break
				end
				return
			end
		end

		-- Check resources
		local resources = workspace:FindFirstChild("Resources")
		if resources then
			for _, resource in resources:GetChildren() do
				if resource:GetAttribute("Depleted") then continue end

				local dist = (rootPart.Position - resource.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestTarget = resource
				end
			end
		end

		if nearestTarget then
			GatherResource:FireServer(nearestTarget.Name)
		end
	end

	-- F to eat food
	if input.KeyCode == Enum.KeyCode.F then
		-- Eat best food available
		local foodPriority = { "CookedMeat", "Berries", "RawMeat" }
		for _, foodId in foodPriority do
			EatFood:FireServer(foodId)
			break
		end
	end

	-- Number keys for hotbar selection (1-8)
	local keyNumber = tonumber(input.KeyCode.Name)
	if keyNumber and keyNumber >= 1 and keyNumber <= 8 then
		-- TODO: equip item from hotbar slot
		print("[Input] Selected hotbar slot", keyNumber)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
	end
end)

-- Sprint handling: update server with sprint state
local SprintUpdate = Remotes:FindFirstChild("SprintUpdate")
if not SprintUpdate then
	-- Create it if it doesn't exist yet (the server may create it)
	-- For now, handle sprint locally via humanoid speed
end

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Client-side sprint prediction (server is authoritative but this feels responsive)
	if isSprinting and humanoid.MoveDirection.Magnitude > 0 then
		humanoid.WalkSpeed = 16 * Config.SPRINT_SPEED_MULT
	else
		humanoid.WalkSpeed = 16
	end
end)

------------------------------------------------------------------------
-- INTERACTION PROMPT (shows "Press E" near resources)
------------------------------------------------------------------------
local promptGui = Instance.new("BillboardGui")
promptGui.Name = "InteractPrompt"
promptGui.Size = UDim2.new(0, 120, 0, 30)
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

	-- Find nearest interactable for prompt
	local nearestDist = 12
	local nearestTarget = nil
	local promptText = "[E] Gather"

	-- Check Signal Fire
	local signalFire = workspace:FindFirstChild("SignalFire")
	if signalFire then
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

			local dist = (rootPart.Position - resource.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestTarget = resource

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
