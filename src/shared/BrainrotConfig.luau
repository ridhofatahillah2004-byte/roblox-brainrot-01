-- Brainrot Egg Rush — shared game configuration.
-- Every number the game runs on lives here so the client HUD and the
-- server services always agree. No Roblox services are touched here,
-- so this module is safe to require from both sides.

local Config = {}

-- Economy ---------------------------------------------------------------
Config.START_CASH = 250
Config.BASE_SLOTS_FREE = 6
Config.MAX_SLOTS = 10
-- Cost of buying extra base slots (slot number -> price in coins).
Config.SLOT_COSTS = {
	[7] = 50000,
	[8] = 250000,
	[9] = 1000000,
	[10] = 5000000,
}

-- Rebirth: cash needed grows x5 per rebirth; each rebirth adds +25% income.
Config.REBIRTH_BASE = 1000000
Config.REBIRTH_SCALE = 5
Config.REBIRTH_BONUS = 0.25

-- Eggs and waves ----------------------------------------------------------
Config.EGG_SPAWN_INTERVAL = 8 -- seconds between new eggs on the belt
Config.EGG_MAX_BELT = 6 -- eggs on the conveyor at once
Config.HATCH_TIME = 6 -- seconds from purchase to hatch
Config.WAVE_INTERVAL = 150 -- seconds between tsunami waves
Config.WAVE_WARNING = 10 -- warning seconds before the wave sweeps
Config.WAVE_SWEEP_TIME = 10 -- seconds the wall takes to cross the map
Config.FOLLOW_SPEED = 18 -- studs/second for following eggs and brainrots
Config.STEAL_HOLD = 3 -- seconds to hold a steal prompt
Config.SLAP_RANGE = 12 -- studs: how close a slap must be to cancel a steal
Config.SLAP_STUN = 2 -- seconds the thief is stunned after a slap

-- Rarities ----------------------------------------------------------------
-- rate is coins per second for a Normal brainrot of this rarity.
Config.RARITIES = {
	Common = { rate = 2, color = Color3.fromRGB(190, 190, 190) },
	Rare = { rate = 8, color = Color3.fromRGB(80, 170, 255) },
	Epic = { rate = 25, color = Color3.fromRGB(180, 80, 255) },
	Legendary = { rate = 80, color = Color3.fromRGB(255, 180, 40) },
	Mythic = { rate = 250, color = Color3.fromRGB(255, 60, 120) },
}
Config.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- Mutations: roll weight and income multiplier.
Config.MUTATIONS = {
	{ name = "Normal", weight = 88, multiplier = 1, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", weight = 8, multiplier = 2, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 3, multiplier = 4, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", weight = 1, multiplier = 8, color = Color3.fromRGB(255, 120, 220) },
}

-- Brainrot cast -----------------------------------------------------------
-- body/head/leg colors are RGB triples; accessory is one of the shapes
-- BrainrotFactory knows how to build ("bat", "ring", "fin", "crown",
-- "wings", "hat", "none"). rate overrides the rarity base rate.
Config.CHARACTERS = {
	-- Common
	pipiKiwi = { name = "Pipi Kiwi", rarity = "Common", rate = 2,
		body = { 120, 200, 90 }, head = { 255, 220, 130 }, accessory = "beak" },
	frigoCamelo = { name = "Frigo Camelo", rarity = "Common", rate = 2,
		body = { 230, 230, 235 }, head = { 200, 200, 210 }, accessory = "none" },
	potHotspot = { name = "Pot Hotspot", rarity = "Common", rate = 2,
		body = { 90, 90, 100 }, head = { 70, 70, 80 }, accessory = "steam" },
	trippiTroppi = { name = "Trippi Troppi", rarity = "Common", rate = 3,
		body = { 255, 140, 60 }, head = { 255, 170, 90 }, accessory = "fin" },
	-- Rare
	chimpanzini = { name = "Chimpanzini Bananini", rarity = "Rare", rate = 8,
		body = { 255, 220, 60 }, head = { 180, 130, 80 }, accessory = "banana" },
	brrPatapim = { name = "Brr Brr Patapim", rarity = "Rare", rate = 8,
		body = { 150, 110, 70 }, head = { 200, 160, 110 }, accessory = "none" },
	giraffaCeleste = { name = "Giraffa Celeste", rarity = "Rare", rate = 9,
		body = { 140, 200, 255 }, head = { 180, 220, 255 }, accessory = "horns" },
	bonecaAmbalabu = { name = "Boneca Ambalabu", rarity = "Rare", rate = 9,
		body = { 255, 150, 200 }, head = { 255, 200, 220 }, accessory = "hat" },
	-- Epic
	bombardiro = { name = "Bombardiro Crocodilo", rarity = "Epic", rate = 25,
		body = { 60, 180, 90 }, head = { 40, 140, 70 }, accessory = "wings" },
	lirili = { name = "Lirili Larila", rarity = "Epic", rate = 25,
		body = { 80, 200, 100 }, head = { 110, 220, 130 }, accessory = "spikes" },
	cappuccino = { name = "Cappuccino Assassino", rarity = "Epic", rate = 30,
		body = { 140, 100, 60 }, head = { 200, 170, 130 }, accessory = "katana" },
	vacaSaturno = { name = "La Vaca Saturno Saturnita", rarity = "Epic", rate = 30,
		body = { 245, 245, 245 }, head = { 230, 230, 230 }, accessory = "ring" },
	-- Legendary
	tungSahur = { name = "Tung Tung Tung Sahur", rarity = "Legendary", rate = 80,
		body = { 150, 105, 60 }, head = { 120, 85, 45 }, accessory = "bat" },
	ballerina = { name = "Ballerina Cappuccina", rarity = "Legendary", rate = 85,
		body = { 250, 220, 200 }, head = { 240, 200, 170 }, accessory = "tutu" },
	tralaleritos = { name = "Los Tralaleritos", rarity = "Legendary", rate = 90,
		body = { 70, 140, 255 }, head = { 100, 170, 255 }, accessory = "fin" },
	-- Mythic
	tralala = { name = "Tralalero Tralala", rarity = "Mythic", rate = 250,
		body = { 60, 130, 255 }, head = { 90, 160, 255 }, accessory = "fin" },
	graipuss = { name = "Graipuss Medussi", rarity = "Mythic", rate = 260,
		body = { 170, 90, 230 }, head = { 200, 130, 255 }, accessory = "tentacles" },
	crocodillitos = { name = "Los Crocodillitos", rarity = "Mythic", rate = 280,
		body = { 50, 170, 80 }, head = { 40, 130, 60 }, accessory = "wings" },
}

