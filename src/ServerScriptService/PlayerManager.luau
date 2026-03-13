--!strict
-- PlayerManager.luau
-- Server-authoritative player state: stats, inventory, death/respawn, sprint.
--
-- REPLICATION STRATEGY (hybrid approach):
--   1. ATTRIBUTES on the Player instance for stats (Health, Hunger, Oxygen, Stamina).
--      Server calls player:SetAttribute("Health", value) which auto-replicates to
--      all clients. Clients read via player:GetAttribute("Health") or listen via
--      player:GetAttributeChangedSignal("Health"):Connect(function() ... end).
--      Clients CANNOT write these attributes back (server authority is enforced).
--   2. NetworkManager.FireClient for bulk data (inventory snapshots) and one-off
--      events (damage feedback, death, respawn).
--
-- Place in: ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerManager = {}

-- Player data tables (keyed by Player instance)
local playerStats: { [Player]: { Health: number, Hunger: number, Oxygen: number, Stamina: number } } = {}
local playerInventory: { [Player]: { [string]: number } } = {}
local playerSprinting: { [Player]: boolean } = {}

-------------------------------------------------------------------------------
-- Attribute replication helpers
-- Attributes set on the Player instance auto-replicate to ALL clients.
-- This is the simplest and most efficient way to share per-player stats.
-------------------------------------------------------------------------------

local STAT_NAMES: { string } = { "Health", "Hunger", "Oxygen", "Stamina" }

local function replicateAllStats(player: Player, stats: { Health: number, Hunger: number, Oxygen: number, Stamina: number })
	for _, name in STAT_NAMES do
		player:SetAttribute(name, math.floor((stats :: any)[name]))
	end
end

local function replicateStat(player: Player, name: string, value: number)
	player:SetAttribute(name, math.floor(value))
end

function PlayerManager.initPlayer(player: Player)
	playerStats[player] = {
		Health = Config.MAX_HEALTH,
		Hunger = Config.MAX_HUNGER,
		Oxygen = Config.MAX_OXYGEN,
		Stamina = Config.MAX_STAMINA,
	}
	playerSprinting[player] = false

	-- Start with basic items
	playerInventory[player] = {
		Wood = 5,
		Berries = 3,
	}

	-- Publish max stat values so the client can size HUD bars
	player:SetAttribute("MaxHealth", Config.MAX_HEALTH)
	player:SetAttribute("MaxHunger", Config.MAX_HUNGER)
	player:SetAttribute("MaxOxygen", Config.MAX_OXYGEN)
	player:SetAttribute("MaxStamina", Config.MAX_STAMINA)

	-- Push initial stat values via attributes
	replicateAllStats(player, playerStats[player])

	-- Create leaderstats (visible in player list)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local solValue = Instance.new("IntValue")
	solValue.Name = "Sol"
	solValue.Value = 1
	solValue.Parent = leaderstats
end

function PlayerManager.onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.MAX_HEALTH

	local stats = playerStats[player]
	if stats then
		humanoid.Health = stats.Health
	end

	-- Set walk speed
	humanoid.WalkSpeed = 16
end

function PlayerManager.cleanupPlayer(player: Player)
	-- TODO: persist to DataStore before clearing
	playerStats[player] = nil
	playerInventory[player] = nil
	playerSprinting[player] = nil
end

function PlayerManager.getStats(player: Player)
	return playerStats[player]
end

function PlayerManager.getInventory(player: Player)
	return playerInventory[player]
end

function PlayerManager.isAlive(player: Player): boolean
	local stats = playerStats[player]
	return stats ~= nil and stats.Health > 0
end

-------------------------------------------------------------------------------
-- Server-authoritative stat mutations
-- Each mutation immediately replicates via attributes.
-------------------------------------------------------------------------------

function PlayerManager.dealDamage(player: Player, amount: number)
	local stats = playerStats[player]
	if not stats or stats.Health <= 0 then return end
	stats.Health = math.max(0, stats.Health - amount)
	replicateStat(player, "Health", stats.Health)
end

function PlayerManager.heal(player: Player, amount: number)
	local stats = playerStats[player]
	if not stats or stats.Health <= 0 then return end
	stats.Health = math.min(Config.MAX_HEALTH, stats.Health + amount)
	replicateStat(player, "Health", stats.Health)
end

function PlayerManager.feed(player: Player, amount: number)
	local stats = playerStats[player]
	if not stats then return end
	stats.Hunger = math.min(Config.MAX_HUNGER, stats.Hunger + amount)
	replicateStat(player, "Hunger", stats.Hunger)
end

function PlayerManager.restoreOxygen(player: Player, amount: number)
	local stats = playerStats[player]
	if not stats then return end
	stats.Oxygen = math.min(Config.MAX_OXYGEN, stats.Oxygen + amount)
	replicateStat(player, "Oxygen", stats.Oxygen)
