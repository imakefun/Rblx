-- GameManager.server.luau
-- Master game loop: manages sol cycle, game state, and coordinates all systems

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerManager = require(ServerScriptService.PlayerManager)
local SignalFireManager = require(ServerScriptService.SignalFireManager)

-- Create RemoteEvents
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local function createRemote(name: string, className: string): Instance
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = Remotes
	return remote
end

-- Events: Server → Client
local SolUpdated = createRemote("SolUpdated", "RemoteEvent")
local TimeUpdated = createRemote("TimeUpdated", "RemoteEvent")
local StatsUpdated = createRemote("StatsUpdated", "RemoteEvent")
local InventoryUpdated = createRemote("InventoryUpdated", "RemoteEvent")
local SignalFireUpdated = createRemote("SignalFireUpdated", "RemoteEvent")
local NotifyClient = createRemote("NotifyClient", "RemoteEvent")

-- Events: Client → Server
local AddFuel = createRemote("AddFuel", "RemoteEvent")
local GatherResource = createRemote("GatherResource", "RemoteEvent")
local CraftItem = createRemote("CraftItem", "RemoteEvent")
local EatFood = createRemote("EatFood", "RemoteEvent")
local DropItem = createRemote("DropItem", "RemoteEvent")

-- Game state
local gameState = {
	currentSol = 1,
	timeInCycle = 0,       -- seconds into current cycle
	isNight = false,
	running = false,
}

-- Lighting presets
local DAY_SETTINGS = {
	ClockTime = 12,
	Brightness = 2,
	Ambient = Color3.fromRGB(135, 135, 128),
	OutdoorAmbient = Color3.fromRGB(128, 128, 128),
	FogEnd = 1000,
	FogColor = Color3.fromRGB(192, 192, 192),
}

local NIGHT_SETTINGS = {
	ClockTime = 0.5,
	Brightness = 0,
	Ambient = Color3.fromRGB(20, 15, 35),          -- slight purple alien tint
	OutdoorAmbient = Color3.fromRGB(15, 10, 30),
	FogEnd = 200,
	FogColor = Color3.fromRGB(10, 8, 20),
}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function lerpColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t))
end

local function updateLighting(timeInCycle: number)
	local dayLen = Config.DAY_LENGTH
	local nightLen = Config.NIGHT_LENGTH
	local totalLen = Config.CYCLE_LENGTH

	local isNight = timeInCycle >= dayLen
	local t: number

	if not isNight then
		-- Daytime: map to ClockTime 6 → 18
		local dayProgress = timeInCycle / dayLen
		local clockTime = lerp(Config.DAWN_HOUR, Config.DUSK_HOUR, dayProgress)
		Lighting.ClockTime = clockTime

		-- Transition zones: dawn (first 10%) and dusk (last 10%)
		if dayProgress < 0.1 then
			t = dayProgress / 0.1 -- 0→1 during dawn
			Lighting.Brightness = lerp(NIGHT_SETTINGS.Brightness, DAY_SETTINGS.Brightness, t)
			Lighting.Ambient = lerpColor(NIGHT_SETTINGS.Ambient, DAY_SETTINGS.Ambient, t)
			Lighting.OutdoorAmbient = lerpColor(NIGHT_SETTINGS.OutdoorAmbient, DAY_SETTINGS.OutdoorAmbient, t)
			Lighting.FogEnd = lerp(NIGHT_SETTINGS.FogEnd, DAY_SETTINGS.FogEnd, t)
			Lighting.FogColor = lerpColor(NIGHT_SETTINGS.FogColor, DAY_SETTINGS.FogColor, t)
		elseif dayProgress > 0.9 then
			t = (dayProgress - 0.9) / 0.1 -- 0→1 during dusk
			Lighting.Brightness = lerp(DAY_SETTINGS.Brightness, NIGHT_SETTINGS.Brightness, t)
			Lighting.Ambient = lerpColor(DAY_SETTINGS.Ambient, NIGHT_SETTINGS.Ambient, t)
			Lighting.OutdoorAmbient = lerpColor(DAY_SETTINGS.OutdoorAmbient, NIGHT_SETTINGS.OutdoorAmbient, t)
			Lighting.FogEnd = lerp(DAY_SETTINGS.FogEnd, NIGHT_SETTINGS.FogEnd, t)
			Lighting.FogColor = lerpColor(DAY_SETTINGS.FogColor, NIGHT_SETTINGS.FogColor, t)
		else
			Lighting.Brightness = DAY_SETTINGS.Brightness
			Lighting.Ambient = DAY_SETTINGS.Ambient
			Lighting.OutdoorAmbient = DAY_SETTINGS.OutdoorAmbient
			Lighting.FogEnd = DAY_SETTINGS.FogEnd
			Lighting.FogColor = DAY_SETTINGS.FogColor
		end
	else
		-- Nighttime: ClockTime 18 → 6 (through midnight)
		local nightProgress = (timeInCycle - dayLen) / nightLen
		local clockTime = Config.DUSK_HOUR + nightProgress * 12
		if clockTime >= 24 then
			clockTime = clockTime - 24
		end
		Lighting.ClockTime = clockTime

		Lighting.Brightness = NIGHT_SETTINGS.Brightness
		Lighting.Ambient = NIGHT_SETTINGS.Ambient
		Lighting.OutdoorAmbient = NIGHT_SETTINGS.OutdoorAmbient
		Lighting.FogEnd = NIGHT_SETTINGS.FogEnd
		Lighting.FogColor = NIGHT_SETTINGS.FogColor
	end

	return isNight
