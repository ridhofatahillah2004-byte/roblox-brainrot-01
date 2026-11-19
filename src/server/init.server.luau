-- Brainrot Egg Rush — server entry point.
-- Creates the RemoteEvents, then starts every service in dependency
-- order: data first, then bases, eggs, stealing, waves and rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameState = require(ServerScriptService.Server.GameState)
local PlayerData = require(ServerScriptService.Server.PlayerData)
local BaseService = require(ServerScriptService.Server.BaseService)
local EggService = require(ServerScriptService.Server.EggService)
local StealService = require(ServerScriptService.Server.StealService)
local WaveService = require(ServerScriptService.Server.WaveService)
local RebirthService = require(ServerScriptService.Server.RebirthService)

-- RemoteEvents live in ReplicatedStorage so the client can find them.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	GameState.Remotes[name] = remote
	return remote
end

makeRemote("StateUpdate") -- server -> client: HUD state, once a second
makeRemote("Notify") -- server -> client: toast notifications
makeRemote("WaveWarning") -- server -> client: tsunami phase + countdown
makeRemote("Rebirth") -- client -> server: rebirth request
makeRemote("BuySlot") -- client -> server: buy another base slot
makeRemote("RequestState") -- client -> server: ask for a fresh HUD state

PlayerData.init()
BaseService.init()
EggService.init()
StealService.init()
WaveService.init()
RebirthService.init()

-- Client-initiated requests.
GameState.Remotes.BuySlot.OnServerEvent:Connect(function(player)
	BaseService.buySlot(player)
end)
GameState.Remotes.RequestState.OnServerEvent:Connect(function(player)
	BaseService.pushState(player)
end)

print("[Brainrot Egg Rush] Server started: bases, eggs, stealing, waves, rebirths ready.")
