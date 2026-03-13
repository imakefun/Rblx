--!strict
-- ShipPartManager.luau
-- Manages ship component collection for the endgame escape sequence.
-- Ship parts spawn around the map; players collect them and bring them
-- back to the Signal Fire to install.
--
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))

local ShipPartManager = {}

-------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------

local SHIP_PARTS = {
	{ id = "NavComputer", displayName = "Navigation Computer", color = Color3.fromRGB(50, 200, 255) },
	{ id = "FuelCell", displayName = "Fusion Fuel Cell", color = Color3.fromRGB(255, 200, 50) },
	{ id = "HullPlating", displayName = "Hull Plating", color = Color3.fromRGB(180, 180, 200) },
	{ id = "CommArray", displayName = "Communications Array", color = Color3.fromRGB(100, 255, 100) },
	{ id = "LifeSupport", displayName = "Life Support Module", color = Color3.fromRGB(255, 100, 100) },
	{ id = "EngineCore", displayName = "Engine Core", color = Color3.fromRGB(255, 150, 50) },
}

local TOTAL_PARTS = #SHIP_PARTS
local SPAWN_DISTANCE_MIN = 80
local SPAWN_DISTANCE_MAX = 200
local COLLECT_RANGE = 8

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local collectedParts: { [string]: boolean } = {}
local partModels: { [string]: BasePart } = {}
local partsCollected = 0
local initialized = false

-------------------------------------------------------------------------------
-- Part model creation
-------------------------------------------------------------------------------

local function createPartModel(partDef: typeof(SHIP_PARTS[1]), position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = "ShipPart_" .. partDef.id
	part.Size = Vector3.new(3, 3, 3)
	part.Position = position + Vector3.new(0, 2, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = partDef.color
	part.Shape = Enum.PartType.Block

	part:SetAttribute("ShipPartId", partDef.id)
	part:SetAttribute("DisplayName", partDef.displayName)

	-- Glow effect
	local light = Instance.new("PointLight")
	light.Color = partDef.color
	light.Brightness = 2
	light.Range = 20
	light.Parent = part

	-- Beacon beam
	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(partDef.color)
	beam.LightEmission = 1
	beam.Width0 = 0.5
	beam.Width1 = 0.1
	beam.FaceCamera = true

	-- Top attachment for beam
	local topAttach = Instance.new("Attachment")
	topAttach.Position = Vector3.new(0, 30, 0)
	topAttach.Parent = part

	beam.Attachment0 = attachment
	beam.Attachment1 = topAttach
	beam.Parent = part

	-- Rotate animation
	local spin = Instance.new("BodyAngularVelocity")
	-- Using attribute-based rotation since BodyAngularVelocity requires unanchored
	-- Instead, we'll handle rotation in a loop
	spin:Destroy()

	return part
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

function ShipPartManager.Init(firePos: Vector3)
	if initialized then return end
	initialized = true

	-- Create ShipParts folder
	local folder = Instance.new("Folder")
	folder.Name = "ShipParts"
	folder.Parent = workspace

	-- Spawn each ship part at a random distant location
	for i, partDef in SHIP_PARTS do
		local angle = (i / TOTAL_PARTS) * math.pi * 2 + math.random() * 0.5
		local dist = math.random(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
		local x = firePos.X + math.cos(angle) * dist
		local z = firePos.Z + math.sin(angle) * dist
		local pos = Vector3.new(x, 0, z)

		local model = createPartModel(partDef, pos)
		model.Parent = folder
		partModels[partDef.id] = model
	end

	-- Spin animation for all ship parts
	task.spawn(function()
		while true do
			for _, model in partModels do
				if model and model.Parent then
					model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(1), 0)
				end
			end
			task.wait(0.03)
		end
	end)

	print("[ShipPartManager] Spawned", TOTAL_PARTS, "ship parts around the map")
end

-------------------------------------------------------------------------------
-- Collection
-------------------------------------------------------------------------------

function ShipPartManager.TryCollect(player: Player, partId: string): boolean
	if collectedParts[partId] then return false end

	local model = partModels[partId]
	if not model or not model.Parent then return false end

	-- Distance check
	local character = player.Character
	if not character then return false end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return false end

	if (rootPart.Position - model.Position).Magnitude > COLLECT_RANGE then
		return false
	end

	-- Collect!
	collectedParts[partId] = true
	partsCollected += 1

	-- Remove from world with effect
	model:Destroy()
	partModels[partId] = nil

	-- Find display name
	local displayName = partId
	for _, partDef in SHIP_PARTS do
		if partDef.id == partId then
			displayName = partDef.displayName
			break
		end
	end

	-- Notify all players
	NetworkManager.FireAllClients("ShipPartCollected", partId, partsCollected, TOTAL_PARTS)
	NetworkManager.FireAllClients("Notify", "ShipPart", `{displayName} recovered! ({partsCollected}/{TOTAL_PARTS})`)

	-- Check for victory
	if partsCollected >= TOTAL_PARTS then
		task.delay(3, function()
			ShipPartManager._triggerEscape()
		end)
	end

	return true
end

function ShipPartManager._triggerEscape()
	NetworkManager.FireAllClients("Notify", "Victory", "All ship parts collected! Initiating escape sequence!")
	NetworkManager.FireAllClients("GameWon", partsCollected)

	-- Victory celebration: flash lights, play effects
	task.delay(5, function()
		NetworkManager.FireAllClients("Notify", "Ending", "You escaped the alien forest! Congratulations!")
	end)
end

function ShipPartManager.GetProgress(): (number, number)
	return partsCollected, TOTAL_PARTS
end

function ShipPartManager.IsPartCollected(partId: string): boolean
	return collectedParts[partId] == true
end

-------------------------------------------------------------------------------
-- Network handlers
-------------------------------------------------------------------------------

function ShipPartManager.RegisterNetworkHandlers()
	NetworkManager.OnClientEvent("CollectShipPart", function(player: Player, partId: any)
		if typeof(partId) ~= "string" then return end
		ShipPartManager.TryCollect(player, partId)
	end)

	NetworkManager.OnClientInvoke("GetShipProgress", function(_player: Player)
		return {
			collected = partsCollected,
			total = TOTAL_PARTS,
			parts = collectedParts,
		}
	end)
end

return ShipPartManager
