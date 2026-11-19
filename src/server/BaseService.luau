-- Brainrot Egg Rush — player bases: plot assignment, brainrot slots,
-- auto-placement when a player brings a brainrot home, and the
-- one-second income tick that pays every placed brainrot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local GameState = require(script.Parent.GameState)
local PlayerData = require(script.Parent.PlayerData)

local BaseService = {}

local basesFolder = nil

-- Bounds of a base pad, from its Pad part, for "is the player home?" checks.
local function computeBounds(pad)
	local pos = pad.Position
	local size = pad.Size
	return {
		minX = pos.X - size.X / 2,
		maxX = pos.X + size.X / 2,
		minZ = pos.Z - size.Z / 2,
		maxZ = pos.Z + size.Z / 2,
	}
end

function BaseService.isOnBase(player)
	local base = GameState.Bases[player]
	if not base then
		return false
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local p = root.Position
	local b = base.bounds
	return p.X >= b.minX and p.X <= b.maxX and p.Z >= b.minZ and p.Z <= b.maxZ
end

-- First free slot index on the player's base, or nil when full.
function BaseService.firstFreeSlot(player)
	local base = GameState.Bases[player]
	if not base then
		return nil
	end
	local max = PlayerData.slotCount(player)
	for i = 1, max do
		if base.slots[i] == nil then
			return i
		end
	end
	return nil
end

-- World position of a slot on the player's base.
function BaseService.slotPosition(player, slotIndex)
	local base = GameState.Bases[player]
	if not base then
		return nil
	end
	local slotsFolder = base.pad.Parent:FindFirstChild("Slots")
	local slotPart = slotsFolder and slotsFolder:FindFirstChild("Slot" .. slotIndex)
	if slotPart then
		return slotPart.Position + Vector3.new(0, 1.5, 0)
	end
	-- Fallback: arrange slots in two rows on the pad.
	local pad = base.pad
	local row = math.floor((slotIndex - 1) / 3)
	local col = (slotIndex - 1) % 3
	return pad.Position + Vector3.new((col - 1) * 6, 1.5, (row - 0.5) * 6)
end

