--!strict
-- CraftingManager.luau
-- Server-authoritative crafting system.
-- Players request crafts; server validates ingredients, deducts them,
-- waits the craft time, then grants the result.
--
-- Place in: ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ItemData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemData"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local CraftingManager = {}

-------------------------------------------------------------------------------
-- Recipe lookup
-------------------------------------------------------------------------------

local recipeMap: { [string]: typeof(ItemData.Recipes[1]) } = {}
for _, recipe in ItemData.Recipes do
	recipeMap[recipe.id] = recipe
end

-- Currently crafting (one craft per player at a time)
local activeCrafts: { [Player]: { recipeId: string, finishTime: number } } = {}

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function canCraft(player: Player, recipeId: string): (boolean, string?)
	local recipe = recipeMap[recipeId]
	if not recipe then
		return false, "Unknown recipe"
	end

	-- Check if already crafting
	if activeCrafts[player] then
		return false, "Already crafting"
	end

	-- Check ingredients
	for _, ingredient in recipe.ingredients do
		if not PlayerManager.hasItem(player, ingredient.item, ingredient.count) then
			return false, `Missing {ingredient.item}`
		end
	end

	return true, nil
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------

function CraftingManager.GetRecipes(): { typeof(ItemData.Recipes[1]) }
	return ItemData.Recipes
end

function CraftingManager.GetRecipeMap(): { [string]: typeof(ItemData.Recipes[1]) }
	return recipeMap
end

function CraftingManager.StartCraft(player: Player, recipeId: string): boolean
	local ok, reason = canCraft(player, recipeId)
	if not ok then
		NetworkManager.FireClient(player, "CraftFailed", reason)
		return false
	end

	local recipe = recipeMap[recipeId]

	-- Deduct ingredients immediately (prevents double-spending)
	for _, ingredient in recipe.ingredients do
		PlayerManager.removeItem(player, ingredient.item, ingredient.count)
	end

	-- Send inventory update
	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end

	-- Start crafting timer
	activeCrafts[player] = {
		recipeId = recipeId,
		finishTime = tick() + recipe.craftTime,
	}

	NetworkManager.FireClient(player, "CraftStarted", recipeId, recipe.craftTime)

	-- Spawn delayed completion
	task.delay(recipe.craftTime, function()
		CraftingManager.CompleteCraft(player, recipeId)
	end)

	return true
end

function CraftingManager.CompleteCraft(player: Player, recipeId: string)
	local craft = activeCrafts[player]
	if not craft or craft.recipeId ~= recipeId then return end

	activeCrafts[player] = nil

	local recipe = recipeMap[recipeId]
	if not recipe then return end

	-- Grant the crafted item
	PlayerManager.addItem(player, recipe.id, 1)

	-- Send updates
	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end

	NetworkManager.FireClient(player, "CraftCompleted", recipeId)
	NetworkManager.FireClient(player, "Notify", "Crafted", `Crafted: {recipe.displayName}`)
end

function CraftingManager.CancelCraft(player: Player)
	local craft = activeCrafts[player]
	if not craft then return end

	-- Refund ingredients
	local recipe = recipeMap[craft.recipeId]
	if recipe then
		for _, ingredient in recipe.ingredients do
			PlayerManager.addItem(player, ingredient.item, ingredient.count)
		end
	end

	activeCrafts[player] = nil

	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end

	NetworkManager.FireClient(player, "CraftCancelled")
end

function CraftingManager.OnPlayerRemoving(player: Player)
	-- Refund any in-progress craft
	CraftingManager.CancelCraft(player)
end

-------------------------------------------------------------------------------
-- Network handlers
-------------------------------------------------------------------------------

function CraftingManager.RegisterNetworkHandlers()
	NetworkManager.OnClientEvent("StartCraft", function(player: Player, recipeId: any)
		if typeof(recipeId) ~= "string" then return end
		CraftingManager.StartCraft(player, recipeId)
	end)

	NetworkManager.OnClientEvent("CancelCraft", function(player: Player)
		CraftingManager.CancelCraft(player)
	end)

	-- Client requests recipe list
	NetworkManager.OnClientInvoke("GetRecipes", function(_player: Player)
		return ItemData.Recipes
	end)

	-- Client checks if can craft
	NetworkManager.OnClientInvoke("CanCraft", function(player: Player, recipeId: any)
		if typeof(recipeId) ~= "string" then return false end
		local ok, _reason = canCraft(player, recipeId)
		return ok
	end)
end

return CraftingManager
