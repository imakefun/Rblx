--!strict
-- StalkerAI.luau
-- Controls Stalker enemies: spawn at night outside the dampening field,
-- chase players, attack, and flee from UV light/fire.
--
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local StalkerAI = {}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

type StalkerData = {
	model: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	target: Player?,
	state: "idle" | "chase" | "attack" | "flee" | "dying",
	attackCooldown: number,
	lifetime: number,
}

local stalkers: { StalkerData } = {}
local isNight = false
local spawnTimer = 0
local SPAWN_INTERVAL = 30 -- seconds between spawn waves at night
local MAX_STALKERS = 6
local npcsFolder: Folder? = nil

-------------------------------------------------------------------------------
-- Stalker model creation
-------------------------------------------------------------------------------

local function createStalkerModel(position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Stalker"

	-- Body (dark, alien creature)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 3, 1.5)
	torso.Position = position + Vector3.new(0, 1.5, 0)
	torso.Anchored = false
	torso.CanCollide = true
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(30, 15, 40)
	torso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = torso.Position + Vector3.new(0, 2, 0)
	head.Anchored = false
	head.CanCollide = false
	head.Material = Enum.Material.Neon
	head.Color = Color3.fromRGB(180, 40, 255) -- glowing purple eyes
	head.Parent = model

	-- Weld head to torso
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Humanoid for pathfinding and health
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 80
	humanoid.Health = 80
	humanoid.WalkSpeed = Config.STALKER_SPEED
	humanoid.Parent = model

	-- Set PrimaryPart
	model.PrimaryPart = torso

	-- NPC type attribute for combat system
	model:SetAttribute("NPCType", "Stalker")
	model:SetAttribute("Damage", Config.STALKER_DAMAGE)

	-- Glowing eyes effect
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color = Color3.fromRGB(180, 40, 255)
	eyeLight.Brightness = 1.5
	eyeLight.Range = 12
	eyeLight.Parent = head

	return model
end

-------------------------------------------------------------------------------
-- Spawn logic
-------------------------------------------------------------------------------