end

-------------------------------------------------------------------------------
-- Stat tick — called by GameManager each Heartbeat for each player.
-- Drains hunger, oxygen; applies signal fire regen; checks death.
-- Returns true if the player just died this tick.
-------------------------------------------------------------------------------

function PlayerManager.tickStats(player: Player, dt: number, isNight: boolean, inSignalFireField: boolean): boolean
	local stats = playerStats[player]
	if not stats or stats.Health <= 0 then return false end

	-- Hunger drain
	stats.Hunger = math.max(0, stats.Hunger - Config.HUNGER_DRAIN_RATE * dt)

	-- Oxygen drain (faster at night — alien atmosphere)
	local o2Drain = if isNight then Config.OXYGEN_DRAIN_NIGHT else Config.OXYGEN_DRAIN_DAY
	stats.Oxygen = math.max(0, stats.Oxygen - o2Drain * dt)

	-- Signal Fire field regen
	if inSignalFireField then
		stats.Health = math.min(Config.MAX_HEALTH, stats.Health + Config.SIGNAL_FIRE_HEAL_RATE * dt)
		stats.Oxygen = math.min(Config.MAX_OXYGEN, stats.Oxygen + Config.SIGNAL_FIRE_O2_REGEN * dt)
	end

	-- Starvation damage
	if stats.Hunger <= 0 then
		stats.Health = math.max(0, stats.Health - Config.HUNGER_DAMAGE_RATE * dt)
	end

	-- Suffocation damage
	if stats.Oxygen <= 0 then
		stats.Health = math.max(0, stats.Health - Config.HUNGER_DAMAGE_RATE * dt)
	end

	-- Sync Humanoid.Health so Roblox's default health bar also works
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = stats.Health
		end
	end

	-- Replicate all stats via attributes (auto-syncs to all clients)
	replicateAllStats(player, stats)

	return stats.Health <= 0
end

function PlayerManager.addItem(player: Player, itemId: string, count: number): boolean
	local inv = playerInventory[player]
	if not inv then return false end

	local itemDef = Config.ITEMS[itemId]
	if not itemDef then
		warn("[PlayerManager] Unknown item: " .. itemId)
		return false
	end

	local current = inv[itemId] or 0
	local maxStack = itemDef.stackSize or 99
	local newCount = math.min(current + count, maxStack)
	inv[itemId] = newCount

	return true
end

function PlayerManager.removeItem(player: Player, itemId: string, count: number): boolean
	local inv = playerInventory[player]
	if not inv then return false end

	local current = inv[itemId] or 0
	if current < count then return false end

	current -= count
	if current <= 0 then
		inv[itemId] = nil
	else
		inv[itemId] = current
	end

	return true
end

function PlayerManager.hasItem(player: Player, itemId: string, count: number): boolean
	local inv = playerInventory[player]
	if not inv then return false end
	return (inv[itemId] or 0) >= count
end

function PlayerManager.onPlayerDied(player: Player)
	local stats = playerStats[player]
	if not stats then return end

	-- Reset stats
	stats.Health = Config.MAX_HEALTH
	stats.Hunger = Config.MAX_HUNGER * 0.5 -- respawn with half hunger
	stats.Oxygen = Config.MAX_OXYGEN

	-- Drop some items on death (lose 25% of resources)
	local inv = playerInventory[player]
	if inv then
		for itemId, count in inv do
			local itemDef = Config.ITEMS[itemId]
			if itemDef and itemDef.category == "Resource" then
				local toLose = math.ceil(count * 0.25)
				inv[itemId] = math.max(0, count - toLose)
				if inv[itemId] == 0 then
					inv[itemId] = nil
				end
			end
		end
	end

	-- Respawn character
	task.defer(function()
		player:LoadCharacter()
	end)
end

function PlayerManager.setSprint(player: Player, sprinting: boolean, dt: number)
	local stats = playerStats[player]
	if not stats then return end

	playerSprinting[player] = sprinting

	if sprinting and stats.Stamina > 0 then
		stats.Stamina = math.max(0, stats.Stamina - Config.STAMINA_DRAIN_SPRINT * dt)

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16 * Config.SPRINT_SPEED_MULT
			end
		end
	else
		stats.Stamina = math.min(Config.MAX_STAMINA, stats.Stamina + Config.STAMINA_REGEN_RATE * dt)

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16
			end
		end
	end

	-- Replicate stamina change immediately
	replicateStat(player, "Stamina", stats.Stamina)
end

function PlayerManager.isSprinting(player: Player): boolean
	return playerSprinting[player] or false
end

return PlayerManager
