--[[
	@file SimulationServer.server.lua
	@desc Server-side bridge between SimulationCore and real Roblox NPCs.
	      Each agent gets a Humanoid rig driven by PathfindingService.
	      State changes affect WalkSpeed, billboard text, and a Highlight glow.
	      Path.Blocked triggers automatic path recomputation.
	      Humanoid.Died cleans up the agent cleanly.
]]

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local SimulationCore = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationCore"))
local SimObservers   = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationObserver"))
local SimCommands    = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationCommands"))

local simControlRE = ReplicatedStorage:WaitForChild("SimControlRE")
local simSpawnRE   = ReplicatedStorage:WaitForChild("SimSpawnRE")
local simStatsRE   = ReplicatedStorage:WaitForChild("SimStatsRE")

-- ── Zone detection ────────────────────────────────────────────────────────────

local zoneCenter = Vector3.new(0, 5, 0)
local zoneRadius = 40

local riotZonePart = workspace:FindFirstChild("RiotZone")
if riotZonePart then
	if riotZonePart:IsA("BasePart") then
		zoneCenter = riotZonePart.Position + Vector3.new(0, 5, 0)
		zoneRadius = math.min(riotZonePart.Size.X, riotZonePart.Size.Z) / 2 * 0.85
	elseif riotZonePart:IsA("Model") and riotZonePart.PrimaryPart then
		zoneCenter = riotZonePart.PrimaryPart.Position + Vector3.new(0, 5, 0)
	end
end

-- ── Pavement waypoints ────────────────────────────────────────────────────────
-- Collect the top-surface centre of every Pavement-material part so agents
-- walk along real sidewalks instead of random circular positions.

