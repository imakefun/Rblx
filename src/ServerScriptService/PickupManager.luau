--!strict
-- PickupManager.luau
-- Manages world item pickups (dropped items that can be collected).
--
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local PickupManager = {}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

type Pickup = {
	model: BasePart,
	itemId: string,
	count: number,
	spawnTime: number,
}

local pickups: { Pickup } = {}
local pickupsFolder: Folder? = nil
local PICKUP_RANGE = 5
local PICKUP_LIFETIME = 180 -- 3 minutes before despawn
local nextPickupId = 1

-------------------------------------------------------------------------------
-- Create pickup in world
-------------------------------------------------------------------------------

function PickupManager.SpawnPickup(itemId: string, count: number, position: Vector3)
	if not pickupsFolder then
		pickupsFolder = workspace:FindFirstChild("Pickups") :: Folder?
		if not pickupsFolder then
			local folder = Instance.new("Folder")
			folder.Name = "Pickups"
			folder.Parent = workspace
			pickupsFolder = folder
		end
	end

	local itemDef = Config.ITEMS[itemId]
	local displayName = if itemDef then itemDef.displayName else itemId

	local part = Instance.new("Part")
	part.Name = "Pickup_" .. nextPickupId
	nextPickupId += 1
	part.Size = Vector3.new(1.5, 1.5, 1.5)
	part.Position = position + Vector3.new(math.random(-2, 2), 1, math.random(-2, 2))
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon

	-- Color based on category
	if itemDef then
		if itemDef.category == "Resource" then
			part.Color = Color3.fromRGB(100, 180, 100)
		elseif itemDef.category == "Food" then
			part.Color = Color3.fromRGB(200, 160, 40)
		elseif itemDef.category == "Fuel" then
			part.Color = Color3.fromRGB(255, 140, 40)
		elseif itemDef.category == "Tool" then
			part.Color = Color3.fromRGB(100, 160, 255)
		else
			part.Color = Color3.fromRGB(200, 200, 200)
		end
	else
		part.Color = Color3.fromRGB(200, 200, 200)
	end

	part:SetAttribute("ItemId", itemId)
	part:SetAttribute("Count", count)
	part:SetAttribute("DisplayName", `{displayName} x{count}`)

	-- Billboard label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.4
	label.Text = `{displayName} x{count}`
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label

	-- Glow
	local light = Instance.new("PointLight")
	light.Brightness = 0.5
	light.Range = 6
	light.Color = part.Color
	light.Parent = part

	part.Parent = pickupsFolder

	table.insert(pickups, {
		model = part,
		itemId = itemId,
		count = count,
		spawnTime = tick(),
	})
end

-------------------------------------------------------------------------------
-- Pickup collection (auto-collect when near)
-------------------------------------------------------------------------------

function PickupManager.Update(dt: number)
	local now = tick()
	local i = 1

	while i <= #pickups do
		local pickup = pickups[i]
		local remove = false

		-- Check lifetime
		if now - pickup.spawnTime > PICKUP_LIFETIME then
			remove = true
		elseif pickup.model.Parent then
			-- Check if any player is near enough to collect
			for _, player in Players:GetPlayers() do
				local character = player.Character
				if not character then continue end
				local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not rootPart then continue end

				local dist = (rootPart.Position - pickup.model.Position).Magnitude
				if dist <= PICKUP_RANGE then
					-- Collect!
					if PlayerManager.addItem(player, pickup.itemId, pickup.count) then
						local inv = PlayerManager.getInventory(player)
						if inv then
							NetworkManager.FireClient(player, "InventoryUpdated", inv)
						end
						NetworkManager.FireClient(player, "PickupCollected", pickup.itemId, pickup.count)
						remove = true
						break
					end
				end
			end
		else
			remove = true
		end

		if remove then
			if pickup.model and pickup.model.Parent then
				pickup.model:Destroy()
			end
			table.remove(pickups, i)
		else
			-- Bob animation
			local age = now - pickup.spawnTime
			local bobY = math.sin(age * 2) * 0.3
			pickup.model.Position = Vector3.new(
				pickup.model.Position.X,
				1.5 + bobY,
				pickup.model.Position.Z
			)
			i += 1
		end
	end
end

function PickupManager.Init()
	if not workspace:FindFirstChild("Pickups") then
		local folder = Instance.new("Folder")
		folder.Name = "Pickups"
		folder.Parent = workspace
		pickupsFolder = folder
	else
		pickupsFolder = workspace:FindFirstChild("Pickups") :: Folder?
	end
end

return PickupManager
