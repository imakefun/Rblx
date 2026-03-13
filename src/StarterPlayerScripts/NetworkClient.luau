--!strict
-- NetworkClient.luau
-- Client-side counterpart to the server's NetworkManager.
-- Routes incoming server messages to registered handlers via ID-based dispatch.
--
-- Place in: StarterPlayerScripts
--
-- USAGE:
--   local NetworkClient = require(script.Parent:WaitForChild("NetworkClient"))
--
--   -- Listen for server messages:
--   NetworkClient.OnServerEvent("StatsUpdated", function(stats) ... end)
--
--   -- Fire a request to the server:
--   NetworkClient.FireServer("AddFuel", "Wood")
--
--   -- Invoke the server and wait for a response:
--   local inv = NetworkClient.InvokeServerAsync("GetInventory")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkClient = {}

-------------------------------------------------------------------------------
-- Wait for the remotes that the server's NetworkManager creates
-------------------------------------------------------------------------------

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remoteEvent = remotes:WaitForChild("GameRemoteEvent") :: RemoteEvent
local remoteFunction = remotes:WaitForChild("GameRemoteFunction") :: RemoteFunction
local unreliableRemote = remotes:WaitForChild("GameUnreliableRemote") :: UnreliableRemoteEvent

-------------------------------------------------------------------------------
-- Handler registries
-------------------------------------------------------------------------------

type EventHandler = (...any) -> ()

local eventHandlers: { [string]: EventHandler } = {}
local unreliableHandlers: { [string]: EventHandler } = {}

function NetworkClient.OnServerEvent(id: string, handler: EventHandler)
	if eventHandlers[id] then
		warn(`[NetworkClient] Overwriting handler for "{id}"`)
	end
	eventHandlers[id] = handler
end

function NetworkClient.OnServerEventUnreliable(id: string, handler: EventHandler)
	if unreliableHandlers[id] then
		warn(`[NetworkClient] Overwriting unreliable handler for "{id}"`)
	end
	unreliableHandlers[id] = handler
end

-------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------

remoteEvent.OnClientEvent:Connect(function(id: unknown, ...: any)
	if typeof(id) ~= "string" then return end
	local handler = eventHandlers[id :: string]
	if handler then
		local ok, err = pcall(handler, ...)
		if not ok then
			warn(`[NetworkClient] Error in handler "{id}": {err}`)
		end
	end
end)

unreliableRemote.OnClientEvent:Connect(function(id: unknown, ...: any)
	if typeof(id) ~= "string" then return end
	local handler = unreliableHandlers[id :: string]
	if handler then
		pcall(handler, ...)
	end
end)

-------------------------------------------------------------------------------
-- Client -> Server
-------------------------------------------------------------------------------

function NetworkClient.FireServer(id: string, ...: any)
	remoteEvent:FireServer(id, ...)
end

--- Invoke the server and yield until a response comes back.
function NetworkClient.InvokeServerAsync(id: string, ...: any): ...any
	return remoteFunction:InvokeServer(id, ...)
end

return NetworkClient
