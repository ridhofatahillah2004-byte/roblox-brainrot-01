-- Brainrot Egg Rush — client HUD: cash and income, base slots, egg tiers,
-- rebirth, tsunami warnings and notifications. The 3D game itself is
-- the world; this is the interface over it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function label(parent, name, text, size, position, textSize, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Fredoka
	l.TextSize = textSize
	l.TextStrokeTransparency = 0.15
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.Text = text
	l.Parent = parent
	return l
end

local function panel(parent, name, size, position)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = f
	f.Parent = parent
	return f
end

-- Top bar: cash, income, rebirths (top-center, clear of Roblox's
-- top-left menu buttons).
local topBar = panel(gui, "TopBar", UDim2.fromOffset(460, 54), UDim2.new(0.5, -230, 0, 10))
local cashLabel = label(topBar, "Cash", "$250", UDim2.fromOffset(180, 54), UDim2.new(0, 12, 0, 0), 26, Color3.fromRGB(255, 230, 80))
local incomeLabel = label(topBar, "Income", "+$0/s", UDim2.fromOffset(140, 54), UDim2.new(0, 200, 0, 0), 20, Color3.fromRGB(140, 255, 140))
local rebirthLabel = label(topBar, "Rebirths", "🌟 x0", UDim2.fromOffset(110, 54), UDim2.new(0, 344, 0, 0), 20, Color3.fromRGB(255, 215, 0))

-- Tsunami banner (top-center, under the top bar).
local waveBanner = panel(gui, "WaveBanner", UDim2.fromOffset(520, 46), UDim2.new(0.5, -260, 0, 74))
waveBanner.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
waveBanner.Visible = false
local waveLabel = label(waveBanner, "WaveText", "", UDim2.fromScale(1, 1), UDim2.new(0, 0, 0, 0), 22)
waveLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Egg tiers panel (right side): what each egg costs and what it can hatch.
local shopPanel = panel(gui, "EggShop", UDim2.fromOffset(210, 210), UDim2.new(1, -222, 0, 84))
label(shopPanel, "Title", "🥚 EGG CONVEYOR", UDim2.fromOffset(210, 28), UDim2.new(0, 0, 0, 6), 18, Color3.fromRGB(255, 230, 80))
local shopY = 36
for _, tier in ipairs(Config.EGG_TIERS) do
	local row = label(shopPanel, tier.key, tier.key .. " — " .. Config.formatMoney(tier.price), UDim2.fromOffset(210, 30), UDim2.new(0, 10, 0, shopY), 16)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = Color3.fromRGB(tier.color[1], tier.color[2], tier.color[3])
	shopY += 30
end
label(shopPanel, "Hint", "Walk to the belt and hold E on an egg to buy it!", UDim2.fromOffset(190, 30), UDim2.new(0, 10, 0, shopY + 4), 13, Color3.fromRGB(200, 200, 220))

-- Base panel (bottom-left): slots and the buy-slot button.
local basePanel = panel(gui, "BasePanel", UDim2.fromOffset(240, 96), UDim2.new(0, 12, 1, -108))
label(basePanel, "Title", "🏠 YOUR BASE", UDim2.fromOffset(240, 26), UDim2.new(0, 0, 0, 6), 18, Color3.fromRGB(140, 220, 255))
local baseLabel = label(basePanel, "Slots", "0 / 6 brainrots", UDim2.fromOffset(220, 26), UDim2.new(0, 10, 0, 32), 16)
baseLabel.TextXAlignment = Enum.TextXAlignment.Left
local slotButton = Instance.new("TextButton")
slotButton.Name = "BuySlot"
slotButton.Size = UDim2.fromOffset(216, 32)
slotButton.Position = UDim2.new(0, 12, 0, 60)
slotButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
slotButton.Font = Enum.Font.Fredoka
slotButton.TextSize = 16
slotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
slotButton.Text = "Buy Slot"
slotButton.Parent = basePanel
local slotCorner = Instance.new("UICorner")
slotCorner.CornerRadius = UDim.new(0, 8)
slotCorner.Parent = slotButton

-- Rebirth button (bottom-right): two clicks to confirm.
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "Rebirth"
rebirthButton.Size = UDim2.fromOffset(220, 48)
rebirthButton.Position = UDim2.new(1, -232, 1, -60)
rebirthButton.BackgroundColor3 = Color3.fromRGB(200, 160, 40)
rebirthButton.Font = Enum.Font.Fredoka
rebirthButton.TextSize = 18
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.Text = "🌟 Rebirth"
rebirthButton.Parent = gui
local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 10)
rebirthCorner.Parent = rebirthButton

-- Notifications (center, fading toasts).
local notifyLabel = label(gui, "Notify", "", UDim2.fromOffset(560, 40), UDim2.new(0.5, -280, 0, 140), 20)
notifyLabel.TextXAlignment = Enum.TextXAlignment.Center
notifyLabel.TextTransparency = 1

