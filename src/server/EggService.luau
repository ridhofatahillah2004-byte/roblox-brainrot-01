-- EggService: the conveyor, buying eggs, hatching them, and the followers
-- (eggs and brainrots) that trail their owner until they are placed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))

local EggService = {}

local ctx = nil
local eggs = {}
local followers = {}
local holds = {}
local uidCounter = 0
local lastFullNotify = {}

local function nextUid(prefix)
	uidCounter += 1
	return prefix .. "_" .. tostring(uidCounter)
end

local function characterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function distanceTo(player, position)
	local root = characterRoot(player)
	if not root then
		return math.huge
	end
	return (root.Position - position).Magnitude
end

-- Put one egg of the given tier on the conveyor.
local function placeEgg(tier)
	local folder = ctx.GameState.getEggFolder()
	local model = BrainrotFactory.buildEgg(tier)
	local uid = nextUid("egg")
	model:SetAttribute("Uid", uid)
	local spawnCFrame = CFrame.new(-BrainrotConfig.World.BeltHalfLength, BrainrotConfig.World.BeltY, 0)
	model:PivotTo(spawnCFrame)
	model.Parent = folder
	eggs[uid] = { model = model, tier = tier }
	return uid
end

-- Spawn one egg on the conveyor, of a randomly rolled tier.
local function spawnEgg()
	placeEgg(BrainrotConfig.rollEggTier())
end

-- Spawn one egg of a named tier right now (the Debug module calls this).
function EggService.spawnEggOfTier(tierName)
	local tier = BrainrotConfig.findEggTier(tierName)
	if not tier then
		return false
	end
	placeEgg(tier)
	return true
end

local function despawnEgg(uid)
	local entry = eggs[uid]
	if not entry then
		return
	end
	eggs[uid] = nil
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
end

-- The spawn loop, with pacing that keeps the belt stocked for the crowd
-- that is actually playing: more players means eggs arrive faster, and
-- there is always at least one Basic egg on the belt, so a new player
-- can always afford to start.
local function startSpawnLoop()
	task.spawn(function()
		while true do
			local playerCount = #Players:GetPlayers()
			local interval = math.max(2, BrainrotConfig.Tuning.EggSpawnInterval - (playerCount - 1))
			task.wait(interval)
			local count = 0
			local hasBasic = false
			for _, entry in pairs(eggs) do
				count += 1
				if entry.tier.Name == "Basic" then
					hasBasic = true
				end
			end
			if count < BrainrotConfig.Tuning.MaxEggsOnBelt then
				if hasBasic then
					spawnEgg()
				else
					placeEgg(BrainrotConfig.findEggTier("Basic"))
				end
			end
		end
	end)
end

-- Turn a following egg into its brainrot.
local function hatchEgg(model, owner, tierName)
	local tier = BrainrotConfig.findEggTier(tierName) or BrainrotConfig.EggTiers[1]
	local rarity = BrainrotConfig.rollRarity(tier)
	local character = BrainrotConfig.rollCharacter(rarity)
	local mutation = BrainrotConfig.rollMutation()
	if not character then
		return
	end
	local spot = model:GetPivot()
	model:Destroy()
	local brainrot = BrainrotFactory.buildBrainrot(character, mutation)
	brainrot:SetAttribute("Uid", nextUid("br"))
	brainrot:SetAttribute("OwnerUserId", owner.UserId)
	brainrot:SetAttribute("EggTier", tier.Name)
	brainrot:SetAttribute("EggPrice", tier.Price)
	brainrot:PivotTo(spot)
	brainrot.Parent = ctx.GameState.getBrainrotFolder()
	followers[brainrot] = { owner = owner, kind = "brainrot" }
	local label = mutation.Name
	if label == "Normal" then
		label = character.Name
	else
		label = mutation.Name .. " " .. character.Name
	end
	ctx.GameState.notify(owner, "Your egg hatched into " .. label .. " ($" .. tostring(character.Income * mutation.Multiplier) .. "/s)! Take it home.", "good")
