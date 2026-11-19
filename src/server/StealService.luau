-- StealService: stealing a rival's brainrot and fighting back with the
-- slap tool. A steal takes 3 seconds of holding E beside the brainrot;
-- a slap from its owner cancels the steal or wins a stolen brainrot back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local StealService = {}

local ctx = nil
local steals = {}
local lastSlap = {}

local SLAP_RANGE = 9
local SLAP_COOLDOWN = 2

local function characterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Build the slap tool every player carries.
local function buildSlapTool()
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.ToolTip = "Slap a thief to stop them stealing your brainrots!"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.4, 1.6)
	handle.Color = Color3.fromRGB(255, 220, 90)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool
	return tool
end

function StealService.giveSlapTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or backpack:FindFirstChild("Slap") then
		return
	end
	buildSlapTool().Parent = backpack
end

local function findTarget(uid)
	local folder = ctx.GameState.getBrainrotFolder()
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("Uid") == uid then
			return model
		end
	end
	return nil
end

local function onInteractHold(player, kind, uid)
	if kind ~= "Brainrot" then
		return
	end
	local target = findTarget(uid)
	if not target then
		return
	end
	if target:GetAttribute("State") ~= "Slotted" then
		return
	end
	if target:GetAttribute("OwnerUserId") == player.UserId then
		return
	end
	local hold = steals[player]
	if not hold or hold.target ~= target then
		steals[player] = { target = target, progress = 0, lastSeen = os.clock() }
		local ownerId = target:GetAttribute("OwnerUserId")
		local owner = Players:GetPlayerByUserId(ownerId)
		if owner then
			ctx.GameState.notify(owner, "Someone is stealing your " .. target.Name .. "! Slap them!", "warn")
		end
	else
		hold.lastSeen = os.clock()
	end
end

-- Hand a stolen brainrot to its new owner and let it follow them home.
local function completeSteal(thief, target)
	local ownerId = target:GetAttribute("OwnerUserId")
	local owner = Players:GetPlayerByUserId(ownerId)
	ctx.BaseService.removeBrainrot(target)
	target:SetAttribute("OwnerUserId", thief.UserId)
	target:SetAttribute("StolenFrom", ownerId)
	target:SetAttribute("State", "Following")
	ctx.EggService.trackFollower(target, thief, "brainrot")
	ctx.GameState.notify(thief, "You stole " .. target.Name .. "! Get it to your base!", "good")
	if owner then
		ctx.GameState.notify(owner, "Your " .. target.Name .. " was stolen!", "warn")
	end
end

local function stepSteals(dt)
	local now = os.clock()
	for player, hold in pairs(steals) do
		local target = hold.target
		if not player.Parent or not target or not target.Parent then
			steals[player] = nil
		elseif now - hold.lastSeen > 0.5 then
			hold.progress = 0
		elseif target:GetAttribute("State") ~= "Slotted" then
			steals[player] = nil
		else
			local root = characterRoot(player)
			local targetRoot = target.PrimaryPart
			if not root or not targetRoot then
				hold.progress = 0
			elseif (root.Position - targetRoot.Position).Magnitude > BrainrotConfig.Tuning.InteractRange then
				hold.progress = 0
			else
				hold.progress += dt
				if hold.progress >= BrainrotConfig.Tuning.StealHoldSeconds then
					steals[player] = nil
					completeSteal(player, target)
				end
			end
		end
	end
end

-- A thief near the owner: stealing from them, or carrying one of theirs.
local function findThiefNear(owner)
	local ownerRoot = characterRoot(owner)
	if not ownerRoot then
		return nil, nil
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= owner then
			local hold = steals[other]
			if hold and hold.target and hold.target:GetAttribute("OwnerUserId") == owner.UserId then
				local otherRoot = characterRoot(other)
				if otherRoot and (otherRoot.Position - ownerRoot.Position).Magnitude <= SLAP_RANGE then
					return other, nil
				end
			end
			-- Carrying a brainrot stolen from this owner.
			local folder = ctx.GameState.getBrainrotFolder()
			for _, model in ipairs(folder:GetChildren()) do
				if model:IsA("Model")
					and model:GetAttribute("OwnerUserId") == other.UserId
					and model:GetAttribute("StolenFrom") == owner.UserId
					and model:GetAttribute("State") == "Following"
				then
					local otherRoot = characterRoot(other)
					if otherRoot and (otherRoot.Position - ownerRoot.Position).Magnitude <= SLAP_RANGE then
						return other, model
					end
				end
			end
		end
	end
	return nil, nil
end

local function onSlap(player)
	local now = os.clock()
	if now - (lastSlap[player] or 0) < SLAP_COOLDOWN then
		return
	end
	lastSlap[player] = now
	local thief, carried = findThiefNear(player)
	if not thief then
		return
	end
	-- Cancel whatever they were stealing.
	steals[thief] = nil
	-- Knock them back.
	local thiefRoot = characterRoot(thief)
	local ownerRoot = characterRoot(player)
	if thiefRoot and ownerRoot then
		local away = thiefRoot.Position - ownerRoot.Position
		if away.Magnitude > 0.1 then
			thiefRoot.AssemblyLinearVelocity = away.Unit * 35 + Vector3.new(0, 18, 0)
		end
	end
	-- Win a stolen brainrot back: home to the owner's base, or follow them.
	if carried then
		ctx.EggService.untrackFollower(carried)
		carried:SetAttribute("OwnerUserId", player.UserId)
		carried:SetAttribute("StolenFrom", 0)
		local slot = ctx.BaseService.placeBrainrot(player, carried)
		if slot == 0 then
			ctx.EggService.trackFollower(carried, player, "brainrot")
		end
		ctx.GameState.notify(player, "Slap! You won " .. carried.Name .. " back!", "good")
		ctx.GameState.notify(thief, "You got slapped and lost " .. carried.Name .. "!", "warn")
	else
		ctx.GameState.notify(player, "Slap! The thief backed off.", "good")
		ctx.GameState.notify(thief, "You got slapped! The steal failed.", "warn")
	end
end

function StealService.init(context)
	ctx = context

	-- One slap tool in the StarterPack so every spawn gets it.
	local template = buildSlapTool()
	template.Parent = StarterPack
	for _, player in ipairs(Players:GetPlayers()) do
		StealService.giveSlapTool(player)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			StealService.giveSlapTool(player)
		end)
	end)

	local holdRemote = ctx.Remotes:WaitForChild("InteractHold")
	holdRemote.OnServerEvent:Connect(onInteractHold)
	local slapRemote = ctx.Remotes:WaitForChild("SlapEvent")
	slapRemote.OnServerEvent:Connect(onSlap)

	RunService.Heartbeat:Connect(stepSteals)
end

return StealService
