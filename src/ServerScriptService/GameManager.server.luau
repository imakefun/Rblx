--!strict
-- GameManager.server.luau
-- Master game loop: coordinates all server systems, manages the sol cycle,
-- and runs the Heartbeat tick for stats/fire/lighting/combat/AI/raids.
--
-- This is a Script (not a ModuleScript) so it auto-runs on the server.
-- It requires all manager modules and wires them together.
--
-- Architecture:
--   GameManager (this file) is the ONLY server Script (besides MapSetup).
--   Everything else is a ModuleScript that exposes Init/Start/Update functions.
--   This keeps the boot order explicit and avoids hidden require chains.
--
-- Place in: ServerScriptService (must be a .server.luau script)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-------------------------------------------------------------------------------
-- Require all manager modules
-------------------------------------------------------------------------------

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local DayNightCycle = require(ServerScriptService:WaitForChild("DayNightCycle"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))
local SignalFireManager = require(ServerScriptService:WaitForChild("SignalFireManager"))
local InventoryManager = require(ServerScriptService:WaitForChild("InventoryManager"))
local CraftingManager = require(ServerScriptService:WaitForChild("CraftingManager"))
local CombatManager = require(ServerScriptService:WaitForChild("CombatManager"))
local StalkerAI = require(ServerScriptService:WaitForChild("StalkerAI"))
local RaidManager = require(ServerScriptService:WaitForChild("RaidManager"))
local ShipPartManager = require(ServerScriptService:WaitForChild("ShipPartManager"))
local PickupManager = require(ServerScriptService:WaitForChild("PickupManager"))

-------------------------------------------------------------------------------
-- Game state
-------------------------------------------------------------------------------

local gameRunning: boolean = false

-------------------------------------------------------------------------------
-- DayNightCycle callbacks
-------------------------------------------------------------------------------

DayNightCycle.OnSolChanged(function(sol: number)
	-- Update all players' leaderstat
	for _, player in Players:GetPlayers() do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local solValue = leaderstats:FindFirstChild("Sol") :: IntValue?
			if solValue then
				solValue.Value = sol
			end
		end
	end

	NetworkManager.FireAllClients("SolUpdated", sol)

	-- Check for Kethari raid trigger
	if RaidManager.ShouldRaid(sol) then
		RaidManager.StartRaid(sol, SignalFireManager.getPosition())
	end

	-- Victory check
	if sol > Config.MAX_SOL then
		NetworkManager.FireAllClients("Notify", "Victory", `You survived all {Config.MAX_SOL} sols!`)
		gameRunning = false
	end
end)

DayNightCycle.OnNightChanged(function(isNight: boolean)
	local phase = if isNight then "Night" else "Day"
	NetworkManager.FireAllClients("TimePhaseChanged", phase, DayNightCycle.GetSol())

	-- Notify Stalker AI of night state change
	StalkerAI.SetNight(isNight)
end)

-------------------------------------------------------------------------------
-- Wire combat kill callbacks to loot systems
-------------------------------------------------------------------------------

CombatManager.OnNPCKilled(function(npc: Model, npcType: string, killer: Player)
	if npcType == "Stalker" then
		StalkerAI.OnStalkerKilled(npc, killer)
	elseif npcType == "KethariMelee" or npcType == "KethariRanged" then
		RaidManager.OnKethariKilled(npc, killer)
	end
end)

-- Wire raid fire attacks to reduce signal fire fuel
RaidManager.OnFireAttacked(function(damage: number)
	-- Raids drain fuel from the fire (1 fuel per damage point)
	local fuelDrain = damage * 0.5
	local state = SignalFireManager.getState()
	if state.fuel > 0 then
		-- We subtract by adding negative (addFuel clamps to max, so we use direct method)
		-- Actually, let's just call update manually -- or we add a drain function
		-- For now, we access the state through a simple approach
		SignalFireManager.addFuel(-fuelDrain)
	end
end)

-------------------------------------------------------------------------------
-- Network handlers for client -> server actions
-- All validation happens here on the server.
-------------------------------------------------------------------------------

-- Add fuel to the Signal Fire
NetworkManager.OnClientEvent("AddFuel", function(player: Player, itemId: any)
	if typeof(itemId) ~= "string" then return end

	local fuelValue = Config.FUEL_VALUES[itemId]
	if not fuelValue then return end

	if not PlayerManager.removeItem(player, itemId, 1) then return end

	SignalFireManager.addFuel(fuelValue)

	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end
end)

-- Eat food
NetworkManager.OnClientEvent("EatFood", function(player: Player, itemId: any)
	if typeof(itemId) ~= "string" then return end

	local itemDef = Config.ITEMS[itemId]
	if not itemDef or not itemDef.hungerRestore then return end

	if not PlayerManager.removeItem(player, itemId, 1) then return end

	PlayerManager.feed(player, itemDef.hungerRestore)

	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end
end)