local function getSpawnPosition(): Vector3?
	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return nil end

	-- Pick a random player to spawn near
	local targetPlayer = allPlayers[math.random(1, #allPlayers)]
	local character = targetPlayer.Character
	if not character then return nil end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return nil end

	-- Spawn at configured distance, random angle
	local angle = math.random() * math.pi * 2
	local dist = Config.STALKER_SPAWN_DISTANCE
	local x = rootPart.Position.X + math.cos(angle) * dist
	local z = rootPart.Position.Z + math.sin(angle) * dist

	return Vector3.new(x, 2, z)
end

function StalkerAI.SpawnStalker()
	if #stalkers >= MAX_STALKERS then return end

	local pos = getSpawnPosition()
	if not pos then return end

	if not npcsFolder then
		npcsFolder = workspace:FindFirstChild("NPCs") :: Folder?
		if not npcsFolder then
			local folder = Instance.new("Folder")
			folder.Name = "NPCs"
			folder.Parent = workspace
			npcsFolder = folder
		end
	end

	local model = createStalkerModel(pos)
	model.Parent = npcsFolder

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart

	local data: StalkerData = {
		model = model,
		humanoid = humanoid,
		rootPart = rootPart,
		target = nil,
		state = "idle",
		attackCooldown = 0,
		lifetime = 0,
	}

	table.insert(stalkers, data)

	-- Listen for death
	humanoid.Died:Connect(function()
		data.state = "dying"
	end)

	NetworkManager.FireAllClients("Notify", "Warning", "You hear something moving in the darkness...")
end

-------------------------------------------------------------------------------
-- AI behavior (called each frame)
-------------------------------------------------------------------------------

local function findNearestPlayer(stalkerPos: Vector3): (Player?, number)
	local nearest: Player? = nil
	local nearestDist = math.huge

	for _, p in Players:GetPlayers() do
		if not PlayerManager.isAlive(p) then continue end
		local character = p.Character
		if not character then continue end
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local dist = (stalkerPos - rootPart.Position).Magnitude
		if dist < nearestDist then
			nearest = p
			nearestDist = dist
		end
	end

	return nearest, nearestDist
end

local function isInSafeZone(pos: Vector3, firePos: Vector3, fireRadius: number): boolean
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local flatFire = Vector3.new(firePos.X, 0, firePos.Z)
	return (flat - flatFire).Magnitude <= fireRadius
end

local function updateStalker(stalker: StalkerData, dt: number, firePos: Vector3, fireRadius: number)
	if stalker.state == "dying" then return end
	if not stalker.model.Parent then
		stalker.state = "dying"
		return
	end

	stalker.lifetime += dt
	stalker.attackCooldown = math.max(0, stalker.attackCooldown - dt)

	local pos = stalker.rootPart.Position

	-- Check if stalker wandered into safe zone → flee
	if isInSafeZone(pos, firePos, fireRadius) then
		stalker.state = "flee"
		-- Move away from fire
		local awayDir = (pos - firePos).Unit
		local fleeTarget = pos + awayDir * 30
		stalker.humanoid:MoveTo(fleeTarget)
		return
	end

	-- Check if near a player with UV Flashlight or Torch → flee
	local target, targetDist = findNearestPlayer(pos)
	if not target then
		stalker.state = "idle"
		return
	end

	-- Check target's equipped tool for light-based weapons
	local targetChar = target.Character
	if targetChar then
		for _, child in targetChar:GetChildren() do
			if child:IsA("Tool") then
				local itemId = child:GetAttribute("ItemId")
				if itemId == "UVFlashlight" or itemId == "Torch" then
					-- Flee from light if close
					if targetDist < 20 then
						stalker.state = "flee"
						local awayDir = (pos - targetChar:GetPivot().Position).Unit
						stalker.humanoid:MoveTo(pos + awayDir * 25)
						return
					end
				end
			end
		end
	end

	-- Chase or attack
	if targetDist > 6 then
		stalker.state = "chase"
		stalker.target = target
		if targetChar then
			local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetRoot then
				stalker.humanoid:MoveTo(targetRoot.Position)
			end
		end
	else
		-- In attack range
		stalker.state = "attack"
		if stalker.attackCooldown <= 0 then
			-- Deal damage
			PlayerManager.dealDamage(target, Config.STALKER_DAMAGE)
			NetworkManager.FireClient(target, "Notify", "Damage", "A Stalker struck you!")
			NetworkManager.FireClient(target, "DamageFeedback", "Stalker", Config.STALKER_DAMAGE)
			stalker.attackCooldown = 1.5
		end
	end

	-- Despawn if alive too long (5 minutes) or if day comes
	if stalker.lifetime > 300 or not isNight then
		stalker.state = "dying"
		-- Fade out
		task.spawn(function()
			if stalker.model and stalker.model.Parent then
				for _, part in stalker.model:GetDescendants() do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end
				task.wait(0.5)
				if stalker.model and stalker.model.Parent then
					stalker.model:Destroy()
				end
			end
		end)
	end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function StalkerAI.Init()
	-- Create NPCs folder
	if not workspace:FindFirstChild("NPCs") then
		local folder = Instance.new("Folder")
		folder.Name = "NPCs"
		folder.Parent = workspace
		npcsFolder = folder
	else
		npcsFolder = workspace:FindFirstChild("NPCs") :: Folder?
	end
end

function StalkerAI.SetNight(night: boolean)
	isNight = night

	if not night then
		-- Despawn all stalkers when day comes
		for _, stalker in stalkers do
			if stalker.state ~= "dying" then
				stalker.state = "dying"
				task.spawn(function()
					task.wait(2)
					if stalker.model and stalker.model.Parent then
						stalker.model:Destroy()
					end
				end)
			end
		end
	end
end

function StalkerAI.Update(dt: number, firePos: Vector3, fireRadius: number)
	-- Spawn logic (only at night)
	if isNight then
		spawnTimer += dt
		if spawnTimer >= SPAWN_INTERVAL then
			spawnTimer = 0
			local numPlayers = #Players:GetPlayers()
			local toSpawn = math.min(2, MAX_STALKERS - #stalkers)
			-- Scale with players
			if numPlayers > 1 then
				toSpawn = math.min(3, MAX_STALKERS - #stalkers)
			end
			for _ = 1, toSpawn do
				StalkerAI.SpawnStalker()
			end
		end
	end

	-- Update all stalkers
	for _, stalker in stalkers do
		updateStalker(stalker, dt, firePos, fireRadius)
	end

	-- Clean up dead stalkers
	local i = 1
	while i <= #stalkers do
		local stalker = stalkers[i]
		if stalker.state == "dying" and (not stalker.model.Parent or stalker.humanoid.Health <= 0) then
			if stalker.model.Parent then
				stalker.model:Destroy()
			end
			table.remove(stalkers, i)
		else
			i += 1
		end
	end
end

function StalkerAI.GetStalkerCount(): number
	return #stalkers
end

-- Called by CombatManager when a stalker is killed
function StalkerAI.OnStalkerKilled(npc: Model, killer: Player)
	-- Drop loot
	local drops = {
		{ item = "KethariCrystal", count = 1 },
	}

	-- 30% chance for extra crystal
	if math.random() < 0.3 then
		drops[1].count = 2
	end

	-- 20% chance for raw meat
	if math.random() < 0.2 then
		table.insert(drops, { item = "RawMeat", count = 1 })
	end

	for _, drop in drops do
		PlayerManager.addItem(killer, drop.item, drop.count)
	end

	local inv = PlayerManager.getInventory(killer)
	if inv then
		NetworkManager.FireClient(killer, "InventoryUpdated", inv)
	end

	NetworkManager.FireClient(killer, "Notify", "Kill", "Stalker defeated!")
end

return StalkerAI
