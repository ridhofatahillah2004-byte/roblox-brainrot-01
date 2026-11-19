-- WaveService: the tsunami. Every few minutes a warning goes out, then a
-- giant wave sweeps the map from west to east. Players caught outside
-- their own base are thrown back and drop what they were carrying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotConfig = require(Shared:WaitForChild("BrainrotConfig"))

local WaveService = {}

local ctx = nil
local waveActive = false
local waveRequested = false

local WALL_SPEED = 40
local WALL_START_X = -150
local WALL_END_X = 150
local HIT_BAND = 7

-- Throw a player back and make them drop what they carry.
local function hitPlayer(player, wallX)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local direction = 1
	if root.Position.X > wallX then
		direction = 1
	else
		direction = -1
	end
	root.AssemblyLinearVelocity = Vector3.new(30 * direction, 25, 0)
	ctx.EggService.dropCarried(player)
	ctx.GameState.notify(player, "The tsunami swept you away! You dropped what you were carrying.", "warn")
end

local function runWave()
	if waveActive then
		return
	end
	waveActive = true

	local wall = Instance.new("Part")
	wall.Name = "TsunamiWave"
	wall.Size = Vector3.new(6, 45, 300)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Transparency = 0.4
	wall.Material = Enum.Material.Glass
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(WALL_START_X, 12, 0)
	wall.Parent = Workspace

	local hit = {}
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not wall.Parent then
			connection:Disconnect()
			return
		end
		local x = wall.Position.X + WALL_SPEED * dt
		wall.CFrame = CFrame.new(x, 12, 0)
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) <= HIT_BAND then
					if not ctx.GameState.isOnOwnBase(player) then
						hit[player] = true
						hitPlayer(player, x)
					end
				end
			end
		end
		if x >= WALL_END_X then
			connection:Disconnect()
			wall:Destroy()
			waveActive = false
			ctx.GameState.notifyAll("The tsunami passed. Back to the conveyor!", "info")
		end
	end)
end

-- Start a wave right now (the Debug module calls this from a tour step).
function WaveService.triggerNow()
	if waveActive then
		return
	end
	waveRequested = true
end

local function startLoop()
	task.spawn(function()
		while true do
			local waited = 0
			local interval = BrainrotConfig.Tuning.WaveInterval
			while waited < interval and not waveRequested do
				task.wait(1)
				waited += 1
			end
			waveRequested = false
			ctx.GameState.notifyAll("TSUNAMI INCOMING! Get to your base in " .. tostring(BrainrotConfig.Tuning.WaveWarningSeconds) .. " seconds!", "warn")
			task.wait(BrainrotConfig.Tuning.WaveWarningSeconds)
			runWave()
			-- Wait until the wave finishes before counting the next interval.
			while waveActive do
				task.wait(0.5)
			end
		end
	end)
end

function WaveService.init(context)
	ctx = context
	startLoop()
end

return WaveService
