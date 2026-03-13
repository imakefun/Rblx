--!strict
-- InventoryManager.luau
-- Server-authoritative tool/equipment and item-use system.
--
-- PATTERN:
--   Tools are DATA on the server (itemId strings), NOT persistent Tool instances.
--   When a player equips, the server creates a Tool model and parents it to the
--   character. When they unequip, the server destroys it. The client requests
--   equip/unequip via NetworkManager; the server validates ownership first.
--   This prevents exploits where clients clone or duplicate tool instances.
--
-- Place in: ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local InventoryManager = {}

-------------------------------------------------------------------------------
-- Types
-------------------------------------------------------------------------------

type EquipRecord = {
	itemId: string,
	toolInstance: Tool,
}

-- Which tool each player currently has equipped
local equippedTools: { [Player]: EquipRecord? } = {}

-------------------------------------------------------------------------------
-- Tool template creation
-- In production, pre-built Tool models live in ServerStorage.
-- Here we create minimal ones programmatically as a reference.
-------------------------------------------------------------------------------

local toolTemplates: Folder? = ReplicatedStorage:FindFirstChild("ToolTemplates") :: Folder?

local function getToolTemplate(itemId: string): Tool?
	-- Check for pre-made model first
	if toolTemplates then
		local existing = toolTemplates:FindFirstChild(itemId)
		if existing and existing:IsA("Tool") then
			return existing:Clone()
		end
	end

	-- Fallback: build a minimal Tool
	local itemDef = Config.ITEMS[itemId]
	if not itemDef or itemDef.category ~= "Tool" then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = itemId
	tool.RequiresHandle = true
	tool.CanBeDropped = false -- server controls drops

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 3)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Color = Color3.fromRGB(120, 100, 80)
	handle.Parent = tool

	-- Tag with metadata for combat/gathering systems
	tool:SetAttribute("ItemId", itemId)
	tool:SetAttribute("Damage", itemDef.damage or 0)
	tool:SetAttribute("DisplayName", itemDef.displayName or itemId)

	return tool
end

-------------------------------------------------------------------------------
-- Equip / Unequip
-------------------------------------------------------------------------------

function InventoryManager.Equip(player: Player, itemId: string): boolean
	if not PlayerManager.hasItem(player, itemId, 1) then
		warn(`[InventoryManager] {player.Name} tried to equip {itemId} without owning it`)
		return false
	end

	local itemDef = Config.ITEMS[itemId]
	if not itemDef or itemDef.category ~= "Tool" then
		return false
	end

	InventoryManager.Unequip(player)

	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local toolInstance = getToolTemplate(itemId)
	if not toolInstance then return false end

	-- Parent to character = auto-equip via Roblox tool system
	toolInstance.Parent = character

	equippedTools[player] = {
		itemId = itemId,
		toolInstance = toolInstance,
	}

	NetworkManager.FireClient(player, "ToolEquipped", itemId)
	return true
end

function InventoryManager.Unequip(player: Player)
	local record = equippedTools[player]
	if not record then return end

	if record.toolInstance and record.toolInstance.Parent then
		record.toolInstance:Destroy()
	end

	equippedTools[player] = nil
	NetworkManager.FireClient(player, "ToolUnequipped")
end

function InventoryManager.GetEquippedItem(player: Player): string?
	local record = equippedTools[player]
	return if record then record.itemId else nil
end

function InventoryManager.GetEquippedTool(player: Player): Tool?
	local record = equippedTools[player]
	return if record then record.toolInstance else nil
end

-------------------------------------------------------------------------------
-- Use consumable items (food, medkits)
-------------------------------------------------------------------------------

function InventoryManager.UseItem(player: Player, itemId: string): boolean
	local itemDef = Config.ITEMS[itemId]
	if not itemDef then return false end

	if not PlayerManager.removeItem(player, itemId, 1) then
		return false
	end

	if itemDef.hungerRestore then
		PlayerManager.feed(player, itemDef.hungerRestore)
	end

	if itemDef.healAmount then
		PlayerManager.heal(player, itemDef.healAmount)
	end

	local inv = PlayerManager.getInventory(player)
	if inv then
		NetworkManager.FireClient(player, "InventoryUpdated", inv)
	end

	return true
end

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

function InventoryManager.OnPlayerRemoving(player: Player)
	InventoryManager.Unequip(player)
	equippedTools[player] = nil
end

function InventoryManager.OnCharacterDied(player: Player)
	InventoryManager.Unequip(player)
end

-------------------------------------------------------------------------------
-- Network handlers (client -> server)
-------------------------------------------------------------------------------

function InventoryManager.RegisterNetworkHandlers()
	NetworkManager.OnClientEvent("EquipTool", function(player: Player, itemId: any)
		if typeof(itemId) ~= "string" then return end
		InventoryManager.Equip(player, itemId)
	end)

	NetworkManager.OnClientEvent("UnequipTool", function(player: Player)
		InventoryManager.Unequip(player)
	end)

	NetworkManager.OnClientEvent("UseItem", function(player: Player, itemId: any)
		if typeof(itemId) ~= "string" then return end
		InventoryManager.UseItem(player, itemId)
	end)

	NetworkManager.OnClientEvent("DropItem", function(player: Player, itemId: any, count: any)
		if typeof(itemId) ~= "string" then return end
		if typeof(count) ~= "number" then return end
		count = math.floor(math.clamp(count, 1, 99))

		local equipped = InventoryManager.GetEquippedItem(player)
		if equipped == itemId then
			InventoryManager.Unequip(player)
		end

		if PlayerManager.removeItem(player, itemId, count) then
			-- TODO: spawn pickup model at player position
			local inv = PlayerManager.getInventory(player)
			if inv then
				NetworkManager.FireClient(player, "InventoryUpdated", inv)
			end
		end
	end)

	NetworkManager.OnClientInvoke("GetInventory", function(player: Player)
		return PlayerManager.getInventory(player)
	end)
end

return InventoryManager
