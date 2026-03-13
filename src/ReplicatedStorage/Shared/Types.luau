--!strict
-- Types.luau
-- Shared type definitions for Stranded: The Forest Beyond
-- Both server and client require this module for consistent typing.

export type PlayerStats = {
	Health: number,
	Hunger: number,
	Oxygen: number,
	Stamina: number,
	Exposure: number,
}

export type InventorySlot = {
	itemId: string,
	count: number,
}

--- Slot-based inventory: array of InventorySlot (index = slot number).
--- Empty slots are represented as { itemId = "", count = 0 }.
export type Inventory = { InventorySlot }

export type PlayerData = {
	stats: PlayerStats,
	inventory: Inventory,
	hotbarIndex: number,
	equippedToolSlot: number?,
	role: string?,
	inventorySize: number,
}

export type SignalFireState = {
	fuel: number,
	maxFuel: number,
	level: number,
	radius: number,
	position: Vector3,
}

export type GameState = {
	currentSol: number,
	timeInCycle: number,
	isNight: boolean,
	running: boolean,
}

return nil
