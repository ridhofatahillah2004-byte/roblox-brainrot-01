-- Brainrot Egg Rush — staging helpers for screenshots and playtests.
-- These exist so a reviewer (or the owner, in Studio) can bring the
-- game to any screen fast: give money, drop an egg, fill a base, or
-- force the tsunami. TOUR.json calls `finish` for the end screenshot.
-- Never called by the game itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local Factory = require(ReplicatedStorage.Shared.BrainrotFactory)
local GameState = require(script.Parent.GameState)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local WaveService = require(script.Parent.WaveService)

local Debug = {}

-- Give a player cash (for staging the shop and rebirth screens).
function Debug.giveMoney(player, amount)
	PlayerData.addCash(player, amount or 100000)
	BaseService.pushState(player)
	return true
end

-- Drop an egg of the named tier on the conveyor belt.
-- Takes a single argument so TOUR.json can call it directly.
function Debug.spawnEgg(tierKey)
	local tier = nil
	for _, t in ipairs(Config.EGG_TIERS) do
		if t.key == tierKey then
			tier = t
			break
		end
	end
	tier = tier or Config.EGG_TIERS[1]
	local conveyor = Workspace:WaitForChild("Conveyor")
	local spots = conveyor:WaitForChild("EggSpots"):GetChildren()
	local spot = spots[1]
	local model = Factory.buildEgg(tier, spot.Position + Vector3.new(0, 2, 0))
	model.Parent = Workspace
	return true
end

-- Fill the first player's base with six assorted brainrots, placed.
function Debug.fillBase(player)
	player = player or Players:GetPlayers()[1]
	if not player then
		return false
	end
	local rec = GameState.Players[player]
	if not rec then
		return false
	end
	local picks = { "pipiKiwi", "chimpanzini", "bombardiro", "tungSahur", "tralala", "graipuss" }
	for i, charKey in ipairs(picks) do
		local mutation = Config.MUTATIONS[1]
		if i >= 5 then
			mutation = Config.MUTATIONS[2] -- Golden, for the showcase slots
		end
		local def = Config.CHARACTERS[charKey]
		local pos = BaseService.slotPosition(player, i) or Vector3.new(0, 4, 0)
		local model = Factory.buildBrainrot(charKey, mutation, pos)
		model.Parent = Workspace
		local id = GameState.nextId()
		local record = {
			id = id,
			charKey = charKey,
			name = def.name,
			rarity = def.rarity,
			mutation = mutation,
			rate = Config.incomeRate(charKey, mutation),
			owner = player,
			state = "placed",
			model = model,
			slot = i,
			beingStolenBy = nil,
		}
		GameState.Brainrots[id] = record
		rec.brainrots[id] = record
		local base = GameState.Bases[player]
		if base then
			base.slots[i] = id
		end
	end
	PlayerData.addCash(player, 500000)
	BaseService.pushState(player)
	return true
end

-- Force the tsunami warning + sweep right now.
function Debug.triggerWave()
	WaveService.triggerNow()
	return true
end

-- TOUR.json entry point: "win" stages a rich base, "lose" fires the wave.
function Debug.finish(arg)
	if arg == "win" then
		Debug.fillBase()
		return true
	elseif arg == "lose" then
		Debug.triggerWave()
		return true
	end
	return false
end

return Debug