end

-- Where a follower should stand: a line trailing behind its owner.
local function followTarget(owner, index)
	local root = characterRoot(owner)
	if not root then
		return nil
	end
	local look = root.CFrame.LookVector
	local right = root.CFrame.RightVector
	local behind = 3 + index * 2
	local side = 0
	if index % 2 == 0 then
		side = -1.5
	else
		side = 1.5
	end
	local position = root.Position - look * behind + right * side
	position = Vector3.new(position.X, root.Position.Y - 2.5, position.Z)
	return CFrame.lookAt(position, position + look)
end

local function followerIndex(owner, model)
	local index = 0
	for other in pairs(followers) do
		if followers[other].owner == owner then
			if other == model then
				return index
			end
			index += 1
		end
	end
	return index
end

local function stepFollowers(dt)
	local now = os.clock()
	-- Collect the moves first: changing the followers table while pairs
	-- walks it is not safe, so hatches and placements run after the loop.
	local toHatch = {}
	local toPlace = {}
	for model, info in pairs(followers) do
		if not model.Parent then
			followers[model] = nil
		elseif not info.owner.Parent then
			followers[model] = nil
		elseif info.kind == "egg" and now >= info.hatchAt then
			table.insert(toHatch, { model = model, owner = info.owner, tierName = model:GetAttribute("Tier") })
			followers[model] = nil
		else
			local target = followTarget(info.owner, followerIndex(info.owner, model))
			if target then
				local current = model:GetPivot()
				model:PivotTo(current:Lerp(target, math.min(1, dt * BrainrotConfig.Tuning.FollowSpeed)))
			end
			if info.kind == "brainrot" and ctx.GameState.isOnOwnBase(info.owner) then
				table.insert(toPlace, { model = model, owner = info.owner })
			end
		end
	end
	for _, job in ipairs(toHatch) do
		if job.model.Parent then
			hatchEgg(job.model, job.owner, job.tierName)
		end
	end
	for _, job in ipairs(toPlace) do
		if job.model.Parent and followers[job.model] then
			local slot = ctx.BaseService.placeBrainrot(job.owner, job.model)
			if slot > 0 then
				followers[job.model] = nil
				local income = job.model:GetAttribute("Income") or 0
				ctx.GameState.notify(job.owner, job.model.Name .. " moved in! It earns $" .. tostring(income) .. "/s.", "good")
			else
				local last = lastFullNotify[job.owner] or 0
				if now - last > 5 then
					lastFullNotify[job.owner] = now
					ctx.GameState.notify(job.owner, "Your base is full! Unlock a slot to place more brainrots.", "warn")
				end
			end
		end
	end
end

local function stepEggs(dt)
	local conveyor = ctx.GameState.getWorld().Conveyor
	local beltEnd = conveyor.Position.X + BrainrotConfig.World.BeltHalfLength
	for uid, entry in pairs(eggs) do
		local model = entry.model
		if not model.Parent then
			eggs[uid] = nil
		else
			local pivot = model:GetPivot()
			local nextPivot = pivot * CFrame.new(BrainrotConfig.Tuning.BeltSpeed * dt, 0, 0) * CFrame.Angles(0, dt * 1.2, 0)
			model:PivotTo(nextPivot)
			if model:GetPivot().Position.X >= beltEnd then
				despawnEgg(uid)
			end
		end
	end
end