-- Give the joining player the first unclaimed base plot.
function BaseService.assignBase(player)
	if GameState.Bases[player] then
		return
	end
	for _, baseModel in ipairs(basesFolder:GetChildren()) do
		if baseModel:IsA("Model") then
			local owner = baseModel:FindFirstChild("Owner")
			if owner and owner.Value == nil then
				owner.Value = player
				local pad = baseModel:FindFirstChild("Pad")
				GameState.Bases[player] = {
					pad = pad,
					slots = {},
					bounds = computeBounds(pad),
				}
				-- Color the pad with the player's own color so bases read
				-- as "mine" at a glance.
				local baseColors = {
					Color3.fromRGB(255, 80, 80),
					Color3.fromRGB(80, 140, 255),
					Color3.fromRGB(80, 220, 110),
					Color3.fromRGB(255, 220, 60),
					Color3.fromRGB(255, 140, 50),
					Color3.fromRGB(180, 90, 255),
					Color3.fromRGB(255, 120, 200),
					Color3.fromRGB(60, 220, 220),
				}
				pad.Color = baseColors[math.random(#baseColors)]
				return
			end
		end
	end
end

function BaseService.releaseBase(player)
	local base = GameState.Bases[player]
	if not base then
		return
	end
	local baseModel = base.pad.Parent
	local owner = baseModel:FindFirstChild("Owner")
	if owner then
		owner.Value = nil
	end
	GameState.Bases[player] = nil
end

-- Move a following brainrot onto a free slot of its owner's base.
function BaseService.placeBrainrot(record)
	local player = record.owner
	local slotIndex = BaseService.firstFreeSlot(player)
	if not slotIndex then
		return false
	end
	local base = GameState.Bases[player]
	base.slots[slotIndex] = record.id
	record.slot = slotIndex
	record.state = "placed"
	local pos = BaseService.slotPosition(player, slotIndex)
	if pos and record.model then
		record.model:PivotTo(CFrame.new(pos))
	end
	return true
end

-- Free a brainrot's slot (steal, rebirth, leave). Does not destroy the model.
function BaseService.unplaceBrainrot(record)
	if record.slot and record.owner then
		local base = GameState.Bases[record.owner]
		if base and base.slots[record.slot] == record.id then
			base.slots[record.slot] = nil
		end
	end
	record.slot = nil
end

-- Buy one more base slot with coins.
function BaseService.buySlot(player)
	local rec = GameState.Players[player]
	if not rec then
		return
	end
	local current = PlayerData.slotCount(player)
	if current >= Config.MAX_SLOTS then
		GameState.Remotes.Notify:FireClient(player, { text = "Your base already has the maximum slots!", color = Color3.fromRGB(255, 120, 120) })
		return
	end
	local cost = Config.SLOT_COSTS[current + 1]
	if not cost then
		return
	end
	if PlayerData.trySpend(player, cost) then
		rec.slotsBought += 1
		GameState.Remotes.Notify:FireClient(player, { text = "Base slot " .. (current + 1) .. " unlocked!", color = Color3.fromRGB(140, 255, 140) })
	else
		GameState.Remotes.Notify:FireClient(player, { text = "You need " .. Config.formatMoney(cost) .. " for another slot.", color = Color3.fromRGB(255, 120, 120) })
	end
end

-- Send one player their current HUD state.
function BaseService.pushState(player)
	local rec = GameState.Players[player]
	if not rec then
		return
	end
	local count = 0
	for _, _ in pairs(rec.brainrots) do
		count += 1
	end
	GameState.Remotes.StateUpdate:FireClient(player, {
		cash = math.floor(rec.cash),
		incomePerSecond = PlayerData.incomePerSecond(player),
		brainrotCount = count,
		rebirths = rec.rebirths,
		multiplier = PlayerData.multiplier(player),
		slotsUsed = count,
		slotsTotal = PlayerData.slotCount(player),
		rebirthCost = Config.rebirthCost(rec.rebirths),
		nextWaveIn = math.max(0, math.floor(GameState.NextWaveIn)),
		carrying = rec.carrying ~= nil,
	})
end

-- Follow loop: following brainrots walk after their owner, and a
-- brainrot that reaches its owner's base pad claims a free slot.
local function followStep(dt)
	for _, record in pairs(GameState.Brainrots) do
		if record.state == "following" and record.model then
			local player = record.owner
			local char = player and player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				if BaseService.isOnBase(player) then
					if BaseService.placeBrainrot(record) then
						GameState.Remotes.Notify:FireClient(player, {
							text = record.name .. " is now earning on your base!",
							color = Color3.fromRGB(140, 255, 140),
						})
					end
				else
					local target = root.Position
					local pivot = record.model:GetPivot()
					local pos = pivot.Position
					local toTarget = target - pos
					toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
					local dist = toTarget.Magnitude
					if dist > 4 then
						local step = math.min(dist, Config.FOLLOW_SPEED * dt)
						local newPos = pos + toTarget.Unit * step
						local bob = math.sin(os.clock() * 4 + record.id) * 0.25
						record.model:PivotTo(CFrame.new(newPos.X, 2.2 + bob, newPos.Z)
							* CFrame.Angles(0, math.atan2(-toTarget.X, -toTarget.Z), 0))
					end
				end
			end
		elseif record.state == "placed" and record.model then
			-- A placed brainrot bobs and slowly turns on its slot.
			local pivot = record.model:GetPivot()
			local pos = pivot.Position
			local _, yaw, _ = pivot:ToOrientation()
			local bob = math.sin(os.clock() * 2 + record.id) * 0.15
			record.model:PivotTo(CFrame.new(pos.X, 2.2 + bob, pos.Z) * CFrame.Angles(0, yaw + dt * 0.25, 0))
		end
	end
end

-- One-second income tick.
local function incomeStep()
	for _, player in ipairs(Players:GetPlayers()) do
		local income = PlayerData.incomePerSecond(player)
		if income > 0 then
			PlayerData.addCash(player, income)
		end
		BaseService.pushState(player)
	end
end

function BaseService.init()
	basesFolder = Workspace:WaitForChild("Bases")
	for _, player in ipairs(Players:GetPlayers()) do
		BaseService.assignBase(player)
	end
	Players.PlayerAdded:Connect(BaseService.assignBase)
	Players.PlayerRemoving:Connect(BaseService.releaseBase)
	RunService.Heartbeat:Connect(followStep)
	task.spawn(function()
		while true do
			task.wait(1)
			incomeStep()
		end
	end)
end

return BaseService
