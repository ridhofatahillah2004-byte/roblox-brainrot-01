-- GameState: the shared spine of the game. It creates the RemoteEvents,
-- finds the world the project file built, hands base plots to players as
-- they join, and pays out income every second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local GameState = {}

local ctx = nil
local world = {}
local baseOwner = {}
local waiting = {}

-- Find the static world parts the Rojo project built. The Eggs and
-- Brainrots folders are created at runtime by EggService, so they are
-- looked up (and made) on demand instead of waited for here.
local function findWorld()
	world.Ground = Workspace:WaitForChild("Ground")
	world.Conveyor = Workspace:WaitForChild("Conveyor")
	world.Bases = Workspace:WaitForChild("Bases")
	world.SpawnLocation = Workspace:WaitForChild("SpawnLocation")
end

-- The folder eggs live in while they ride the conveyor.
function GameState.getEggFolder()
	local folder = Workspace:FindFirstChild("Eggs")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Eggs"
		folder.Parent = Workspace
	end
	return folder
end

-- The folder every brainrot model lives in (following or slotted).
function GameState.getBrainrotFolder()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = Workspace
	end
	return folder
end

local function makeRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	-- Client -> server.
	for _, name in ipairs({ "InteractHold", "SlapEvent", "BuySlot", "SellCarried", "RebirthEvent" }) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	-- Server -> client.
	for _, name in ipairs({ "StateSync", "Notify" }) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
	ctx.Remotes = folder
end

-- Send a banner message to one player. kind is "info", "good" or "warn".
function GameState.notify(player, message, kind)
	if not ctx or not ctx.Remotes then
		return
	end
	local remote = ctx.Remotes:FindFirstChild("Notify")
	if remote then
		remote:FireClient(player, { message = message, kind = kind or "info" })
	end
end

function GameState.notifyAll(message, kind)
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.notify(player, message, kind)
	end
end

function GameState.getWorld()
	return world
end

function GameState.getBaseModel(baseId)
	if not world.Bases then
		return nil
	end
	return world.Bases:FindFirstChild("Base" .. tostring(baseId))
end

function GameState.getBasePad(baseId)
	local base = GameState.getBaseModel(baseId)
	if not base then
		return nil
	end
	return base:FindFirstChild("Pad")
end

-- The anchor part a slotted brainrot stands on (1-based slot index).
function GameState.getSlotAnchor(baseId, slotIndex)
	local base = GameState.getBaseModel(baseId)
	if not base then
		return nil
	end
	return base:FindFirstChild("Slot" .. tostring(slotIndex))
end

function GameState.getBaseOwner(baseId)
	return baseOwner[baseId]
end

-- Is the player's character standing on their own base pad?
function GameState.isOnOwnBase(player)
	local record = ctx.PlayerData.get(player)
	if not record or record.BaseId == 0 then
		return false
	end
	local pad = GameState.getBasePad(record.BaseId)
	local character = player.Character
	if not pad or not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local padPos = pad.Position
	local half = pad.Size / 2
	return math.abs(root.Position.X - padPos.X) <= half.X
		and math.abs(root.Position.Z - padPos.Z) <= half.Z
		and root.Position.Y > padPos.Y - 2
		and root.Position.Y < padPos.Y + 10
end

local function assignBase(player)
	for baseId = 1, BrainrotConfig.Base.PlotCount do
		if baseOwner[baseId] == nil then
			baseOwner[baseId] = player
			ctx.PlayerData.setBaseId(player, baseId)
			GameState.notify(player, "Your base is #" .. tostring(baseId) .. "! Bring your brainrots home.", "good")
			return baseId
		end
	end
	table.insert(waiting, player)
	GameState.notify(player, "All bases are taken. You will get one when a player leaves.", "warn")
	return 0
end

local function freeBase(player)
	for baseId, owner in pairs(baseOwner) do
		if owner == player then
			baseOwner[baseId] = nil
			-- Hand the freed plot to the longest-waiting player.
			if #waiting > 0 then
				local nextPlayer = table.remove(waiting, 1)
				if nextPlayer and nextPlayer.Parent then
					baseOwner[baseId] = nextPlayer
					ctx.PlayerData.setBaseId(nextPlayer, baseId)
					GameState.notify(nextPlayer, "A base freed up! Your base is #" .. tostring(baseId) .. ".", "good")
				end
			end
			return
		end
	end
	for i, waiter in ipairs(waiting) do
		if waiter == player then
			table.remove(waiting, i)
			return
		end
	end
end

local function onPlayerAdded(player)
	-- PlayerData loads the record first; wait a beat so it exists.
	task.spawn(function()
		local tries = 0
		while not ctx.PlayerData.get(player) and tries < 50 do
			task.wait(0.1)
			tries += 1
		end
		if not ctx.PlayerData.get(player) then
			return
		end
		assignBase(player)
		if ctx.StealService then
			ctx.StealService.giveSlapTool(player)
		end
		GameState.notify(player, "Welcome to Brainrot Egg Rush! Buy an egg from the conveyor with E.", "info")
	end)
end

local function onPlayerRemoving(player)
	freeBase(player)
	if ctx.EggService then
		ctx.EggService.cleanupPlayer(player)
	end
end

-- The income loop: every tick, each player's slotted brainrots pay out.
local function startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(BrainrotConfig.Tuning.IncomeTickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local income = ctx.BaseService.getIncome(player)
				if income > 0 then
					ctx.PlayerData.addCash(player, income)
				end
				ctx.PlayerData.setIncome(player, income)
				ctx.PlayerData.sync(player)
			end
		end
	end)
end

function GameState.init(context)
	ctx = context
	makeRemotes()
	findWorld()
end

function GameState.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	startIncomeLoop()
end

return GameState
