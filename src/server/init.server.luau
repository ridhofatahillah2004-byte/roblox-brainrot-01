-- Brainrot Egg Rush: buy meme eggs off the conveyor, hatch them into
-- brainrots, bring them home to earn coins, and keep them safe from
-- thieves and the tsunami. This script starts every service, in the
-- order they depend on each other.

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")

local GameState = require(Server:WaitForChild("GameState"))
local PlayerData = require(Server:WaitForChild("PlayerData"))
local BaseService = require(Server:WaitForChild("BaseService"))
local EggService = require(Server:WaitForChild("EggService"))
local StealService = require(Server:WaitForChild("StealService"))
local WaveService = require(Server:WaitForChild("WaveService"))
local RebirthService = require(Server:WaitForChild("RebirthService"))
local Debug = require(Server:WaitForChild("Debug"))

-- One shared table every service reads its collaborators from, so no
-- service has to require another at the top and risk a cycle.
local ctx = {
	GameState = GameState,
	PlayerData = PlayerData,
	BaseService = BaseService,
	EggService = EggService,
	StealService = StealService,
	WaveService = WaveService,
	RebirthService = RebirthService,
	Debug = Debug,
}

GameState.init(ctx)
PlayerData.init(ctx)
BaseService.init(ctx)
EggService.init(ctx)
StealService.init(ctx)
WaveService.init(ctx)
RebirthService.init(ctx)
Debug.init(ctx)
GameState.start()

print("Brainrot Egg Rush is running.")
