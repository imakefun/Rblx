--[[
	BuildingGenerator.luau
	Procedural building creation system for "Stranded: The Forest Beyond"

	Generates explorable multi-floor structures from BuildingData definitions.
	Each building contains:
	  - Exterior walls, roof, and foundation
	  - Interior floors with rooms, corridors, and staircases
	  - Trap placements (visual markers + kill bricks)
	  - Enemy spawn points (marked with SpawnPoint parts)
	  - Loot containers (glowing crates)
	  - Puzzle elements (visual indicators)
	  - Boss arena (for buildings with hiddenBoss)
	  - Decorative details per biome theme
]]

local BuildingGenerator = {}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function color(brickColorName: string): Color3
	local ok, bc = pcall(BrickColor.new, brickColorName)
	if ok then return bc.Color end
	return BrickColor.new("Medium stone grey").Color
end

local function makePart(parent: Instance, props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function makeLabel(parent: Instance, text: string, studOffset: Vector3?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset = studOffset or Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.Text = text
	tl.Parent = bb
end

local function makePointLight(parent: Instance, lightColor: Color3, brightness: number?, range: number?)
	local pl = Instance.new("PointLight")
	pl.Color = lightColor
	pl.Brightness = brightness or 1
	pl.Range = range or 20
	pl.Parent = parent
end

local function makeGlow(part: BasePart, glowColor: Color3)
	part.Material = Enum.Material.Neon
	part.Color = glowColor
	makePointLight(part, glowColor, 0.8, 14)
end

---------------------------------------------------------------------
-- Sub-generators
---------------------------------------------------------------------

-- Foundation / floor slab
local function buildFloorSlab(parent, origin, sizeX, sizeZ, floorY, floorColor, material)
	local thickness = 2
	return makePart(parent, {
		Name = "FloorSlab",
		Size = Vector3.new(sizeX, thickness, sizeZ),
		Position = origin + Vector3.new(0, floorY, 0),
		Color = floorColor,
		Material = material or Enum.Material.Concrete,
	})
end

-- Exterior walls with window cut-outs (using multiple segments)
local function buildWalls(parent, origin, sizeX, sizeZ, baseY, wallHeight, wallColor, accentColor, material, windowChance)
	local wallThickness = 3
	local windowChance2 = windowChance or 0.3
	local segHeight = math.min(wallHeight, 8)
	local numSegs = math.max(1, math.floor(wallHeight / segHeight))

	-- Four walls: +X, -X, +Z, -Z
	local wallDefs = {
		{ name = "WallPosX", size = Vector3.new(wallThickness, segHeight, sizeZ), offsetFn = function(sy) return Vector3.new(sizeX/2, sy, 0) end },
		{ name = "WallNegX", size = Vector3.new(wallThickness, segHeight, sizeZ), offsetFn = function(sy) return Vector3.new(-sizeX/2, sy, 0) end },
		{ name = "WallPosZ", size = Vector3.new(sizeX - wallThickness*2, segHeight, wallThickness), offsetFn = function(sy) return Vector3.new(0, sy, sizeZ/2) end },
		{ name = "WallNegZ", size = Vector3.new(sizeX - wallThickness*2, segHeight, wallThickness), offsetFn = function(sy) return Vector3.new(0, sy, -sizeZ/2) end },
	}

	for _, wd in wallDefs do
		for seg = 0, numSegs - 1 do
			local sy = baseY + segHeight/2 + seg * segHeight
			local isWindow = math.random() < windowChance2 and seg > 0
			if isWindow then
				-- Two smaller segments with a gap (window)
				local halfLen
				if wd.size.X > wd.size.Z then
					halfLen = wd.size.X
				else
					halfLen = wd.size.Z
				end
				local windowWidth = math.min(6, halfLen * 0.3)
				-- Just make a slightly transparent segment to suggest a window
				local wp = makePart(parent, {
					Name = wd.name .. "_Window",
					Size = wd.size,
					Position = origin + wd.offsetFn(sy),
					Color = accentColor,
					Material = Enum.Material.Glass,
					Transparency = 0.5,
				})
			else
				makePart(parent, {
					Name = wd.name,
					Size = wd.size,
					Position = origin + wd.offsetFn(sy),
					Color = wallColor,
					Material = material or Enum.Material.Concrete,
				})
			end
		end
	end
end

-- Roof
local function buildRoof(parent, origin, sizeX, sizeZ, topY, roofColor, roofStyle, accentColor)
	if roofStyle == "dome" then
		-- Dome made of a sphere-like part
		local radius = math.min(sizeX, sizeZ) / 2
		makePart(parent, {
			Name = "RoofDome",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(radius * 2, radius, radius * 2),
			Position = origin + Vector3.new(0, topY + radius/2, 0),
			Color = roofColor,
			Material = Enum.Material.SmoothPlastic,
		})
	elseif roofStyle == "spire" then
		-- Tall pointed top
		local spireH = 20
		makePart(parent, {
			Name = "RoofSpire",
			Size = Vector3.new(6, spireH, 6),
			Position = origin + Vector3.new(0, topY + spireH/2, 0),
			Color = accentColor,
			Material = Enum.Material.Neon,
		})
		-- Base cap
		makePart(parent, {
			Name = "RoofCap",
			Size = Vector3.new(sizeX, 2, sizeZ),
			Position = origin + Vector3.new(0, topY, 0),
			Color = roofColor,
			Material = Enum.Material.Concrete,
		})
	elseif roofStyle == "organic" then
		-- Mushroom cap / organic dome
		makePart(parent, {
			Name = "RoofOrganic",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(sizeX * 1.2, sizeX * 0.5, sizeZ * 1.2),
			Position = origin + Vector3.new(0, topY + sizeX * 0.15, 0),
			Color = roofColor,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.1,
		})
	elseif roofStyle == "open" then
		-- No solid roof — just corner pillars implying ruins
		for _, cx in { -1, 1 } do
			for _, cz in { -1, 1 } do
				makePart(parent, {
					Name = "RoofPillar",
					Size = Vector3.new(4, 12, 4),
					Position = origin + Vector3.new(cx * (sizeX/2 - 2), topY + 6, cz * (sizeZ/2 - 2)),
					Color = roofColor,
					Material = Enum.Material.Slate,
				})
			end
		end
	else
		-- Flat roof
		makePart(parent, {
			Name = "RoofFlat",
			Size = Vector3.new(sizeX + 2, 2, sizeZ + 2),
			Position = origin + Vector3.new(0, topY, 0),
			Color = roofColor,
			Material = Enum.Material.Concrete,
		})
	end
end

-- Internal staircase between floors
local function buildStaircase(parent, origin, baseY, floorHeight, stairColor)
	local steps = 8
	local stepH = floorHeight / steps
	local stepD = 3
	local stepW = 6

	for i = 0, steps - 1 do
		makePart(parent, {
			Name = "Stair_" .. i,
			Size = Vector3.new(stepW, stepH, stepD),
			Position = origin + Vector3.new(0, baseY + stepH/2 + i * stepH, -i * stepD),
			Color = stairColor,
			Material = Enum.Material.Concrete,
		})
	end
end

-- Interior room dividers
local function buildInteriorWalls(parent, origin, sizeX, sizeZ, floorY, wallHeight, wallColor)
	local numRoomsX = math.max(1, math.floor(sizeX / 25))
	local numRoomsZ = math.max(1, math.floor(sizeZ / 25))

	for ix = 1, numRoomsX - 1 do
		local xPos = -sizeX/2 + ix * (sizeX / numRoomsX)
		-- Leave a doorway gap in the middle
		local wallLen = sizeZ * 0.35
		makePart(parent, {
			Name = "IntWall_X_" .. ix .. "_A",
			Size = Vector3.new(2, wallHeight, wallLen),
			Position = origin + Vector3.new(xPos, floorY + wallHeight/2, sizeZ/2 - wallLen/2),
			Color = wallColor,
			Material = Enum.Material.Concrete,
		})
		makePart(parent, {
			Name = "IntWall_X_" .. ix .. "_B",
			Size = Vector3.new(2, wallHeight, wallLen),
			Position = origin + Vector3.new(xPos, floorY + wallHeight/2, -sizeZ/2 + wallLen/2),
			Color = wallColor,
			Material = Enum.Material.Concrete,
		})
	end

	for iz = 1, numRoomsZ - 1 do
		local zPos = -sizeZ/2 + iz * (sizeZ / numRoomsZ)
		local wallLen = sizeX * 0.35
		makePart(parent, {
			Name = "IntWall_Z_" .. iz .. "_A",
			Size = Vector3.new(wallLen, wallHeight, 2),
			Position = origin + Vector3.new(sizeX/2 - wallLen/2, floorY + wallHeight/2, zPos),
			Color = wallColor,
			Material = Enum.Material.Concrete,
		})
		makePart(parent, {
			Name = "IntWall_Z_" .. iz .. "_B",
			Size = Vector3.new(wallLen, wallHeight, 2),
			Position = origin + Vector3.new(-sizeX/2 + wallLen/2, floorY + wallHeight/2, zPos),
			Color = wallColor,
			Material = Enum.Material.Concrete,
		})
	end
end

-- Doorway (entrance hole in front wall)
local function buildEntrance(parent, origin, sizeZ, baseY, wallColor)
	local doorW = 8
	local doorH = 12
	-- Archway frame
	makePart(parent, {
		Name = "DoorFrameL",
		Size = Vector3.new(2, doorH, 3),
		Position = origin + Vector3.new(-doorW/2 - 1, baseY + doorH/2, -sizeZ/2),
		Color = wallColor,
		Material = Enum.Material.Concrete,
	})
	makePart(parent, {
		Name = "DoorFrameR",
		Size = Vector3.new(2, doorH, 3),
		Position = origin + Vector3.new(doorW/2 + 1, baseY + doorH/2, -sizeZ/2),
		Color = wallColor,
		Material = Enum.Material.Concrete,
	})
	makePart(parent, {
		Name = "DoorLintel",
		Size = Vector3.new(doorW + 6, 3, 4),
		Position = origin + Vector3.new(0, baseY + doorH + 1.5, -sizeZ/2),
		Color = wallColor,
		Material = Enum.Material.Concrete,
	})
end

---------------------------------------------------------------------
-- Gameplay element generators
---------------------------------------------------------------------

local function placeLootCrates(parent, origin, sizeX, sizeZ, floors, floorHeight, baseY, lootData, accentColor)
	local folder = Instance.new("Folder")
	folder.Name = "LootCrates"
	folder.Parent = parent

	local crateCount = 0
	for _, loot in lootData do
		crateCount += math.ceil(loot.chance * 3)
	end
	crateCount = math.clamp(crateCount, 2, 12)

	for i = 1, crateCount do
		local floor = math.random(1, floors)
		local fy = baseY + (floor - 1) * floorHeight + 3
		local rx = math.random() * (sizeX * 0.6) - sizeX * 0.3
		local rz = math.random() * (sizeZ * 0.6) - sizeZ * 0.3

		local crate = makePart(folder, {
			Name = "LootCrate_" .. i,
			Size = Vector3.new(3, 3, 3),
			Position = origin + Vector3.new(rx, fy, rz),
			Color = accentColor,
			Material = Enum.Material.SmoothPlastic,
		})
		crate:SetAttribute("IsLoot", true)
		crate:SetAttribute("CrateIndex", i)

		-- Glow effect
		makePointLight(crate, accentColor, 0.6, 10)

		-- Top highlight
		makePart(folder, {
			Name = "CrateGlow_" .. i,
			Size = Vector3.new(2, 0.5, 2),
			Position = origin + Vector3.new(rx, fy + 1.75, rz),
			Color = accentColor,
			Material = Enum.Material.Neon,
			Transparency = 0.3,
		})
	end
end

local function placeTrapMarkers(parent, origin, sizeX, sizeZ, floors, floorHeight, baseY, trapsData)
	local folder = Instance.new("Folder")
	folder.Name = "Traps"
	folder.Parent = parent

	for _, trap in trapsData do
		for i = 1, trap.count do
			local floor = math.random(1, floors)
			local fy = baseY + (floor - 1) * floorHeight + 1
			local rx = math.random() * (sizeX * 0.7) - sizeX * 0.35
			local rz = math.random() * (sizeZ * 0.7) - sizeZ * 0.35

			local trapPart = makePart(folder, {
				Name = trap.type .. "_" .. i,
				Size = Vector3.new(5, 1, 5),
				Position = origin + Vector3.new(rx, fy, rz),
				Color = Color3.fromRGB(200, 50, 50),
				Material = Enum.Material.Neon,
				Transparency = 0.6,
			})
			trapPart:SetAttribute("TrapType", trap.type)
			trapPart:SetAttribute("Damage", trap.damage)
			trapPart:SetAttribute("IsTrap", true)

			-- Warning stripes (small accent part)
			makePart(folder, {
				Name = trap.type .. "_Warning_" .. i,
				Size = Vector3.new(5.2, 0.2, 5.2),
				Position = origin + Vector3.new(rx, fy + 0.6, rz),
				Color = Color3.fromRGB(255, 200, 0),
				Material = Enum.Material.Neon,
				Transparency = 0.4,
			})
		end
	end
end

local function placeEnemySpawns(parent, origin, sizeX, sizeZ, floors, floorHeight, baseY, enemiesData)
	local folder = Instance.new("Folder")
	folder.Name = "EnemySpawns"
	folder.Parent = parent

	for _, enemy in enemiesData do
		for i = 1, enemy.count do
			local floor = math.random(1, floors)
			local fy = baseY + (floor - 1) * floorHeight + 3
			local rx = math.random() * (sizeX * 0.6) - sizeX * 0.3
			local rz = math.random() * (sizeZ * 0.6) - sizeZ * 0.3

			local sp = makePart(folder, {
				Name = enemy.type .. "_Spawn_" .. i,
				Size = Vector3.new(2, 4, 2),
				Position = origin + Vector3.new(rx, fy, rz),
				Color = Color3.fromRGB(255, 80, 80),
				Material = Enum.Material.ForceField,
				Transparency = 0.5,
			})
			sp:SetAttribute("EnemyType", enemy.type)
			sp:SetAttribute("IsBoss", enemy.isBoss)
			sp:SetAttribute("IsSpawnPoint", true)

			makeLabel(sp, enemy.type, Vector3.new(0, 3, 0))
		end
	end
end

local function placeBossArena(parent, origin, sizeX, sizeZ, baseY, bossData, accentColor)
	local folder = Instance.new("Folder")
	folder.Name = "BossArena"
	folder.Parent = parent

	-- Arena platform
	local arenaSize = math.min(sizeX, sizeZ) * 0.5
	local arenaY = baseY + 1

	makePart(folder, {
		Name = "ArenaFloor",
		Size = Vector3.new(arenaSize, 1, arenaSize),
		Position = origin + Vector3.new(0, arenaY, 0),
		Color = accentColor,
		Material = Enum.Material.Neon,
		Transparency = 0.7,
	})

	-- Arena border pillars
	for angle = 0, 315, 45 do
		local rad = math.rad(angle)
		local dist = arenaSize / 2 - 2
		makePart(folder, {
			Name = "ArenaPillar_" .. angle,
			Size = Vector3.new(3, 15, 3),
			Position = origin + Vector3.new(math.cos(rad) * dist, arenaY + 7.5, math.sin(rad) * dist),
			Color = accentColor,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		})
	end

	-- Boss spawn marker
	local bossSpawn = makePart(folder, {
		Name = "BossSpawn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 8, 8),
		CFrame = CFrame.new(origin + Vector3.new(0, arenaY + 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 0, 80),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	})
	bossSpawn:SetAttribute("IsBossSpawn", true)
	bossSpawn:SetAttribute("BossName", bossData.name)
	bossSpawn:SetAttribute("BossHealth", bossData.health)
	bossSpawn:SetAttribute("BossDamage", bossData.damage)

	makeLabel(bossSpawn, "BOSS: " .. bossData.name, Vector3.new(0, 6, 0))
	makePointLight(bossSpawn, Color3.fromRGB(255, 0, 80), 2, 30)
end

local function placePuzzleElements(parent, origin, sizeX, sizeZ, baseY, floorHeight, puzzleData, accentColor, lightColor)
	local folder = Instance.new("Folder")
	folder.Name = "Puzzle"
	folder.Parent = parent

	-- Central puzzle marker
	local fy = baseY + floorHeight / 2
	local marker = makePart(folder, {
		Name = "PuzzleMarker",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 6, 6),
		Position = origin + Vector3.new(0, fy + 3, 0),
		Color = lightColor,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	})
	marker:SetAttribute("PuzzleType", puzzleData.type)
	marker:SetAttribute("PuzzleDesc", puzzleData.description)

	makeLabel(marker, "PUZZLE: " .. puzzleData.type, Vector3.new(0, 5, 0))
	makePointLight(marker, lightColor, 1.5, 25)

	-- Interaction nodes around the room
	local nodeCount = 4
	for i = 1, nodeCount do
		local angle = math.rad((i - 1) * (360 / nodeCount))
		local dist = math.min(sizeX, sizeZ) * 0.3
		local node = makePart(folder, {
			Name = "PuzzleNode_" .. i,
			Size = Vector3.new(3, 5, 3),
			Position = origin + Vector3.new(math.cos(angle) * dist, fy, math.sin(angle) * dist),
			Color = accentColor,
			Material = Enum.Material.Neon,
			Transparency = 0.5,
		})
		node:SetAttribute("NodeIndex", i)
		node:SetAttribute("IsInteractable", true)
	end
end

---------------------------------------------------------------------
-- Biome decorators
---------------------------------------------------------------------

local function decorateCrashSite(parent, origin, sizeX, sizeZ, baseY, height)
	-- Scattered debris, sparking wires
	for i = 1, 6 do
		local rx = math.random() * sizeX * 0.8 - sizeX * 0.4
		local rz = math.random() * sizeZ * 0.8 - sizeZ * 0.4
		makePart(parent, {
			Name = "Debris_" .. i,
			Size = Vector3.new(math.random(2, 5), math.random(1, 3), math.random(2, 5)),
			Position = origin + Vector3.new(rx, baseY + 1.5, rz),
			Color = BrickColor.new("Dark stone grey").Color,
			Material = Enum.Material.CorrodedMetal,
			Rotation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15)),
		})
	end
