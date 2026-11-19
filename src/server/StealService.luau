-- Brainrot Egg Rush — stealing: hold a prompt on a rival's brainrot to
-- take it, while its owner can slap you to cancel the steal and send
-- you flying. The threat that makes a full base worth defending.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local GameState = require(script.Parent.GameState)
local BaseService = require(script.Parent.BaseService)

local StealService = {}

local slapCooldown = {}

-- Attach the steal prompt to a newly placed brainrot.
function StealService.attachPrompt(record)
	if not record.model then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Steal"
	prompt.ActionText = "Steal"
	prompt.ObjectText = record.name .. " — " .. Config.formatMoney(record.rate) .. "/s"
	prompt.HoldDuration = Config.STEAL_HOLD
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = record.model.PrimaryPart

	prompt.PromptButtonHoldBegan:Connect(function(player)
		if player == record.owner then
			return
		end
		GameState.Steals[player] = { brainrotId = record.id, victim = record.owner, cancelled = false }
		record.beingStolenBy = player
		if record.owner then
			GameState.Remotes.Notify:FireClient(record.owner, {
				text = "⚠️ " .. player.DisplayName .. " is stealing your " .. record.name .. "! Slap them!",
				color = Color3.fromRGB(255, 80, 80),
			})
		end
	end)

	prompt.PromptButtonHoldEnded:Connect(function(player)
		local steal = GameState.Steals[player]
		if steal and steal.brainrotId == record.id then
			GameState.Steals[player] = nil
			record.beingStolenBy = nil
		end
	end)

	prompt.Triggered:Connect(function(player)
		StealService.completeSteal(player, record)
	end)

	record.prompt = prompt
end

function StealService.detachPrompt(record)
	if record.prompt then
		record.prompt:Destroy()
		record.prompt = nil
	end
end

-- The hold finished: move the brainrot to the thief's base if every
-- check still holds (free slot, still placed, steal not cancelled).
function StealService.completeSteal(player, record)
	local steal = GameState.Steals[player]
	GameState.Steals[player] = nil
	record.beingStolenBy = nil
	if not steal or steal.cancelled or steal.brainrotId ~= record.id then
		return
	end
	if record.state ~= "placed" then
		return
	end
	if record.owner == player then
		return
	end
	local victim = record.owner
	if BaseService.firstFreeSlot(player) == nil then
		GameState.Remotes.Notify:FireClient(player, { text = "Your base is full — no room for the steal!", color = Color3.fromRGB(255, 120, 120) })
		return
	end
	-- Move it: out of the victim's record and slots, into the thief's.
	local victimRec = victim and GameState.Players[victim]
	if victimRec then
		victimRec.brainrots[record.id] = nil
	end
	BaseService.unplaceBrainrot(record)
	StealService.detachPrompt(record)
	local thiefRec = GameState.Players[player]
	if not thiefRec then
		return
	end
	thiefRec.brainrots[record.id] = record
	record.owner = player
	record.state = "following"
	GameState.Remotes.Notify:FireClient(player, { text = "You stole " .. record.name .. "! Run it home!", color = Color3.fromRGB(140, 255, 140) })
	if victim then
		GameState.Remotes.Notify:FireClient(victim, { text = "💢 " .. player.DisplayName .. " stole your " .. record.name .. "!", color = Color3.fromRGB(255, 80, 80) })
	end
end

-- The slap tool: cancels an in-progress steal on your own brainrots
-- and knocks the thief away, stunned for a moment.
local function onSlapActivated(player)
	local now = os.clock()
	if slapCooldown[player] and now - slapCooldown[player] < 1 then
		return
	end
	slapCooldown[player] = now
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for thief, steal in pairs(GameState.Steals) do
		if steal.victim == player and not steal.cancelled then
			local thiefChar = thief.Character
			local thiefRoot = thiefChar and thiefChar:FindFirstChild("HumanoidRootPart")
			if thiefRoot and (thiefRoot.Position - root.Position).Magnitude <= Config.SLAP_RANGE then
				steal.cancelled = true
				local away = (thiefRoot.Position - root.Position).Unit
				thiefRoot.CFrame = thiefRoot.CFrame + Vector3.new(away.X * 20, 0, away.Z * 20) + Vector3.new(0, 4, 0)
				local humanoid = thiefChar:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
					task.delay(Config.SLAP_STUN, function()
						if humanoid.Parent then
							humanoid.WalkSpeed = 16
						end
					end)
				end
				GameState.Remotes.Notify:FireClient(player, { text = "SLAP! You stopped the steal!", color = Color3.fromRGB(140, 255, 140) })
				GameState.Remotes.Notify:FireClient(thief, { text = "You got slapped! The steal failed.", color = Color3.fromRGB(255, 120, 120) })
			end
		end
	end
end

function StealService.giveSlapTool(player)
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 2.4, 0.6)
	handle.Color = Color3.fromRGB(255, 200, 120)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	tool.Activated:Connect(function()
		onSlapActivated(player)
	end)
	local backpack = player:WaitForChild("Backpack")
	tool.Parent = backpack
end

-- Prompts live on placed brainrots: attach when one is placed, detach
-- when it leaves a base. BaseService does the placing, so watch the
-- brainrot table for state changes each heartbeat.
local function promptWatcher()
	for _, record in pairs(GameState.Brainrots) do
		if record.state == "placed" and record.prompt == nil then
			StealService.attachPrompt(record)
		elseif record.state ~= "placed" and record.prompt ~= nil then
			StealService.detachPrompt(record)
		end
	end
end

function StealService.init()
	for _, player in ipairs(Players:GetPlayers()) do
		StealService.giveSlapTool(player)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			local backpack = player:FindFirstChild("Backpack")
			if backpack and not backpack:FindFirstChild("Slap") then
				StealService.giveSlapTool(player)
			end
		end)
	end)
	-- Prompts live on placed brainrots: attach when one is placed, detach
	-- when it leaves a base. Checked twice a second, not every frame.
	task.spawn(function()
		while true do
			task.wait(0.5)
			promptWatcher()
		end
	end)
end

return StealService