-- Advance one player's hold-to-buy. Called every heartbeat.
local function stepHolds(dt)
	local now = os.clock()
	for player, hold in pairs(holds) do
		if not player.Parent then
			holds[player] = nil
		elseif now - hold.lastSeen > 0.5 then
			hold.progress = 0
		elseif now < (hold.denyUntil or 0) then
			-- Waiting out a denied purchase; do not advance.
		else
			local entry = eggs[hold.uid]
			if not entry or not entry.model.Parent then
				holds[player] = nil
			elseif distanceTo(player, entry.model:GetPivot().Position) > BrainrotConfig.Tuning.InteractRange then
				hold.progress = 0
			else
				hold.progress += dt
				if hold.progress >= BrainrotConfig.Tuning.BuyHoldSeconds then
					holds[player] = nil
					local tier = entry.tier
					if ctx.PlayerData.spendCash(player, tier.Price) then
						-- Keep the very egg that was bought: take it off the
						-- belt and let it follow its new owner until it hatches.
						local bought = entry.model
						eggs[hold.uid] = nil
						bought.Parent = ctx.GameState.getBrainrotFolder()
						followers[bought] = { owner = player, kind = "egg", hatchAt = now + BrainrotConfig.Tuning.HatchSeconds }
						ctx.GameState.notify(player, "You bought a " .. tier.Name .. " Egg! It hatches in " .. tostring(BrainrotConfig.Tuning.HatchSeconds) .. " seconds.", "good")
					else
						hold.denyUntil = now + 2
						ctx.GameState.notify(player, "You need $" .. tostring(tier.Price) .. " for a " .. tier.Name .. " Egg.", "warn")
					end
				end
			end
		end
	end
end

local function onInteractHold(player, kind, uid)
	if kind ~= "Egg" then
		return
	end
	local entry = eggs[uid]
	if not entry then
		return
	end
	local hold = holds[player]
	if not hold or hold.uid ~= uid then
		holds[player] = { uid = uid, progress = 0, lastSeen = os.clock(), denyUntil = 0 }
	else
		hold.lastSeen = os.clock()
	end
end

-- Sell what the player is carrying (a brainrot first, else an egg).
local function sellCarried(player)
	local best = nil
	for model, info in pairs(followers) do
		if info.owner == player then
			if info.kind == "brainrot" then
				best = model
				break
			elseif not best then
				best = model
			end
		end
	end
	if not best then
		ctx.GameState.notify(player, "You are not carrying anything to sell.", "info")
		return
	end
	local price = best:GetAttribute("EggPrice") or best:GetAttribute("Price") or 0
	local value = math.floor(price * BrainrotConfig.Tuning.SellShare)
	followers[best] = nil
	local name = best.Name
	best:Destroy()
	ctx.PlayerData.addCash(player, value)
	ctx.PlayerData.sync(player)
	ctx.GameState.notify(player, "Sold " .. name .. " for $" .. tostring(value) .. ".", "good")
end

-- Track a model as a follower (used when a brainrot is stolen).
function EggService.trackFollower(model, owner, kind)
	followers[model] = { owner = owner, kind = kind }
end

-- Stop tracking a model as a follower.
function EggService.untrackFollower(model)
	followers[model] = nil
end

-- The wave knocks the player's carried things loose: eggs are lost, and
-- brainrots run home to the base when a slot is free.
function EggService.dropCarried(player)
	for model, info in pairs(followers) do
		if info.owner == player then
			if info.kind == "egg" then
				followers[model] = nil
				model:Destroy()
			else
				local slot = ctx.BaseService.placeBrainrot(player, model)
				if slot > 0 then
					followers[model] = nil
				end
			end
		end
	end
end

function EggService.cleanupPlayer(player)
	for model, info in pairs(followers) do
		if info.owner == player then
			followers[model] = nil
			model:Destroy()
		end
	end
	holds[player] = nil
	for _, model in ipairs(ctx.BaseService.getSlottedBrainrots(player)) do
		model:Destroy()
	end
end

function EggService.init(context)
	ctx = context
	ctx.GameState.getEggFolder()
	ctx.GameState.getBrainrotFolder()

	local holdRemote = ctx.Remotes:WaitForChild("InteractHold")
	holdRemote.OnServerEvent:Connect(onInteractHold)
	local sellRemote = ctx.Remotes:WaitForChild("SellCarried")
	sellRemote.OnServerEvent:Connect(function(player)
		sellCarried(player)
	end)

	startSpawnLoop()
	RunService.Heartbeat:Connect(function(dt)
		stepEggs(dt)
		stepFollowers(dt)
		stepHolds(dt)
	end)
end

return EggService
