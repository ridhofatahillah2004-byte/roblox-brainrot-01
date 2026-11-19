-- PlayerData: one record per player (cash, rebirths, unlocked base slots).
-- Saves to a DataStore when it can; when it cannot (Studio without API
-- access, for example) the game keeps going with in-memory data only.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local PlayerData = {}

local ctx = nil
local records = {}
local store = nil

local STORE_NAME = "BrainrotEggRushV1"
local STORE_KEY_PREFIX = "player_"

local function defaultRecord()
	return {
		Cash = BrainrotConfig.Tuning.StartCash,
		Rebirths = 0,
		UnlockedSlots = BrainrotConfig.Base.FreeSlots,
		BaseId = 0,
		Income = 0,
	}
end

local function dataStore()
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStore unavailable, playing without saves: " .. tostring(result))
	end
	return store
end

local function loadRecord(player)
	local record = defaultRecord()
	local ds = dataStore()
	if ds then
		local ok, saved = pcall(function()
			return ds:GetAsync(STORE_KEY_PREFIX .. tostring(player.UserId))
		end)
		if ok and type(saved) == "table" then
			record.Cash = tonumber(saved.Cash) or record.Cash
			record.Rebirths = tonumber(saved.Rebirths) or record.Rebirths
			record.UnlockedSlots = tonumber(saved.UnlockedSlots) or record.UnlockedSlots
		elseif not ok then
			warn("[PlayerData] Load failed for " .. player.Name .. ": " .. tostring(saved))
		end
	end
	return record
end

local function saveRecord(player)
	local record = records[player]
	if not record then
		return
	end
	local ds = dataStore()
	if not ds then
		return
	end
	local ok, err = pcall(function()
		ds:SetAsync(STORE_KEY_PREFIX .. tostring(player.UserId), {
			Cash = record.Cash,
			Rebirths = record.Rebirths,
			UnlockedSlots = record.UnlockedSlots,
		})
	end)
	if not ok then
		warn("[PlayerData] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Send the player's current numbers to their client.
function PlayerData.sync(player)
	local record = records[player]
	if not record or not ctx or not ctx.Remotes then
		return
	end
	local remote = ctx.Remotes:FindFirstChild("StateSync")
	if remote then
		remote:FireClient(player, {
			cash = record.Cash,
			income = record.Income,
			rebirths = record.Rebirths,
			unlockedSlots = record.UnlockedSlots,
			baseId = record.BaseId,
		})
	end
end

function PlayerData.get(player)
	return records[player]
end

function PlayerData.getCash(player)
	local record = records[player]
	return record and record.Cash or 0
end

function PlayerData.addCash(player, amount)
	local record = records[player]
	if not record then
		return
	end
	record.Cash = math.max(0, record.Cash + amount)
end

-- Take cash when the player can afford it. Returns true on success.
function PlayerData.spendCash(player, amount)
	local record = records[player]
	if not record or record.Cash < amount then
		return false
	end
	record.Cash -= amount
	PlayerData.sync(player)
	return true
end

function PlayerData.getRebirths(player)
	local record = records[player]
	return record and record.Rebirths or 0
end

function PlayerData.addRebirth(player)
	local record = records[player]
	if not record then
		return false
	end
	record.Rebirths += 1
	PlayerData.sync(player)
	return true
end

function PlayerData.getUnlockedSlots(player)
	local record = records[player]
	return record and record.UnlockedSlots or BrainrotConfig.Base.FreeSlots
end

function PlayerData.unlockSlot(player)
	local record = records[player]
	if not record then
		return false
	end
	if record.UnlockedSlots >= BrainrotConfig.Base.SlotCount then
		return false
	end
	record.UnlockedSlots += 1
	PlayerData.sync(player)
	return true
end

function PlayerData.setIncome(player, income)
	local record = records[player]
	if record then
		record.Income = income
	end
end

function PlayerData.setBaseId(player, baseId)
	local record = records[player]
	if record then
		record.BaseId = baseId
		PlayerData.sync(player)
	end
end

function PlayerData.init(context)
	ctx = context

	Players.PlayerAdded:Connect(function(player)
		records[player] = loadRecord(player)
		PlayerData.sync(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveRecord(player)
		records[player] = nil
	end)

	-- Autosave every minute so a crash costs little.
	task.spawn(function()
		while true do
			task.wait(BrainrotConfig.Tuning.AutosaveSeconds)
			for player in pairs(records) do
				saveRecord(player)
			end
		end
	end)

	-- Players who joined before this service started.
	for _, player in ipairs(Players:GetPlayers()) do
		if not records[player] then
			records[player] = loadRecord(player)
			PlayerData.sync(player)
		end
	end
end

return PlayerData
