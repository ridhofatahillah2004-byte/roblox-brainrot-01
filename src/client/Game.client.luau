-- Brainrot Egg Rush client: the HUD (cash, income, base, rebirth, prompts),
-- the E key to buy eggs and steal brainrots, and the slap tool.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local interactHold = Remotes:WaitForChild("InteractHold")
local slapEvent = Remotes:WaitForChild("SlapEvent")
local buySlot = Remotes:WaitForChild("BuySlot")
local sellCarried = Remotes:WaitForChild("SellCarried")
local rebirthEvent = Remotes:WaitForChild("RebirthEvent")
local stateSync = Remotes:WaitForChild("StateSync")
local notifyEvent = Remotes:WaitForChild("Notify")

-- My numbers, kept up to date by StateSync.
local state = { cash = 0, income = 0, rebirths = 0, unlockedSlots = 2, baseId = 0 }
local currentTarget = nil
local holding = false
local holdStart = 0
local lastHoldSent = 0
local slapConnected = {}

-- ---------- HUD ----------

local gui = Instance.new("ScreenGui")
gui.Name = "GameGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function makeLabel(parent, name, position, size, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.35
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, size, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(40, 120, 220)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.Parent = parent
	return button
end

local topLeft = Instance.new("Frame")
topLeft.Name = "TopLeft"
topLeft.Position = UDim2.new(0, 12, 0, 12)
topLeft.Size = UDim2.fromOffset(300, 96)
topLeft.BackgroundTransparency = 1
topLeft.Parent = gui

local cashLabel = makeLabel(topLeft, "Cash", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 22)
local incomeLabel = makeLabel(topLeft, "Income", UDim2.new(0, 0, 0, 32), UDim2.new(1, 0, 0, 30), 18)
local baseLabel = makeLabel(topLeft, "Base", UDim2.new(0, 0, 0, 64), UDim2.new(1, 0, 0, 30), 18)

local rebirthButton = makeButton(gui, "Rebirth", UDim2.new(1, -220, 0, 12), UDim2.fromOffset(208, 40), "Rebirth - $1,000,000 (x5)")
local rebirthLabel = makeLabel(gui, "RebirthLevel", UDim2.new(1, -220, 0, 56), UDim2.fromOffset(208, 26), 16)
rebirthLabel.Text = "Rebirths: 0"

local promptLabel = makeLabel(gui, "Prompt", UDim2.new(0.5, -250, 1, -110), UDim2.fromOffset(500, 34), 20)
promptLabel.TextXAlignment = Enum.TextXAlignment.Center
promptLabel.BackgroundTransparency = 0.35

local progressBack = Instance.new("Frame")
progressBack.Name = "ProgressBack"
progressBack.Position = UDim2.new(0.5, -150, 1, -72)
progressBack.Size = UDim2.fromOffset(300, 12)
progressBack.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
progressBack.BackgroundTransparency = 0.3
progressBack.Visible = false
progressBack.Parent = gui

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(90, 200, 90)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBack

local sellButton = makeButton(gui, "Sell", UDim2.new(1, -220, 1, -120), UDim2.fromOffset(208, 40), "Sell carried")
sellButton.Visible = false

local slotButton = makeButton(gui, "UnlockSlot", UDim2.new(1, -220, 1, -168), UDim2.fromOffset(208, 40), "Unlock slot")
slotButton.Visible = false

local banner = makeLabel(gui, "Banner", UDim2.new(0.5, -350, 0, 90), UDim2.fromOffset(700, 44), 24)
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.Visible = false

local helpLabel = makeLabel(gui, "Help", UDim2.new(0, 12, 1, -40), UDim2.fromOffset(520, 28), 15)
helpLabel.Text = "E: buy egg / steal brainrot - Click with the Slap tool to stop a thief"

gui.Parent = player:WaitForChild("PlayerGui")

-- ---------- State ----------

local function refreshLabels()
	cashLabel.Text = "Cash: $" .. tostring(state.cash)
	incomeLabel.Text = "Income: $" .. tostring(state.income) .. "/s"
	if state.baseId > 0 then
		baseLabel.Text = "Base #" .. tostring(state.baseId) .. " - " .. tostring(state.unlockedSlots) .. "/10 slots"
	else
		baseLabel.Text = "Waiting for a base..."
	end
	rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths) .. " (income x" .. tostring(BrainrotConfig.rebirthMultiplier(state.rebirths)) .. ")"
	if state.unlockedSlots < BrainrotConfig.Base.SlotCount then
		local nextSlot = state.unlockedSlots + 1
		local cost = BrainrotConfig.slotCost(nextSlot)
		slotButton.Text = "Unlock slot " .. tostring(nextSlot) .. " - $" .. tostring(cost)
		slotButton.Visible = true
	else
		slotButton.Visible = false
	end
end

