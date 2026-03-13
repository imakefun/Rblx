--!strict
-- RaidManager.luau
-- Handles periodic Kethari raid events.
-- Kethari spawn in waves, attack the Signal Fire and players.
--
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local RaidManager = {}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

type KethariData = {
	model: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	state: "approach" | "attack" | "dying",
	attackCooldown: number,
	targetType: "fire" | "player",
	targetPlayer: Player?,
}

local activeKethari: { KethariData } = {}
local raidActive = false
local lastRaidSol = 0
local npcsFolder: Folder? = nil

-------------------------------------------------------------------------------
-- Kethari model creation
-------------------------------------------------------------------------------

local function createKethariModel(position: Vector3, variant: string): Model
	local model = Instance.new("Model")
	model.Name = "Kethari_" .. variant

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 4, 1.5)
	torso.Position = position + Vector3.new(0, 2, 0)
	torso.Anchored = false
	torso.CanCollide = true
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Position = torso.Position + Vector3.new(0, 2.5, 0)
	head.Anchored = false
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.KETHARI_HEALTH
	humanoid.Health = Config.KETHARI_HEALTH
	humanoid.WalkSpeed = 14
	humanoid.Parent = model

	model.PrimaryPart = torso

	if variant == "Melee" then
		torso.Color = Color3.fromRGB(100, 40, 30)
		head.Color = Color3.fromRGB(120, 50, 35)
		model:SetAttribute("NPCType", "KethariMelee")
		model:SetAttribute("Damage", Config.KETHARI_MELEE_DAMAGE)
	else
		torso.Color = Color3.fromRGB(40, 50, 100)
		head.Color = Color3.fromRGB(50, 60, 120)
		model:SetAttribute("NPCType", "KethariRanged")
		model:SetAttribute("Damage", Config.KETHARI_RANGED_DAMAGE)
	end

	-- Eye glow
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color = Color3.fromRGB(255, 100, 50)
	eyeLight.Brightness = 1
	eyeLight.Range = 8
	eyeLight.Parent = head

	return model
end

-------------------------------------------------------------------------------
-- Raid spawning
-------------------------------------------------------------------------------

local function calculateRaidSize(currentSol: number): number
	local numPlayers = #Players:GetPlayers()
	local count = Config.RAID_BASE_COUNT
		+ math.floor(currentSol * Config.RAID_SCALE_PER_SOL)
		+ numPlayers * Config.RAID_SCALE_PER_PLAYER
	return math.min(count, 15) -- cap at 15
end

function RaidManager.StartRaid(currentSol: number, firePos: Vector3)
	if raidActive then return end
	raidActive = true
	lastRaidSol = currentSol

	if not npcsFolder then
		npcsFolder = workspace:FindFirstChild("NPCs") :: Folder?
		if not npcsFolder then
			local folder = Instance.new("Folder")
			folder.Name = "NPCs"
			folder.Parent = workspace
			npcsFolder = folder
		end
	end

	local count = calculateRaidSize(currentSol)

	NetworkManager.FireAllClients("Notify", "Raid", `Kethari raid incoming! ({count} hostiles)`)
	NetworkManager.FireAllClients("RaidStarted", count)

	-- Spawn in staggered waves
	for i = 1, count do
		task.delay((i - 1) * 1.5, function()
			if not raidActive then return end

			local angle = (i / count) * math.pi * 2 + math.random() * 0.5
			local dist = 120 + math.random(0, 40)
			local spawnPos = firePos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)

			-- 70% melee, 30% ranged
			local variant = if math.random() < 0.7 then "Melee" else "Ranged"
			local model = createKethariModel(spawnPos, variant)
			model.Parent = npcsFolder

			local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
			local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart

			local data: KethariData = {
				model = model,
				humanoid = humanoid,
				rootPart = rootPart,
				state = "approach",
				attackCooldown = 0,
				targetType = if math.random() < 0.6 then "fire" else "player",
				targetPlayer = nil,
			}

			table.insert(activeKethari, data)

			humanoid.Died:Connect(function()
				data.state = "dying"
			end)
		end)
	end
end

-------------------------------------------------------------------------------
-- AI update
-------------------------------------------------------------------------------

