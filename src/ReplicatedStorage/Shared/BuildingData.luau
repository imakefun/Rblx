--[[
	BuildingData.luau
	Definitions for 25 explorable structures across the 5 biomes of
	"Stranded: The Forest Beyond"

	Each building entry contains:
	  - id            : unique key
	  - name          : display name
	  - zone          : 1-5 matching game zones
	  - zoneName      : human-readable zone
	  - difficulty     : 1-5 star rating
	  - description    : flavour / lore text
	  - footprint      : {x, z} base size in studs
	  - height         : approximate total height in studs
	  - floors         : number of navigable levels
	  - palette        : {primary, secondary, accent, light} BrickColor names
	  - features       : list of gameplay tags
	  - enemies        : {type, count, isBoss}  (spawned inside)
	  - loot           : {itemId, chance, min, max}
	  - traps          : {type, count, damage}
	  - puzzle         : {type, description}  or nil
	  - hiddenBoss     : {name, health, damage, loot} or nil
]]

local BuildingData = {}

BuildingData.Buildings = {

	------------------------------------------------------------------------
	-- ZONE 1 · CRASH SITE  (familiar forest, wreckage, early-game)
	------------------------------------------------------------------------

	{
		id              = "wrecked_cargo_bay",
		name            = "Wrecked Cargo Bay",
		zone            = 1,
		zoneName        = "Crash Site",
		difficulty      = 1,
		description     = "A massive section of the original ship's cargo hold, torn open on impact. Crates and containers are scattered across multiple collapsed decks. The floors groan underfoot — some sections have rusted through entirely.",
		footprint       = { x = 80, z = 60 },
		height          = 40,
		floors          = 3,
		palette         = { primary = "Dark stone grey", secondary = "Medium stone grey", accent = "Bright orange", light = "Neon orange" },
		features        = { "loot", "traps", "parkour", "enemies" },
		enemies         = {
			{ type = "Stalker", count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "ScrapMetal",  chance = 0.9,  min = 2, max = 5 },
			{ itemId = "Wire",        chance = 0.7,  min = 1, max = 3 },
			{ itemId = "Components",  chance = 0.4,  min = 1, max = 2 },
			{ itemId = "BatteryCell", chance = 0.15, min = 1, max = 1 },
		},
		traps           = {
			{ type = "CollapsingFloor", count = 4, damage = 20 },
			{ type = "SteamVent",       count = 3, damage = 10 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "emergency_bunker",
		name            = "Emergency Bunker",
		zone            = 1,
		zoneName        = "Crash Site",
		difficulty      = 2,
		description     = "A reinforced underground shelter built by previous survivors who never made it off-world. Airtight doors seal each section — some require power cells to open. Journals on makeshift desks hint at what drove them mad.",
		footprint       = { x = 50, z = 50 },
		height          = 20,
		floors          = 2,
		palette         = { primary = "Dark stone grey", secondary = "Earth green", accent = "Sand red", light = "Cool yellow" },
		features        = { "loot", "puzzle", "lore", "traps" },
		enemies         = {
			{ type = "Stalker", count = 1, isBoss = false },
		},
		loot            = {
			{ itemId = "Medkit",      chance = 0.5,  min = 1, max = 2 },
			{ itemId = "ScrapMetal",  chance = 0.8,  min = 1, max = 3 },
			{ itemId = "Components",  chance = 0.5,  min = 1, max = 2 },
			{ itemId = "BatteryCell", chance = 0.25, min = 1, max = 1 },
		},
		traps           = {
			{ type = "TripwireAlarm", count = 2, damage = 0  },
			{ type = "PitFall",       count = 1, damage = 25 },
		},
		puzzle          = { type = "PowerCell", description = "Find and insert 3 power cells to unlock the inner vault." },
		hiddenBoss      = nil,
	},

	{
		id              = "overgrown_radio_tower",
		name            = "Overgrown Radio Tower",
		zone            = 1,
		zoneName        = "Crash Site",
		difficulty      = 2,
		description     = "A skeletal communications tower from an earlier expedition, now strangled by alien vines that pulse faintly at night. The climb is treacherous, but the transmitter at the top still holds salvageable tech.",
		footprint       = { x = 30, z = 30 },
		height          = 90,
		floors          = 6,
		palette         = { primary = "Medium stone grey", secondary = "Earth green", accent = "Bright red", light = "Neon orange" },
		features        = { "loot", "parkour", "enemies", "verticality" },
		enemies         = {
			{ type = "Stalker", count = 3, isBoss = false },
		},
		loot            = {
			{ itemId = "Wire",        chance = 0.8,  min = 2, max = 4 },
			{ itemId = "Components",  chance = 0.6,  min = 1, max = 3 },
			{ itemId = "ScrapMetal",  chance = 0.5,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "CollapsingPlatform", count = 3, damage = 15 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "abandoned_survivor_camp",
		name            = "Abandoned Survivor Camp",
		zone            = 1,
		zoneName        = "Crash Site",
		difficulty      = 1,
		description     = "A sprawling camp of lean-tos, scrap walls, and overturned vehicles. Whoever lived here left in a hurry — or didn't leave at all. Booby traps still guard the supply caches they hid beneath the floorboards.",
		footprint       = { x = 70, z = 70 },
		height          = 15,
		floors          = 1,
		palette         = { primary = "Brown", secondary = "Dark stone grey", accent = "Sand red", light = "Warm yellow" },
		features        = { "loot", "traps", "lore", "exploration" },
		enemies         = {
			{ type = "Stalker", count = 1, isBoss = false },
		},
		loot            = {
			{ itemId = "Wood",        chance = 0.9,  min = 3, max = 6 },
			{ itemId = "ScrapMetal",  chance = 0.7,  min = 1, max = 3 },
			{ itemId = "Berries",     chance = 0.6,  min = 2, max = 5 },
			{ itemId = "RawMeat",     chance = 0.3,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "BearTrap",      count = 5, damage = 30 },
			{ type = "TripwireAlarm", count = 3, damage = 0  },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "fuel_depot_ruins",
		name            = "Fuel Depot Ruins",
		zone            = 1,
		zoneName        = "Crash Site",
		difficulty      = 3,
		description     = "Half-buried fuel storage tanks jut from the hillside like broken ribs. Volatile fumes still leak from cracked pipes — one wrong step and the whole place ignites. But the fuel inside is priceless.",
		footprint       = { x = 60, z = 40 },
		height          = 25,
		floors          = 2,
		palette         = { primary = "Dark stone grey", secondary = "Bright yellow", accent = "Bright red", light = "Neon orange" },
		features        = { "loot", "traps", "hazard", "enemies" },
		enemies         = {
			{ type = "Stalker", count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "BatteryCell", chance = 0.6,  min = 1, max = 2 },
			{ itemId = "Coal",        chance = 0.7,  min = 2, max = 4 },
			{ itemId = "ScrapMetal",  chance = 0.8,  min = 2, max = 4 },
			{ itemId = "Components",  chance = 0.3,  min = 1, max = 1 },
		},
		traps           = {
			{ type = "ExplosiveBarrel", count = 6, damage = 45 },
			{ type = "GasLeak",         count = 3, damage = 8  },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	------------------------------------------------------------------------
	-- ZONE 2 · DEEP WOODS  (dense forest, Kethari territory)
	------------------------------------------------------------------------

	{
		id              = "kethari_watchtower",
		name            = "Kethari Watchtower",
		zone            = 2,
		zoneName        = "Deep Woods",
		difficulty      = 3,
		description     = "A towering structure of lashed bone and alien timber, rising above the canopy. Kethari sentries patrol every platform. At the summit, a war horn can be sounded — or silenced before it calls reinforcements.",
		footprint       = { x = 35, z = 35 },
		height          = 80,
		floors          = 5,
		palette         = { primary = "Reddish brown", secondary = "Dark orange", accent = "Bright violet", light = "Lime green" },
		features        = { "enemies", "loot", "parkour", "verticality" },
		enemies         = {
			{ type = "KethariMelee",  count = 4, isBoss = false },
			{ type = "KethariRanged", count = 3, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.7,  min = 1, max = 3 },
			{ itemId = "Components",     chance = 0.5,  min = 1, max = 2 },
			{ itemId = "BioFiber",       chance = 0.6,  min = 2, max = 4 },
		},
		traps           = {
			{ type = "SwingingLog",  count = 2, damage = 25 },
			{ type = "SpikePit",     count = 1, damage = 35 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "kethari_war_lodge",
		name            = "Kethari War Lodge",
		zone            = 2,
		zoneName        = "Deep Woods",
		difficulty      = 4,
		description     = "The ceremonial heart of a Kethari warband. Trophies of alien beasts line the walls, and a crystal altar pulses at the centre. Disturbing the altar summons the Warband Chief — and his elite guard.",
		footprint       = { x = 60, z = 50 },
		height          = 30,
		floors          = 2,
		palette         = { primary = "Reddish brown", secondary = "Bright violet", accent = "Gold", light = "Magenta" },
		features        = { "enemies", "loot", "puzzle", "boss" },
		enemies         = {
			{ type = "KethariMelee",  count = 6, isBoss = false },
			{ type = "KethariRanged", count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.9,  min = 2, max = 5 },
			{ itemId = "Components",     chance = 0.6,  min = 1, max = 3 },
			{ itemId = "ProwlerHide",    chance = 0.4,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "PoisonDart",  count = 4, damage = 15 },
		},
		puzzle          = { type = "CrystalAltar", description = "Place 3 Kethari Crystals on the altar pedestals in the correct colour order to open the trophy vault." },
		hiddenBoss      = {
			name   = "Kethari Warband Chief",
			health = 250,
			damage = 25,
			loot   = { { itemId = "KethariCrystal", min = 5, max = 8 }, { itemId = "Components", min = 2, max = 4 } },
		},
	},

	{
		id              = "hollowed_titan_tree",
		name            = "Hollowed Titan Tree",
		zone            = 2,
		zoneName        = "Deep Woods",
		difficulty      = 3,
		description     = "A colossal petrified tree, easily 200 feet in diameter, hollowed out over centuries. Inside, spiralling ramps connect fungal shelves that serve as floors. Something large nests at the very top.",
		footprint       = { x = 50, z = 50 },
		height          = 100,
		floors          = 7,
		palette         = { primary = "Brown", secondary = "Dark green", accent = "Bright green", light = "Lime green" },
		features        = { "loot", "parkour", "enemies", "verticality", "hiddenRooms" },
		enemies         = {
			{ type = "Stalker",       count = 2, isBoss = false },
			{ type = "KethariMelee",  count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "Wood",        chance = 0.9,  min = 4, max = 8 },
			{ itemId = "BioFiber",    chance = 0.7,  min = 2, max = 5 },
			{ itemId = "Berries",     chance = 0.5,  min = 3, max = 6 },
		},
		traps           = {
			{ type = "CollapsingBranch", count = 3, damage = 20 },
			{ type = "SporeCloud",       count = 2, damage = 5  },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "bone_bridge_outpost",
		name            = "Bone Bridge Outpost",
		zone            = 2,
		zoneName        = "Deep Woods",
		difficulty      = 3,
		description     = "A fortified bridge spanning a deep ravine, constructed from the ribcage of some gargantuan beast. Kethari snipers guard the crossing. Below, in the ravine mist, something prowls.",
		footprint       = { x = 90, z = 30 },
		height          = 45,
		floors          = 3,
		palette         = { primary = "Institutional white", secondary = "Reddish brown", accent = "Dark orange", light = "Cool yellow" },
		features        = { "enemies", "loot", "traps", "parkour" },
		enemies         = {
			{ type = "KethariRanged", count = 4, isBoss = false },
			{ type = "KethariMelee",  count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.5,  min = 1, max = 2 },
			{ itemId = "ScrapMetal",     chance = 0.6,  min = 2, max = 3 },
			{ itemId = "ProwlerHide",    chance = 0.3,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "TrapDoor",     count = 3, damage = 30 },
			{ type = "SwingingLog",  count = 2, damage = 25 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "hunters_snare_den",
		name            = "Hunter's Snare Den",
		zone            = 2,
		zoneName        = "Deep Woods",
		difficulty      = 4,
		description     = "What appears to be a natural cave is actually an elaborate Kethari hunting ground. Net traps dangle from above, pit snares line every path, and at the centre waits the Alpha Prowler — chained, starving, and very angry.",
		footprint       = { x = 55, z = 55 },
		height          = 20,
		floors          = 1,
		palette         = { primary = "Dark stone grey", secondary = "Reddish brown", accent = "Bright red", light = "Neon orange" },
		features        = { "traps", "enemies", "boss", "loot" },
		enemies         = {
			{ type = "KethariMelee", count = 3, isBoss = false },
		},
		loot            = {
			{ itemId = "ProwlerHide",    chance = 0.9,  min = 3, max = 6 },
			{ itemId = "RawMeat",        chance = 0.8,  min = 2, max = 4 },
			{ itemId = "KethariCrystal", chance = 0.4,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "NetTrap",    count = 4, damage = 0  },
			{ type = "SpikePit",   count = 3, damage = 35 },
			{ type = "BearTrap",   count = 5, damage = 30 },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "Alpha Prowler",
			health = 300,
			damage = 30,
			loot   = { { itemId = "ProwlerHide", min = 5, max = 8 }, { itemId = "RawMeat", min = 3, max = 5 } },
		},
	},

	------------------------------------------------------------------------
	-- ZONE 3 · THE RUINS  (ancient alien architecture, glyph puzzles)
	------------------------------------------------------------------------

	{
		id              = "glyph_obelisk_chamber",
		name            = "Glyph Obelisk Chamber",
		zone            = 3,
		zoneName        = "The Ruins",
		difficulty      = 3,
		description     = "A circular amphitheatre surrounds a 60-foot obelisk covered in shifting alien glyphs. Smaller pillars around the perimeter each display a fragment of a message. Translate them in the correct sequence to unlock the obelisk's knowledge.",
		footprint       = { x = 60, z = 60 },
		height          = 60,
		floors          = 2,
		palette         = { primary = "Sand blue", secondary = "Dark stone grey", accent = "Cyan", light = "Toothpaste" },
		features        = { "puzzle", "lore", "loot", "enemies" },
		enemies         = {
			{ type = "Stalker", count = 3, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.8,  min = 2, max = 4 },
			{ itemId = "Components",     chance = 0.6,  min = 1, max = 3 },
		},
		traps           = {
			{ type = "EnergyPulse", count = 2, damage = 20 },
		},
		puzzle          = { type = "GlyphSequence", description = "Use the Scanner to translate 6 glyph pillars and activate them in chronological order to unseal the obelisk core." },
		hiddenBoss      = nil,
	},

	{
		id              = "sunken_archive",
		name            = "Sunken Archive",
		zone            = 3,
		zoneName        = "The Ruins",
		difficulty      = 4,
		description     = "A vast library half-consumed by the earth, its crystalline data-slabs still intact. Glyph-locked doors divide sections by clearance level. The deepest chamber holds a star chart showing the way home — and a guardian that doesn't want you to have it.",
		footprint       = { x = 70, z = 50 },
		height          = 35,
		floors          = 3,
		palette         = { primary = "Sand blue", secondary = "Medium blue", accent = "Cyan", light = "Pastel Blue" },
		features        = { "puzzle", "lore", "loot", "enemies", "boss" },
		enemies         = {
			{ type = "Stalker", count = 4, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.9,  min = 3, max = 6 },
			{ itemId = "Components",     chance = 0.7,  min = 2, max = 4 },
			{ itemId = "PlasmaCore",     chance = 0.2,  min = 1, max = 1 },
		},
		traps           = {
			{ type = "LaserGrid",    count = 3, damage = 15 },
			{ type = "EnergyPulse",  count = 2, damage = 20 },
		},
		puzzle          = { type = "GlyphLock", description = "Scan and decode 4 glyph-locked doors, each requiring a translated passphrase from data-slabs found on the same floor." },
		hiddenBoss      = {
			name   = "Archive Sentinel",
			health = 350,
			damage = 28,
			loot   = { { itemId = "PlasmaCore", min = 1, max = 2 }, { itemId = "KethariCrystal", min = 4, max = 7 } },
		},
	},

	{
		id              = "shattered_observatory",
		name            = "Shattered Observatory",
		zone            = 3,
		zoneName        = "The Ruins",
		difficulty      = 3,
		description     = "A domed structure whose ceiling has cracked open to the alien sky. The holographic star map still flickers to life if you can reroute power through the broken conduits. The constellations it shows are not from Earth.",
		footprint       = { x = 50, z = 50 },
		height          = 45,
		floors          = 2,
		palette         = { primary = "Sand blue", secondary = "Dark stone grey", accent = "Deep blue", light = "Pastel light blue" },
		features        = { "puzzle", "lore", "loot", "parkour" },
		enemies         = {
			{ type = "Stalker", count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "Components",     chance = 0.7,  min = 2, max = 4 },
			{ itemId = "Wire",           chance = 0.8,  min = 2, max = 5 },
			{ itemId = "KethariCrystal", chance = 0.5,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "ElectricalSurge", count = 3, damage = 18 },
		},
		puzzle          = { type = "PowerConduit", description = "Reconnect 5 broken power conduits across the dome to reactivate the star map hologram and decode the planetary coordinates." },
		hiddenBoss      = nil,
	},

	{
		id              = "guardian_crypt",
		name            = "Guardian Crypt",
		zone            = 3,
		zoneName        = "The Ruins",
		difficulty      = 5,
		description     = "Deep beneath the ruins lies a sealed tomb. The walls are etched with warnings in a hundred alien dialects. Inside, a Stalker unlike any other stands vigil over a cache of pure crystals — it has guarded this place for millennia.",
		footprint       = { x = 45, z = 45 },
		height          = 30,
		floors          = 2,
		palette         = { primary = "Dark stone grey", secondary = "Black", accent = "Royal purple", light = "Magenta" },
		features        = { "boss", "loot", "traps", "lore" },
		enemies         = {
			{ type = "Stalker", count = 4, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 1.0,  min = 5, max = 10 },
			{ itemId = "PlasmaCore",     chance = 0.5,  min = 1, max = 2 },
			{ itemId = "Components",     chance = 0.8,  min = 3, max = 5 },
		},
		traps           = {
			{ type = "PressurePlate",  count = 4, damage = 25 },
			{ type = "PoisonGas",      count = 2, damage = 10 },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "The Ancient Guardian",
			health = 500,
			damage = 40,
			loot   = { { itemId = "PlasmaCore", min = 2, max = 3 }, { itemId = "KethariCrystal", min = 8, max = 12 } },
		},
	},

	{
		id              = "resonance_spire",
		name            = "Resonance Spire",
		zone            = 3,
		zoneName        = "The Ruins",
		difficulty      = 4,
		description     = "A needle-thin tower of alien crystal that hums at a frequency you can feel in your teeth. Platforms spiral upward through resonance chambers that amplify or dampen sound in deadly ways. At the apex: a signal amplifier that could boost your radio range.",
		footprint       = { x = 30, z = 30 },
		height          = 110,
		floors          = 8,
		palette         = { primary = "Cyan", secondary = "Sand blue", accent = "Toothpaste", light = "Cyan" },
		features        = { "parkour", "puzzle", "loot", "hazard" },
		enemies         = {
			{ type = "Stalker", count = 3, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.8,  min = 2, max = 4 },
			{ itemId = "Components",     chance = 0.7,  min = 2, max = 3 },
			{ itemId = "Wire",           chance = 0.6,  min = 2, max = 4 },
		},
		traps           = {
			{ type = "SonicBurst",        count = 4, damage = 15 },
			{ type = "CollapsingPlatform", count = 3, damage = 20 },
		},
		puzzle          = { type = "ResonanceTuning", description = "Activate crystal tuning forks on each floor in the correct harmonic order to open the apex chamber." },
		hiddenBoss      = nil,
	},

	------------------------------------------------------------------------
	-- ZONE 4 · SPORE VALLEY  (bioluminescent alien flora, Exposure hazard)
	------------------------------------------------------------------------

	{
		id              = "mycelium_hive",
		name            = "Mycelium Hive",
		zone            = 4,
		zoneName        = "Spore Valley",
		difficulty      = 4,
		description     = "A cathedral-sized mushroom whose cap forms the roof and whose gills create a maze of corridors below. Every surface exhales spores that raise your Exposure meter. Bio-fiber loot is plentiful — if you can hold your breath long enough.",
		footprint       = { x = 65, z = 65 },
		height          = 55,
		floors          = 4,
		palette         = { primary = "Lavender", secondary = "Medium lilac", accent = "Lime green", light = "Lime green" },
		features        = { "hazard", "loot", "enemies", "exploration" },
		enemies         = {
			{ type = "SporeDrone", count = 5, isBoss = false },
		},
		loot            = {
			{ itemId = "BioFiber",       chance = 0.9,  min = 4, max = 8 },
			{ itemId = "KethariCrystal", chance = 0.4,  min = 1, max = 2 },
			{ itemId = "Berries",        chance = 0.6,  min = 3, max = 6 },
		},
		traps           = {
			{ type = "SporeCloud",     count = 8, damage = 5  },
			{ type = "AcidPool",       count = 3, damage = 12 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "bioluminescent_grotto",
		name            = "Bioluminescent Grotto",
		zone            = 4,
		zoneName        = "Spore Valley",
		difficulty      = 4,
		description     = "A cavern system lit entirely by living light. Crystalline organisms pulse in patterns that form a language — touch the wrong one and the light goes out, replaced by something hungry in the dark. Touch the right ones and hidden paths reveal themselves.",
		footprint       = { x = 70, z = 55 },
		height          = 40,
		floors          = 3,
		palette         = { primary = "Dark stone grey", secondary = "Black", accent = "Lime green", light = "Cyan" },
		features        = { "puzzle", "loot", "enemies", "hazard" },
		enemies         = {
			{ type = "Stalker",    count = 3, isBoss = false },
			{ type = "SporeDrone", count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 0.7,  min = 2, max = 4 },
			{ itemId = "BioFiber",       chance = 0.8,  min = 3, max = 5 },
			{ itemId = "PlasmaCore",     chance = 0.15, min = 1, max = 1 },
		},
		traps           = {
			{ type = "DarknessZone",   count = 3, damage = 0  },
			{ type = "PoisonPool",     count = 4, damage = 10 },
		},
		puzzle          = { type = "LightSequence", description = "Touch bioluminescent crystals in the pattern displayed on the cave ceiling to illuminate hidden pathways. Wrong inputs plunge the room into darkness." },
		hiddenBoss      = nil,
	},

	{
		id              = "spore_colossus_remains",
		name            = "Spore Colossus Remains",
		zone            = 4,
		zoneName        = "Spore Valley",
		difficulty      = 5,
		description     = "The fossilised skeleton of something impossibly large, its bones now colonised by parasitic fungi. Entire rooms exist inside its ribcage and skull. The fungal network has formed a crude nervous system — and it's waking up.",
		footprint       = { x = 90, z = 40 },
		height          = 60,
		floors          = 4,
		palette         = { primary = "Institutional white", secondary = "Lavender", accent = "Magenta", light = "Lime green" },
		features        = { "boss", "enemies", "loot", "parkour", "hazard" },
		enemies         = {
			{ type = "SporeDrone", count = 6, isBoss = false },
		},
		loot            = {
			{ itemId = "BioFiber",       chance = 1.0,  min = 5, max = 10 },
			{ itemId = "KethariCrystal", chance = 0.6,  min = 2, max = 4 },
			{ itemId = "PlasmaCore",     chance = 0.25, min = 1, max = 1 },
		},
		traps           = {
			{ type = "SporeCloud",       count = 6, damage = 5  },
			{ type = "TendrilGrab",      count = 3, damage = 20 },
			{ type = "AcidPool",         count = 2, damage = 12 },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "The Colossus Awakened",
			health = 600,
			damage = 35,
			loot   = { { itemId = "PlasmaCore", min = 2, max = 3 }, { itemId = "BioFiber", min = 8, max = 12 } },
		},
	},

	{
		id              = "fungal_laboratory",
		name            = "Fungal Laboratory",
		zone            = 4,
		zoneName        = "Spore Valley",
		difficulty      = 3,
		description     = "An alien research facility half-consumed by the very organisms it once studied. Containment pods have shattered, and experimental specimens roam freely. The workbenches still hold refined crafting materials — if you can clear the lab.",
		footprint       = { x = 55, z = 45 },
		height          = 25,
		floors          = 2,
		palette         = { primary = "Medium stone grey", secondary = "Lavender", accent = "Lime green", light = "Pastel light blue" },
		features        = { "loot", "enemies", "exploration", "hazard" },
		enemies         = {
			{ type = "SporeDrone",    count = 4, isBoss = false },
			{ type = "Stalker",       count = 1, isBoss = false },
		},
		loot            = {
			{ itemId = "Components",     chance = 0.8,  min = 3, max = 6 },
			{ itemId = "BioFiber",       chance = 0.7,  min = 2, max = 4 },
			{ itemId = "KethariCrystal", chance = 0.5,  min = 1, max = 3 },
			{ itemId = "Wire",           chance = 0.6,  min = 2, max = 3 },
		},
		traps           = {
			{ type = "SporeCloud",     count = 4, damage = 5  },
			{ type = "ElectricalSurge", count = 2, damage = 18 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "parasite_nexus",
		name            = "Parasite Nexus",
		zone            = 4,
		zoneName        = "Spore Valley",
		difficulty      = 5,
		description     = "A pulsing organic node the size of a warehouse, connected to the valley's fungal network by throbbing tendrils. Destroying the core will weaken the spores across the entire valley — but the network will fight back with everything it has.",
		footprint       = { x = 50, z = 50 },
		height          = 35,
		floors          = 2,
		palette         = { primary = "Magenta", secondary = "Dark stone grey", accent = "Lime green", light = "Magenta" },
		features        = { "enemies", "boss", "hazard", "waves" },
		enemies         = {
			{ type = "SporeDrone", count = 8, isBoss = false },
		},
		loot            = {
			{ itemId = "BioFiber",       chance = 1.0,  min = 6, max = 12 },
			{ itemId = "KethariCrystal", chance = 0.8,  min = 3, max = 6 },
			{ itemId = "PlasmaCore",     chance = 0.3,  min = 1, max = 2 },
		},
		traps           = {
			{ type = "TendrilGrab",  count = 6, damage = 20 },
			{ type = "SporeCloud",   count = 10, damage = 5 },
			{ type = "AcidPool",     count = 4, damage = 12 },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "Nexus Core",
			health = 450,
			damage = 0,
			loot   = { { itemId = "PlasmaCore", min = 3, max = 5 }, { itemId = "BioFiber", min = 10, max = 15 } },
		},
	},

	------------------------------------------------------------------------
	-- ZONE 5 · THE CORE  (fully alien landscape, endgame)
	------------------------------------------------------------------------

	{
		id              = "kethari_cathedral",
		name            = "Kethari Cathedral",
		zone            = 5,
		zoneName        = "The Core",
		difficulty      = 5,
		description     = "A soaring alien temple where the Kethari worship the forest itself. Crystal spires pierce the ceiling, casting prismatic light across a congregation of the most elite warriors. The High Shaman channels the planet's energy from an altar of living crystal.",
		footprint       = { x = 80, z = 60 },
		height          = 70,
		floors          = 3,
		palette         = { primary = "Bright violet", secondary = "Gold", accent = "Magenta", light = "Magenta" },
		features        = { "boss", "enemies", "loot", "lore" },
		enemies         = {
			{ type = "KethariMelee",  count = 6, isBoss = false },
			{ type = "KethariRanged", count = 4, isBoss = false },
		},
		loot            = {
			{ itemId = "KethariCrystal", chance = 1.0,  min = 5, max = 10 },
			{ itemId = "PlasmaCore",     chance = 0.5,  min = 1, max = 2 },
			{ itemId = "Components",     chance = 0.8,  min = 3, max = 6 },
		},
		traps           = {
			{ type = "EnergyPulse",   count = 4, damage = 25 },
			{ type = "CrystalShard",  count = 3, damage = 30 },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "Kethari High Shaman",
			health = 600,
			damage = 45,
			loot   = { { itemId = "PlasmaCore", min = 3, max = 5 }, { itemId = "KethariCrystal", min = 10, max = 15 } },
		},
	},

	{
		id              = "alien_engine_room",
		name            = "Alien Engine Room",
		zone            = 5,
		zoneName        = "The Core",
		difficulty      = 5,
		description     = "The engine core of an alien vessel far older than the Kethari. Massive turbines still spin in place, powered by an energy source your Scanner can barely comprehend. A ship component is lodged in the reactor housing — extracting it will require precision and speed.",
		footprint       = { x = 70, z = 70 },
		height          = 50,
		floors          = 3,
		palette         = { primary = "Dark stone grey", secondary = "Cyan", accent = "Neon orange", light = "Cyan" },
		features        = { "puzzle", "loot", "enemies", "hazard", "traps" },
		enemies         = {
			{ type = "Stalker",       count = 4, isBoss = false },
			{ type = "KethariMelee",  count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "PlasmaCore",     chance = 0.7,  min = 1, max = 3 },
			{ itemId = "Components",     chance = 0.9,  min = 4, max = 8 },
			{ itemId = "Wire",           chance = 0.8,  min = 3, max = 6 },
			{ itemId = "BatteryCell",    chance = 0.6,  min = 2, max = 3 },
		},
		traps           = {
			{ type = "TurbineBlade",     count = 4, damage = 50 },
			{ type = "ElectricalSurge",  count = 5, damage = 18 },
			{ type = "SteamVent",        count = 3, damage = 10 },
		},
		puzzle          = { type = "ReactorExtraction", description = "Shut down 4 turbine subsystems in sequence while avoiding blade hazards, then extract the ship component from the reactor housing before emergency restart." },
		hiddenBoss      = nil,
	},

	{
		id              = "wardens_lair",
		name            = "The Warden's Lair",
		zone            = 5,
		zoneName        = "The Core",
		difficulty      = 5,
		description     = "The heart of the forest's immune system. This cavern of living crystal is where the apex Stalker — the Warden — rests between hunts. The walls shift and reconfigure, funnelling intruders toward the centre. Endgame loot lines the walls like trophies.",
		footprint       = { x = 60, z = 60 },
		height          = 45,
		floors          = 2,
		palette         = { primary = "Black", secondary = "Royal purple", accent = "Magenta", light = "Really red" },
		features        = { "boss", "traps", "loot", "hazard" },
		enemies         = {
			{ type = "Stalker", count = 6, isBoss = false },
		},
		loot            = {
			{ itemId = "PlasmaCore",     chance = 0.8,  min = 2, max = 4 },
			{ itemId = "KethariCrystal", chance = 1.0,  min = 5, max = 10 },
			{ itemId = "Components",     chance = 0.9,  min = 3, max = 6 },
		},
		traps           = {
			{ type = "ShiftingWalls",   count = 4, damage = 30 },
			{ type = "CrystalShard",    count = 6, damage = 30 },
			{ type = "DarknessZone",    count = 3, damage = 0  },
		},
		puzzle          = nil,
		hiddenBoss      = {
			name   = "The Warden",
			health = 800,
			damage = 50,
			loot   = { { itemId = "PlasmaCore", min = 4, max = 6 }, { itemId = "KethariCrystal", min = 10, max = 15 } },
		},
	},

	{
		id              = "crystalline_forge",
		name            = "Crystalline Forge",
		zone            = 5,
		zoneName        = "The Core",
		difficulty      = 4,
		description     = "A facility where alien alloys were once smelted using crystalline energy. The forge still works — molten crystal flows in channels across the floor, and platforms hover above the deadly streams. The materials here could upgrade any weapon or armour.",
		footprint       = { x = 55, z = 55 },
		height          = 40,
		floors          = 3,
		palette         = { primary = "Dark stone grey", secondary = "Neon orange", accent = "Bright yellow", light = "Neon orange" },
		features        = { "parkour", "loot", "hazard", "enemies" },
		enemies         = {
			{ type = "Stalker",       count = 3, isBoss = false },
			{ type = "KethariMelee",  count = 2, isBoss = false },
		},
		loot            = {
			{ itemId = "PlasmaCore",     chance = 0.6,  min = 1, max = 2 },
			{ itemId = "KethariCrystal", chance = 0.9,  min = 3, max = 6 },
			{ itemId = "ScrapMetal",     chance = 0.8,  min = 4, max = 8 },
			{ itemId = "Components",     chance = 0.7,  min = 2, max = 4 },
		},
		traps           = {
			{ type = "LavaStream",        count = 6, damage = 40 },
			{ type = "CollapsingPlatform", count = 4, damage = 20 },
		},
		puzzle          = nil,
		hiddenBoss      = nil,
	},

	{
		id              = "heart_chamber",
		name            = "The Heart Chamber",
		zone            = 5,
		zoneName        = "The Core",
		difficulty      = 5,
		description     = "The literal heart of the alien world — a chamber of living crystal that beats with a slow, planetary pulse. This is where the forest's consciousness resides. The final ship component is embedded in the heart itself. Taking it will wake everything.",
		footprint       = { x = 70, z = 70 },
		height          = 60,
		floors          = 3,
		palette         = { primary = "Bright violet", secondary = "Magenta", accent = "Cyan", light = "Magenta" },
		features        = { "boss", "puzzle", "loot", "lore", "finale" },
		enemies         = {
			{ type = "Stalker",       count = 4, isBoss = false },
			{ type = "KethariMelee",  count = 4, isBoss = false },
			{ type = "KethariRanged", count = 2, isBoss = false },
			{ type = "SporeDrone",    count = 4, isBoss = false },
		},
		loot            = {
			{ itemId = "PlasmaCore",     chance = 1.0,  min = 3, max = 5 },
			{ itemId = "KethariCrystal", chance = 1.0,  min = 8, max = 15 },
			{ itemId = "Components",     chance = 1.0,  min = 5, max = 10 },
		},
		traps           = {
			{ type = "CrystalShard",    count = 8, damage = 30 },
			{ type = "EnergyPulse",     count = 6, damage = 25 },
			{ type = "ShiftingWalls",   count = 4, damage = 30 },
		},
		puzzle          = { type = "HeartExtraction", description = "Sever 6 crystal tendrils connecting the heart to the chamber walls while surviving the planet's immune response. Each severed tendril escalates enemy spawns." },
		hiddenBoss      = {
			name   = "The Forest's Will",
			health = 1000,
			damage = 55,
			loot   = { { itemId = "PlasmaCore", min = 5, max = 8 }, { itemId = "KethariCrystal", min = 15, max = 20 } },
		},
	},
}

-- Quick-access index by id
BuildingData.ById = {}
for _, building in BuildingData.Buildings do
	BuildingData.ById[building.id] = building
end

-- Quick-access grouped by zone
BuildingData.ByZone = { {}, {}, {}, {}, {} }
for _, building in BuildingData.Buildings do
	table.insert(BuildingData.ByZone[building.zone], building)
end

return BuildingData
