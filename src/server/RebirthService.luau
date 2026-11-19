-- Brainrot Egg Rush — rebirth: trade everything for a permanent
-- income multiplier and climb the ladder again, faster.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local GameState = require(script.Parent.GameState)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local RebirthService = {}

function RebirthService.rebirth(player)
	local rec = GameState.Players[player]
	if not rec then
		return
	end
	local cost = Config.rebirthCost(rec.rebirths)
	if rec.cash < cost then
		GameState.Remotes.Notify:FireClient(player, {
			text = "You need " .. Config.formatMoney(cost) .. " to rebirth.",
			color = Color3.fromRGB(255, 120, 120),
		})
		return
	end
	-- Clear every brainrot the player owns, placed or following.
	for id, record in pairs(rec.brainrots) do
		BaseService.unplaceBrainrot(record)
		if record.model then
			record.model:Destroy()
		end
		GameState.Brainrots[id] = nil
	end
	rec.brainrots = {}
	rec.cash = 0
	rec.carrying = nil
	rec.rebirths += 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash then
			cash.Value = 0
		end
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = rec.rebirths
		end
	end
	local mult = PlayerData.multiplier(player)
	GameState.Remotes.Notify:FireClient(player, {
		text = "🌟 REBIRTH #" .. rec.rebirths .. "! All income is now x" .. string.format("%.2f", mult) .. " forever!",
		color = Color3.fromRGB(255, 215, 0),
	})
	BaseService.pushState(player)
end

function RebirthService.init()
	GameState.Remotes.Rebirth.OnServerEvent:Connect(function(player)
		RebirthService.rebirth(player)
	end)
end

return RebirthService
