-- BrainrotConfig: every number that defines Brainrot Egg Rush.
-- Pure data (no Roblox services), so it can be required by the server,
-- by the client, and by a plain Luau test harness.

local BrainrotConfig = {}

-- How the game is tuned.
BrainrotConfig.Tuning = {
	-- Coins a new player starts with: exactly one Basic egg.
	StartCash = 100,
	-- Seconds between egg spawns on the conveyor.
	EggSpawnInterval = 8,
	-- Most eggs that may sit on the conveyor at once.
	MaxEggsOnBelt = 5,
	-- How long a bought egg takes to hatch once it is following you.
	HatchSeconds = 6,
	-- Seconds a player must hold E to buy an egg.
	BuyHoldSeconds = 0.6,
	-- Seconds a player must hold E to steal a rival brainrot.
	StealHoldSeconds = 3,
	-- How close (studs) a player must be to interact with an egg or brainrot.
	InteractRange = 10,
	-- Seconds between tsunami waves.
	WaveInterval = 150,
	-- Warning time before the wave arrives.
	WaveWarningSeconds = 10,
	-- How fast an egg slides along the conveyor (studs per second).
	BeltSpeed = 6,
	-- How fast a follower trails its owner (lerp factor per second).
	FollowSpeed = 5,
	-- Coins a carried brainrot sells for, as a share of its egg's price.
	SellShare = 0.5,
	-- How often income is paid out (seconds).
	IncomeTickSeconds = 1,
	-- How often player data is auto-saved (seconds).
	AutosaveSeconds = 60,
}

-- The cast: 18 Italian meme brainrots across 5 rarities.
-- Income is coins per second while the brainrot sits in a base slot.
-- BodyColor tints the character; Feature picks the accessory the factory adds.
BrainrotConfig.Characters = {
	-- Common
	{ Name = "Chimpanzini Bananini", Rarity = "Common", Income = 2, BodyColor = Color3.fromRGB(232, 196, 106), Feature = "Banana" },
	{ Name = "Lirili Larila", Rarity = "Common", Income = 3, BodyColor = Color3.fromRGB(148, 210, 189), Feature = "Cactus" },
	{ Name = "Boneca Ambalabu", Rarity = "Common", Income = 4, BodyColor = Color3.fromRGB(224, 122, 95), Feature = "Frog" },
	{ Name = "Trippi Troppi", Rarity = "Common", Income = 5, BodyColor = Color3.fromRGB(135, 206, 235), Feature = "Fish" },
	-- Rare
	{ Name = "Tung Tung Tung Sahur", Rarity = "Rare", Income = 10, BodyColor = Color3.fromRGB(160, 120, 70), Feature = "Log" },
	{ Name = "Ballerina Cappuccina", Rarity = "Rare", Income = 15, BodyColor = Color3.fromRGB(245, 222, 179), Feature = "Ballet" },
	{ Name = "Cappuccino Assassino", Rarity = "Rare", Income = 20, BodyColor = Color3.fromRGB(139, 90, 43), Feature = "Cup" },
	{ Name = "Tralalero Tralala", Rarity = "Rare", Income = 25, BodyColor = Color3.fromRGB(66, 135, 245), Feature = "Shark" },
	-- Epic
	{ Name = "Bombardiro Crocodilo", Rarity = "Epic", Income = 45, BodyColor = Color3.fromRGB(90, 140, 70), Feature = "Croc" },
	{ Name = "Frigo Camelo", Rarity = "Epic", Income = 60, BodyColor = Color3.fromRGB(200, 200, 210), Feature = "Fridge" },
	{ Name = "La Vaca Saturno Saturnita", Rarity = "Epic", Income = 80, BodyColor = Color3.fromRGB(220, 190, 230), Feature = "Ring" },
	{ Name = "Giraffa Celeste", Rarity = "Epic", Income = 100, BodyColor = Color3.fromRGB(255, 215, 130), Feature = "Giraffe" },
	-- Legendary
	{ Name = "Los Tralaleritos", Rarity = "Legendary", Income = 140, BodyColor = Color3.fromRGB(80, 160, 255), Feature = "Shark" },
	{ Name = "Graipuss Medussi", Rarity = "Legendary", Income = 170, BodyColor = Color3.fromRGB(190, 120, 220), Feature = "Jelly" },
	{ Name = "Pot Hotspot", Rarity = "Legendary", Income = 200, BodyColor = Color3.fromRGB(230, 90, 60), Feature = "Pot" },
	{ Name = "Las Tralaleritas", Rarity = "Legendary", Income = 220, BodyColor = Color3.fromRGB(255, 150, 200), Feature = "Shark" },
	-- Mythic
	{ Name = "Ballerino Lololo", Rarity = "Mythic", Income = 250, BodyColor = Color3.fromRGB(255, 235, 150), Feature = "Ballet" },
	{ Name = "Los Combinasionas", Rarity = "Mythic", Income = 280, BodyColor = Color3.fromRGB(120, 255, 170), Feature = "Crown" },
}

-- Rarity colours, used by the HUD and by the factory's name tag.
BrainrotConfig.RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Rare = Color3.fromRGB(90, 180, 255),
	Epic = Color3.fromRGB(180, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 60, 90),
}

