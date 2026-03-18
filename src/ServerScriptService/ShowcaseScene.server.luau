--[[
	ShowcaseScene.server.luau
	Spawns all 25 buildings in a 5×5 grid organised by zone (one row per biome)
	for design review and walk-through testing.

	Grid layout:
	  Row 1 (Z = 0)    → Zone 1: Crash Site       (5 buildings)
	  Row 2 (Z = +gap) → Zone 2: Deep Woods        (5 buildings)
	  Row 3             → Zone 3: The Ruins         (5 buildings)
	  Row 4             → Zone 4: Spore Valley      (5 buildings)
	  Row 5             → Zone 5: The Core          (5 buildings)

	Each cell is 200×200 studs with a ground plate coloured per biome.
	A central spawn platform with teleport pads lets the player jump
	between buildings quickly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local BuildingData      = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BuildingData"))
local BuildingGenerator = require(script.Parent:WaitForChild("BuildingGenerator"))

---------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------

local CELL_SIZE    = 200   -- studs per grid cell
local GRID_COLS    = 5
local GRID_ROWS    = 5
local GRID_ORIGIN  = Vector3.new(-CELL_SIZE * (GRID_COLS - 1) / 2, 0, -CELL_SIZE * (GRID_ROWS - 1) / 2)

local ZONE_GROUND_COLORS = {
	[1] = BrickColor.new("Earth green").Color,      -- Crash Site: forest floor
	[2] = BrickColor.new("Dark green").Color,        -- Deep Woods: dense canopy floor
	[3] = BrickColor.new("Sand blue").Color,         -- The Ruins: ancient stone
	[4] = BrickColor.new("Lavender").Color,          -- Spore Valley: fungal
	[5] = BrickColor.new("Dark stone grey").Color,   -- The Core: alien rock
}

local ZONE_GROUND_MATERIALS = {
	[1] = Enum.Material.Grass,
	[2] = Enum.Material.LeafyGrass,
	[3] = Enum.Material.Slate,
	[4] = Enum.Material.SmoothPlastic,
	[5] = Enum.Material.Basalt,
}

local ZONE_NAMES = {
	[1] = "CRASH SITE",
	[2] = "DEEP WOODS",
	[3] = "THE RUINS",
	[4] = "SPORE VALLEY",
	[5] = "THE CORE",
}

---------------------------------------------------------------------
-- Create root folders
---------------------------------------------------------------------

local showcaseFolder = Instance.new("Folder")
showcaseFolder.Name = "BuildingShowcase"
showcaseFolder.Parent = workspace

local groundFolder = Instance.new("Folder")
groundFolder.Name = "GroundPlates"
groundFolder.Parent = showcaseFolder

local buildingsFolder = Instance.new("Folder")
buildingsFolder.Name = "Buildings"
buildingsFolder.Parent = showcaseFolder

local teleportFolder = Instance.new("Folder")
teleportFolder.Name = "TeleportPads"
teleportFolder.Parent = showcaseFolder

---------------------------------------------------------------------
-- Helper: create a billboard label
---------------------------------------------------------------------

local function addLabel(parent, text, offset, textColor, fontSize)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, fontSize or 300, 0, 60)
	bb.StudsOffset = offset or Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = textColor or Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.Text = text
	tl.Parent = bb
end

---------------------------------------------------------------------
-- Build the grid
---------------------------------------------------------------------

print("[ShowcaseScene] Generating 25 buildings in a 5x5 grid...")

local buildIndex = 0

for zone = 1, GRID_ROWS do
	local zoneBuildings = BuildingData.ByZone[zone]
	if not zoneBuildings then continue end

	-- Zone row label (floating sign at the left edge)
	local rowLabelPos = GRID_ORIGIN + Vector3.new(-CELL_SIZE * 0.6, 30, (zone - 1) * CELL_SIZE)
	local rowSign = Instance.new("Part")
	rowSign.Name = "ZoneSign_" .. zone
	rowSign.Anchored = true
	rowSign.CanCollide = false
	rowSign.Transparency = 1
	rowSign.Size = Vector3.new(1, 1, 1)
	rowSign.Position = rowLabelPos
	rowSign.Parent = groundFolder
	addLabel(rowSign, ZONE_NAMES[zone], Vector3.new(0, 0, 0), ZONE_GROUND_COLORS[zone], 400)

	for col = 1, math.min(#zoneBuildings, GRID_COLS) do
		buildIndex += 1
		local bData = zoneBuildings[col]

		-- Cell centre
		local cellOrigin = GRID_ORIGIN + Vector3.new((col - 1) * CELL_SIZE, 0, (zone - 1) * CELL_SIZE)

		-- Ground plate
		local ground = Instance.new("Part")
		ground.Name = "Ground_" .. bData.id
		ground.Anchored = true
		ground.Size = Vector3.new(CELL_SIZE - 4, 2, CELL_SIZE - 4)
		ground.Position = cellOrigin + Vector3.new(0, -1, 0)
		ground.Color = ZONE_GROUND_COLORS[zone]
		ground.Material = ZONE_GROUND_MATERIALS[zone]
		ground.TopSurface = Enum.SurfaceType.Smooth
		ground.BottomSurface = Enum.SurfaceType.Smooth
		ground.Parent = groundFolder

		-- Generate building
		local buildingModel = BuildingGenerator.Generate(bData, cellOrigin + Vector3.new(0, 1, 0))
		buildingModel.Parent = buildingsFolder

		-- Teleport pad at ground level near building entrance
		local padPos = cellOrigin + Vector3.new(0, 1, -(CELL_SIZE / 2 - 10))
		local pad = Instance.new("Part")
		pad.Name = "TeleportPad_" .. bData.id
		pad.Anchored = true
		pad.Size = Vector3.new(8, 1, 8)
		pad.Position = padPos
		pad.Color = ZONE_GROUND_COLORS[zone]
		pad.Material = Enum.Material.Neon
		pad.Transparency = 0.3
		pad.TopSurface = Enum.SurfaceType.Smooth
		pad.BottomSurface = Enum.SurfaceType.Smooth
		pad.Parent = teleportFolder
		pad:SetAttribute("BuildingId", bData.id)
		pad:SetAttribute("BuildingName", bData.name)
		addLabel(pad, bData.name, Vector3.new(0, 4, 0))

		print(string.format("[ShowcaseScene] %d/25 — %s (Zone %d)", buildIndex, bData.name, zone))
	end
end

---------------------------------------------------------------------
-- Central Hub Platform with teleport directory
---------------------------------------------------------------------

local hubPos = Vector3.new(0, 5, -CELL_SIZE * (GRID_ROWS + 1) / 2)

-- Hub platform
local hub = Instance.new("Part")
hub.Name = "HubPlatform"
hub.Anchored = true
hub.Size = Vector3.new(120, 3, 120)
hub.Position = hubPos
hub.Color = Color3.fromRGB(40, 40, 50)
hub.Material = Enum.Material.SmoothPlastic
hub.TopSurface = Enum.SurfaceType.Smooth
hub.BottomSurface = Enum.SurfaceType.Smooth
hub.Parent = showcaseFolder

-- Hub label
local hubLabel = Instance.new("Part")
hubLabel.Name = "HubLabel"
hubLabel.Anchored = true
hubLabel.CanCollide = false
hubLabel.Transparency = 1
hubLabel.Size = Vector3.new(1, 1, 1)
hubLabel.Position = hubPos + Vector3.new(0, 20, 0)
hubLabel.Parent = showcaseFolder
addLabel(hubLabel, "BUILDING SHOWCASE — 25 STRUCTURES", Vector3.new(0, 0, 0), Color3.fromRGB(255, 220, 100), 500)

local subLabel = Instance.new("Part")
subLabel.Name = "HubSubLabel"
subLabel.Anchored = true
subLabel.CanCollide = false
subLabel.Transparency = 1
subLabel.Size = Vector3.new(1, 1, 1)
subLabel.Position = hubPos + Vector3.new(0, 14, 0)
subLabel.Parent = showcaseFolder
addLabel(subLabel, "Step on a coloured pad to teleport to that building", Vector3.new(0, 0, 0), Color3.fromRGB(180, 180, 180), 450)

-- Create teleport pads on the hub (5×5 mini-grid)
local miniPadSize = 10
local miniGap = 4
local miniGridWidth = GRID_COLS * (miniPadSize + miniGap) - miniGap
local miniGridDepth = GRID_ROWS * (miniPadSize + miniGap) - miniGap
local miniOrigin = hubPos + Vector3.new(-miniGridWidth / 2 + miniPadSize / 2, 1.6, -miniGridDepth / 2 + miniPadSize / 2)

local hubPadTargets = {} -- padPart → target position

buildIndex = 0
for zone = 1, GRID_ROWS do
	local zoneBuildings = BuildingData.ByZone[zone]
	if not zoneBuildings then continue end

	for col = 1, math.min(#zoneBuildings, GRID_COLS) do
		buildIndex += 1
		local bData = zoneBuildings[col]

		local padPos2 = miniOrigin + Vector3.new((col - 1) * (miniPadSize + miniGap), 0, (zone - 1) * (miniPadSize + miniGap))
		local targetPos = GRID_ORIGIN + Vector3.new((col - 1) * CELL_SIZE, 5, (zone - 1) * CELL_SIZE) + Vector3.new(0, 0, -(CELL_SIZE / 2 - 15))

		local miniPad = Instance.new("Part")
		miniPad.Name = "HubPad_" .. bData.id
		miniPad.Anchored = true
		miniPad.Size = Vector3.new(miniPadSize, 1, miniPadSize)
		miniPad.Position = padPos2
		miniPad.Color = ZONE_GROUND_COLORS[zone]
		miniPad.Material = Enum.Material.Neon
		miniPad.Transparency = 0.2
		miniPad.TopSurface = Enum.SurfaceType.Smooth
		miniPad.BottomSurface = Enum.SurfaceType.Smooth
		miniPad.Parent = showcaseFolder

		addLabel(miniPad, bData.name, Vector3.new(0, 3, 0), ZONE_GROUND_COLORS[zone], 200)

		hubPadTargets[miniPad] = targetPos
	end
end

---------------------------------------------------------------------
-- Teleportation logic
---------------------------------------------------------------------

local debounce = {}

local function setupTeleport(pad: BasePart, targetPosition: Vector3)
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if debounce[player.UserId] then return end

		debounce[player.UserId] = true

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(targetPosition + Vector3.new(0, 3, 0))
		end

		task.delay(2, function()
			debounce[player.UserId] = nil
		end)
	end)
end

-- Connect hub pads
for pad, target in hubPadTargets do
	setupTeleport(pad, target)
end

-- Connect return pads (at each building entrance) back to hub
for _, pad in teleportFolder:GetChildren() do
	setupTeleport(pad, hubPos + Vector3.new(0, 3, 0))
end

---------------------------------------------------------------------
-- Spawn players on hub
---------------------------------------------------------------------

local spawn = Instance.new("SpawnLocation")
spawn.Name = "ShowcaseSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = hubPos + Vector3.new(0, 1.6, -40)
spawn.Color = Color3.fromRGB(80, 200, 80)
spawn.Material = Enum.Material.Neon
spawn.Transparency = 0.3
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.BottomSurface = Enum.SurfaceType.Smooth
spawn.Parent = showcaseFolder

print("[ShowcaseScene] ✓ All 25 buildings generated. Hub platform ready.")
print("[ShowcaseScene] Grid: 5 rows (zones) × 5 columns = 25 structures")
print("[ShowcaseScene] Cell size: " .. CELL_SIZE .. " studs | Total area: " .. (CELL_SIZE * GRID_COLS) .. " × " .. (CELL_SIZE * GRID_ROWS) .. " studs")
