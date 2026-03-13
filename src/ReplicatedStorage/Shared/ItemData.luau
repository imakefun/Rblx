-- ItemData.luau
-- Item definitions and crafting recipes

local ItemData = {}

-- Fabricator recipes by tier
ItemData.Recipes = {
	-- Tier 1: Crash Salvage (available immediately)
	{
		id = "MakeshiftAxe",
		displayName = "Makeshift Axe",
		tier = 1,
		ingredients = { { item = "Wood", count = 5 }, { item = "Stone", count = 3 } },
		craftTime = 3,
	},
	{
		id = "Torch",
		displayName = "Torch",
		tier = 1,
		ingredients = { { item = "Wood", count = 3 } },
		craftTime = 2,
	},
	{
		id = "WoodenBarricade",
		displayName = "Wooden Barricade",
		tier = 1,
		ingredients = { { item = "Wood", count = 8 } },
		craftTime = 4,
		placeable = true,
		health = 50,
	},
	{
		id = "Bedroll",
		displayName = "Bedroll",
		tier = 1,
		ingredients = { { item = "Wood", count = 6 }, { item = "SkipperHide", count = 2 } },
		craftTime = 5,
		placeable = true,
	},
	{
		id = "CookedMeat",
		displayName = "Cooked Meat",
		tier = 1,
		ingredients = { { item = "RawMeat", count = 1 } },
		craftTime = 3,
	},

	-- Tier 2: Scrap + Wood
	{
		id = "BearTrap",
		displayName = "Bear Trap",
		tier = 2,
		ingredients = { { item = "ScrapMetal", count = 4 }, { item = "Wire", count = 2 } },
		craftTime = 5,
		placeable = true,
		damage = 30,
	},
	{
		id = "ReinforcedWall",
		displayName = "Reinforced Wall",
		tier = 2,
		ingredients = { { item = "Wood", count = 10 }, { item = "ScrapMetal", count = 4 } },
		craftTime = 6,
		placeable = true,
		health = 120,
	},
	{
		id = "Crossbow",
		displayName = "Crossbow",
		tier = 2,
		ingredients = { { item = "Wood", count = 6 }, { item = "Wire", count = 3 }, { item = "ScrapMetal", count = 2 } },
		craftTime = 8,
		damage = 20,
	},
	{
		id = "UpgradedPack",
		displayName = "Upgraded Pack",
		tier = 2,
		ingredients = { { item = "ProwlerHide", count = 3 }, { item = "Wire", count = 2 } },
		craftTime = 5,
		inventoryBonus = 8,
	},
	{
		id = "Medkit",
		displayName = "Medkit",
		tier = 2,
		ingredients = { { item = "Berries", count = 5 }, { item = "Wire", count = 1 } },
		craftTime = 4,
		healAmount = 40,
	},

	-- Tier 3: + Kethari Crystals
	{
		id = "AlloyWall",
		displayName = "Alloy Wall",
		tier = 3,
		ingredients = { { item = "ScrapMetal", count = 8 }, { item = "KethariCrystal", count = 2 } },
		craftTime = 8,
		placeable = true,
		health = 250,
	},
	{
		id = "PulseBow",
		displayName = "Pulse Bow",
		tier = 3,
		ingredients = { { item = "KethariCrystal", count = 3 }, { item = "Wire", count = 4 }, { item = "Components", count = 2 } },
		craftTime = 10,
		damage = 35,
	},
	{
		id = "ExoArmor",
		displayName = "Exo-Armor",
		tier = 3,
		ingredients = { { item = "ScrapMetal", count = 10 }, { item = "KethariCrystal", count = 4 }, { item = "Components", count = 3 } },
		craftTime = 12,
		damageReduction = 0.3,
	},
	{
		id = "UVFlashlight",
		displayName = "UV Flashlight",
		tier = 3,
		ingredients = { { item = "Components", count = 4 }, { item = "BatteryCell", count = 1 } },
		craftTime = 6,
	},
}

return ItemData