end

local function decorateDeepWoods(parent, origin, sizeX, sizeZ, baseY, height)
	-- Bone/wood decorations, hanging vines (thin parts)
	for i = 1, 5 do
		local rx = (math.random() - 0.5) * sizeX * 0.9
		local rz = (math.random() - 0.5) * sizeZ * 0.9
		-- Bone pillar
		makePart(parent, {
			Name = "BoneDecor_" .. i,
			Size = Vector3.new(2, math.random(6, 14), 2),
			Position = origin + Vector3.new(rx, baseY + 5, rz),
			Color = BrickColor.new("Institutional white").Color,
			Material = Enum.Material.Marble,
		})
	end
	-- Hanging vines from top
	for i = 1, 8 do
		local rx = (math.random() - 0.5) * sizeX * 0.8
		local rz = (math.random() - 0.5) * sizeZ * 0.8
		makePart(parent, {
			Name = "Vine_" .. i,
			Size = Vector3.new(0.5, math.random(8, 20), 0.5),
			Position = origin + Vector3.new(rx, baseY + height - 5, rz),
			Color = BrickColor.new("Dark green").Color,
			Material = Enum.Material.Grass,
		})
	end
end

local function decorateRuins(parent, origin, sizeX, sizeZ, baseY, height)
	-- Glyph pillars, broken columns
	for i = 1, 6 do
		local angle = math.rad((i - 1) * 60)
		local dist = math.min(sizeX, sizeZ) * 0.35
		local pillarH = math.random(8, 16)
		local pillar = makePart(parent, {
			Name = "GlyphPillar_" .. i,
			Size = Vector3.new(3, pillarH, 3),
			Position = origin + Vector3.new(math.cos(angle) * dist, baseY + pillarH/2, math.sin(angle) * dist),
			Color = BrickColor.new("Sand blue").Color,
			Material = Enum.Material.Slate,
		})
		-- Glyph accent strip
		makePart(parent, {
			Name = "GlyphStrip_" .. i,
			Size = Vector3.new(3.2, 2, 0.5),
			Position = origin + Vector3.new(math.cos(angle) * dist, baseY + pillarH * 0.6, math.sin(angle) * dist - 1.5),
			Color = BrickColor.new("Cyan").Color,
			Material = Enum.Material.Neon,
			Transparency = 0.3,
		})
	end