local pavementWaypoints = {}
for _, desc in ipairs(workspace:GetDescendants()) do
	if desc:IsA("BasePart") and desc.Material == Enum.Material.Pavement then
		local topY = desc.Position.Y + desc.Size.Y / 2 + 3
		pavementWaypoints[#pavementWaypoints + 1] =
			Vector3.new(desc.Position.X, topY, desc.Position.Z)
	end
end
if #pavementWaypoints > 0 then
	print(string.format("[SimServer] %d Pavement waypoints loaded", #pavementWaypoints))
end

-- ── Workspace folder ──────────────────────────────────────────────────────────

local npcFolder = workspace:FindFirstChild("SimNPCs") or Instance.new("Folder")
npcFolder.Name   = "SimNPCs"
npcFolder.Parent = workspace

-- ── Visual data tables ────────────────────────────────────────────────────────

-- State-specific billboard text
local LABELS = {
	Citizen = {
		Idle     = "Civilian",
		Moving   = "Wandering",
		Reacting = "!! PANIC !!",
		Conflict = "FIGHTING",
		Done     = "—",
	},
	Officer = {
		Idle     = "Officer",
		Moving   = "Patrolling",
		Acting   = ">> RESPONDING",
		Done     = "—",
	},
}

-- WalkSpeed per state
local SPEEDS = {
	Citizen = { Idle = 0, Moving = 11, Reacting = 20, Conflict = 0, Done = 0 },
	Officer = { Idle = 0, Moving = 14, Acting   = 22, Done = 0 },
}

-- ── R6-style NPC builder ──────────────────────────────────────────────────────
-- Parts are positioned in absolute world space, welds created while all parts
-- share the same parent (model, not yet in workspace), then model is parented
-- to workspace so physics activates after everything is locked together.

local SKIN_TONES = {
	Color3.fromRGB(255, 218, 185),
	Color3.fromRGB(210, 180, 140),
	Color3.fromRGB(160, 120,  90),
	Color3.fromRGB(100,  70,  50),
	Color3.fromRGB(240, 200, 160),
}

local SHIRT_COLORS = {
	Color3.fromRGB(220,  50,  50),
	Color3.fromRGB( 50, 120, 220),
	Color3.fromRGB( 50, 180,  80),
	Color3.fromRGB(230, 180,  30),
	Color3.fromRGB(150,  50, 200),
	Color3.fromRGB(240, 120,  20),
	Color3.fromRGB( 60, 180, 200),
}

local PANTS_COLORS = {
	Color3.fromRGB( 40,  40,  80),
	Color3.fromRGB( 60,  60,  60),
	Color3.fromRGB( 30,  60, 100),
	Color3.fromRGB( 80,  50,  30),
	Color3.fromRGB( 50,  50,  50),
}

local function weld(model, p0, p1)
	local w    = Instance.new("WeldConstraint")
	w.Part0    = p0
	w.Part1    = p1
	w.Parent   = model
end

local function buildNPC(agent)
	local isOfficer = agent.agentType == "Officer"
	local model     = Instance.new("Model")
	model.Name      = (isOfficer and "Officer" or "Citizen") .. "_" .. agent.id

	-- Appearance colours
	local skin   = isOfficer and Color3.fromRGB(210, 180, 140)
		or SKIN_TONES[math.random(#SKIN_TONES)]
	local shirt  = isOfficer and Color3.fromRGB( 30,  50, 140)
		or SHIRT_COLORS[math.random(#SHIRT_COLORS)]
	local pants  = isOfficer and Color3.fromRGB( 20,  30,  80)
		or PANTS_COLORS[math.random(#PANTS_COLORS)]

	-- Root: invisible physics anchor at foot level
	-- R6 convention: HumanoidRootPart centre is 3 studs above ground
	local spawnCF = CFrame.new(agent.position + Vector3.new(0, 3, 0))

	local root = Instance.new("Part")
	root.Name          = "HumanoidRootPart"
	root.Size          = Vector3.new(2, 2, 1)
	root.Transparency  = 1
	root.CanCollide    = false
	root.Anchored      = false
	root.CastShadow    = false
	root.CFrame        = spawnCF
	root.Parent        = model

	-- Torso
	local torso = Instance.new("Part")
	torso.Name       = "Torso"
	torso.Size       = Vector3.new(2, 2, 1)
	torso.Color      = shirt
	torso.Material   = Enum.Material.SmoothPlastic
	torso.CanCollide = true
	torso.CastShadow = false
	torso.CFrame     = spawnCF   -- same centre as root
	torso.Parent     = model

	-- Head
	local head = Instance.new("Part")
	head.Name       = "Head"
	head.Shape      = Enum.PartType.Block
	head.Size       = Vector3.new(2, 1, 1)
	head.Color      = skin
	head.Material   = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.CastShadow = false
	head.CFrame     = spawnCF * CFrame.new(0, 1.5, 0)   -- top of torso
	head.Parent     = model

	-- Left Arm
	local lArm = Instance.new("Part")
	lArm.Name       = "Left Arm"
	lArm.Size       = Vector3.new(1, 2, 1)
	lArm.Color      = skin
	lArm.Material   = Enum.Material.SmoothPlastic
	lArm.CanCollide = false
	lArm.CastShadow = false
	lArm.CFrame     = spawnCF * CFrame.new(-1.5, 0, 0)
	lArm.Parent     = model

	-- Right Arm
	local rArm = Instance.new("Part")
	rArm.Name       = "Right Arm"
	rArm.Size       = Vector3.new(1, 2, 1)
	rArm.Color      = skin
	rArm.Material   = Enum.Material.SmoothPlastic
	rArm.CanCollide = false
	rArm.CastShadow = false
	rArm.CFrame     = spawnCF * CFrame.new(1.5, 0, 0)
	rArm.Parent     = model

	-- Left Leg
	local lLeg = Instance.new("Part")
	lLeg.Name       = "Left Leg"
	lLeg.Size       = Vector3.new(1, 2, 1)
	lLeg.Color      = pants
	lLeg.Material   = Enum.Material.SmoothPlastic
	lLeg.CanCollide = false
	lLeg.CastShadow = false
	lLeg.CFrame     = spawnCF * CFrame.new(-0.5, -2, 0)
	lLeg.Parent     = model

	-- Right Leg
	local rLeg = Instance.new("Part")
	rLeg.Name       = "Right Leg"
	rLeg.Size       = Vector3.new(1, 2, 1)
	rLeg.Color      = pants
	rLeg.Material   = Enum.Material.SmoothPlastic
	rLeg.CanCollide = false
	rLeg.CastShadow = false
	rLeg.CFrame     = spawnCF * CFrame.new(0.5, -2, 0)
	rLeg.Parent     = model

	-- Weld all body parts to root BEFORE parenting to workspace
	weld(model, root, torso)
	weld(model, root, head)
	weld(model, root, lArm)
	weld(model, root, rArm)
	weld(model, root, lLeg)
	weld(model, root, rLeg)

	-- Officer hat
	if isOfficer then
		local hat = Instance.new("Part")
		hat.Name       = "Hat"
		hat.Shape      = Enum.PartType.Cylinder
		hat.Size       = Vector3.new(0.3, 2.1, 2.1)
		hat.Color      = Color3.fromRGB(20, 30, 80)
		hat.Material   = Enum.Material.SmoothPlastic
		hat.CanCollide = false
		hat.CastShadow = false
		hat.CFrame     = spawnCF * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
		hat.Parent     = model
		weld(model, root, hat)
	end

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed             = isOfficer and 14 or 11
	humanoid.JumpPower             = 0
	humanoid.HealthDisplayDistance = 0
	humanoid.NameDisplayDistance   = 0
	humanoid.Parent                = model

	model.PrimaryPart = root

	-- BillboardGui on the head
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 130, 0, 28)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = false
	bb.Adornee     = head
	bb.Parent      = model

	local tl = Instance.new("TextLabel")
	tl.Size                   = UDim2.new(1, 0, 1, 0)
	tl.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
	tl.BackgroundTransparency = 0.3
	tl.TextColor3             = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.5
	tl.Font                   = Enum.Font.GothamBold
	tl.TextSize               = 11
	tl.Text                   = isOfficer and "Officer" or "Civilian"
	tl.Parent                 = bb

	-- Highlight (off by default)
	local hl = Instance.new("Highlight")
	hl.Enabled             = false
	hl.DepthMode           = Enum.HighlightDepthMode.Occluded
	hl.FillTransparency    = 0.55
	hl.OutlineTransparency = 0
	hl.Parent              = model

	-- Parent to workspace last so physics activates after welds are set
	model.Parent = npcFolder

	return model, tl, hl
end

-- ── Visual updater (called each tick) ────────────────────────────────────────

local function updateVisuals(agent, view)
	local model = view.model
	if not model or not model.Parent then return end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local state    = agent.state
	local atype    = agent.agentType
	local isPanic    = state == "Reacting"
	local isAct      = state == "Acting"
	local isConflict = state == "Conflict"

	-- Billboard text + background tint
	local lbl = view.label
	if lbl then
		local textMap = LABELS[atype]
		lbl.Text = textMap and (textMap[state] or state) or state
		if isPanic or isConflict then
			lbl.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
			lbl.TextColor3       = Color3.fromRGB(255, 220, 80)
		elseif isAct then
			lbl.BackgroundColor3 = Color3.fromRGB(140, 85, 10)
			lbl.TextColor3       = Color3.new(1, 1, 1)
		else
			lbl.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			lbl.TextColor3       = Color3.new(1, 1, 1)
		end
	end

	-- WalkSpeed
	if humanoid and humanoid.Health > 0 then
		local speedMap = SPEEDS[atype]
		humanoid.WalkSpeed = speedMap and (speedMap[state] or 11) or 11
	end

	-- Highlight glow
	local hl = view.highlight
	if hl then
		if isConflict then
			hl.FillColor    = Color3.fromRGB(255, 200,   0)
			hl.OutlineColor = Color3.fromRGB(255, 100,   0)
			hl.Enabled      = true
		elseif isPanic then
			hl.FillColor    = Color3.fromRGB(220,  40,  40)
			hl.OutlineColor = Color3.fromRGB(255, 200,  50)
			hl.Enabled      = true
		elseif isAct then
			hl.FillColor    = Color3.fromRGB(255, 140,   0)
			hl.OutlineColor = Color3.fromRGB(255, 230,   0)
			hl.Enabled      = true
		else
			hl.Enabled = false
		end
	end
end

-- ── Pathfinding loop per NPC ──────────────────────────────────────────────────

local PATH_PARAMS = {
	AgentRadius  = 1.5,
	AgentHeight  = 5,
	AgentCanJump = false,
	Costs        = { Water = math.huge },
}

local function startPathLoop(agent, npcModel)
	task.spawn(function()
		local root     = npcModel.PrimaryPart
		local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end

		-- Clean up NPC on death
		humanoid.Died:Connect(function()
			agent:stop()
			task.delay(1.5, function()
				if npcModel.Parent then npcModel:Destroy() end
			end)
		end)

		while npcModel.Parent and agent:isAlive() do
			local target = agent._targetPosition

			if target and humanoid.Health > 0 then
				agent._targetPosition = nil

				local path    = PathfindingService:CreatePath(PATH_PARAMS)
				local requeue = false

				-- Re-queue when path gets dynamically blocked
				local blockedConn = path.Blocked:Connect(function()
					requeue = true
					humanoid:MoveTo(root.Position)   -- stop in place
				end)

				local ok = pcall(path.ComputeAsync, path, root.Position, target)

				if ok and path.Status == Enum.PathStatus.Success then
					for _, wp in ipairs(path:GetWaypoints()) do
						if requeue or agent._targetPosition then break end
						humanoid:MoveTo(wp.Position)
						humanoid.MoveToFinished:Wait(4)
						-- Update position after each waypoint so conflict detection is current
						if root.Parent then
							agent.position = root.Position
						end
					end
				else
					-- No path (open area / flat ground) — move directly
					humanoid:MoveTo(target)
					humanoid.MoveToFinished:Wait(8)
				end

				blockedConn:Disconnect()

				-- If the path was blocked mid-journey, let the agent retry next tick
				if requeue then
					agent._targetPosition = target
				end

				if root.Parent then
					agent.position = root.Position
				end

				-- Wander arrival → back to Idle
				if agent.state == "Moving" then
					agent:transitionTo("Idle")
				end
			end

			task.wait(0.08)
		end

		if npcModel.Parent then npcModel:Destroy() end
	end)
end

-- ── View registry ─────────────────────────────────────────────────────────────

local agentViews = {}

local function registerAgent(agent)
	local ok, model, label, highlight = pcall(buildNPC, agent)
	if not ok then
		warn("[SimServer] buildNPC failed for agent " .. tostring(agent.id) .. ": " .. tostring(model))
		return
	end
	local view = { model = model, label = label, highlight = highlight }
	agentViews[agent] = view
	startPathLoop(agent, model)
end

-- ── Core setup ────────────────────────────────────────────────────────────────

local core = SimulationCore.new({
	citizenCount = 10,
	officerCount = 4,
	tickInterval = 1.5,
	parallel     = true,
	zoneCenter   = zoneCenter,
	zoneRadius   = zoneRadius,
	waypoints    = #pavementWaypoints > 0 and pavementWaypoints or nil,
})

local invoker = SimCommands.SimCommandInvoker.new(core)

for _, agent in ipairs(core:getAgents()) do
	registerAgent(agent)
end

-- ── Tick observer ─────────────────────────────────────────────────────────────

local tickObs = SimObservers.UIObserver.new({
	onTick = function(stats)
		for agent, view in pairs(agentViews) do
			updateVisuals(agent, view)
		end
		simStatsRE:FireAllClients(stats)
	end,
	onRiotChanged = function(active)
		print(string.format("[SimServer] tick=%d riot=%s", core:getTickCount(), tostring(active)))
	end,
})
tickObs._name = "ServerTickObserver"
core:attach(tickObs)

-- ── onAgentAdded ─────────────────────────────────────────────────────────────

local addObs = SimObservers.ISimObserver.new("ServerAgentAdded")
addObs.onAgentAdded = function(_, agent)
	registerAgent(agent)
end
core:attach(addObs)

-- ── Remote handlers ───────────────────────────────────────────────────────────

simControlRE.OnServerEvent:Connect(function(_, action: string)
	if action == "start" then
		invoker:execute(SimCommands.StartCommand.new())

	elseif action == "pause" then
		invoker:execute(SimCommands.PauseCommand.new())

	elseif action == "reset" then
		for agent, view in pairs(agentViews) do
			if view.model and view.model.Parent then view.model:Destroy() end
			agentViews[agent] = nil
		end
		invoker:execute(SimCommands.ResetCommand.new())
		for _, agent in ipairs(core:getAgents()) do
			registerAgent(agent)
		end

	elseif action == "undo" then
		invoker:undo()

	elseif action == "fast" then
		invoker:execute(SimCommands.SetSpeedCommand.new(0.6))

	elseif action == "normal" then
		invoker:execute(SimCommands.SetSpeedCommand.new(1.5))
	end
end)

simSpawnRE.OnServerEvent:Connect(function(_, agentType: string)
	if agentType == "Citizen" then
		core:addCitizen()
	elseif agentType == "Officer" then
		core:addOfficer()
	end
end)

-- ── Start ─────────────────────────────────────────────────────────────────────

core:start()

_G.SimCore    = core
_G.SimInvoker = invoker