-- Gather a resource (tree, rock, bush, debris)
NetworkManager.OnClientEvent("GatherResource", function(player: Player, targetName: any)
	if typeof(targetName) ~= "string" then return end

	local resources = workspace:FindFirstChild("Resources")
	local target = if resources then resources:FindFirstChild(targetName) else nil
	if not target or not target:IsA("BasePart") then return end

	local resourceType = target:GetAttribute("ResourceType")
	if not resourceType then return end

	-- Distance check (server-authoritative anti-cheat)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end
	if (rootPart.Position - target.Position).Magnitude > 15 then return end

	-- Hit processing
	local hitsLeft = target:GetAttribute("HitsLeft") :: number?
	if not hitsLeft or hitsLeft <= 0 then return end

	target:SetAttribute("HitsLeft", hitsLeft - 1)

	if hitsLeft - 1 <= 0 then
		-- Resource depleted: give drops
		local drops: { { item: string, count: number } } = {}
		if resourceType == "Tree" then
			drops = { { item = "Wood", count = Config.TREE_WOOD_DROP } }
		elseif resourceType == "Rock" then
			drops = { { item = "Stone", count = Config.ROCK_STONE_DROP } }
		elseif resourceType == "Bush" then
			drops = { { item = "Berries", count = Config.BUSH_BERRY_DROP } }
		elseif resourceType == "CrashDebris" then
			drops = { { item = "ScrapMetal", count = 2 }, { item = "Wire", count = 1 } }
		end

		for _, drop in drops do
			PlayerManager.addItem(player, drop.item, drop.count)
		end

		-- Hide and respawn
		target.Transparency = 1
		target.CanCollide = false
		target:SetAttribute("Depleted", true)

		-- Also hide leaves for trees
		for _, child in target:GetChildren() do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
		end

		task.delay(Config.RESOURCE_RESPAWN_TIME, function()
			if target and target.Parent then
				target.Transparency = 0
				target.CanCollide = true
				target:SetAttribute("Depleted", false)
				for _, child in target:GetChildren() do
					if child:IsA("BasePart") then
						child.Transparency = 0
					end
				end
				if resourceType == "Tree" then
					target:SetAttribute("HitsLeft", Config.TREE_HITS)
				elseif resourceType == "Rock" then
					target:SetAttribute("HitsLeft", Config.ROCK_HITS)
				else
					target:SetAttribute("HitsLeft", 1)
				end
			end
		end)

		local inv = PlayerManager.getInventory(player)
		if inv then
			NetworkManager.FireClient(player, "InventoryUpdated", inv)
		end
	end
end)

-- Sprint toggle
NetworkManager.OnClientEvent("SetSprinting", function(player: Player, sprinting: any)
	if typeof(sprinting) ~= "boolean" then return end
	PlayerManager.setSprint(player, sprinting, 0)
end)

-- Client requests full stats (e.g. after reconnect)
NetworkManager.OnClientInvoke("GetMyStats", function(player: Player)
	return PlayerManager.getStats(player)
end)

-------------------------------------------------------------------------------
-- Register sub-system network handlers
-------------------------------------------------------------------------------

InventoryManager.RegisterNetworkHandlers()
CraftingManager.RegisterNetworkHandlers()
CombatManager.RegisterNetworkHandlers()
ShipPartManager.RegisterNetworkHandlers()

-------------------------------------------------------------------------------
-- Player lifecycle
-------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
	PlayerManager.initPlayer(player)

	player.CharacterAdded:Connect(function(character: Model)
		PlayerManager.onCharacterAdded(player, character)

		-- Watch for death
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			InventoryManager.OnCharacterDied(player)
			PlayerManager.onPlayerDied(player)
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	InventoryManager.OnPlayerRemoving(player)
	CraftingManager.OnPlayerRemoving(player)
	CombatManager.OnPlayerRemoving(player)
	PlayerManager.cleanupPlayer(player)
end)

-- Handle players that joined before this script ran
for _, player in Players:GetPlayers() do
	task.spawn(function()
		PlayerManager.initPlayer(player)
	end)
end

-------------------------------------------------------------------------------
-- Initialize systems
-------------------------------------------------------------------------------

SignalFireManager.init()
DayNightCycle.Init()
StalkerAI.Init()
RaidManager.Init()
PickupManager.Init()
ShipPartManager.Init(SignalFireManager.getPosition())

-------------------------------------------------------------------------------
-- Main Heartbeat loop
-- This is the single place where per-frame logic runs on the server.
-------------------------------------------------------------------------------

gameRunning = true

RunService.Heartbeat:Connect(function(dt: number)
	if not gameRunning then return end

	-- 1. Advance day/night cycle (updates Lighting.ClockTime, fires callbacks)
	local isNight = DayNightCycle.Update(dt)

	-- 2. Update Signal Fire (burn fuel, update visuals)
	SignalFireManager.update(dt)

	-- 3. Broadcast signal fire state (using unreliable for high-frequency updates)
	NetworkManager.FireAllClientsUnreliable("SignalFireUpdated", SignalFireManager.getState())

	-- 4. Update AI systems
	local firePos = SignalFireManager.getPosition()
	local fireState = SignalFireManager.getState()
	StalkerAI.Update(dt, firePos, fireState.radius)
	RaidManager.Update(dt, firePos)

	-- 5. Update world pickups (auto-collect when players are near)
	PickupManager.Update(dt)

	-- 6. Tick each player's stats
	for _, player in Players:GetPlayers() do
		-- Check if player is inside the dampening field
		local inField = false
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				inField = SignalFireManager.isInField(rootPart.Position)
			end
		end

		-- Tick stats (hunger drain, O2 drain, regen, damage)
		local justDied = PlayerManager.tickStats(player, dt, isNight, inField)

		if justDied then
			InventoryManager.OnCharacterDied(player)
			PlayerManager.onPlayerDied(player)
		end

		-- Sprint handling (dt-based stamina drain)
		if PlayerManager.isSprinting(player) then
			PlayerManager.setSprint(player, true, dt)
		end
	end
end)

print("[GameManager] All systems initialized. Sol 1 begins.")
