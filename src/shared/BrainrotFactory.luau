-- BrainrotFactory: builds every 3D model in the game from plain parts.
-- No uploaded assets: each egg and each brainrot is assembled here, so
-- the place file stays self-contained and the game works in Studio
-- without any asset permission.

local BrainrotFactory = {}

local BrainrotConfig = require(script.Parent.BrainrotConfig)

-- Make one part and parent it to the model.
local function newPart(name, parent, size, color, shape, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	if cframe then
		part.CFrame = cframe
	end
	part.Parent = parent
	return part
end

-- A floating label above a model: name on the first line, detail below.
local function addLabel(model, adornee, title, detail, titleColor)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(140, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = model

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.55, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor or Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.Parent = gui

	local detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "Detail"
	detailLabel.Position = UDim2.new(0, 0, 0.55, 0)
	detailLabel.Size = UDim2.new(1, 0, 0.45, 0)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Text = detail
	detailLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	detailLabel.TextScaled = true
	detailLabel.Font = Enum.Font.SourceSans
	detailLabel.TextStrokeTransparency = 0.2
	detailLabel.Parent = gui

	return gui
end

-- One accessory per feature, built from a couple of parts on the head.
-- `head` is the head part; positions are relative to the model's origin.
local function addFeature(model, feature, bodyColor)
	if feature == "Banana" then
		local peel = newPart("Banana", model, Vector3.new(0.5, 1.6, 0.5), Color3.fromRGB(255, 220, 60), Enum.PartType.Block, CFrame.new(0.7, 4.2, 0) * CFrame.Angles(0, 0, -0.5))
		peel.Material = Enum.Material.SmoothPlastic
	elseif feature == "Cactus" then
		newPart("Cactus", model, Vector3.new(0.5, 1.4, 0.5), Color3.fromRGB(60, 180, 90), Enum.PartType.Cylinder, CFrame.new(0, 4.6, 0))
	elseif feature == "Frog" then
		newPart("FrogEyeL", model, Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(80, 200, 100), Enum.PartType.Ball, CFrame.new(-0.6, 4.4, 0))
		newPart("FrogEyeR", model, Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(80, 200, 100), Enum.PartType.Ball, CFrame.new(0.6, 4.4, 0))
	elseif feature == "Fish" then
		newPart("Fin", model, Vector3.new(0.3, 1.2, 1.4), Color3.fromRGB(50, 120, 220), Enum.PartType.Block, CFrame.new(0, 4.4, 0) * CFrame.Angles(0.6, 0, 0))
	elseif feature == "Log" then
		local log = newPart("Log", model, Vector3.new(3.2, 0.9, 0.9), Color3.fromRGB(150, 105, 55), Enum.PartType.Cylinder, CFrame.new(0, 4.3, 0) * CFrame.Angles(0, 0, math.pi / 2))
		log.Material = Enum.Material.Wood
	elseif feature == "Ballet" then
		local skirt = newPart("Skirt", model, Vector3.new(3.4, 0.3, 3.4), Color3.fromRGB(255, 170, 210), Enum.PartType.Cylinder, CFrame.new(0, 0.9, 0))
		skirt.Material = Enum.Material.SmoothPlastic
		newPart("Bun", model, Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(90, 60, 40), Enum.PartType.Ball, CFrame.new(0, 4.6, 0))
	elseif feature == "Cup" then
		newPart("Cup", model, Vector3.new(1.0, 1.2, 1.0), Color3.fromRGB(250, 250, 245), Enum.PartType.Cylinder, CFrame.new(0, 4.5, 0))
	elseif feature == "Shark" then
		newPart("SharkFin", model, Vector3.new(0.3, 1.3, 1.2), Color3.fromRGB(120, 140, 160), Enum.PartType.Block, CFrame.new(0, 4.5, 0) * CFrame.Angles(-0.5, 0, 0))
		newPart("SharkTail", model, Vector3.new(0.3, 1.0, 0.9), Color3.fromRGB(120, 140, 160), Enum.PartType.Block, CFrame.new(0, 1.2, -1.3) * CFrame.Angles(0.5, 0, 0))
	elseif feature == "Croc" then
		newPart("Snout", model, Vector3.new(1.4, 0.8, 2.0), Color3.fromRGB(90, 140, 70), Enum.PartType.Block, CFrame.new(0, 3.0, 1.4))
		newPart("ToothL", model, Vector3.new(0.25, 0.4, 0.25), Color3.fromRGB(255, 255, 255), Enum.PartType.Block, CFrame.new(-0.5, 2.6, 2.2))
		newPart("ToothR", model, Vector3.new(0.25, 0.4, 0.25), Color3.fromRGB(255, 255, 255), Enum.PartType.Block, CFrame.new(0.5, 2.6, 2.2))
	elseif feature == "Fridge" then
		local fridge = newPart("Fridge", model, Vector3.new(1.8, 2.4, 0.8), Color3.fromRGB(225, 225, 230), Enum.PartType.Block, CFrame.new(0, 1.6, -1.2))
		fridge.Material = Enum.Material.Metal
	elseif feature == "Ring" then
		local ring = newPart("Ring", model, Vector3.new(4.6, 0.25, 4.6), Color3.fromRGB(255, 210, 90), Enum.PartType.Cylinder, CFrame.new(0, 1.4, 0))
		ring.Material = Enum.Material.Neon
	elseif feature == "Giraffe" then
		newPart("Neck", model, Vector3.new(0.9, 2.2, 0.9), Color3.fromRGB(255, 215, 130), Enum.PartType.Block, CFrame.new(0, 4.6, 0))
		newPart("HornL", model, Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(120, 80, 40), Enum.PartType.Cylinder, CFrame.new(-0.4, 6.0, 0))
		newPart("HornR", model, Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(120, 80, 40), Enum.PartType.Cylinder, CFrame.new(0.4, 6.0, 0))
	elseif feature == "Jelly" then
		local dome = newPart("JellyDome", model, Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(230, 150, 255), Enum.PartType.Ball, CFrame.new(0, 3.6, 0))
		dome.Transparency = 0.45
		dome.Material = Enum.Material.Glass
	elseif feature == "Pot" then
		newPart("Pot", model, Vector3.new(1.4, 1.0, 1.4), Color3.fromRGB(220, 70, 50), Enum.PartType.Cylinder, CFrame.new(0, 4.4, 0))
	elseif feature == "Crown" then
		newPart("Crown", model, Vector3.new(1.6, 0.6, 1.6), Color3.fromRGB(255, 215, 0), Enum.PartType.Cylinder, CFrame.new(0, 4.5, 0))
		newPart("Spike", model, Vector3.new(0.3, 0.7, 0.3), Color3.fromRGB(255, 215, 0), Enum.PartType.Block, CFrame.new(0, 5.1, 0))
	end
end

-- Build an egg of the given tier (a table from BrainrotConfig.EggTiers).
-- Returns the Model; the caller sets its EggId attribute and positions it.
function BrainrotFactory.buildEgg(tier)
	local model = Instance.new("Model")
	model.Name = tier.Name .. " Egg"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.5, 0.5, 0.5)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root

	local shell = newPart("Egg", model, Vector3.new(2.4, 3.0, 2.4), tier.Color, Enum.PartType.Ball, CFrame.new(0, 1.5, 0))
	shell.Material = Enum.Material.SmoothPlastic
	newPart("Stand", model, Vector3.new(2.0, 0.3, 2.0), Color3.fromRGB(120, 120, 120), Enum.PartType.Cylinder, CFrame.new(0, 0.15, 0))

	model:SetAttribute("Tier", tier.Name)
	model:SetAttribute("Price", tier.Price)
	addLabel(model, shell, tier.Name .. " Egg", "$" .. tostring(tier.Price), tier.Color)
	return model
end

-- Build a brainrot character. `character` is a row of BrainrotConfig.Characters,
-- `mutation` a row of BrainrotConfig.Mutations (or nil for Normal).
-- Returns the Model; the caller sets OwnerUserId, State, BaseId, SlotIndex.
function BrainrotFactory.buildBrainrot(character, mutation)
	mutation = mutation or { Name = "Normal", Multiplier = 1, Color = Color3.fromRGB(255, 255, 255) }
	local income = character.Income * mutation.Multiplier

	local model = Instance.new("Model")
	model.Name = character.Name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.5, 0.5, 0.5)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root

	newPart("Body", model, Vector3.new(2.4, 2.4, 1.6), character.BodyColor, Enum.PartType.Block, CFrame.new(0, 1.4, 0))
	local head = newPart("Head", model, Vector3.new(2.0, 2.0, 2.0), character.BodyColor, Enum.PartType.Ball, CFrame.new(0, 3.4, 0))
	newPart("EyeL", model, Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball, CFrame.new(-0.5, 3.6, 1.0))
	newPart("EyeR", model, Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball, CFrame.new(0.5, 3.6, 1.0))
	newPart("PupilL", model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(20, 20, 20), Enum.PartType.Ball, CFrame.new(-0.5, 3.6, 1.2))
	newPart("PupilR", model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(20, 20, 20), Enum.PartType.Ball, CFrame.new(0.5, 3.6, 1.2))
	newPart("FootL", model, Vector3.new(0.8, 0.4, 1.0), Color3.fromRGB(60, 60, 60), Enum.PartType.Block, CFrame.new(-0.6, 0.2, 0))
	newPart("FootR", model, Vector3.new(0.8, 0.4, 1.0), Color3.fromRGB(60, 60, 60), Enum.PartType.Block, CFrame.new(0.6, 0.2, 0))

	addFeature(model, character.Feature, character.BodyColor)

	-- A coloured aura marks mutated brainrots so they stand out.
	if mutation.Name ~= "Normal" then
		local aura = newPart("Aura", model, Vector3.new(3.6, 4.6, 3.6), mutation.Color, Enum.PartType.Ball, CFrame.new(0, 2.2, 0))
		aura.Transparency = 0.75
		aura.Material = Enum.Material.Neon
	end

	model:SetAttribute("Character", character.Name)
	model:SetAttribute("Rarity", character.Rarity)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("Income", income)
	model:SetAttribute("State", "Following")

	local rarityColor = BrainrotConfig.RarityColors[character.Rarity] or Color3.fromRGB(255, 255, 255)
	local detail = "$" .. tostring(income) .. "/s"
	if mutation.Name ~= "Normal" then
		detail = mutation.Name .. " $" .. tostring(income) .. "/s"
	end
	addLabel(model, head, character.Name, detail, rarityColor)
	return model
end

return BrainrotFactory