stateSync.OnClientEvent:Connect(function(data)
	state.cash = data.cash or state.cash
	state.income = data.income or state.income
	state.rebirths = data.rebirths or state.rebirths
	state.unlockedSlots = data.unlockedSlots or state.unlockedSlots
	state.baseId = data.baseId or state.baseId
	refreshLabels()
end)

local bannerUntil = 0
notifyEvent.OnClientEvent:Connect(function(data)
	banner.Text = data.message or ""
	if data.kind == "warn" then
		banner.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
	elseif data.kind == "good" then
		banner.BackgroundColor3 = Color3.fromRGB(30, 120, 50)
	else
		banner.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	end
	banner.Visible = true
	bannerUntil = os.clock() + 5
end)

rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

slotButton.MouseButton1Click:Connect(function()
	buySlot:FireServer()
end)

sellButton.MouseButton1Click:Connect(function()
	sellCarried:FireServer()
end)

-- ---------- Slap tool ----------

local function watchSlapTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Slap" or slapConnected[tool] then
		return
	end
	slapConnected[tool] = true
	tool.Activated:Connect(function()
		slapEvent:FireServer()
	end)
end

local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(watchSlapTool)
for _, tool in ipairs(backpack:GetChildren()) do
	watchSlapTool(tool)
end
player.CharacterAdded:Connect(function(character)
	character.ChildAdded:Connect(watchSlapTool)
	for _, tool in ipairs(character:GetChildren()) do
		watchSlapTool(tool)
	end
end)

-- ---------- Interacting ----------

local function characterRoot()
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function nearestEgg(root)
	local folder = Workspace:FindFirstChild("Eggs")
	if not folder then
		return nil
	end
	local best = nil
	local bestDistance = BrainrotConfig.Tuning.InteractRange
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart then
			local distance = (root.Position - model.PrimaryPart.Position).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				best = model
			end
		end
	end
	if not best then
		return nil
	end
	return { kind = "Egg", uid = best:GetAttribute("Uid"), tier = best:GetAttribute("Tier"), price = best:GetAttribute("Price") }
end

local function nearestStealable(root)
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		return nil
	end
	local best = nil
	local bestDistance = BrainrotConfig.Tuning.InteractRange
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model")
			and model.PrimaryPart
			and model:GetAttribute("State") == "Slotted"
			and model:GetAttribute("OwnerUserId") ~= player.UserId
		then
			local distance = (root.Position - model.PrimaryPart.Position).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				best = model
			end
		end
	end
	if not best then
		return nil
	end
	return { kind = "Brainrot", uid = best:GetAttribute("Uid"), name = best.Name }
end

local function carriedBrainrot()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		return nil
	end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model")
			and model:GetAttribute("State") == "Following"
			and model:GetAttribute("OwnerUserId") == player.UserId
		then
			return model
		end
	end
	return nil
end

local function scanTargets()
	local root = characterRoot()
	if not root then
		currentTarget = nil
		promptLabel.Text = ""
		return
	end
	currentTarget = nearestEgg(root) or nearestStealable(root)
	if currentTarget then
		if currentTarget.kind == "Egg" then
			promptLabel.Text = "Hold E to buy " .. tostring(currentTarget.tier) .. " Egg - $" .. tostring(currentTarget.price)
		else
			promptLabel.Text = "Hold E to steal " .. tostring(currentTarget.name) .. "!"
		end
	else
		promptLabel.Text = ""
	end
	local carried = carriedBrainrot()
	if carried then
		local price = carried:GetAttribute("EggPrice") or carried:GetAttribute("Price") or 0
		local value = math.floor(price * BrainrotConfig.Tuning.SellShare)
		sellButton.Text = "Sell " .. carried.Name .. " ($" .. tostring(value) .. ")"
		sellButton.Visible = true
	else
		sellButton.Visible = false
	end
end

local function holdSeconds()
	if not currentTarget then
		return 0
	end
	if currentTarget.kind == "Egg" then
		return BrainrotConfig.Tuning.BuyHoldSeconds
	end
	return BrainrotConfig.Tuning.StealHoldSeconds
end

local function onInteract(_actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		holding = true
		holdStart = os.clock()
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		holding = false
		holdStart = 0
		progressBack.Visible = false
	end
end

ContextActionService:BindAction("BrainrotInteract", onInteract, false, Enum.KeyCode.E)

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if banner.Visible and now > bannerUntil then
		banner.Visible = false
	end
	scanTargets()
	if holding and currentTarget then
		local needed = holdSeconds()
		local held = now - holdStart
		progressBack.Visible = true
		progressFill.Size = UDim2.new(math.clamp(held / needed, 0, 1), 0, 1, 0)
		if now - lastHoldSent >= 0.25 then
			lastHoldSent = now
			interactHold:FireServer(currentTarget.kind, currentTarget.uid)
		end
		if held >= needed then
			-- The server completes the action; reset so the bar starts over.
			holdStart = now
		end
	else
		progressBack.Visible = false
	end
end)

refreshLabels()
