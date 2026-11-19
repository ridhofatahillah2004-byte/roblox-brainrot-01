-- Brainrot Egg Rush — the conveyor belt: eggs roll in, players buy one,
-- carry it home while it hatches into a random brainrot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local Factory = require(ReplicatedStorage.Shared.BrainrotFactory)
local GameState = require(script.Parent.GameState)
local PlayerData = require(script.Parent.PlayerData)

local EggService = {}

local beltSpots = {} -- { Part, eggId|nil }
local beltFolder = nil

-- Weighted tier roll for a fresh egg on the belt.
local TIER_WEIGHTS = { Basic = 45, Silver = 30, Golden = 15, Diamond = 7, Rainbow = 3 }

local function pickTier()
	local key = Config.weightedPick(TIER_WEIGHTS)
	for _, tier in ipairs(Config.EGG_TIERS) do
		if tier.key == key then
			return tier
		end
	end
	return Config.EGG_TIERS[1]
end

local function attachBuyPrompt(egg)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyEgg"
	prompt.ActionText = "Buy Egg"
	prompt.ObjectText = egg.tier.key .. " Egg — " .. Config.formatMoney(egg.tier.price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg.model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		EggService.buyEgg(player, egg.id)
	end)
	egg.prompt = prompt
end

local function spawnEgg()
	if #GameState.Eggs >= Config.EGG_MAX_BELT then
		return
	end
	local freeSpot = nil
	for _, spot in ipairs(beltSpots) do
		if spot.eggId == nil then
			freeSpot = spot
			break
		end
	end
	if not freeSpot then
		return
	end
	local tier = pickTier()
	local id = GameState.nextId()
	local model = Factory.buildEgg(tier, freeSpot.part.Position + Vector3.new(0, 2, 0))
	model.Parent = Workspace
	local egg = {
		id = id,
		tier = tier,
		model = model,
		state = "belt",
		owner = nil,
		hatchAt = 0,
		spot = freeSpot,
	}
	freeSpot.eggId = id
	GameState.Eggs[id] = egg
	attachBuyPrompt(egg)
end

-- A player buys the egg they prompted. One egg at a time per player.
function EggService.buyEgg(player, eggId)
	local egg = GameState.Eggs[eggId]
	if not egg or egg.state ~= "belt" then
		return
	end
	local rec = GameState.Players[player]
	if not rec then
		return
	end
	if rec.carrying ~= nil then
		GameState.Remotes.Notify:FireClient(player, { text = "You are already carrying an egg!", color = Color3.fromRGB(255, 120, 120) })
		return
	end
	if not PlayerData.trySpend(player, egg.tier.price) then
		GameState.Remotes.Notify:FireClient(player, { text = "You need " .. Config.formatMoney(egg.tier.price) .. " for that egg.", color = Color3.fromRGB(255, 120, 120) })
		return
	end
	egg.state = "carried"
	egg.owner = player
	egg.hatchAt = os.clock() + Config.HATCH_TIME
	if egg.spot then
		egg.spot.eggId = nil
		egg.spot = nil
	end
	if egg.prompt then
		egg.prompt:Destroy()
		egg.prompt = nil
	end
	rec.carrying = eggId
	GameState.Remotes.Notify:FireClient(player, {
		text = "You bought a " .. egg.tier.key .. " Egg! It hatches in " .. Config.HATCH_TIME .. "s — run home!",
		color = Color3.fromRGB(255, 230, 80),
	})
end

-- The egg hatches into a random brainrot of its tier.
local function hatchEgg(egg)
	local player = egg.owner
	local rec = player and GameState.Players[player]
	local rarity = Config.weightedPick(egg.tier.weights) or "Common"
	local charKey = Config.randomCharacter(rarity)
	local mutation = Config.rollMutation()
	if rec then
		rec.carrying = nil
	end
	if egg.model then
		egg.model:Destroy()
	end
	GameState.Eggs[egg.id] = nil
	if not player or not charKey then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local spawnPos = root and (root.Position + Vector3.new(0, 2, 4)) or Vector3.new(0, 4, 0)
	local model = Factory.buildBrainrot(charKey, mutation, spawnPos)
	model.Parent = Workspace
	local id = GameState.nextId()
	local def = Config.CHARACTERS[charKey]
	local record = {
		id = id,
		charKey = charKey,
		name = def.name,
		rarity = rarity,
		mutation = mutation,
		rate = Config.incomeRate(charKey, mutation),
		owner = player,
		state = "following",
		model = model,
		slot = nil,
		beingStolenBy = nil,
	}
	GameState.Brainrots[id] = record
	rec.brainrots[id] = record
	local prefix = mutation.name == "Normal" and "" or (mutation.name .. " ")
	GameState.Remotes.Notify:FireClient(player, {
		text = "Your egg hatched into a " .. prefix .. def.name .. " (" .. Config.formatMoney(record.rate) .. "/s)! Bring it to your base!",
		color = Config.RARITIES[rarity].color,
	})
end

-- A carried egg is dropped (tsunami hit): it rolls away and is lost.
function EggService.dropEgg(player)
	local rec = GameState.Players[player]
	if not rec or rec.carrying == nil then
		return
	end
	local egg = GameState.Eggs[rec.carrying]
	rec.carrying = nil
	if egg then
		if egg.model then
			egg.model:Destroy()
		end
		GameState.Eggs[egg.id] = nil
	end
	GameState.Remotes.Notify:FireClient(player, { text = "The tsunami knocked your egg away!", color = Color3.fromRGB(255, 120, 120) })
end

-- Follow loop: carried eggs trail their owner; belt eggs bob in place;
-- eggs whose hatch timer expired hatch.
local function eggStep(dt)
	for _, egg in pairs(GameState.Eggs) do
		if egg.state == "carried" and egg.owner then
			local char = egg.owner.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and egg.model then
				local target = root.Position + Vector3.new(0, 1, -3)
				local pivot = egg.model:GetPivot()
				local pos = pivot.Position
				local toTarget = target - pos
				toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
				local dist = toTarget.Magnitude
				if dist > 1.5 then
					local step = math.min(dist, Config.FOLLOW_SPEED * dt)
					local newPos = pos + toTarget.Unit * step
					local bob = math.sin(os.clock() * 5 + egg.id) * 0.2
					egg.model:PivotTo(CFrame.new(newPos.X, 3 + bob, newPos.Z))
				end
			end
			if os.clock() >= egg.hatchAt then
				hatchEgg(egg)
			end
		elseif egg.state == "belt" and egg.model then
			local pivot = egg.model:GetPivot()
			local bob = math.sin(os.clock() * 2 + egg.id) * 0.2
			egg.model:PivotTo(CFrame.new(pivot.Position.X, 3.2 + bob, pivot.Position.Z))
		end
	end
end

function EggService.init()
	local conveyor = Workspace:WaitForChild("Conveyor")
	local spotsFolder = conveyor:WaitForChild("EggSpots")
	for _, spot in ipairs(spotsFolder:GetChildren()) do
		if spot:IsA("BasePart") then
			table.insert(beltSpots, { part = spot, eggId = nil })
		end
	end
	-- A few eggs to start with so the first player is not waiting.
	for _ = 1, 3 do
		spawnEgg()
	end
	RunService.Heartbeat:Connect(eggStep)
	task.spawn(function()
		while true do
			task.wait(Config.EGG_SPAWN_INTERVAL)
			spawnEgg()
		end
	end)
end

return EggService