end

local function decorateSporeValley(parent, origin, sizeX, sizeZ, baseY, height)
	-- Bioluminescent mushrooms, spore particles (represented by small glowing spheres)
	for i = 1, 10 do
		local rx = (math.random() - 0.5) * sizeX * 0.85
		local rz = (math.random() - 0.5) * sizeZ * 0.85
		local ry = baseY + math.random(2, math.max(3, math.floor(height * 0.7)))
		-- Mushroom stem
		local stemH = math.random(3, 8)
		makePart(parent, {
			Name = "MushroomStem_" .. i,
			Size = Vector3.new(1, stemH, 1),
			Position = origin + Vector3.new(rx, ry, rz),
			Color = BrickColor.new("Lavender").Color,
			Material = Enum.Material.SmoothPlastic,
		})
		-- Mushroom cap (glowing)
		local cap = makePart(parent, {
			Name = "MushroomCap_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(4, 2, 4),
			Position = origin + Vector3.new(rx, ry + stemH/2 + 1, rz),
			Color = BrickColor.new("Lime green").Color,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		})
		makePointLight(cap, BrickColor.new("Lime green").Color, 0.5, 8)
	end
	-- Floating spore particles
	for i = 1, 15 do
		local rx = (math.random() - 0.5) * sizeX * 0.9
		local rz = (math.random() - 0.5) * sizeZ * 0.9
		local ry = baseY + math.random(3, math.max(4, math.floor(height * 0.8)))
		makePart(parent, {
			Name = "Spore_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.5, 0.5, 0.5),
			Position = origin + Vector3.new(rx, ry, rz),
			Color = BrickColor.new("Lime green").Color,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		})
	end
