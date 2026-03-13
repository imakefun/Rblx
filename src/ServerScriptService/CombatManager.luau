--!strict
-- CombatManager.luau
-- Server-authoritative combat: melee hit detection, damage application,
-- tool activation, and NPC damage handling.
--
-- Place in: ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetworkManager = require(ServerScriptService:WaitForChild("NetworkManager"))
local PlayerManager = require(ServerScriptService:WaitForChild("PlayerManager"))
local InventoryManager = require(ServerScriptService:WaitForChild("InventoryManager"))

local CombatManager = {}

-------------------------------------------------------------------------------
-- Attack cooldowns (prevent spam)
-------------------------------------------------------------------------------

local MELEE_RANGE = 8 -- studs
local ATTACK_COOLDOWN = 0.6 -- seconds
local lastAttackTime: { [Player]: number } = {}

-------------------------------------------------------------------------------
-- NPC health tracking
-- All NPCs are Models with a Humanoid. We track extras via attributes.
-------------------------------------------------------------------------------

function CombatManager.DamageNPC(npc: Model, damage: number, attacker: Player?): boolean
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	humanoid:TakeDamage(damage)

	-- Flash the NPC red briefly for feedback
	local rootPart = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart then
		local originalColor = rootPart.Color
		rootPart.Color = Color3.fromRGB(255, 60, 60)
		task.delay(0.15, function()
			if rootPart and rootPart.Parent then
				rootPart.Color = originalColor
			end
		end)
	end

	-- Notify attacker of hit
	if attacker then
		NetworkManager.FireClient(attacker, "HitConfirm", damage)
	end

	-- Check if NPC died
	if humanoid.Health <= 0 then
		return true -- caller handles drops/cleanup
	end

	return false
end

-------------------------------------------------------------------------------
-- Player melee attack
-------------------------------------------------------------------------------

function CombatManager.ProcessMeleeAttack(player: Player)
	-- Cooldown check
	local now = tick()
	local last = lastAttackTime[player] or 0
	if now - last < ATTACK_COOLDOWN then return end
	lastAttackTime[player] = now

	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- Determine damage based on equipped tool
	local equippedItem = InventoryManager.GetEquippedItem(player)
	local damage = Config.FIST_DAMAGE

	if equippedItem then
		local itemDef = Config.ITEMS[equippedItem]
		if itemDef and itemDef.damage then
			damage = itemDef.damage
		end
	end

	-- Find targets in range (NPCs only, not other players)
	local hits = 0
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then return end

	for _, npc in npcsFolder:GetChildren() do
		if not npc:IsA("Model") then continue end
		local npcRoot = npc:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not npcRoot then continue end

		local dist = (rootPart.Position - npcRoot.Position).Magnitude
		if dist > MELEE_RANGE then continue end

		-- Direction check: only hit NPCs roughly in front of the player
		local toNPC = (npcRoot.Position - rootPart.Position).Unit
		local facing = rootPart.CFrame.LookVector
		local dot = facing:Dot(toNPC)
		if dot < 0.3 then continue end -- must be facing the NPC

		local killed = CombatManager.DamageNPC(npc, damage, player)
		hits += 1

		if killed then
			-- Fire event so StalkerAI/RaidManager can handle drops
			local npcType = npc:GetAttribute("NPCType") :: string?
			if npcType then
				CombatManager._onNPCKilled(npc, npcType, player)
			end
		end

		-- Only hit one NPC per swing
		break
	end

	-- Play attack feedback even if no hit
	NetworkManager.FireClient(player, "AttackSwing", equippedItem or "Fists")
end

-------------------------------------------------------------------------------
-- NPC death callback system
-------------------------------------------------------------------------------

type KillCallback = (npc: Model, npcType: string, killer: Player) -> ()
local killCallbacks: { KillCallback } = {}

function CombatManager.OnNPCKilled(callback: KillCallback)
	table.insert(killCallbacks, callback)
end

function CombatManager._onNPCKilled(npc: Model, npcType: string, killer: Player)
	for _, callback in killCallbacks do
		task.spawn(callback, npc, npcType, killer)
	end
end

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

function CombatManager.OnPlayerRemoving(player: Player)
	lastAttackTime[player] = nil
end

-------------------------------------------------------------------------------
-- Network handlers
-------------------------------------------------------------------------------

function CombatManager.RegisterNetworkHandlers()
	NetworkManager.OnClientEvent("MeleeAttack", function(player: Player)
		CombatManager.ProcessMeleeAttack(player)
	end)
end

return CombatManager