-- Egg tiers: price and the rarity weights a hatch rolls from.
Config.EGG_TIERS = {
	{ key = "Basic", price = 100, color = { 200, 200, 200 },
		weights = { Common = 70, Rare = 25, Epic = 4, Legendary = 1, Mythic = 0 } },
	{ key = "Silver", price = 1000, color = { 190, 200, 215 },
		weights = { Common = 40, Rare = 40, Epic = 15, Legendary = 4, Mythic = 1 } },
	{ key = "Golden", price = 10000, color = { 255, 210, 60 },
		weights = { Common = 0, Rare = 40, Epic = 35, Legendary = 20, Mythic = 5 } },
	{ key = "Diamond", price = 100000, color = { 130, 220, 255 },
		weights = { Common = 0, Rare = 0, Epic = 50, Legendary = 35, Mythic = 15 } },
	{ key = "Rainbow", price = 1000000, color = { 255, 120, 220 },
		weights = { Common = 0, Rare = 0, Epic = 0, Legendary = 60, Mythic = 40 } },
}

-- Helpers -----------------------------------------------------------------
-- Pick one entry from a {name = weight} table, weighted at random.
function Config.weightedPick(weights)
	local total = 0
	for _, w in pairs(weights) do
		total += w
	end
	if total <= 0 then
		return nil
	end
	local roll = math.random() * total
	for name, w in pairs(weights) do
		roll -= w
		if roll <= 0 then
			return name
		end
	end
	return nil
end

-- Pick a random character key of the given rarity.
function Config.randomCharacter(rarity)
	local pool = {}
	for key, def in pairs(Config.CHARACTERS) do
		if def.rarity == rarity then
			table.insert(pool, key)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.random(#pool)]
end

-- Roll a mutation from Config.MUTATIONS.
function Config.rollMutation()
	local weights = {}
	for _, m in ipairs(Config.MUTATIONS) do
		weights[m.name] = m.weight
	end
	local name = Config.weightedPick(weights)
	for _, m in ipairs(Config.MUTATIONS) do
		if m.name == name then
			return m
		end
	end
	return Config.MUTATIONS[1]
end

-- Coins per second for a brainrot of this character and mutation.
function Config.incomeRate(charKey, mutation)
	local def = Config.CHARACTERS[charKey]
	if not def then
		return 0
	end
	return def.rate * mutation.multiplier
end

-- Cash needed to rebirth at the given rebirth count (0-based).
function Config.rebirthCost(rebirths)
	return Config.REBIRTH_BASE * (Config.REBIRTH_SCALE ^ rebirths)
end

-- Income multiplier from rebirths.
function Config.rebirthMultiplier(rebirths)
	return 1 + Config.REBIRTH_BONUS * rebirths
end

-- Short human-readable money, e.g. 1.5K, 2.3M, 12.0B.
function Config.formatMoney(n)
	n = math.floor(n + 0.5)
	if n < 1000 then
		return "$" .. tostring(n)
	elseif n < 1000000 then
		return string.format("$%.1fK", n / 1000)
	elseif n < 1000000000 then
		return string.format("$%.1fM", n / 1000000)
	else
		return string.format("$%.1fB", n / 1000000000)
	end
end

return Config
