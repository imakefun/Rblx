-- SignalFireManager.luau
-- Manages the Signal Fire: fuel, dampening field, safe zone

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local SignalFireManager = {}

local state = {
	fuel = 50,               -- start with some fuel
	level = 1,
	position = Vector3.new(0, 0, 0),  -- set during init
	radius = Config.SIGNAL_FIRE_LEVELS[1].radius,
	maxFuel = Config.SIGNAL_FIRE_MAX_FUEL,
}

local fireModel: Model? = nil
local fieldPart: Part? = nil

function SignalFireManager.init()
	-- Create the Signal Fire in workspace
	local resources = workspace:FindFirstChild("Resources")
	if not resources then
		resources = Instance.new("Folder")
		resources.Name = "Resources"
		resources.Parent = workspace
	end

	-- Fire base
	local base = Instance.new("Part")
	base.Name = "SignalFire"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(2, 6, 6)
	base.Position = Vector3.new(0, 1, 0)
	base.Rotation = Vector3.new(0, 0, 90)
	base.Anchored = true
	base.Material = Enum.Material.Slate
	base.Color = Color3.fromRGB(80, 60, 40)
	base.Parent = workspace

	-- Fire effect
	local fire = Instance.new("Fire")
	fire.Size = 8
	fire.Heat = 10
	fire.Color = Color3.fromRGB(255, 150, 50)
	fire.SecondaryColor = Color3.fromRGB(255, 80, 20)
	fire.Parent = base

	-- Light
	local light = Instance.new("PointLight")
	light.Name = "FireLight"
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 40
	light.Parent = base

	-- Dampening field visualization (transparent cylinder)
	local field = Instance.new("Part")
	field.Name = "DampeningField"
	field.Shape = Enum.PartType.Cylinder
	field.Size = Vector3.new(1, state.radius * 2, state.radius * 2)
	field.Position = Vector3.new(0, 0.5, 0)
	field.Rotation = Vector3.new(0, 0, 90)
	field.Anchored = true
	field.CanCollide = false
	field.Transparency = 0.85
	field.Material = Enum.Material.ForceField
	field.Color = Color3.fromRGB(100, 180, 255)
	field.Parent = workspace

	state.position = base.Position
	fireModel = base
	fieldPart = field

	-- Create some initial resources around the fire
	SignalFireManager.spawnResources()

	print("[SignalFireManager] Signal Fire initialized at", state.position)
end