end

local function decorateCore(parent, origin, sizeX, sizeZ, baseY, height)
	-- Crystal formations, energy conduits, alien tech
	for i = 1, 8 do
		local rx = (math.random() - 0.5) * sizeX * 0.7
		local rz = (math.random() - 0.5) * sizeZ * 0.7
		local crystalH = math.random(5, 15)
		local crystal = makePart(parent, {
			Name = "Crystal_" .. i,
			Size = Vector3.new(2, crystalH, 2),
			Position = origin + Vector3.new(rx, baseY + crystalH/2, rz),
			Color = BrickColor.new("Magenta").Color,
			Material = Enum.Material.Neon,
			Transparency = 0.15,
			Rotation = Vector3.new(math.random(-20, 20), math.random(0, 360), math.random(-20, 20)),
		})
		makePointLight(crystal, BrickColor.new("Magenta").Color, 0.8, 12)
	end
	-- Energy conduit lines on floor
	for i = 1, 4 do
		local isX = i <= 2
		local offset = (i % 2 == 0) and 1 or -1
		makePart(parent, {
			Name = "Conduit_" .. i,
			Size = isX and Vector3.new(sizeX * 0.8, 0.3, 1) or Vector3.new(1, 0.3, sizeZ * 0.8),
			Position = origin + Vector3.new(
				isX and 0 or (offset * sizeX * 0.2),
				baseY + 1.2,
				isX and (offset * sizeZ * 0.2) or 0
			),
			Color = BrickColor.new("Cyan").Color,
			Material = Enum.Material.Neon,
			Transparency = 0.3,
		})
	end