end

-- Main game loop
local function gameLoop(dt: number)
	if not gameState.running then return end

	gameState.timeInCycle += dt

	-- Check for cycle completion (new sol)
	if gameState.timeInCycle >= Config.CYCLE_LENGTH then
		gameState.timeInCycle -= Config.CYCLE_LENGTH
		gameState.currentSol += 1

		if gameState.currentSol > Config.MAX_SOL then
			-- Victory!
			NotifyClient:FireAllClients("Victory", "You survived all " .. Config.MAX_SOL .. " sols!")
			gameState.running = false
			return
		end

		SolUpdated:FireAllClients(gameState.currentSol)
	end

	-- Update lighting and determine day/night
	local wasNight = gameState.isNight
	gameState.isNight = updateLighting(gameState.timeInCycle)

	-- Broadcast night transition
	if gameState.isNight and not wasNight then
		TimeUpdated:FireAllClients("Night", gameState.currentSol)
	elseif not gameState.isNight and wasNight then
		TimeUpdated:FireAllClients("Day", gameState.currentSol)
	end

	-- Update Signal Fire
	SignalFireManager.update(dt)
	SignalFireUpdated:FireAllClients(SignalFireManager.getState())

	-- Update all player stats
	for _, player in Players:GetPlayers() do
		local stats = PlayerManager.getStats(player)
		if stats then
			-- Hunger drain
			stats.Hunger = math.max(0, stats.Hunger - Config.HUNGER_DRAIN_RATE * dt)

			-- Oxygen drain (faster at night)
			local o2Drain = gameState.isNight and Config.OXYGEN_DRAIN_NIGHT or Config.OXYGEN_DRAIN_DAY
			stats.Oxygen = math.max(0, stats.Oxygen - o2Drain * dt)

			-- Signal Fire regen
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local inField = SignalFireManager.isInField(rootPart.Position)
					if inField then
						stats.Health = math.min(Config.MAX_HEALTH, stats.Health + Config.SIGNAL_FIRE_HEAL_RATE * dt)
						stats.Oxygen = math.min(Config.MAX_OXYGEN, stats.Oxygen + Config.SIGNAL_FIRE_O2_REGEN * dt)
					end
				end
			end

			-- Hunger damage
			if stats.Hunger <= 0 then
				stats.Health = math.max(0, stats.Health - Config.HUNGER_DAMAGE_RATE * dt)
			end

			-- O2 damage
			if stats.Oxygen <= 0 then
				stats.Health = math.max(0, stats.Health - Config.HUNGER_DAMAGE_RATE * dt)
			end

			-- Sync humanoid health
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = stats.Health
				end
			end

			-- Death check
			if stats.Health <= 0 then
				PlayerManager.onPlayerDied(player)
			end

			-- Send stats to client
			StatsUpdated:FireClient(player, stats)
		end
	end
