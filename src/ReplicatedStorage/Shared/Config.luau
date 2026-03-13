-- Config.luau
-- All game constants and tuning values

local Config = {}

-- Day/Night Cycle
Config.DAY_LENGTH = 360        -- seconds (6 minutes)
Config.NIGHT_LENGTH = 240      -- seconds (4 minutes)
Config.CYCLE_LENGTH = Config.DAY_LENGTH + Config.NIGHT_LENGTH
Config.DAWN_HOUR = 6.0         -- ClockTime when day starts
Config.DUSK_HOUR = 18.0        -- ClockTime when night starts
Config.MAX_SOL = 99

-- Player Stats
Config.MAX_HEALTH = 100
Config.MAX_HUNGER = 100
Config.MAX_OXYGEN = 100
Config.MAX_STAMINA = 100

Config.HUNGER_DRAIN_RATE = 0.5     -- per second
Config.OXYGEN_DRAIN_DAY = 0.1      -- per second during day
Config.OXYGEN_DRAIN_NIGHT = 0.3    -- per second at night (alien atmosphere)
Config.STAMINA_DRAIN_SPRINT = 15   -- per second while sprinting
Config.STAMINA_REGEN_RATE = 8      -- per second while not sprinting
Config.HUNGER_DAMAGE_RATE = 2      -- HP per second when hunger is 0
Config.SPRINT_SPEED_MULT = 1.6     -- multiplier on walk speed

-- Signal Fire
Config.SIGNAL_FIRE_MAX_FUEL = 100
Config.SIGNAL_FIRE_BURN_RATE = 0.3   -- fuel per second
Config.SIGNAL_FIRE_LEVELS = {
	[1] = { radius = 30,  fuelCost = 0 },
	[2] = { radius = 50,  fuelCost = 50 },
	[3] = { radius = 80,  fuelCost = 120 },
	[4] = { radius = 120, fuelCost = 200 },
	[5] = { radius = 180, fuelCost = 350 },
}
Config.SIGNAL_FIRE_HEAL_RATE = 2      -- HP per second inside field
Config.SIGNAL_FIRE_O2_REGEN = 3       -- O2 per second inside field

-- Fuel values (how much fuel each item adds)
Config.FUEL_VALUES = {
	Wood = 10,
	Coal = 25,
	BatteryCell = 40,
	PlasmaCore = 80,
}

-- Resources
Config.TREE_CHOP_TIME = 1.5     -- seconds per hit
Config.TREE_HITS = 3             -- hits to fell a tree
Config.TREE_WOOD_DROP = 3        -- wood per tree
Config.ROCK_MINE_TIME = 2.0
Config.ROCK_HITS = 4
Config.ROCK_STONE_DROP = 2
Config.BUSH_BERRY_DROP = 2
Config.RESOURCE_RESPAWN_TIME = 120  -- seconds (respawn each cycle in practice)

-- Inventory
Config.DEFAULT_INVENTORY_SIZE = 16
Config.HOTBAR_SIZE = 8

-- Items
Config.ITEMS = {
	Wood = { displayName = "Wood", stackSize = 50, category = "Resource" },
	Stone = { displayName = "Stone", stackSize = 50, category = "Resource" },
	ScrapMetal = { displayName = "Scrap Metal", stackSize = 30, category = "Resource" },
	Wire = { displayName = "Wire", stackSize = 30, category = "Resource" },
	Components = { displayName = "Components", stackSize = 20, category = "Resource" },
	Berries = { displayName = "Berries", stackSize = 20, category = "Food", hungerRestore = 10 },
	Coal = { displayName = "Coal", stackSize = 30, category = "Fuel" },
	BatteryCell = { displayName = "Battery Cell", stackSize = 10, category = "Fuel" },
	PlasmaCore = { displayName = "Plasma Core", stackSize = 5, category = "Fuel" },
	KethariCrystal = { displayName = "Kethari Crystal", stackSize = 15, category = "Resource" },
	MakeshiftAxe = { displayName = "Makeshift Axe", stackSize = 1, category = "Tool", damage = 10 },
	Torch = { displayName = "Torch", stackSize = 1, category = "Tool" },
	UVFlashlight = { displayName = "UV Flashlight", stackSize = 1, category = "Tool" },
	RawMeat = { displayName = "Raw Meat", stackSize = 10, category = "Food", hungerRestore = 5 },
	CookedMeat = { displayName = "Cooked Meat", stackSize = 10, category = "Food", hungerRestore = 25 },
	SkipperHide = { displayName = "Skipper Hide", stackSize = 10, category = "Resource" },
	ProwlerHide = { displayName = "Prowler Hide", stackSize = 10, category = "Resource" },

	-- Crafted items
	WoodenBarricade = { displayName = "Wooden Barricade", stackSize = 5, category = "Placeable" },
	Bedroll = { displayName = "Bedroll", stackSize = 1, category = "Placeable" },
	BearTrap = { displayName = "Bear Trap", stackSize = 5, category = "Placeable", damage = 30 },
	ReinforcedWall = { displayName = "Reinforced Wall", stackSize = 5, category = "Placeable" },
	Crossbow = { displayName = "Crossbow", stackSize = 1, category = "Tool", damage = 20 },
	UpgradedPack = { displayName = "Upgraded Pack", stackSize = 1, category = "Tool" },
	Medkit = { displayName = "Medkit", stackSize = 5, category = "Consumable", healAmount = 40 },
	AlloyWall = { displayName = "Alloy Wall", stackSize = 5, category = "Placeable" },
	PulseBow = { displayName = "Pulse Bow", stackSize = 1, category = "Tool", damage = 35 },
	ExoArmor = { displayName = "Exo-Armor", stackSize = 1, category = "Tool", damageReduction = 0.3 },
}

-- Combat
Config.STALKER_DAMAGE = 33
Config.STALKER_SPEED = 22          -- studs/sec
Config.STALKER_SPAWN_DISTANCE = 150 -- studs from campfire
Config.FIST_DAMAGE = 5
Config.AXE_DAMAGE = 15

-- Kethari Raids
Config.RAID_INTERVAL_SOLS = 3        -- raid every N sols
Config.RAID_BASE_COUNT = 4           -- base number of Kethari
Config.RAID_SCALE_PER_SOL = 0.5      -- extra Kethari per sol
Config.RAID_SCALE_PER_PLAYER = 1     -- extra Kethari per player
Config.KETHARI_MELEE_DAMAGE = 12
Config.KETHARI_RANGED_DAMAGE = 8
Config.KETHARI_HEALTH = 60

return Config
