--!strict
-- NetworkManager.luau
-- Central hub for ALL client-server communication.
--
-- PATTERN: Single RemoteEvent + single RemoteFunction with ID-based routing.
-- Instead of creating dozens of individual RemoteEvent instances, we multiplex
-- all messages through one remote using a string ID as the first argument.
-- This keeps the Instance tree clean and makes it trivial to add new messages.
--
-- Server-side module. Place in: ServerScriptService
--
-- USAGE (register a handler for client -> server messages):
--   NetworkManager.OnClientEvent("AddFuel", function(player, itemId)
--       -- validate and process on server
--   end)
--
-- USAGE (send to client):
--   NetworkManager.FireClient(player, "StatsUpdated", statsTable)
--   NetworkManager.FireAllClients("SolUpdated", newSol)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkManager = {}

-------------------------------------------------------------------------------
-- Create remote instances (server owns creation)
-- Placed in ReplicatedStorage so both server and client can access them.
-------------------------------------------------------------------------------

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "GameRemoteEvent"
remoteEvent.Parent = remotes

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "GameRemoteFunction"
remoteFunction.Parent = remotes

-- UnreliableRemoteEvent: for high-frequency, loss-tolerant data
-- (e.g. signal fire fuel gauge updates every frame)
local unreliableRemote = Instance.new("UnreliableRemoteEvent")
unreliableRemote.Name = "GameUnreliableRemote"
unreliableRemote.Parent = remotes

-------------------------------------------------------------------------------
-- Handler registries
-------------------------------------------------------------------------------

type EventHandler = (player: Player, ...any) -> ()
type FunctionHandler = (player: Player, ...any) -> ...any

local eventHandlers: { [string]: EventHandler } = {}
local functionHandlers: { [string]: FunctionHandler } = {}

--- Register a handler for a message ID fired by clients.
function NetworkManager.OnClientEvent(id: string, handler: EventHandler)
	if eventHandlers[id] then
		warn(`[NetworkManager] Overwriting event handler for "{id}"`)
	end
	eventHandlers[id] = handler
end

--- Register a handler for a RemoteFunction invocation from clients.
--- Handler MUST return the response value(s).
function NetworkManager.OnClientInvoke(id: string, handler: FunctionHandler)
	if functionHandlers[id] then
		warn(`[NetworkManager] Overwriting function handler for "{id}"`)
	end
	functionHandlers[id] = handler
end

-------------------------------------------------------------------------------
-- Incoming message routing (validation + dispatch)
-------------------------------------------------------------------------------

remoteEvent.OnServerEvent:Connect(function(player: Player, id: unknown, ...: any)
	if typeof(id) ~= "string" then
		warn(`[NetworkManager] Non-string message ID from {player.Name}`)
		return
	end

	local handler = eventHandlers[id :: string]
	if not handler then
		warn(`[NetworkManager] No handler for event "{id}" (from {player.Name})`)
		return
	end

	local ok, err = pcall(handler, player, ...)
	if not ok then
		warn(`[NetworkManager] Error in handler "{id}": {err}`)
	end
end)

remoteFunction.OnServerInvoke = function(player: Player, id: unknown, ...: any): ...any
	if typeof(id) ~= "string" then
		warn(`[NetworkManager] Non-string function ID from {player.Name}`)
		return nil
	end

	local handler = functionHandlers[id :: string]
	if not handler then
		warn(`[NetworkManager] No handler for function "{id}"`)
		return nil
	end

	return handler(player, ...)
end

-------------------------------------------------------------------------------
-- Server -> Client: reliable
-------------------------------------------------------------------------------

function NetworkManager.FireClient(player: Player, id: string, ...: any)
	remoteEvent:FireClient(player, id, ...)
end

function NetworkManager.FireAllClients(id: string, ...: any)
	remoteEvent:FireAllClients(id, ...)
end

-------------------------------------------------------------------------------
-- Server -> Client: unreliable (high-frequency, loss-tolerant)
-------------------------------------------------------------------------------

function NetworkManager.FireClientUnreliable(player: Player, id: string, ...: any)
	unreliableRemote:FireClient(player, id, ...)
end

function NetworkManager.FireAllClientsUnreliable(id: string, ...: any)
	unreliableRemote:FireAllClients(id, ...)
end

return NetworkManager
