-- RebirthService: pay $1M to rebirth. Every rebirth multiplies all income
-- by five, so a rebirthed base earns far more from the same brainrots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local RebirthService = {}

local ctx = nil

local function onRebirth(player)
	local record = ctx.PlayerData.get(player)
	if not record then
		return
	end
	if record.Rebirths >= BrainrotConfig.Rebirth.MaxLevel then
		ctx.GameState.notify(player, "You are already at the max rebirth level.", "info")
		return
	end
	local cost = BrainrotConfig.Rebirth.Cost
	if not ctx.PlayerData.spendCash(player, cost) then
		ctx.GameState.notify(player, "Rebirth costs $" .. tostring(cost) .. ".", "warn")
		return
	end
	ctx.PlayerData.addRebirth(player)
	local multiplier = BrainrotConfig.rebirthMultiplier(record.Rebirths)
	ctx.GameState.notify(player, "REBIRTH! Your income is now x" .. tostring(multiplier) .. "!", "good")
end

function RebirthService.init(context)
	ctx = context
	local remote = ctx.Remotes:WaitForChild("RebirthEvent")
	remote.OnServerEvent:Connect(onRebirth)
end

return RebirthService
