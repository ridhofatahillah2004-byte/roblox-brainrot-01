-- Brainrot Egg Rush — player money, rebirths and leaderstats.
-- Cash lives in memory and is best-effort saved to a DataStore so a
-- crash or a Studio playtest without API access never breaks the game.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game:GetService("ReplicatedStorage").Shared.BrainrotConfig)
local GameState = require(script.Parent.GameState)

local PlayerData = {}

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("BrainrotEggRush_v1")
	end)
	if ok then
		store = result
	end
end

local function newRecord()
	return {
		cash = Config.START_CASH,
		rebirths = 0,
		brainrots = {},
		slotsBought = 0,
		carrying = nil,
	}
end

-- Income multiplier from rebirths.
function PlayerData.multiplier(player)
	local rec = GameState.Players[player]
	if not rec then
		return 1
	end
	return Config.rebirthMultiplier(rec.rebirths)
end

-- Coins per second the player earns from placed brainrots right now.
function PlayerData.incomePerSecond(player)
	local rec = GameState.Players[player]
	if not rec then
		return 0
	end
	local total = 0
	for _, b in pairs(rec.brainrots) do
		if b.state == "placed" then
			total += b.rate
		end
	end
	return total * PlayerData.multiplier(player)
end

function PlayerData.slotCount(player)
	local rec = GameState.Players[player]
	if not rec then
		return Config.BASE_SLOTS_FREE
	end
	return Config.BASE_SLOTS_FREE + rec.slotsBought
end

function PlayerData.addCash(player, amount)
	local rec = GameState.Players[player]
	if not rec then
		return
	end
	rec.cash += amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = math.floor(rec.cash)
		end
	end
end

-- Returns true when the player could afford it; spends nothing otherwise.
function PlayerData.trySpend(player, amount)
	local rec = GameState.Players[player]
	if not rec or rec.cash < amount then
		return false
	end
	rec.cash -= amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = math.floor(rec.cash)
		end
	end
	return true
end

function PlayerData.onPlayerAdded(player)
	local rec = newRecord()
	GameState.Players[player] = rec

	-- Best-effort load: a failed load just means a fresh start.
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			rec.cash = saved.cash or Config.START_CASH
			rec.rebirths = saved.rebirths or 0
			rec.slotsBought = saved.slotsBought or 0
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(rec.cash)
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = rec.rebirths
	rebirths.Parent = leaderstats
	leaderstats.Parent = player
end

function PlayerData.onPlayerRemoving(player)
	local rec = GameState.Players[player]
	if rec and store then
		pcall(function()
			store:SetAsync("player_" .. player.UserId, {
				cash = math.floor(rec.cash),
				rebirths = rec.rebirths,
				slotsBought = rec.slotsBought,
			})
		end)
	end
	-- Hand their base back and clean up their brainrots and eggs.
	local base = GameState.Bases[player]
	if base then
		for _, id in pairs(base.slots) do
			local b = GameState.Brainrots[id]
			if b and b.model then
				b.model:Destroy()
			end
			GameState.Brainrots[id] = nil
		end
		GameState.Bases[player] = nil
	end
	for id, b in pairs(GameState.Brainrots) do
		if b.owner == player and b.model then
			b.model:Destroy()
			GameState.Brainrots[id] = nil
		end
	end
	GameState.Players[player] = nil
	GameState.Steals[player] = nil
end

function PlayerData.init()
	Players.PlayerAdded:Connect(PlayerData.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerData.onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.onPlayerAdded(player)
	end
end

return PlayerData