end

local biomeDecorators = {
	[1] = decorateCrashSite,
	[2] = decorateDeepWoods,
	[3] = decorateRuins,
	[4] = decorateSporeValley,
	[5] = decorateCore,
}

---------------------------------------------------------------------
-- Roof-style per zone
---------------------------------------------------------------------

local roofStyles = {
	[1] = "flat",      -- industrial wreckage
	[2] = "open",      -- organic / primitive
	[3] = "dome",      -- ancient alien
	[4] = "organic",   -- mushroom / spore
	[5] = "spire",     -- alien crystal tech
}

---------------------------------------------------------------------
-- Wall material per zone
---------------------------------------------------------------------

local wallMaterials = {
	[1] = Enum.Material.CorrodedMetal,
	[2] = Enum.Material.Wood,
	[3] = Enum.Material.Slate,
	[4] = Enum.Material.SmoothPlastic,
	[5] = Enum.Material.Glass,
}

---------------------------------------------------------------------
-- Main generator
---------------------------------------------------------------------

function BuildingGenerator.Generate(buildingData: any, origin: Vector3): Model
	local model = Instance.new("Model")
	model.Name = buildingData.id

	local sizeX = buildingData.footprint.x
	local sizeZ = buildingData.footprint.z
	local totalHeight = buildingData.height
	local numFloors = buildingData.floors
	local floorHeight = totalHeight / numFloors
	local zone = buildingData.zone

	local primaryColor = color(buildingData.palette.primary)
	local secondaryColor = color(buildingData.palette.secondary)
	local accentColor = color(buildingData.palette.accent)
	local lightColor = color(buildingData.palette.light)

	local baseY = origin.Y
	local wallMat = wallMaterials[zone] or Enum.Material.Concrete
	local roofStyle = roofStyles[zone] or "flat"

	-- Override roof style for specific tall buildings
	if totalHeight >= 80 then roofStyle = "spire" end

	-- Foundation
	buildFloorSlab(model, origin, sizeX + 4, sizeZ + 4, baseY - 1, secondaryColor, Enum.Material.Slate)

	-- Floors
	for f = 1, numFloors do
		local floorY = baseY + (f - 1) * floorHeight

		-- Floor slab (skip ground floor — foundation covers it)
		if f > 1 then
			local slab = buildFloorSlab(model, origin, sizeX - 2, sizeZ - 2, floorY, secondaryColor, Enum.Material.Concrete)
			-- Stairwell hole
			makePart(model, {
				Name = "StairwellHole_" .. f,
				Size = Vector3.new(8, 0.5, 8),
				Position = origin + Vector3.new(sizeX/2 - 8, floorY, sizeZ/2 - 8),
				Color = accentColor,
				Material = Enum.Material.Neon,
				Transparency = 0.7,
			})
		end

		-- Walls for this floor segment
		buildWalls(model, origin, sizeX, sizeZ, floorY, floorHeight, primaryColor, accentColor, wallMat, 0.25)

		-- Interior dividers
		if sizeX >= 40 or sizeZ >= 40 then
			buildInteriorWalls(model, origin, sizeX * 0.9, sizeZ * 0.9, floorY, math.min(floorHeight - 2, 10), secondaryColor)
		end

		-- Staircase to next floor
		if f < numFloors then
			buildStaircase(model, origin + Vector3.new(sizeX/2 - 10, 0, sizeZ/2 - 6), floorY + 2, floorHeight - 2, secondaryColor)
		end
	end

	-- Roof
	local topY = baseY + totalHeight
	buildRoof(model, origin, sizeX, sizeZ, topY, primaryColor, roofStyle, accentColor)

	-- Entrance
	buildEntrance(model, origin, sizeZ, baseY, accentColor)

	-- Biome decoration
	local decorator = biomeDecorators[zone]
	if decorator then
		decorator(model, origin, sizeX, sizeZ, baseY, totalHeight)
	end

	-- Gameplay elements
	placeLootCrates(model, origin, sizeX, sizeZ, numFloors, floorHeight, baseY, buildingData.loot, accentColor)
	placeTrapMarkers(model, origin, sizeX, sizeZ, numFloors, floorHeight, baseY, buildingData.traps)
	placeEnemySpawns(model, origin, sizeX, sizeZ, numFloors, floorHeight, baseY, buildingData.enemies)

	if buildingData.hiddenBoss then
		placeBossArena(model, origin, sizeX, sizeZ, baseY, buildingData.hiddenBoss, accentColor)
	end

	if buildingData.puzzle then
		placePuzzleElements(model, origin, sizeX, sizeZ, baseY, floorHeight, buildingData.puzzle, accentColor, lightColor)
	end

	-- Ambient light for the building
	local ambientLight = makePart(model, {
		Name = "AmbientLight",
		Size = Vector3.new(1, 1, 1),
		Position = origin + Vector3.new(0, baseY + totalHeight / 2, 0),
		Transparency = 1,
		CanCollide = false,
	})
	makePointLight(ambientLight, lightColor, 0.4, math.max(sizeX, sizeZ) * 0.6)

	-- Name billboard above building
	local signPost = makePart(model, {
		Name = "SignPost",
		Size = Vector3.new(2, 2, 2),
		Position = origin + Vector3.new(0, topY + 15, 0),
		Transparency = 1,
		CanCollide = false,
	})

	local signBB = Instance.new("BillboardGui")
	signBB.Size = UDim2.new(0, 350, 0, 80)
	signBB.AlwaysOnTop = true
	signBB.Parent = signPost

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = lightColor
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = buildingData.name
	nameLabel.Parent = signBB

	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Size = UDim2.new(1, 0, 0.35, 0)
	zoneLabel.Position = UDim2.new(0, 0, 0.6, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	zoneLabel.TextStrokeTransparency = 0.3
	zoneLabel.TextScaled = true
	zoneLabel.Font = Enum.Font.Gotham
	zoneLabel.Text = string.format("Zone %d · %s · Difficulty %s", buildingData.zone, buildingData.zoneName, string.rep("★", buildingData.difficulty))
	zoneLabel.Parent = signBB

	-- Set primary part
	model.PrimaryPart = model:FindFirstChild("FloorSlab")
	model.Parent = nil -- caller decides parent

	return model
end

return BuildingGenerator
