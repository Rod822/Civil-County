--[[
	@file SimulationUI.client.luau
	@desc Client-side GUI for the Lab 3b multi-agent city simulation.
	      Opens with the Q key. Displays live agent stats, riot intensity,
	      and benchmark results. Buttons wire into SimulationCommands.
]]

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local SimulationCore     = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationCore"))
local SimObservers       = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationObserver"))
local SimCommands        = require(ReplicatedStorage:WaitForChild("Simulation"):WaitForChild("SimulationCommands"))
local Benchmark          = require(ReplicatedStorage:WaitForChild("Parallel"):WaitForChild("Benchmark"))
local SequentialSort     = require(ReplicatedStorage:WaitForChild("Parallel"):WaitForChild("SequentialSort"))
local ParallelSort       = require(ReplicatedStorage:WaitForChild("Parallel"):WaitForChild("ParallelSort"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Palette ───────────────────────────────────────────────────────────────────
local C = {
	bg       = Color3.fromRGB(18,  20,  26),
	panel    = Color3.fromRGB(28,  31,  42),
	header   = Color3.fromRGB(36,  40,  56),
	accent   = Color3.fromRGB(90, 160, 255),
	riot     = Color3.fromRGB(220,  70,  50),
	calm     = Color3.fromRGB(60,  200, 120),
	text     = Color3.fromRGB(220, 225, 240),
	muted    = Color3.fromRGB(130, 135, 155),
	btnGreen = Color3.fromRGB(50,  170,  90),
	btnRed   = Color3.fromRGB(200,  60,  60),
	btnBlue  = Color3.fromRGB(60,  120, 210),
	btnGray  = Color3.fromRGB(70,   75,  95),
}

local open = false
local core: any = nil
local invoker: any = nil
local bench = Benchmark.new()

-- ── UI helpers ────────────────────────────────────────────────────────────────
local function frame(parent, name, size, pos, color, zIndex)
	local f = Instance.new("Frame")
	f.Name            = name
	f.Size            = size
	f.Position        = pos
	f.BackgroundColor3 = color or C.panel
	f.BorderSizePixel = 0
	f.ZIndex          = zIndex or 1
	f.Parent          = parent
	return f
end

local function label(parent, text, size, pos, color, align, zIndex, fontSize)
	local l = Instance.new("TextLabel")
	l.Size              = size
	l.Position          = pos
	l.BackgroundTransparency = 1
	l.Text              = text
	l.TextColor3        = color or C.text
	l.TextXAlignment    = align or Enum.TextXAlignment.Left
	l.Font              = Enum.Font.GothamMedium
	l.TextSize          = fontSize or 13
	l.ZIndex            = zIndex or 2
	l.Parent            = parent
	return l
end

local function btn(parent, text, size, pos, color, zIndex)
	local b = Instance.new("TextButton")
	b.Size              = size
	b.Position          = pos
	b.BackgroundColor3  = color or C.btnBlue
	b.BorderSizePixel   = 0
	b.Text              = text
	b.TextColor3        = Color3.new(1, 1, 1)
	b.Font              = Enum.Font.GothamBold
	b.TextSize          = 12
	b.AutoButtonColor   = true
	b.ZIndex            = zIndex or 2
	b.Parent            = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = b
	return b
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
end

-- ── Build UI ──────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "SimulationUI"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Enabled         = false
screenGui.Parent          = playerGui

-- Root window
local win = frame(screenGui, "Window",
	UDim2.new(0, 520, 0, 560),
	UDim2.new(0.5, -260, 0.5, -280),
	C.bg, 1)
corner(win, 10)

-- Title bar
local titleBar = frame(win, "TitleBar", UDim2.new(1, 0, 0, 36), UDim2.new(0,0,0,0), C.header, 2)
corner(titleBar, 10)
-- cover bottom corners of title bar
frame(win, "TitleBarBottom", UDim2.new(1, 0, 0, 10), UDim2.new(0,0,0,26), C.header, 2)

label(titleBar, "City Simulation — Lab 3b",
	UDim2.new(1, -10, 1, 0), UDim2.new(0, 12, 0, 0),
	C.text, Enum.TextXAlignment.Left, 3, 14)

local closeBtn = btn(titleBar, "✕",
	UDim2.new(0, 28, 0, 24), UDim2.new(1, -34, 0, 6),
	C.btnRed, 3)

-- ── Tab row ───────────────────────────────────────────────────────────────────
local TAB_Y = 44
local tabNames = { "Live", "Benchmark", "Log" }
local tabs: { TextButton } = {}
local tabBodies: { Frame } = {}

local function switchTab(idx)
	for i, t in ipairs(tabs) do
		t.BackgroundColor3 = (i == idx) and C.accent or C.btnGray
		tabBodies[i].Visible = (i == idx)
	end
end

for i, name in ipairs(tabNames) do
	local t = btn(win, name,
		UDim2.new(0, 100, 0, 26),
		UDim2.new(0, 8 + (i-1)*108, 0, TAB_Y),
		C.btnGray, 2)
	tabs[i] = t
	local body = frame(win, name .. "Body",
		UDim2.new(1, -16, 1, -(TAB_Y + 34)),
		UDim2.new(0, 8, 0, TAB_Y + 30),
		C.panel, 2)
	corner(body)
	body.Visible = (i == 1)
	tabBodies[i] = body
	t.MouseButton1Click:Connect(function() switchTab(i) end)
end

-- ── Tab 1: Live ───────────────────────────────────────────────────────────────
local liveBody = tabBodies[1]

-- Riot status strip
local riotStrip = frame(liveBody, "RiotStrip",
	UDim2.new(1, -16, 0, 28),
	UDim2.new(0, 8, 0, 8),
	C.calm, 2)
corner(riotStrip, 5)
local riotLabel = label(riotStrip, "Status: CALM",
	UDim2.new(1,0,1,0), UDim2.new(0,10,0,0),
	Color3.new(1,1,1), Enum.TextXAlignment.Left, 3, 13)

-- Stat grid
local statY = 46
local statDefs = {
	{ key = "tick",       lbl = "Tick #"          },
	{ key = "citizens",   lbl = "Citizens"         },
	{ key = "officers",   lbl = "Officers"         },
	{ key = "panicking",  lbl = "Panicking"        },
	{ key = "responding", lbl = "Responding"       },
	{ key = "tickMs",     lbl = "Tick time (ms)"   },
}
local statLabels: { [string]: TextLabel } = {}

for i, def in ipairs(statDefs) do
	local col = ((i-1) % 2)
	local row = math.floor((i-1) / 2)
	local cell = frame(liveBody, def.key,
		UDim2.new(0, 220, 0, 44),
		UDim2.new(0, 8 + col * 234, 0, statY + row * 50),
		C.header, 3)
	corner(cell, 5)
	label(cell, def.lbl,
		UDim2.new(1,0,0,18), UDim2.new(0,8,0,4),
		C.muted, Enum.TextXAlignment.Left, 4, 11)
	local val = label(cell, "—",
		UDim2.new(1,0,0,20), UDim2.new(0,8,0,20),
		C.accent, Enum.TextXAlignment.Left, 4, 16)
	statLabels[def.key] = val
end

-- Riot intensity bar
local barY = statY + 3 * 50 + 6
label(liveBody, "Riot intensity",
	UDim2.new(1,-16,0,16), UDim2.new(0,8,0,barY),
	C.muted, Enum.TextXAlignment.Left, 3, 11)
local barBg = frame(liveBody, "BarBg",
	UDim2.new(1,-16,0,12),
	UDim2.new(0,8,0,barY+16),
	Color3.fromRGB(40,44,60), 3)
corner(barBg, 4)
local barFill = frame(barBg, "Fill",
	UDim2.new(0,0,1,0), UDim2.new(0,0,0,0),
	C.calm, 4)
corner(barFill, 4)

-- Mode label (parallel / sequential)
local modeLabel = label(liveBody, "Mode: Parallel",
	UDim2.new(1,-16,0,16), UDim2.new(0,8,0,barY+32),
	C.muted, Enum.TextXAlignment.Left, 3, 11)

-- Control buttons
local ctrlY = barY + 52
local ctrlDefs = {
	{ lbl = "Start",   color = C.btnGreen },
	{ lbl = "Pause",   color = C.btnGray  },
	{ lbl = "Reset",   color = C.btnRed   },
	{ lbl = "Undo",    color = C.btnBlue  },
	{ lbl = "2x Fast", color = C.btnBlue  },
	{ lbl = "Seq",     color = C.btnGray  },
}
local ctrlBtns: { [string]: TextButton } = {}
for i, def in ipairs(ctrlDefs) do
	local col = (i-1) % 3
	local row = math.floor((i-1) / 3)
	local b = btn(liveBody, def.lbl,
		UDim2.new(0, 130, 0, 30),
		UDim2.new(0, 8 + col * 140, 0, ctrlY + row * 36),
		def.color, 3)
	ctrlBtns[def.lbl] = b
end

-- ── Tab 2: Benchmark ─────────────────────────────────────────────────────────
local benchBody = tabBodies[2]
local benchOut  = Instance.new("TextLabel")
benchOut.Size               = UDim2.new(1,-16,1,-50)
benchOut.Position           = UDim2.new(0,8,0,8)
benchOut.BackgroundColor3   = C.header
benchOut.BorderSizePixel    = 0
benchOut.Text               = "Press 'Run Benchmark' to start..."
benchOut.TextColor3         = C.text
benchOut.TextXAlignment     = Enum.TextXAlignment.Left
benchOut.TextYAlignment     = Enum.TextYAlignment.Top
benchOut.Font               = Enum.Font.Code
benchOut.TextSize           = 11
benchOut.TextWrapped        = true
benchOut.ZIndex             = 3
benchOut.Parent             = benchBody
corner(benchOut, 5)

local runBenchBtn = btn(benchBody, "Run Benchmark",
	UDim2.new(1,-16,0,30),
	UDim2.new(0,8,1,-38),
	C.btnBlue, 3)

-- ── Tab 3: Log ────────────────────────────────────────────────────────────────
local logBody   = tabBodies[3]
local logOut    = Instance.new("TextLabel")
logOut.Size               = UDim2.new(1,-16,1,-16)
logOut.Position           = UDim2.new(0,8,0,8)
logOut.BackgroundColor3   = C.header
logOut.BorderSizePixel    = 0
logOut.Text               = ""
logOut.TextColor3         = C.muted
logOut.TextXAlignment     = Enum.TextXAlignment.Left
logOut.TextYAlignment     = Enum.TextYAlignment.Top
logOut.Font               = Enum.Font.Code
logOut.TextSize           = 11
logOut.TextWrapped        = true
logOut.ZIndex             = 3
logOut.Parent             = logBody
corner(logOut, 5)

local logLines: { string } = {}
local function appendLog(msg: string)
	logLines[#logLines + 1] = string.format("[%d] %s", math.floor(tick() % 10000), msg)
	if #logLines > 30 then table.remove(logLines, 1) end
	logOut.Text = table.concat(logLines, "\n")
end

-- ── Simulation setup ──────────────────────────────────────────────────────────
local function buildSim(parallel: boolean)
	core = SimulationCore.new({
		citizenCount = 12,
		officerCount = 4,
		tickInterval = 1.0,
		parallel     = parallel,
	})
	invoker = SimCommands.SimCommandInvoker.new(core)

	local statsObserver = SimObservers.UIObserver.new({
		onTick = function(stats)
			-- Update stat grid
			statLabels["tick"].Text       = tostring(stats.tick)
			statLabels["citizens"].Text   = tostring(stats.citizens)
			statLabels["officers"].Text   = tostring(stats.officers)
			statLabels["panicking"].Text  = tostring(stats.panicking)
			statLabels["responding"].Text = tostring(stats.responding)
			statLabels["tickMs"].Text     = string.format("%.2f", core:getLastTickTime() * 1000)

			-- Riot intensity bar
			local intensity = (stats.citizens > 0)
				and math.clamp(stats.panicking / stats.citizens, 0, 1)
				or 0
			barFill.Size = UDim2.new(intensity, 0, 1, 0)
			barFill.BackgroundColor3 = (intensity > 0.4) and C.riot or C.calm
		end,
		onRiotChanged = function(active)
			riotStrip.BackgroundColor3 = active and C.riot or C.calm
			riotLabel.Text = active and "Status: RIOT ACTIVE" or "Status: CALM"
			appendLog(active and "RIOT started!" or "Riot ended.")
		end,
	})

	core:attach(statsObserver)
	modeLabel.Text = "Mode: " .. (parallel and "Parallel (task.spawn)" or "Sequential (for-loop)")
end

-- initial build
buildSim(true)

-- ── Button wiring ─────────────────────────────────────────────────────────────
ctrlBtns["Start"].MouseButton1Click:Connect(function()
	invoker:execute(SimCommands.StartCommand.new())
	appendLog("Start")
end)

ctrlBtns["Pause"].MouseButton1Click:Connect(function()
	invoker:execute(SimCommands.PauseCommand.new())
	appendLog("Pause")
end)

ctrlBtns["Reset"].MouseButton1Click:Connect(function()
	invoker:execute(SimCommands.ResetCommand.new())
	appendLog("Reset")
	for _, v in pairs(statLabels) do v.Text = "—" end
	barFill.Size = UDim2.new(0, 0, 1, 0)
	riotStrip.BackgroundColor3 = C.calm
	riotLabel.Text = "Status: CALM"
end)

ctrlBtns["Undo"].MouseButton1Click:Connect(function()
	local ok = invoker:undo()
	appendLog("Undo → " .. tostring(ok))
end)

ctrlBtns["2x Fast"].MouseButton1Click:Connect(function()
	invoker:execute(SimCommands.SetSpeedCommand.new(0.5))
	appendLog("Speed → 0.5s/tick")
end)

local seqMode = false
ctrlBtns["Seq"].MouseButton1Click:Connect(function()
	seqMode = not seqMode
	local wasRunning = core:isRunning()
	core:pause()
	buildSim(not seqMode)
	ctrlBtns["Seq"].Text = seqMode and "Parallel" or "Seq"
	if wasRunning then
		invoker:execute(SimCommands.StartCommand.new())
	end
	appendLog("Mode toggled → " .. (seqMode and "Sequential" or "Parallel"))
end)

-- ── Benchmark tab ─────────────────────────────────────────────────────────────
runBenchBtn.MouseButton1Click:Connect(function()
	runBenchBtn.Text = "Running..."
	runBenchBtn.Active = false
	task.spawn(function()
		bench:clear()
		local sizes = {100, 500, 1000, 5000}
		for _, sz in ipairs(sizes) do
			local data = {}
			for i = 1, sz do data[i] = math.random(1, sz * 2) end

			local seqS = SequentialSort.new()
			bench:measure("Sequential/" .. sz, seqS, table.clone(data))

			for _, w in ipairs({2, 4, 8}) do
				local parS = ParallelSort.new(w)
				bench:measure(string.format("Parallel(w=%d)/%d", w, sz), parS, table.clone(data))
			end

			task.wait()
		end

		-- Simulation tick benchmark
		local seqCore = SimulationCore.new({ citizenCount=20, officerCount=5, parallel=false })
		local t0 = os.clock()
		seqCore:runFor(50)
		local seqTickTime = (os.clock() - t0) / 50 * 1000

		local parCore = SimulationCore.new({ citizenCount=20, officerCount=5, parallel=true })
		local t1 = os.clock()
		parCore:runFor(50)
		local parTickTime = (os.clock() - t1) / 50 * 1000

		local lines = { bench:summarize(), "",
			string.format("Sim tick (seq,  20 agents): %.4f ms", seqTickTime),
			string.format("Sim tick (par,  20 agents): %.4f ms", parTickTime),
		}
		benchOut.Text = table.concat(lines, "\n")
		runBenchBtn.Text = "Run Benchmark"
		runBenchBtn.Active = true
	end)
end)

-- ── Open/close ────────────────────────────────────────────────────────────────
closeBtn.MouseButton1Click:Connect(function()
	open = false
	screenGui.Enabled = false
	core:pause()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Q then
		open = not open
		screenGui.Enabled = open
		if open then
			switchTab(1)
		else
			core:pause()
		end
	end
end)