-- Egg tiers. Weight is the chance a tier is picked when a new egg spawns
-- on the conveyor. RarityWeights is the chance each rarity hatches from it.
BrainrotConfig.EggTiers = {
	{ Name = "Basic", Price = 100, Color = Color3.fromRGB(240, 240, 230), Weight = 55,
		RarityWeights = { Common = 70, Rare = 22, Epic = 6, Legendary = 2, Mythic = 0 } },
	{ Name = "Silver", Price = 1000, Color = Color3.fromRGB(200, 200, 210), Weight = 25,
		RarityWeights = { Common = 40, Rare = 35, Epic = 18, Legendary = 6, Mythic = 1 } },
	{ Name = "Golden", Price = 10000, Color = Color3.fromRGB(255, 215, 0), Weight = 12,
		RarityWeights = { Common = 15, Rare = 35, Epic = 30, Legendary = 16, Mythic = 4 } },
	{ Name = "Diamond", Price = 100000, Color = Color3.fromRGB(140, 230, 255), Weight = 6,
		RarityWeights = { Common = 0, Rare = 20, Epic = 40, Legendary = 30, Mythic = 10 } },
	{ Name = "Rainbow", Price = 1000000, Color = Color3.fromRGB(255, 120, 220), Weight = 2,
		RarityWeights = { Common = 0, Rare = 0, Epic = 25, Legendary = 45, Mythic = 30 } },
}

-- Mutations rolled when an egg hatches. Weight is the roll chance.
BrainrotConfig.Mutations = {
	{ Name = "Normal", Multiplier = 1, Weight = 70, Color = Color3.fromRGB(255, 255, 255) },
	{ Name = "Golden", Multiplier = 2, Weight = 20, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Multiplier = 4, Weight = 8, Color = Color3.fromRGB(140, 230, 255) },
	{ Name = "Rainbow", Multiplier = 8, Weight = 2, Color = Color3.fromRGB(255, 120, 220) },
}

-- Rebirth: pay the cost, income multiplies by Multiplier per level.
BrainrotConfig.Rebirth = {
	Cost = 1000000,
	Multiplier = 5,
	MaxLevel = 10,
}

-- Base slots. The first FreeSlots are open; the rest cost coins to unlock.
BrainrotConfig.Base = {
	PlotCount = 8,
	SlotCount = 10,
	FreeSlots = 2,
	SlotCosts = { 500, 2000, 10000, 50000, 150000, 400000, 1000000, 2500000 },
}

-- The world layout. gen_project.py builds the same numbers into
-- default.project.json, so the two files must agree.
BrainrotConfig.World = {
	PlotRadius = 46,
	-- The conveyor runs along X through the middle of the plaza.
	BeltHalfLength = 28,
	-- The top of the belt, where eggs ride (the belt part is 1 stud thick,
	-- centred at y = 1.5).
	BeltY = 2,
}

-- Look a character up by name; returns nil when the name is unknown.
function BrainrotConfig.findCharacter(name: string)
	for _, character in ipairs(BrainrotConfig.Characters) do
		if character.Name == name then
			return character
		end
	end
	return nil
end

-- Look an egg tier up by name; returns nil when the name is unknown.
function BrainrotConfig.findEggTier(name: string)
	for _, tier in ipairs(BrainrotConfig.EggTiers) do
		if tier.Name == name then
			return tier
		end
	end
	return nil
end

-- Look a mutation up by name; returns nil when the name is unknown.
function BrainrotConfig.findMutation(name: string)
	for _, mutation in ipairs(BrainrotConfig.Mutations) do
		if mutation.Name == name then
			return mutation
		end
	end
	return nil
end

-- Pick one entry from a weighted table ({ Name = weight, ... } or a list
-- of tables with a Weight field). rng is math.random by default; tests
-- may pass their own function.
function BrainrotConfig.weightedPick(entries, rng)
	rng = rng or math.random
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.Weight
	end
	local roll = rng(1, total)
	local running = 0
	for _, entry in ipairs(entries) do
		running += entry.Weight
		if roll <= running then
			return entry
		end
	end
	return entries[#entries]
end

-- Roll a rarity for an egg tier, from its RarityWeights table.
function BrainrotConfig.rollRarity(tier, rng)
	local entries = {}
	for rarity, weight in pairs(tier.RarityWeights) do
		table.insert(entries, { Name = rarity, Weight = weight })
	end
	-- Sort so the roll is stable no matter the hash order.
	table.sort(entries, function(a, b) return a.Name < b.Name end)
	return BrainrotConfig.weightedPick(entries, rng).Name
end

-- Roll a character of the given rarity.
function BrainrotConfig.rollCharacter(rarity: string, rng)
	local pool = {}
	for _, character in ipairs(BrainrotConfig.Characters) do
		if character.Rarity == rarity then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[(rng or math.random)(1, #pool)]
end

-- Roll a mutation for a fresh hatch.
function BrainrotConfig.rollMutation(rng)
	return BrainrotConfig.weightedPick(BrainrotConfig.Mutations, rng)
end

-- Roll the egg tier for a fresh conveyor spawn.
function BrainrotConfig.rollEggTier(rng)
	return BrainrotConfig.weightedPick(BrainrotConfig.EggTiers, rng)
end

-- The income multiplier for a rebirth level.
function BrainrotConfig.rebirthMultiplier(level: number): number
	return BrainrotConfig.Rebirth.Multiplier ^ level
end

-- The price to unlock a slot (1-based). Free slots cost 0.
function BrainrotConfig.slotCost(slotIndex: number): number
	if slotIndex <= BrainrotConfig.Base.FreeSlots then
		return 0
	end
	return BrainrotConfig.Base.SlotCosts[slotIndex - BrainrotConfig.Base.FreeSlots] or 0
end

return BrainrotConfig
