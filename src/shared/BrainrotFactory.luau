-- Brainrot Egg Rush — builds the 3D models: brainrot characters and eggs.
-- Everything is built from plain Parts so the whole cast is code, no
-- uploaded assets. Models are Anchored and moved by the server with
-- PivotTo, so they never fight the physics engine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)

local Factory = {}

local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function part(name, size, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- One small accessory per character, so the cast reads as different
-- creatures at a glance instead of recolored boxes.
local function addAccessory(model, kind, bodyColor)
	if kind == "bat" then
		local bat = part("Bat", Vector3.new(0.35, 2.2, 0.35), Color3.fromRGB(120, 85, 45), Enum.PartType.Cylinder)
		bat.CFrame = model.PrimaryPart.CFrame * CFrame.new(1.4, 0.6, 0) * CFrame.Angles(0, 0, math.rad(35))
		bat.Parent = model
	elseif kind == "ring" then
		local ring = part("Ring", Vector3.new(4.4, 0.25, 4.4), Color3.fromRGB(255, 210, 60), Enum.PartType.Cylinder)
		ring.CFrame = model.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(12))
		ring.Parent = model
	elseif kind == "fin" then
		local fin = part("Fin", Vector3.new(0.3, 1.4, 1.6), Color3.fromRGB(30, 90, 200))
		fin.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-25), 0, 0)
		fin.Parent = model
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = part("Wing", Vector3.new(0.25, 1.4, 1.8), Color3.fromRGB(240, 240, 240))
			wing.CFrame = model.PrimaryPart.CFrame * CFrame.new(side * 1.3, 0.9, -0.3) * CFrame.Angles(0, side * math.rad(25), 0)
			wing.Parent = model
		end
	elseif kind == "crown" then
		local crown = part("Crown", Vector3.new(1.4, 0.5, 1.4), Color3.fromRGB(255, 215, 0))
		crown.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, 2.4, 0)
		crown.Parent = model
	elseif kind == "hat" then
		local hat = part("Hat", Vector3.new(1.8, 0.4, 1.8), Color3.fromRGB(255, 120, 180))
		hat.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, 2.3, 0)
		hat.Parent = model
	elseif kind == "banana" then
		local banana = part("Banana", Vector3.new(0.4, 1.6, 0.4), Color3.fromRGB(255, 235, 80), Enum.PartType.Cylinder)
		banana.CFrame = model.PrimaryPart.CFrame * CFrame.new(-1.3, 0.4, 0) * CFrame.Angles(0, 0, math.rad(50))
		banana.Parent = model
	elseif kind == "beak" then
		local beak = part("Beak", Vector3.new(0.5, 0.4, 0.8), Color3.fromRGB(255, 170, 40))
		beak.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, 1.5, 1.0)
		beak.Parent = model
	elseif kind == "steam" then
		for i = 1, 3 do
			local puff = part("Steam", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(240, 240, 240), Enum.PartType.Ball)
			puff.Transparency = 0.4
			puff.CFrame = model.PrimaryPart.CFrame * CFrame.new((i - 2) * 0.5, 2.6 + i * 0.3, 0)
			puff.Parent = model
		end
	elseif kind == "horns" then
		for _, side in ipairs({ -1, 1 }) do
			local horn = part("Horn", Vector3.new(0.3, 0.9, 0.3), Color3.fromRGB(240, 230, 200), Enum.PartType.Cylinder)
			horn.CFrame = model.PrimaryPart.CFrame * CFrame.new(side * 0.6, 2.5, 0) * CFrame.Angles(0, 0, side * math.rad(-20))
			horn.Parent = model
		end
	elseif kind == "katana" then
		local blade = part("Katana", Vector3.new(0.2, 2.4, 0.2), Color3.fromRGB(200, 210, 220))
		blade.CFrame = model.PrimaryPart.CFrame * CFrame.new(1.4, 0.6, 0.4) * CFrame.Angles(math.rad(20), 0, math.rad(-30))
		blade.Parent = model
	elseif kind == "spikes" then
		for i = 1, 3 do
			local spike = part("Spike", Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(40, 140, 60))
			spike.CFrame = model.PrimaryPart.CFrame * CFrame.new((i - 2) * 0.7, 2.3, -0.6)
			spike.Parent = model
		end
	elseif kind == "tentacles" then
		for i = 1, 4 do
			local tentacle = part("Tentacle", Vector3.new(0.3, 1.2, 0.3), Color3.fromRGB(200, 130, 255), Enum.PartType.Cylinder)
			tentacle.CFrame = model.PrimaryPart.CFrame * CFrame.new((i - 2.5) * 0.45, -1.6, 0) * CFrame.Angles(0, 0, (i - 2.5) * math.rad(12))
			tentacle.Parent = model
		end
	elseif kind == "tutu" then
		local tutu = part("Tutu", Vector3.new(2.6, 0.25, 2.6), Color3.fromRGB(255, 200, 220), Enum.PartType.Cylinder)
		tutu.CFrame = model.PrimaryPart.CFrame * CFrame.new(0, -0.6, 0)
		tutu.Parent = model
	end
