-- PlayerManager.luau
-- Server-side player state: stats, inventory, death/respawn

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerManager = {}

-- Player data tables (keyed by Player instance)
local playerStats: { [Player]: { Health: number, Hunger: number, Oxygen: number, Stamina: number } } = {}
local playerInventory: { [Player]: { [string]: number } } = {}

function PlayerManager.initPlayer(player: Player)
	playerStats[player] = {
		Health = Config.MAX_HEALTH,
		Hunger = Config.MAX_HUNGER,
		Oxygen = Config.MAX_OXYGEN,
		Stamina = Config.MAX_STAMINA,
	}

	-- Start with basic items
	playerInventory[player] = {
		Wood = 5,
		Berries = 3,
	}

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
	playerStats[player] = nil
	playerInventory[player] = nil
end

function PlayerManager.getStats(player: Player)
	return playerStats[player]
end

function PlayerManager.getInventory(player: Player)
	return playerInventory[player]
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
end

return PlayerManager
