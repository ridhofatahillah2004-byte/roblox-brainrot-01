-- Debug: staging helpers the tour (TOUR.json) and a reviewer in Studio
-- call to bring the game to a screen: put an egg on the belt, start the
-- tsunami now, or hand every player some cash. The functions take one
-- argument, which may arrive as the first or the second parameter.

local Debug = {}

local ctx = nil

local function pickString(a, b)
	if type(a) == "string" then
		return a
	elseif type(b) == "string" then
		return b
	end
	return nil
end

local function pickNumber(a, b)
	if type(a) == "number" then
		return a
	elseif type(b) == "number" then
		return b
	end
	return nil
end

-- Put an egg of the named tier on the conveyor (default Basic).
function Debug.spawnEgg(a, b)
	local tierName = pickString(a, b) or "Basic"
	if ctx and ctx.EggService then
		return ctx.EggService.spawnEggOfTier(tierName)
	end
	return false
end

-- Start the tsunami right now instead of waiting for the timer.
function Debug.startWave(_a, _b)
	if ctx and ctx.WaveService then
		ctx.WaveService.triggerNow()
		return true
	end
	return false
end

-- Give every player in the server the given amount of cash.
function Debug.grantCash(a, b)
	local amount = pickNumber(a, b) or 0
	if not ctx or not ctx.PlayerData then
		return false
	end
	local Players = game:GetService("Players")
	for _, player in ipairs(Players:GetPlayers()) do
		ctx.PlayerData.addCash(player, amount)
		ctx.PlayerData.sync(player)
	end
	return true
end

function Debug.init(context)
	ctx = context
end

return Debug