end

-- Handle client requests
AddFuel.OnServerEvent:Connect(function(player, itemId: string)
	local fuelValue = Config.FUEL_VALUES[itemId]
	if not fuelValue then return end

	local inventory = PlayerManager.getInventory(player)
	if not inventory then return end

	-- Check player has the item
	local removed = PlayerManager.removeItem(player, itemId, 1)
	if not removed then return end

	SignalFireManager.addFuel(fuelValue)
	InventoryUpdated:FireClient(player, PlayerManager.getInventory(player))
end)

EatFood.OnServerEvent:Connect(function(player, itemId: string)
	local itemDef = Config.ITEMS[itemId]
	if not itemDef or not itemDef.hungerRestore then return end

	local removed = PlayerManager.removeItem(player, itemId, 1)
	if not removed then return end

	local stats = PlayerManager.getStats(player)
	if stats then
		stats.Hunger = math.min(Config.MAX_HUNGER, stats.Hunger + itemDef.hungerRestore)
	end

	InventoryUpdated:FireClient(player, PlayerManager.getInventory(player))
end)

GatherResource.OnServerEvent:Connect(function(player, targetId: string)
	-- Validate the target exists in workspace
	local target = workspace:FindFirstChild("Resources") and workspace.Resources:FindFirstChild(targetId)
	if not target then return end

	local resourceType = target:GetAttribute("ResourceType")
	if not resourceType then return end

	-- Check distance
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	local distance = (rootPart.Position - target.Position).Magnitude
	if distance > 15 then return end

	-- Process hits
	local hitsLeft = target:GetAttribute("HitsLeft")
	if not hitsLeft or hitsLeft <= 0 then return end

	target:SetAttribute("HitsLeft", hitsLeft - 1)

	if hitsLeft - 1 <= 0 then
		-- Resource depleted — give drops and hide
		local drops = {}
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

		-- Hide resource, respawn later
		target.Transparency = 1
		target.CanCollide = false
		target:SetAttribute("Depleted", true)

		task.delay(Config.RESOURCE_RESPAWN_TIME, function()
			if target and target.Parent then
				target.Transparency = 0
				target.CanCollide = true
				target:SetAttribute("Depleted", false)
				if resourceType == "Tree" then
					target:SetAttribute("HitsLeft", Config.TREE_HITS)
				elseif resourceType == "Rock" then
					target:SetAttribute("HitsLeft", Config.ROCK_HITS)
				else
					target:SetAttribute("HitsLeft", 1)
				end
			end
		end)

		InventoryUpdated:FireClient(player, PlayerManager.getInventory(player))
	end
end)

-- Player connections
Players.PlayerAdded:Connect(function(player)
	PlayerManager.initPlayer(player)

	player.CharacterAdded:Connect(function(character)
		PlayerManager.onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerManager.cleanupPlayer(player)
end)

-- Initialize and start
SignalFireManager.init()

gameState.running = true
gameState.timeInCycle = 0
gameState.currentSol = 1

-- Set initial lighting
updateLighting(0)
SolUpdated:FireAllClients(1)

-- Connect to heartbeat (server tick)
RunService.Heartbeat:Connect(gameLoop)

print("[GameManager] Game started — Sol 1")
