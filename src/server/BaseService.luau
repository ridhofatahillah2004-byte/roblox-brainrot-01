-- BaseService: everything about a player's base plot — its slots, which
-- brainrot sits in each one, what the base earns, and unlocking new slots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local BaseService = {}

local ctx = nil

-- All brainrots currently slotted in a player's base.
function BaseService.getSlottedBrainrots(player)
	local found = {}
	local folder = ctx.GameState.getBrainrotFolder()
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model")
			and model:GetAttribute("State") == "Slotted"
			and model:GetAttribute("OwnerUserId") == player.UserId
		then
			table.insert(found, model)
		end
	end
	return found
end

-- Coins per second the player's base earns right now.
function BaseService.getIncome(player)
	local record = ctx.PlayerData.get(player)
	if not record then
		return 0
	end
	local rebirthBoost = BrainrotConfig.rebirthMultiplier(record.Rebirths)
	local total = 0
	for _, model in ipairs(BaseService.getSlottedBrainrots(player)) do
		total += (model:GetAttribute("Income") or 0) * rebirthBoost
	end
	return total
end

function BaseService.isSlotUnlocked(player, slotIndex)
	return slotIndex <= ctx.PlayerData.getUnlockedSlots(player)
end

-- The first unlocked slot with no brainrot in it, or 0 when none is free.
function BaseService.findFreeSlot(player)
	local record = ctx.PlayerData.get(player)
	if not record or record.BaseId == 0 then
		return 0
	end
	for slotIndex = 1, ctx.PlayerData.getUnlockedSlots(player) do
		local taken = false
		for _, model in ipairs(BaseService.getSlottedBrainrots(player)) do
			if model:GetAttribute("SlotIndex") == slotIndex then
				taken = true
				break
			end
		end
		if not taken then
			return slotIndex
		end
	end
	return 0
end

-- Seat a following brainrot in the player's first free slot.
-- Returns the slot index, or 0 when there is nowhere to put it.
function BaseService.placeBrainrot(player, model)
	local record = ctx.PlayerData.get(player)
	if not record or record.BaseId == 0 then
		return 0
	end
	local slotIndex = BaseService.findFreeSlot(player)
	if slotIndex == 0 then
		return 0
	end
	local anchor = ctx.GameState.getSlotAnchor(record.BaseId, slotIndex)
	if not anchor then
		return 0
	end
	model:SetAttribute("State", "Slotted")
	model:SetAttribute("BaseId", record.BaseId)
	model:SetAttribute("SlotIndex", slotIndex)
	model:PivotTo(anchor.CFrame * CFrame.new(0, 0.4, 0))
	return slotIndex
end

-- Lift a brainrot out of its slot (steal, wave, sell). The caller decides
-- where it goes next; this only clears the slot.
function BaseService.removeBrainrot(model)
	model:SetAttribute("State", "Following")
	model:SetAttribute("BaseId", 0)
	model:SetAttribute("SlotIndex", 0)
end

-- Buy the next locked slot. Returns true when it unlocked.
function BaseService.unlockSlot(player)
	local record = ctx.PlayerData.get(player)
	if not record then
		return false
	end
	local nextSlot = record.UnlockedSlots + 1
	if nextSlot > BrainrotConfig.Base.SlotCount then
		ctx.GameState.notify(player, "All 10 slots are already unlocked.", "info")
		return false
	end
	local cost = BrainrotConfig.slotCost(nextSlot)
	if not ctx.PlayerData.spendCash(player, cost) then
		ctx.GameState.notify(player, "You need $" .. tostring(cost) .. " to unlock slot " .. tostring(nextSlot) .. ".", "warn")
		return false
	end
	ctx.PlayerData.unlockSlot(player)
	ctx.GameState.notify(player, "Slot " .. tostring(nextSlot) .. " unlocked!", "good")
	return true
end

function BaseService.init(context)
	ctx = context
	local buySlot = ctx.Remotes:WaitForChild("BuySlot")
	buySlot.OnServerEvent:Connect(function(player)
		BaseService.unlockSlot(player)
	end)
end

return BaseService