local function updateKethari(kethari: KethariData, dt: number, firePos: Vector3)
	if kethari.state == "dying" then return end
	if not kethari.model.Parent then
		kethari.state = "dying"
		return
	end

	kethari.attackCooldown = math.max(0, kethari.attackCooldown - dt)

	local pos = kethari.rootPart.Position
	local damage = (kethari.model:GetAttribute("Damage") :: number?) or Config.KETHARI_MELEE_DAMAGE

	-- Target the fire or nearest player
	if kethari.targetType == "fire" then
		local distToFire = (pos - firePos).Magnitude
		if distToFire > 5 then
			kethari.humanoid:MoveTo(firePos)
			kethari.state = "approach"
		else
			-- Attack the fire (reduce fuel)
			kethari.state = "attack"
			if kethari.attackCooldown <= 0 then
				kethari.attackCooldown = 2
				-- Signal fire damage is handled via callback
				RaidManager._onFireAttacked(damage)
			end
		end
	else
		-- Target nearest player
		local nearestPlayer: Player? = nil
		local nearestDist = math.huge
		for _, p in Players:GetPlayers() do
			if not PlayerManager.isAlive(p) then continue end
			local char = p.Character
			if not char then continue end
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then continue end
			local d = (pos - root.Position).Magnitude
			if d < nearestDist then
				nearestPlayer = p
				nearestDist = d
			end
		end

		if nearestPlayer and nearestDist <= 5 then
			kethari.state = "attack"
			if kethari.attackCooldown <= 0 then
				PlayerManager.dealDamage(nearestPlayer, damage)
				NetworkManager.FireClient(nearestPlayer, "DamageFeedback", "Kethari", damage)
				kethari.attackCooldown = 1.8
			end
		elseif nearestPlayer then
			kethari.state = "approach"
			local char = nearestPlayer.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					kethari.humanoid:MoveTo(root.Position)
				end
			end
		else
			-- No players, attack fire instead
			kethari.targetType = "fire"
		end
	end
end

-------------------------------------------------------------------------------
-- Fire attack callback
-------------------------------------------------------------------------------

type FireAttackCallback = (damage: number) -> ()
local fireAttackCallback: FireAttackCallback? = nil

function RaidManager.OnFireAttacked(callback: FireAttackCallback)
	fireAttackCallback = callback
end

function RaidManager._onFireAttacked(damage: number)
	if fireAttackCallback then
		fireAttackCallback(damage)
	end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function RaidManager.Init()
	if not workspace:FindFirstChild("NPCs") then
		local folder = Instance.new("Folder")
		folder.Name = "NPCs"
		folder.Parent = workspace
		npcsFolder = folder
	else
		npcsFolder = workspace:FindFirstChild("NPCs") :: Folder?
	end
end

function RaidManager.ShouldRaid(currentSol: number): boolean
	if raidActive then return false end
	if currentSol <= 1 then return false end -- no raid on sol 1
	if currentSol - lastRaidSol < Config.RAID_INTERVAL_SOLS then return false end
	return currentSol % Config.RAID_INTERVAL_SOLS == 0
end

function RaidManager.Update(dt: number, firePos: Vector3)
	-- Update all Kethari
	for _, kethari in activeKethari do
		updateKethari(kethari, dt, firePos)
	end

	-- Clean up dead Kethari
	local i = 1
	while i <= #activeKethari do
		local kethari = activeKethari[i]
		if kethari.state == "dying" then
			if kethari.model.Parent then
				kethari.model:Destroy()
			end
			table.remove(activeKethari, i)
		else
			i += 1
		end
	end

	-- Check if raid is over
	if raidActive and #activeKethari == 0 then
		raidActive = false
		NetworkManager.FireAllClients("Notify", "Victory", "Kethari raid repelled!")
		NetworkManager.FireAllClients("RaidEnded")
	end
end

function RaidManager.IsRaidActive(): boolean
	return raidActive
end

-- Called by CombatManager when a Kethari is killed
function RaidManager.OnKethariKilled(npc: Model, killer: Player)
	-- Drop loot
	local drops = {
		{ item = "KethariCrystal", count = 1 },
	}

	-- 40% chance for components
	if math.random() < 0.4 then
		table.insert(drops, { item = "Components", count = 1 })
	end

	-- 25% chance for scrap metal
	if math.random() < 0.25 then
		table.insert(drops, { item = "ScrapMetal", count = 2 })
	end

	for _, drop in drops do
		PlayerManager.addItem(killer, drop.item, drop.count)
	end

	local inv = PlayerManager.getInventory(killer)
	if inv then
		NetworkManager.FireClient(killer, "InventoryUpdated", inv)
	end

	NetworkManager.FireClient(killer, "Notify", "Kill", "Kethari eliminated!")
end

return RaidManager