-- Help (top-right "?").
local helpButton = Instance.new("TextButton")
helpButton.Name = "Help"
helpButton.Size = UDim2.fromOffset(44, 44)
helpButton.Position = UDim2.new(1, -56, 0, 10)
helpButton.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
helpButton.BackgroundTransparency = 0.25
helpButton.Font = Enum.Font.Fredoka
helpButton.TextSize = 24
helpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
helpButton.Text = "?"
helpButton.Parent = gui
local helpCorner = Instance.new("UICorner")
helpCorner.CornerRadius = UDim.new(0, 10)
helpCorner.Parent = helpButton

local helpFrame = panel(gui, "Help", UDim2.fromOffset(360, 300), UDim2.new(0.5, -180, 0.5, -150))
helpFrame.Visible = false
label(helpFrame, "Title", "HOW TO PLAY", UDim2.fromOffset(360, 30), UDim2.new(0, 0, 0, 8), 22, Color3.fromRGB(255, 230, 80))
local helpText = label(helpFrame, "Body", "1. Buy an egg on the conveyor (hold E).\n"
	.. "2. It hatches in 6 seconds into a brainrot.\n"
	.. "3. Walk it home: it claims a free slot on your base and earns coins every second.\n"
	.. "4. Buy better eggs, unlock more slots, chase Golden / Diamond / Rainbow mutations.\n"
	.. "5. Steal rivals' brainrots (hold E on them) — but watch out: they can slap you!\n"
	.. "6. When the tsunami warning sounds, RUN to your base or be swept away.\n"
	.. "7. Rebirth at $1M for a permanent +25% income, then climb again!",
	UDim2.fromOffset(336, 240), UDim2.new(0, 12, 0, 44), 15, Color3.fromRGB(230, 230, 240))
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
helpText.TextWrapped = true

helpButton.MouseButton1Click:Connect(function()
	helpFrame.Visible = not helpFrame.Visible
end)

-- State -------------------------------------------------------------------
local rebirthArmed = false
local rebirthCost = Config.REBIRTH_BASE

remotes.StateUpdate.OnClientEvent:Connect(function(state)
	cashLabel.Text = Config.formatMoney(state.cash)
	incomeLabel.Text = "+" .. Config.formatMoney(state.incomePerSecond) .. "/s"
	rebirthLabel.Text = "🌟 x" .. state.rebirths
	baseLabel.Text = state.slotsUsed .. " / " .. state.slotsTotal .. " brainrots"
	rebirthCost = state.rebirthCost
	if state.carrying then
		rebirthButton.Text = "🥚 Carrying an egg…"
	elseif rebirthArmed then
		rebirthButton.Text = "Sure? Rebirth for " .. Config.formatMoney(rebirthCost)
	elseif state.cash >= rebirthCost then
		rebirthButton.Text = "🌟 Rebirth — " .. Config.formatMoney(rebirthCost)
	else
		rebirthButton.Text = "🌟 Rebirth — " .. Config.formatMoney(rebirthCost)
	end
	local nextSlot = state.slotsTotal + 1
	local slotCost = Config.SLOT_COSTS and Config.SLOT_COSTS[nextSlot]
	if slotCost then
		slotButton.Text = "Buy Slot " .. nextSlot .. " — " .. Config.formatMoney(slotCost)
	else
		slotButton.Text = "Max slots reached"
	end
end)

local notifySerial = 0
remotes.Notify.OnClientEvent:Connect(function(data)
	notifySerial += 1
	local serial = notifySerial
	notifyLabel.Text = data.text
	notifyLabel.TextColor3 = data.color or Color3.fromRGB(255, 255, 255)
	notifyLabel.TextTransparency = 0
	task.delay(4, function()
		if serial == notifySerial then
			notifyLabel.TextTransparency = 1
		end
	end)
end)

remotes.WaveWarning.OnClientEvent:Connect(function(data)
	if data.phase == "warning" then
		waveBanner.Visible = true
		waveLabel.Text = "🌊 TSUNAMI IN " .. data.secondsLeft .. "s — RUN TO YOUR BASE!"
	elseif data.phase == "sweep" then
		waveBanner.Visible = true
		waveLabel.Text = "🌊 TSUNAMI! STAY ON YOUR BASE!"
	elseif data.phase == "done" then
		waveBanner.Visible = false
	elseif data.phase == "countdown" then
		waveBanner.Visible = false
	end
end)

slotButton.MouseButton1Click:Connect(function()
	remotes.BuySlot:FireServer()
end)

rebirthButton.MouseButton1Click:Connect(function()
	if not rebirthArmed then
		rebirthArmed = true
		rebirthButton.Text = "Sure? Rebirth for " .. Config.formatMoney(rebirthCost)
		task.delay(5, function()
			rebirthArmed = false
		end)
	else
		rebirthArmed = false
		remotes.Rebirth:FireServer()
	end
end)

gui.Parent = player:WaitForChild("PlayerGui")
remotes.RequestState:FireServer()
