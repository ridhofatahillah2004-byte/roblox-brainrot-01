-- Brainrot Egg Rush — the tsunami wave: every few minutes a warning
-- sounds and a wall of water sweeps the map. Anyone caught outside
-- their own base is flung back and drops whatever egg they carry.
-- The threat that forces the dash home with the catch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.BrainrotConfig)
local GameState = require(script.Parent.GameState)
local BaseService = require(script.Parent.BaseService)
local EggService = require(script.Parent.EggService)

local WaveService = {}

local MAP_HALF = 150 -- the wall travels from -MAP_HALF to +MAP_HALF on Z
local wall = nil

local function fireWarning(phase, secondsLeft)
	GameState.Remotes.WaveWarning:FireAllClients({ phase = phase, secondsLeft = secondsLeft })
end

local function buildWall()
	local part = Instance.new("Part")
	part.Name = "TsunamiWall"
	part.Size = Vector3.new(420, 46, 4)
	part.Color = Color3.fromRGB(60, 140, 255)
	part.Transparency = 0.35
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(0, 20, -MAP_HALF)
	part.Parent = Workspace
	return part
end

-- Fling everyone the wall is about to catch who is not safe at home.
local function sweepStep()
	for _, player in ipairs(Players:GetPlayers()) do
		if not BaseService.isOnBase(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				-- Only fling players the wall has actually reached.
				if math.abs(root.Position.Z - wall.Position.Z) < 12 then
					root.AssemblyLinearVelocity = Vector3.new(0, 55, 90)
					EggService.dropEgg(player)
					GameState.Remotes.Notify:FireClient(player, { text = "🌊 The tsunami got you! Get back to your base!", color = Color3.fromRGB(120, 180, 255) })
				end
			end
		end
	end
end

local function runWave()
	GameState.WaveActive = true
	wall = buildWall()
	fireWarning("sweep", 0)
	local start = os.clock()
	local sweepConn
	sweepConn = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - start) / Config.WAVE_SWEEP_TIME
		if t >= 1 then
			sweepConn:Disconnect()
			if wall then
				wall:Destroy()
				wall = nil
			end
			GameState.WaveActive = false
			GameState.NextWaveIn = Config.WAVE_INTERVAL
			fireWarning("done", 0)
			return
		end
		local z = -MAP_HALF + t * (MAP_HALF * 2)
		wall.CFrame = CFrame.new(0, 20, z)
		sweepStep()
	end)
end

function WaveService.triggerNow()
	if GameState.WaveActive then
		return
	end
	GameState.NextWaveIn = 0
end

function WaveService.init()
	GameState.NextWaveIn = Config.WAVE_INTERVAL
	task.spawn(function()
		while true do
			task.wait(1)
			if GameState.WaveActive then
				continue
			end
			GameState.NextWaveIn -= 1
			if GameState.NextWaveIn <= 0 then
				-- Warning phase: 10 seconds to run home.
				for i = Config.WAVE_WARNING, 1, -1 do
					fireWarning("warning", i)
					-- Flash the beacon red while the warning sounds.
					local beacon = Workspace:FindFirstChild("Beacon")
					local light = beacon and beacon:FindFirstChild("BeaconLight")
					if light then
						light.Color = Color3.fromRGB(255, 40, 40)
						light.Material = Enum.Material.Neon
					end
					task.wait(1)
				end
				local beacon = Workspace:FindFirstChild("Beacon")
				local light = beacon and beacon:FindFirstChild("BeaconLight")
				if light then
					light.Color = Color3.fromRGB(255, 220, 60)
					light.Material = Enum.Material.SmoothPlastic
				end
				runWave()
			elseif GameState.NextWaveIn % 10 == 0 or GameState.NextWaveIn <= 5 then
				fireWarning("countdown", GameState.NextWaveIn)
			end
		end
	end)
end

return WaveService