end

-- Name + income tag floating above a brainrot.
local function addTag(model, def, mutation, rate)
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(140, 48)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 15
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = def.name
	nameLabel.Parent = tag

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.fromScale(0, 0.55)
	rateLabel.Size = UDim2.fromScale(1, 0.45)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.FredokaOne
	rateLabel.TextSize = 14
	rateLabel.TextStrokeTransparency = 0.2
	local prefix = mutation.name == "Normal" and "" or (mutation.name .. " ")
	rateLabel.Text = prefix .. Config.formatMoney(rate) .. "/s"
	rateLabel.TextColor3 = mutation.color
	rateLabel.Parent = tag
end

-- Build one brainrot character model at the given position.
-- Returns the Model; its PrimaryPart is the body.
function Factory.buildBrainrot(charKey, mutation, position)
	local def = Config.CHARACTERS[charKey]
	assert(def, "unknown brainrot: " .. tostring(charKey))

	local model = Instance.new("Model")
	model.Name = def.name

	local body = part("Body", Vector3.new(2, 2.2, 1.4), rgb(def.body))
	body.CFrame = CFrame.new(position)
	body.Parent = model
	model.PrimaryPart = body

	local head = part("Head", Vector3.new(1.6, 1.5, 1.3), rgb(def.head))
	head.CFrame = body.CFrame * CFrame.new(0, 1.8, 0)
	head.Parent = model

	-- Eyes: two black balls on the face.
	for _, side in ipairs({ -1, 1 }) do
		local eye = part("Eye", Vector3.new(0.35, 0.45, 0.2), Color3.fromRGB(20, 20, 20), Enum.PartType.Ball)
		eye.CFrame = head.CFrame * CFrame.new(side * 0.4, 0.15, 0.68)
		eye.Parent = model
	end

	-- Legs.
	for _, side in ipairs({ -1, 1 }) do
		local leg = part("Leg", Vector3.new(0.5, 0.9, 0.6), rgb(def.body))
		leg.CFrame = body.CFrame * CFrame.new(side * 0.5, -1.5, 0)
		leg.Parent = model
	end

	addAccessory(model, def.accessory, rgb(def.body))

	-- Mutated brainrots glow: a neon shell around the body.
	if mutation.name ~= "Normal" then
		local shell = part("Glow", Vector3.new(2.4, 2.6, 1.8), mutation.color)
		shell.Transparency = 0.75
		shell.Material = Enum.Material.Neon
		shell.CFrame = body.CFrame
		shell.Parent = model
	end

	addTag(model, def, mutation, Config.incomeRate(charKey, mutation))
	return model
end

-- Build one egg on the conveyor belt. tier is one entry of
-- Config.EGG_TIERS. The egg carries its tier in an attribute.
function Factory.buildEgg(tier, position)
	local model = Instance.new("Model")
	model.Name = tier.key .. " Egg"
	model:SetAttribute("Tier", tier.key)
	model:SetAttribute("Price", tier.price)

	local shell = part("Shell", Vector3.new(2.2, 2.8, 2.2), rgb(tier.color), Enum.PartType.Ball)
	shell.CFrame = CFrame.new(position)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Parent = model
	model.PrimaryPart = shell

	-- A flat disc around the middle so tiers read apart on the belt.
	local stripe = part("Stripe", Vector3.new(2.35, 0.35, 2.35), Color3.fromRGB(255, 255, 255), Enum.PartType.Cylinder)
	stripe.CFrame = shell.CFrame
	stripe.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(150, 44)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.fromScale(1, 0.55)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Font = Enum.Font.FredokaOne
	tierLabel.TextSize = 16
	tierLabel.TextStrokeTransparency = 0.2
	tierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	tierLabel.Text = tier.key .. " Egg"
	tierLabel.Parent = tag

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Position = UDim2.fromScale(0, 0.55)
	priceLabel.Size = UDim2.fromScale(1, 0.45)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.FredokaOne
	priceLabel.TextSize = 15
	priceLabel.TextStrokeTransparency = 0.2
	priceLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
	priceLabel.Text = Config.formatMoney(tier.price)
	priceLabel.Parent = tag

	return model
end

return Factory