function SignalFireManager.spawnResources()
	local resources = workspace:FindFirstChild("Resources")
	if not resources then
		resources = Instance.new("Folder")
		resources.Name = "Resources"
		resources.Parent = workspace
	end

	-- Spawn trees in a ring around the campfire
	local treePositions = {}
	for i = 1, 30 do
		local angle = (i / 30) * math.pi * 2
		local dist = math.random(20, 80)
		local x = math.cos(angle) * dist + math.random(-5, 5)
		local z = math.sin(angle) * dist + math.random(-5, 5)
		table.insert(treePositions, Vector3.new(x, 0, z))
	end

	for i, pos in treePositions do
		local tree = Instance.new("Part")
		tree.Name = "Tree_" .. i
		tree.Size = Vector3.new(2, math.random(8, 14), 2)
		tree.Position = pos + Vector3.new(0, tree.Size.Y / 2, 0)
		tree.Anchored = true
		tree.Material = Enum.Material.Wood
		tree.Color = Color3.fromRGB(90, 65, 40)
		tree:SetAttribute("ResourceType", "Tree")
		tree:SetAttribute("HitsLeft", Config.TREE_HITS)
		tree:SetAttribute("Depleted", false)
		tree.Parent = resources

		-- Leaves
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(6, 6, 6) * (math.random(80, 120) / 100)
		leaves.Position = tree.Position + Vector3.new(0, tree.Size.Y / 2, 0)
		leaves.Anchored = true
		leaves.Material = Enum.Material.Grass
		leaves.Color = Color3.fromRGB(40, math.random(90, 130), 30)
		leaves.CanCollide = false
		leaves.Parent = tree
	end

	-- Spawn rocks
	for i = 1, 15 do
		local angle = math.random() * math.pi * 2
		local dist = math.random(15, 70)
		local rock = Instance.new("Part")
		rock.Name = "Rock_" .. i
		rock.Size = Vector3.new(math.random(2, 4), math.random(1, 3), math.random(2, 4))
		rock.Position = Vector3.new(math.cos(angle) * dist, rock.Size.Y / 2, math.sin(angle) * dist)
		rock.Anchored = true
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(120, 120, 120)
		rock:SetAttribute("ResourceType", "Rock")
		rock:SetAttribute("HitsLeft", Config.ROCK_HITS)
		rock:SetAttribute("Depleted", false)
		rock.Parent = resources
	end

	-- Spawn bushes
	for i = 1, 12 do
		local angle = math.random() * math.pi * 2
		local dist = math.random(10, 60)
		local bush = Instance.new("Part")
		bush.Name = "Bush_" .. i
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(3, 2, 3)
		bush.Position = Vector3.new(math.cos(angle) * dist, 1, math.sin(angle) * dist)
		bush.Anchored = true
		bush.Material = Enum.Material.Grass
		bush.Color = Color3.fromRGB(30, 100, 30)
		bush:SetAttribute("ResourceType", "Bush")
		bush:SetAttribute("HitsLeft", 1)
		bush:SetAttribute("Depleted", false)
		bush.Parent = resources
	end

	-- Spawn crash debris
	for i = 1, 8 do
		local angle = math.random() * math.pi * 2
		local dist = math.random(8, 40)
		local debris = Instance.new("Part")
		debris.Name = "Debris_" .. i
		debris.Size = Vector3.new(math.random(2, 5), math.random(1, 2), math.random(2, 5))
		debris.Position = Vector3.new(math.cos(angle) * dist, debris.Size.Y / 2, math.sin(angle) * dist)
		debris.Rotation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15))
		debris.Anchored = true
		debris.Material = Enum.Material.Metal
		debris.Color = Color3.fromRGB(160, 160, 170)
		debris:SetAttribute("ResourceType", "CrashDebris")
		debris:SetAttribute("HitsLeft", 2)
		debris:SetAttribute("Depleted", false)
		debris.Parent = resources
	end

	print("[SignalFireManager] Spawned resources around Signal Fire")
end

function SignalFireManager.update(dt: number)
	if state.fuel <= 0 then return end

	-- Burn fuel
	state.fuel = math.max(0, state.fuel - Config.SIGNAL_FIRE_BURN_RATE * dt)

	-- Update visual fire size based on fuel percentage
	if fireModel then
		local fireFX = fireModel:FindFirstChildOfClass("Fire")
		if fireFX then
			local fuelPct = state.fuel / state.maxFuel
			fireFX.Size = 3 + fuelPct * 12
			fireFX.Heat = 5 + fuelPct * 10
		end

		local light = fireModel:FindFirstChild("FireLight")
		if light then
			local fuelPct = state.fuel / state.maxFuel
			light.Brightness = 0.5 + fuelPct * 2.5
			light.Range = 15 + fuelPct * 35
		end
	end
end

function SignalFireManager.addFuel(amount: number)
	state.fuel = math.min(state.maxFuel, state.fuel + amount)
	print("[SignalFireManager] Fuel added. Current:", math.floor(state.fuel))
end

function SignalFireManager.upgradeLevel()
	if state.level >= 5 then return false end

	local nextLevel = state.level + 1
	local levelData = Config.SIGNAL_FIRE_LEVELS[nextLevel]

	state.level = nextLevel
	state.radius = levelData.radius

	-- Update field visual
	if fieldPart then
		fieldPart.Size = Vector3.new(1, state.radius * 2, state.radius * 2)
	end

	print("[SignalFireManager] Upgraded to level", state.level, "- Radius:", state.radius)
	return true
end

function SignalFireManager.isInField(position: Vector3): boolean
	local dist = (Vector3.new(position.X, 0, position.Z) - Vector3.new(state.position.X, 0, state.position.Z)).Magnitude
	return dist <= state.radius
end

function SignalFireManager.getState()
	return {
		fuel = state.fuel,
		maxFuel = state.maxFuel,
		level = state.level,
		radius = state.radius,
		position = state.position,
	}
end

function SignalFireManager.getPosition(): Vector3
	return state.position
end

return SignalFireManager
