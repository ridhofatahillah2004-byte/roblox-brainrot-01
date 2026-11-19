-- Brainrot Egg Rush — the server's shared state.
-- Every service reads and writes this one table, so there are no
-- circular requires between services: services require GameState,
-- GameState requires only Config.

local GameState = {
	-- [Player] = { cash, rebirths, brainrots = { [id] = record }, slotsBought, carrying = eggId|nil }
	Players = {},
	-- [Player] = { pad = Model, slots = { [i] = brainrotId|nil }, bounds = {minX, maxX, minZ, maxZ} }
	Bases = {},
	-- [eggId] = { id, tier, model, prompt, state = "belt"|"carried"|"hatching", owner, hatchAt }
	Eggs = {},
	-- [brainrotId] = { id, charKey, mutation, rate, owner, state = "following"|"placed", model, slot, baseOwner, beingStolenBy }
	Brainrots = {},
	-- [Player thief] = { brainrotId, victim, cancelled }
	Steals = {},
	-- RemoteEvents, filled in by init.server.luau.
	Remotes = {},
	-- Seconds until the next wave (counts down in WaveService).
	NextWaveIn = 0,
	-- True while a wave is sweeping the map.
	WaveActive = false,
	NextId = 1,
}

function GameState.nextId()
	local id = GameState.NextId
	GameState.NextId += 1
	return id
end

return GameState
