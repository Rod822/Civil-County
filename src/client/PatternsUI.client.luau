--[[
	@file PatternsUI.client.luau
	@desc Interactive demonstration of all 15 design patterns in Civil-County
	       Press P to toggle. Each panel runs live code against the real modules.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local liveDemoConnection = nil
local simDemoConnection  = nil

local JobFactory        = require(ReplicatedStorage.Patterns.Factories.JobFactory)
local NotificationFactory = require(ReplicatedStorage.Patterns.Factories.NotificationFactory)
local MissionBuilder    = require(ReplicatedStorage.Patterns.Creational.MissionBuilder)
local ServiceRegistry   = require(ReplicatedStorage.Patterns.Creational.ServiceRegistry)
local ServiceDecorator  = require(ReplicatedStorage.Patterns.Structural.ServiceDecorator)
local ExternalAPIAdapter = require(ReplicatedStorage.Patterns.Structural.ExternalAPIAdapter)
local DataProxy         = require(ReplicatedStorage.Patterns.Structural.DataProxy)
local JobBridge         = require(ReplicatedStorage.Patterns.Structural.JobBridge)
local PaymentStrategy   = require(ReplicatedStorage.Patterns.Behavioral.PaymentStrategy)
local PlayerState       = require(ReplicatedStorage.Patterns.Behavioral.PlayerState)
local GameCommand       = require(ReplicatedStorage.Patterns.Behavioral.GameCommand)
local PlayerDataObserver = require(ReplicatedStorage.Patterns.Behavioral.PlayerDataObserver)
local ValidationChain   = require(ReplicatedStorage.Patterns.Behavioral.ValidationChain)

-- ──────────────────────────────────────────────────────────────
-- Constants
-- ──────────────────────────────────────────────────────────────
local C = {
	bg        = Color3.fromRGB(18, 18, 18),
	sidebar   = Color3.fromRGB(12, 12, 12),
	card      = Color3.fromRGB(28, 28, 28),
	accent    = Color3.fromRGB(38, 100, 170),
	accentDim = Color3.fromRGB(25, 65, 110),
	green     = Color3.fromRGB(40, 130, 60),
	red       = Color3.fromRGB(160, 45, 45),
	amber     = Color3.fromRGB(170, 120, 20),
	text      = Color3.fromRGB(210, 210, 210),
	textDim   = Color3.fromRGB(130, 130, 130),
	textCode  = Color3.fromRGB(160, 200, 130),
	border    = Color3.fromRGB(45, 45, 45),
	btnHover  = Color3.fromRGB(50, 50, 50),
}

local CATEGORY_COLOR = {
	Creational        = Color3.fromRGB(60, 100, 160),
	Structural        = Color3.fromRGB(120, 70, 160),
	Behavioral        = Color3.fromRGB(40, 130, 100),
	["Live Use Case"] = Color3.fromRGB(160, 100, 30),
	["Simulation"]    = Color3.fromRGB(30, 140, 130),
}

local W, H = 740, 560
local SIDEBAR_W = 195

-- ──────────────────────────────────────────────────────────────
-- Root GUI
-- ──────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PatternsDemo"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.new(0, W, 0, H)
root.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
root.BackgroundColor3 = C.bg
root.BorderSizePixel = 0
root.Parent = screenGui

-- ──────────────────────────────────────────────────────────────
-- Dragging
-- ──────────────────────────────────────────────────────────────
do
	local dragging, dragStart, frameStart
	root.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			frameStart = root.Position
		end
	end)
	root.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = inp.Position - dragStart
			root.Position = UDim2.new(
				frameStart.X.Scale, frameStart.X.Offset + delta.X,
				frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
			)
		end
	end)
end

-- ──────────────────────────────────────────────────────────────
-- Header bar
-- ──────────────────────────────────────────────────────────────
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
header.BorderSizePixel = 0
header.Parent = root

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -50, 1, 0)
headerTitle.Position = UDim2.new(0, 12, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.TextColor3 = C.text
headerTitle.TextSize = 14
headerTitle.Font = Enum.Font.GothamBold
headerTitle.Text = "Design Patterns  /  Civil-County  /  15 patterns implemented"
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 38, 0, 38)
closeBtn.Position = UDim2.new(1, -38, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Text = "x"
closeBtn.Parent = header
closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

-- ──────────────────────────────────────────────────────────────
-- Sidebar
-- ──────────────────────────────────────────────────────────────
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = root

local sideScroll = Instance.new("ScrollingFrame")
sideScroll.Size = UDim2.new(1, 0, 1, 0)
sideScroll.BackgroundTransparency = 1
sideScroll.BorderSizePixel = 0
sideScroll.ScrollBarThickness = 4
sideScroll.ScrollBarImageColor3 = C.border
sideScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sideScroll.Parent = sidebar

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 0)
sideLayout.Parent = sideScroll
sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	sideScroll.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y)
end)

-- ──────────────────────────────────────────────────────────────
-- Content panel
-- ──────────────────────────────────────────────────────────────
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -SIDEBAR_W, 1, -38)
content.Position = UDim2.new(0, SIDEBAR_W, 0, 38)
content.BackgroundColor3 = C.bg
content.BorderSizePixel = 0
content.Parent = root

-- thin divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, 1, 1, 0)
divider.BackgroundColor3 = C.border
divider.BorderSizePixel = 0
divider.Parent = content

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name = "ContentScroll"
contentScroll.Size = UDim2.new(1, -1, 1, 0)
contentScroll.Position = UDim2.new(0, 1, 0, 0)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.ScrollBarThickness = 5
contentScroll.ScrollBarImageColor3 = C.border
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.Parent = content

-- ──────────────────────────────────────────────────────────────
-- UI helpers
-- ──────────────────────────────────────────────────────────────
local function makeLabel(parent, text, size, pos, color, textSize, font, align, wrap)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.TextColor3 = color or C.text
	l.TextSize = textSize or 13
	l.Font = font or Enum.Font.Gotham
	l.Text = text
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextWrapped = wrap ~= false
	l.Parent = parent
	return l
end

local function makeBtn(parent, text, size, pos, bg)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bg or C.accentDim
	b.BorderSizePixel = 0
	b.TextColor3 = C.text
	b.TextSize = 12
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	return b
end

local function makeOutput(parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 1, -8)
	lbl.Position = UDim2.new(0, 5, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = C.textCode
	lbl.TextSize = 11
	lbl.Font = Enum.Font.Code
	lbl.Text = ""
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.Parent = frame
	return lbl
end

local function makeSeparator(parent, yPos)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -20, 0, 1)
	f.Position = UDim2.new(0, 10, 0, yPos)
	f.BackgroundColor3 = C.border
	f.BorderSizePixel = 0
	f.Parent = parent
end

local function setCanvas(h)
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, h)
	contentScroll.CanvasPosition = Vector2.new(0, 0)
end

-- ──────────────────────────────────────────────────────────────
-- Per-pattern demo builders
-- ──────────────────────────────────────────────────────────────
local demos = {}

-- Helper: standard content header block, returns next Y offset
local PW = W - SIDEBAR_W - 20  -- usable content width

local function drawHeader(name, category, desc)
	contentScroll:ClearAllChildren()

	local catColor = CATEGORY_COLOR[category] or C.accent

	-- pattern name
	makeLabel(contentScroll, name,
		UDim2.new(0, PW - 80, 0, 28),
		UDim2.new(0, 10, 0, 14),
		C.text, 20, Enum.Font.GothamBold)

	-- category badge
	local badge = Instance.new("Frame")
	badge.Size = UDim2.new(0, 90, 0, 20)
	badge.Position = UDim2.new(0, PW - 80, 0, 18)
	badge.BackgroundColor3 = catColor
	badge.BorderSizePixel = 0
	badge.Parent = contentScroll
	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.TextColor3 = Color3.new(1,1,1)
	badgeText.TextSize = 10
	badgeText.Font = Enum.Font.GothamBold
	badgeText.Text = category:upper()
	badgeText.Parent = badge

	-- description
	makeLabel(contentScroll, desc,
		UDim2.new(0, PW - 10, 0, 32),
		UDim2.new(0, 10, 0, 48),
		C.textDim, 12, Enum.Font.Gotham)

	makeSeparator(contentScroll, 88)

	return 100  -- next Y
end

-- ── 1. Factory Method ────────────────────────────────────────
demos["Factory Method"] = function()
	local y = drawHeader(
		"Factory Method",
		"Creational",
		"JobFactory encapsulates job object creation. Callers request a job by name; the factory handles instantiation and caches results."
	)

	makeLabel(contentScroll, "Select a job to create via factory:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 22

	local jobNames = { "Police", "FireService", "Paramedic", "Civilian" }
	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 100), UDim2.new(0, 10, 0, y + 32))

	local factory = JobFactory.new()

	for i, jobName in ipairs(jobNames) do
		local btn = makeBtn(contentScroll, jobName,
			UDim2.new(0, 100, 0, 26),
			UDim2.new(0, 10 + (i-1) * 108, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local job = factory:createJob(jobName)
			if job then
				out.Text = string.format(
					"factory:createJob(%q)\n\njob.name        = %q\njob.teamName    = %q\njob.basePay     = %d\njob.jobDescription = %q",
					jobName, job.name, job.teamName, job.basePay, job.jobDescription
				)
			else
				out.Text = "nil  -- job does not exist in config"
			end
		end)
	end

	-- cache proof
	y = y + 140
	makeLabel(contentScroll, "Cache proof  (same instance returned for repeated calls):",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	local cacheOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 44), UDim2.new(0, 10, 0, y + 28))
	local cacheBtn = makeBtn(contentScroll, "Run cache test",
		UDim2.new(0, 130, 0, 26), UDim2.new(0, 10, 0, y))
	cacheBtn.MouseButton1Click:Connect(function()
		local f2 = JobFactory.new()
		local a = f2:createJob("Police")
		local b = f2:createJob("Police")
		cacheOut.Text = string.format(
			"a = factory:createJob(\"Police\")\nb = factory:createJob(\"Police\")\na == b  ->  %s  (same table reference)",
			tostring(rawequal(a, b))
		)
	end)

	setCanvas(y + 80)
end

-- ── 2. Abstract Factory ──────────────────────────────────────
demos["Abstract Factory"] = function()
	local y = drawHeader(
		"Abstract Factory",
		"Creational",
		"NotificationFactory creates families of related notification objects. The factory decides the concrete type; callers stay decoupled from it."
	)

	local factory = NotificationFactory.new()
	local types = { "InGame", "UI", "Email", "Unknown" }
	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 90), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Create notification by type:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	for i, t in ipairs(types) do
		local btn = makeBtn(contentScroll, t,
			UDim2.new(0, 90, 0, 26),
			UDim2.new(0, 10 + (i-1) * 98, 0, y), t == "Unknown" and C.red or C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local n = factory:createNotification(t, "Player1", "Alert", "Something happened", "High")
			if n then
				local lines = {}
				for k, v in pairs(n) do
					table.insert(lines, string.format("  .%-12s = %s", k, tostring(v)))
				end
				table.sort(lines)
				out.Text = "createNotification(" .. t .. ")\n" .. table.concat(lines, "\n")
			else
				out.Text = "createNotification(" .. t .. ")  ->  nil\n-- unknown type; factory returns nil"
			end
		end)
	end

	y = y + 130
	makeLabel(contentScroll, "Batch creation:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	local batchOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 54), UDim2.new(0, 10, 0, y + 28))
	local batchBtn = makeBtn(contentScroll, "Create batch (3 players)",
		UDim2.new(0, 170, 0, 26), UDim2.new(0, 10, 0, y))
	batchBtn.MouseButton1Click:Connect(function()
		local batch = factory:createBatchNotifications("InGame", {"Alice","Bob","Carol"}, "Shift", "Starts now")
		batchOut.Text = string.format(
			"createBatchNotifications(\"InGame\", {3 players}, ...)\n-> returned %d notification objects", #batch
		)
	end)

	setCanvas(y + 90)
end

-- ── 3. Builder ───────────────────────────────────────────────
demos["Builder"] = function()
	local y = drawHeader(
		"Builder",
		"Creational",
		"MissionBuilder constructs complex Mission objects step by step using a fluent API. The same builder process can produce different configurations."
	)

	local presets = {
		{
			label = "Police Patrol",
			fn = function(b) return b:setTitle("Patrol District 5"):setAssignedJob("Police")
				:setReward(200):setBonusReward(50):setDifficulty("Medium")
				:addObjective("Visit all checkpoints"):addObjective("Report incidents"):build()
			end,
		},
		{
			label = "Fire Response",
			fn = function(b) return b:setTitle("Warehouse Fire"):setAssignedJob("FireService")
				:setReward(350):setBonusReward(100):setDifficulty("Hard"):setTimeLimit(600)
				:addObjective("Contain fire"):addObjective("Evacuate civilians"):addObjective("File report"):build()
			end,
		},
		{
			label = "Medical Call",
			fn = function(b) return b:setTitle("Downtown Emergency"):setAssignedJob("Paramedic")
				:setReward(180):setDifficulty("Easy")
				:addObjective("Reach patient"):addObjective("Stabilise"):build()
			end,
		},
	}

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 130), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Choose a mission preset to build:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	for i, preset in ipairs(presets) do
		local btn = makeBtn(contentScroll, preset.label,
			UDim2.new(0, 130, 0, 26),
			UDim2.new(0, 10 + (i-1) * 138, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local mission = preset.fn(MissionBuilder.new())
			out.Text = string.format(
				"title       = %q\nassignedJob = %q\nreward      = %d  (+%d bonus)\ndifficulty  = %q\ntimeLimit   = %ds\nobjectives  = %d items:\n  %s",
				mission.title, mission.assignedJob, mission.reward, mission.bonusReward,
				mission.difficulty, mission.timeLimit, #mission.objectives,
				table.concat(mission.objectives, "\n  ")
			)
		end)
	end

	y = y + 170
	makeLabel(contentScroll, "Reset proof:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	local resetOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 44), UDim2.new(0, 10, 0, y + 28))
	local resetBtn = makeBtn(contentScroll, "build -> reset -> build",
		UDim2.new(0, 160, 0, 26), UDim2.new(0, 10, 0, y))
	resetBtn.MouseButton1Click:Connect(function()
		local b = MissionBuilder.new()
		b:setTitle("Custom Op"):setReward(500)
		local m1 = b:build()
		b:reset()
		local m2 = b:build()
		resetOut.Text = string.format(
			"after build:  title=%q  reward=%d\nafter reset:  title=%q  reward=%d",
			m1.title, m1.reward, m2.title, m2.reward
		)
	end)

	setCanvas(y + 90)
end

-- ── 4. Singleton ─────────────────────────────────────────────
demos["Singleton"] = function()
	local y = drawHeader(
		"Singleton",
		"Creational",
		"ServiceRegistry maintains exactly one instance. Multiple calls to getInstance() always return the same table reference."
	)

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 80), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Run identity checks:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local btn1 = makeBtn(contentScroll, "getInstance() twice",
		UDim2.new(0, 155, 0, 26), UDim2.new(0, 10, 0, y))
	btn1.MouseButton1Click:Connect(function()
		local a = ServiceRegistry.getInstance()
		local b = ServiceRegistry.getInstance()
		out.Text = string.format(
			"a = ServiceRegistry.getInstance()\nb = ServiceRegistry.getInstance()\n\nrawequal(a, b)  ->  %s  (same object in memory)",
			tostring(rawequal(a, b))
		)
	end)

	local btn2 = makeBtn(contentScroll, "Shared state test",
		UDim2.new(0, 140, 0, 26), UDim2.new(0, 175, 0, y))
	btn2.MouseButton1Click:Connect(function()
		local r1 = ServiceRegistry.getInstance()
		r1:clear()
		r1:register("Demo", { version = 3 })
		local r2 = ServiceRegistry.getInstance()
		local svc = r2:get("Demo")
		out.Text = string.format(
			"r1:register(\"Demo\", {version=3})\n-- retrieve from r2 (different variable, same instance):\nr2:get(\"Demo\").version  ->  %s",
			svc and tostring(svc.version) or "nil"
		)
	end)

	y = y + 120
	makeLabel(contentScroll, "Service registry operations:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	local regOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 64), UDim2.new(0, 10, 0, y + 28))

	local regBtn = makeBtn(contentScroll, "Register / duplicate guard",
		UDim2.new(0, 190, 0, 26), UDim2.new(0, 10, 0, y))
	regBtn.MouseButton1Click:Connect(function()
		local r = ServiceRegistry.getInstance()
		r:clear()
		local ok1 = r:register("JobService", {})
		local ok2 = r:register("JobService", {})
		regOut.Text = string.format(
			"r:register(\"JobService\", {})  ->  %s  (first)\nr:register(\"JobService\", {})  ->  %s  (duplicate blocked)\nr:hasService(\"JobService\")    ->  %s",
			tostring(ok1), tostring(ok2), tostring(r:hasService("JobService"))
		)
	end)

	setCanvas(y + 100)
end

-- ── 5. Decorator ─────────────────────────────────────────────
demos["Decorator"] = function()
	local y = drawHeader(
		"Decorator",
		"Structural",
		"ServiceDecorator wraps an existing service and adds Logging, Audit, and Performance tracking without changing the original class."
	)

	local dec = ServiceDecorator.new({ name = "JobService" })

	local stackOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 70), UDim2.new(0, 10, 0, y + 32))
	local logOut   = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 70), UDim2.new(0, 10, 0, y + 140))

	local function refreshStack()
		local d = dec:getDecorators()
		if #d == 0 then
			stackOut.Text = "(no decorators applied)"
		else
			stackOut.Text = "Active decorators:\n" .. table.concat(d, "\n")
		end
	end

	makeLabel(contentScroll, "Add decorators to a service:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	refreshStack()

	local addLog = makeBtn(contentScroll, "+ Logging",
		UDim2.new(0, 100, 0, 26), UDim2.new(0, 10, 0, y))
	local addAudit = makeBtn(contentScroll, "+ Audit",
		UDim2.new(0, 90, 0, 26), UDim2.new(0, 118, 0, y))
	local addPerf = makeBtn(contentScroll, "+ Performance",
		UDim2.new(0, 120, 0, 26), UDim2.new(0, 216, 0, y))
	local clrBtn = makeBtn(contentScroll, "Clear",
		UDim2.new(0, 70, 0, 26), UDim2.new(0, 344, 0, y), C.red)

	addLog.MouseButton1Click:Connect(function()
		dec:addLoggingDecorator("assignJob")
		refreshStack()
	end)
	addAudit.MouseButton1Click:Connect(function()
		dec:addAuditDecorator("paycheck", "Finance")
		refreshStack()
	end)
	addPerf.MouseButton1Click:Connect(function()
		dec:addPerformanceMonitoring("loadPlayer")
		refreshStack()
	end)
	clrBtn.MouseButton1Click:Connect(function()
		dec = ServiceDecorator.new({ name = "JobService" })
		refreshStack()
		logOut.Text = ""
	end)

	y = y + 110
	makeLabel(contentScroll, "Log an operation:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local ops = { { "assignJob", "Police -> Alice" }, { "paycheck", "Alice +250" }, { "firePlayer", "Bob removed" } }
	for i, op in ipairs(ops) do
		local btn = makeBtn(contentScroll, "Log: " .. op[1],
			UDim2.new(0, 140, 0, 24),
			UDim2.new(0, 10 + (i-1) * 148, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			dec:logOperation(op[1], op[2])
			local logs = dec:getLogs()
			local last3 = {}
			for j = math.max(1, #logs - 2), #logs do
				table.insert(last3, logs[j])
			end
			logOut.Text = "Recent logs:\n" .. table.concat(last3, "\n")
		end)
	end

	setCanvas(y + 120)
end

-- ── 6. Adapter ───────────────────────────────────────────────
demos["Adapter"] = function()
	local y = drawHeader(
		"Adapter",
		"Structural",
		"ExternalAPIAdapter wraps an incompatible DataStore API so the rest of the code talks to a uniform interface."
	)

	local rawAPI = {
		GetAsync = function(_, k) return "raw_" .. k end,
		SetAsync = function(_, _, _) return true end,
		RemoveAsync = function(_, _) return true end,
	}

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 110), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Adapt a raw DataStore and inspect the result:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local adapted

	local adaptBtn = makeBtn(contentScroll, "Create adapter",
		UDim2.new(0, 130, 0, 26), UDim2.new(0, 10, 0, y))
	adaptBtn.MouseButton1Click:Connect(function()
		local adp = ExternalAPIAdapter.new("DataStore", rawAPI)
		adapted = adp:adaptDataStore(rawAPI)
		local methods = adp:getAdaptedMethods()
		out.Text = string.format(
			"ExternalAPIAdapter.new(\"DataStore\", rawAPI)\nadapter:adaptDataStore(rawAPI)\n\nAdapted methods (%d):\n  %s",
			#methods, table.concat(methods, ", ")
		)
	end)

	local useBtn = makeBtn(contentScroll, "Use adapted service",
		UDim2.new(0, 150, 0, 26), UDim2.new(0, 148, 0, y))
	useBtn.MouseButton1Click:Connect(function()
		if not adapted then
			out.Text = "Create the adapter first."
			return
		end
		local ok, result = pcall(function()
			return adapted.get and adapted:get("playerData_123") or "adapted.get not found"
		end)
		out.Text = string.format(
			"adapted:get(\"playerData_123\")\n->  %s\n\nThe adapter translates get/set/delete to\nGetAsync/SetAsync/RemoveAsync on the raw API.",
			ok and tostring(result) or result
		)
	end)

	setCanvas(y + 160)
end

-- ── 7. Facade ────────────────────────────────────────────────
demos["Facade"] = function()
	local y = drawHeader(
		"Facade",
		"Structural",
		"GameFacade exposes a single simplified surface over three separate services. Client code makes one call instead of coordinating each subsystem."
	)

	local mockJob    = { _playersDataService = { _profiles = {} } }
	local mockData   = { _profiles = {} }
	local mockNotify = {}

	local GameFacade = require(ReplicatedStorage.Patterns.Structural.GameFacade)
	local facade = GameFacade.new(mockJob, mockData, mockNotify)

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 110), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "facade hides 3 services behind one interface:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local statusBtn = makeBtn(contentScroll, "getServiceStatus()",
		UDim2.new(0, 155, 0, 26), UDim2.new(0, 10, 0, y))
	statusBtn.MouseButton1Click:Connect(function()
		local status = facade:getServiceStatus()
		local lines = {}
		for k, v in pairs(status) do
			table.insert(lines, string.format("  %-22s  %s", k, v))
		end
		table.sort(lines)
		out.Text = "facade:getServiceStatus()\n{\n" .. table.concat(lines, "\n") .. "\n}"
	end)

	y = y + 52
	makeLabel(contentScroll, "Without facade:  caller would call JobService, PlayersData, and\nNotificationService separately. Facade collapses that into one surface.",
		UDim2.new(0, PW - 10, 0, 36), UDim2.new(0, 10, 0, y), C.textDim, 11)

	setCanvas(y + 80)
end

-- ── 8. Proxy ─────────────────────────────────────────────────
demos["Proxy"] = function()
	local y = drawHeader(
		"Proxy",
		"Structural",
		"DataProxy sits in front of the real data source. It caches results so repeated reads skip the expensive fetch. Tracks hits, misses, and evictions."
	)

	local fetchCount = 0
	local proxy = DataProxy.new(nil, 60)
	local function fetch(_)
		fetchCount = fetchCount + 1
		return "PlayerData_" .. tostring(tick()):sub(1, 8)
	end

	local out  = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 90), UDim2.new(0, 10, 0, y + 32))
	local stat = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 60), UDim2.new(0, 10, 0, y + 160))

	local function updateStats()
		local s = proxy:getCacheStats()
		stat.Text = string.format(
			"hits=%d  misses=%d  evictions=%d  hitRate=%.0f%%  entries=%d  fetches_called=%d",
			s.cacheHits, s.cacheMisses, s.evictions,
			s.hitRate * 100, s.totalEntries, fetchCount
		)
	end

	makeLabel(contentScroll, "Interact with the cache:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local keys = { "player:101", "player:102", "player:101" }

	for i, key in ipairs(keys) do
		local btn = makeBtn(contentScroll, 'get("' .. key .. '")',
			UDim2.new(0, 140, 0, 26),
			UDim2.new(0, 10 + (i-1) * 148, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local val = proxy:get(key, fetch)
			local cached = proxy:isCached(key)
			out.Text = string.format(
				'proxy:get("%s")\n->  %s\n\ncached after call: %s',
				key, tostring(val), tostring(cached)
			)
			updateStats()
		end)
	end

	y = y + 126
	makeLabel(contentScroll, "Cache stats:", UDim2.new(0, PW, 0, 14), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 18
	updateStats()

	local invBtn = makeBtn(contentScroll, 'invalidate("player:101")',
		UDim2.new(0, 195, 0, 26), UDim2.new(0, 10, 0, y + 68))
	invBtn.MouseButton1Click:Connect(function()
		proxy:invalidate("player:101")
		out.Text = 'invalidate("player:101")\ncached now: ' .. tostring(proxy:isCached("player:101"))
		updateStats()
	end)

	setCanvas(y + 130)
end

-- ── 9. Bridge ────────────────────────────────────────────────
demos["Bridge"] = function()
	local y = drawHeader(
		"Bridge",
		"Structural",
		"JobBridge decouples the Job abstraction (what a job is) from its implementation (how it behaves on server vs client). Both sides can evolve independently."
	)

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 110), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Same abstraction, different implementations:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local serverBtn = makeBtn(contentScroll, "Server abstraction",
		UDim2.new(0, 150, 0, 26), UDim2.new(0, 10, 0, y))
	local clientBtn = makeBtn(contentScroll, "Client abstraction",
		UDim2.new(0, 150, 0, 26), UDim2.new(0, 168, 0, y))

	serverBtn.MouseButton1Click:Connect(function()
		local job = JobBridge.createServerJobAbstraction("Police", 250)
		local info = job:getJobInfo()
		out.Text = string.format(
			"createServerJobAbstraction(\"Police\", 250)\n\ninfo.name           = %q\ninfo.implementation = %q\ninfo.description    = %q\n\nServer impl: persists data, manages Teams, gives tools.",
			info.name, info.implementation, info.description
		)
	end)
	clientBtn.MouseButton1Click:Connect(function()
		local job = JobBridge.createClientJobAbstraction("Police")
		local info = job:getJobInfo()
		out.Text = string.format(
			"createClientJobAbstraction(\"Police\")\n\ninfo.name           = %q\ninfo.implementation = %q\ninfo.description    = %q\n\nClient impl: updates local UI state only.",
			info.name, info.implementation, info.description
		)
	end)

	setCanvas(y + 165)
end

-- ── 10. Strategy ─────────────────────────────────────────────
demos["Strategy"] = function()
	local y = drawHeader(
		"Strategy",
		"Behavioral",
		"PaymentStrategy swaps calculation algorithms at runtime. PaymentContext holds a reference to the current strategy and delegates the calculation to it."
	)

	local basePay, hours, bonus = 240, 10, 1.3
	local strategies = {
		{ name = "Basic",       s = PaymentStrategy.BasicPaymentStrategy.new() },
		{ name = "Overtime",    s = PaymentStrategy.OvertimePaymentStrategy.new() },
		{ name = "Performance", s = PaymentStrategy.PerformancePaymentStrategy.new() },
		{ name = "HazardPay",   s = PaymentStrategy.HazardPayPaymentStrategy.new() },
	}

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 110), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, string.format("Input: basePay=%d  hours=%d  bonus=%.1f", basePay, hours, bonus),
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	for i, data in ipairs(strategies) do
		local btn = makeBtn(contentScroll, data.name,
			UDim2.new(0, 110, 0, 26),
			UDim2.new(0, 10 + (i-1) * 118, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local ctx = PaymentStrategy.PaymentContext.new(data.s)
			local amount = ctx:calculatePayment(basePay, hours, bonus)
			out.Text = string.format(
				"context:setStrategy(%sPaymentStrategy)\nstrategyName  = %q\n\ncalculate(%d, %d, %.1f)\n->  %.2f currency",
				data.name, ctx:getStrategyName(), basePay, hours, bonus, amount
			)
		end)
	end

	y = y + 130
	makeLabel(contentScroll, "Context switch at runtime:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20
	local switchOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 60), UDim2.new(0, 10, 0, y + 28))
	local switchBtn = makeBtn(contentScroll, "Switch Basic -> Overtime at runtime",
		UDim2.new(0, 235, 0, 26), UDim2.new(0, 10, 0, y))
	switchBtn.MouseButton1Click:Connect(function()
		local ctx = PaymentStrategy.PaymentContext.new(PaymentStrategy.BasicPaymentStrategy.new())
		local before = ctx:calculatePayment(basePay, hours, bonus)
		local nameBefore = ctx:getStrategyName()
		ctx:setStrategy(PaymentStrategy.OvertimePaymentStrategy.new())
		local after = ctx:calculatePayment(basePay, hours, bonus)
		switchOut.Text = string.format(
			"strategy=%q  ->  %.2f\nsetStrategy(Overtime)\nstrategy=%q  ->  %.2f",
			nameBefore, before, ctx:getStrategyName(), after
		)
	end)

	setCanvas(y + 105)
end

-- ── 11. State ────────────────────────────────────────────────
demos["State"] = function()
	local y = drawHeader(
		"State",
		"Behavioral",
		"PlayerStateContext delegates behavior to the current state object. Transitions are validated by the state itself, preventing illegal moves."
	)

	local stateMap = {
		Idle       = PlayerState.IdleState.new(),
		OnDuty     = PlayerState.OnDutyState.new(),
		InMission  = PlayerState.InMissionState.new(),
		Resting    = PlayerState.RestingState.new(),
		Offline    = PlayerState.OfflineState.new(),
	}
	local order = { "Idle", "OnDuty", "InMission", "Resting", "Offline" }

	local ctx = PlayerState.PlayerStateContext.new(stateMap["Idle"])

	local curLabel = makeLabel(contentScroll, "Current state: Idle",
		UDim2.new(0, PW - 10, 0, 24), UDim2.new(0, 10, 0, y),
		C.text, 14, Enum.Font.GothamBold)

	local histOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 44), UDim2.new(0, 10, 0, y + 30))
	local resultOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 32), UDim2.new(0, 10, 0, y + 82))

	local function refresh(msg)
		curLabel.Text = "Current state:  " .. ctx:getCurrentStateName()
		local hist = ctx:getStateHistory()
		histOut.Text = "history:  " .. table.concat(hist, "  ->  ")
		resultOut.Text = msg or ""
	end
	refresh()

	y = y + 126
	makeLabel(contentScroll, "Attempt transitions:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	for i, name in ipairs(order) do
		local btn = makeBtn(contentScroll, "-> " .. name,
			UDim2.new(0, 100, 0, 26),
			UDim2.new(0, 10 + (i-1) * 107, 0, y),
			name == "Offline" and C.red or C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local ok = ctx:transitionTo(stateMap[name])
			if ok then
				refresh(string.format("transitionTo(%q)  ->  OK", name))
			else
				refresh(string.format(
					"transitionTo(%q)  ->  BLOCKED\n%q cannot transition to %q",
					name, ctx:getCurrentStateName(), name
				))
			end
		end)
	end

	local resetBtn = makeBtn(contentScroll, "Reset to Idle",
		UDim2.new(0, 100, 0, 26),
		UDim2.new(0, PW - 110, 0, y), C.amber)
	resetBtn.MouseButton1Click:Connect(function()
		ctx = PlayerState.PlayerStateContext.new(stateMap["Idle"])
		refresh("context reset")
	end)

	setCanvas(y + 80)
end

-- ── 12. Command ──────────────────────────────────────────────
demos["Command"] = function()
	local y = drawHeader(
		"Command",
		"Behavioral",
		"CommandInvoker treats requests as objects. This enables queuing, history, and undo. Invoker and receiver are fully decoupled."
	)

	local invoker = GameCommand.CommandInvoker.new(10)
	local commandNames = { "AssignJob:Police", "Paycheck:Alice", "AssignJob:FireService", "SendAlert:Riot" }
	local nameIdx = 0

	local histOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 100), UDim2.new(0, 10, 0, y + 32))
	local msgOut  = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 32), UDim2.new(0, 10, 0, y + 140))

	local function refreshHistory(msg)
		local hist = invoker:getHistory()
		local lines = {}
		for i, cmd in ipairs(hist) do
			table.insert(lines, string.format("  [%d] %s", i, cmd:getName()))
		end
		if #lines == 0 then
			histOut.Text = "(history empty)"
		else
			histOut.Text = "Command history  (" .. #hist .. " items):\n" .. table.concat(lines, "\n")
		end
		msgOut.Text = msg or ""
	end
	refreshHistory()

	makeLabel(contentScroll, "Execute and undo mock commands:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local execBtn = makeBtn(contentScroll, "Execute next command",
		UDim2.new(0, 170, 0, 26), UDim2.new(0, 10, 0, y))
	execBtn.MouseButton1Click:Connect(function()
		nameIdx = nameIdx % #commandNames + 1
		local cmdName = commandNames[nameIdx]
		local mock = {
			_name = cmdName,
			_done = false,
			execute = function(self)
				if self._done then return false end
				self._done = true
				return true
			end,
			undo = function(self)
				if not self._done then return false end
				self._done = false
				return true
			end,
			getName = function(self) return self._name end,
		}
		invoker:execute(mock)
		refreshHistory("executed: " .. cmdName)
	end)

	local undoBtn = makeBtn(contentScroll, "Undo last",
		UDim2.new(0, 100, 0, 26), UDim2.new(0, 188, 0, y), C.amber)
	undoBtn.MouseButton1Click:Connect(function()
		local ok = invoker:undo()
		refreshHistory(ok and "undo succeeded" or "nothing to undo")
	end)

	local clearBtn = makeBtn(contentScroll, "Clear history",
		UDim2.new(0, 110, 0, 26), UDim2.new(0, 296, 0, y), C.red)
	clearBtn.MouseButton1Click:Connect(function()
		invoker:clearHistory()
		refreshHistory("history cleared")
	end)

	setCanvas(y + 190)
end

-- ── 13. Observer ─────────────────────────────────────────────
demos["Observer"] = function()
	local y = drawHeader(
		"Observer",
		"Behavioral",
		"PlayerDataSubject keeps a list of observers. When data changes, all attached observers are notified. Subject and observers never reference each other directly."
	)

	local subject  = PlayerDataObserver.PlayerDataSubject.new()
	local logging  = PlayerDataObserver.LoggingObserver.new()
	local audit    = PlayerDataObserver.AuditObserver.new()

	subject:attach(logging)
	subject:attach(audit)

	local logOut   = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 100), UDim2.new(0, 10, 0, y + 32))
	local countOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 24), UDim2.new(0, 10, 0, y + 140))

	local function refreshLogs()
		local logs = logging:getLogs()
		local trail = audit:getAuditTrail()
		local last = {}
		for i = math.max(1, #logs - 3), #logs do
			table.insert(last, logs[i])
		end
		logOut.Text = "LoggingObserver (last " .. #last .. " of " .. #logs .. "):\n" .. table.concat(last, "\n")
		countOut.Text = "AuditObserver trail length: " .. #trail
	end
	refreshLogs()

	makeLabel(contentScroll, "Trigger events on the subject:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local balance = 500
	local balBtn = makeBtn(contentScroll, "Balance change",
		UDim2.new(0, 135, 0, 26), UDim2.new(0, 10, 0, y))
	balBtn.MouseButton1Click:Connect(function()
		balance = balance + math.random(50, 200)
		subject:notifyBalanceChange(balance)
		refreshLogs()
	end)

	local jobBtn = makeBtn(contentScroll, "Job change",
		UDim2.new(0, 110, 0, 26), UDim2.new(0, 153, 0, y))
	local jobs = { "Police", "FireService", "Paramedic", "Civilian" }
	local ji = 1
	jobBtn.MouseButton1Click:Connect(function()
		ji = ji % #jobs + 1
		subject:notifyJobChange(jobs[ji])
		refreshLogs()
	end)

	local lvlBtn = makeBtn(contentScroll, "Level up",
		UDim2.new(0, 90, 0, 26), UDim2.new(0, 271, 0, y))
	local lv = 1
	lvlBtn.MouseButton1Click:Connect(function()
		lv = lv + 1
		subject:notifyLevelUp(lv)
		refreshLogs()
	end)

	y = y + 50
	makeLabel(contentScroll, "Observer count:  " .. tostring(subject:getObserverCount()),
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)

	y = y + 120
	local detachBtn = makeBtn(contentScroll, "Detach LoggingObserver",
		UDim2.new(0, 180, 0, 26), UDim2.new(0, 10, 0, y), C.amber)
	detachBtn.MouseButton1Click:Connect(function()
		local ok = subject:detach("LoggingObserver")
		logOut.Text = "detach(\"LoggingObserver\")  ->  " .. tostring(ok)
			.. "\nobserverCount now: " .. subject:getObserverCount()
	end)

	setCanvas(y + 80)
end

-- ── 14. Template Method ──────────────────────────────────────
demos["Template Method"] = function()
	local y = drawHeader(
		"Template Method",
		"Behavioral",
		"MissionTemplate defines the algorithm skeleton in a base class. Concrete subclasses (PatrolMission, RescueMission) override only the steps that differ."
	)

	local MissionTemplate = require(ReplicatedStorage.Patterns.Behavioral.MissionTemplate)

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 130), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Inspect a concrete mission template:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local templates = {
		{ label = "PatrolMission",  ctor = function() return MissionTemplate.PatrolMissionTemplate and MissionTemplate.PatrolMissionTemplate.new() end },
		{ label = "RescueMission",  ctor = function() return MissionTemplate.RescueMissionTemplate and MissionTemplate.RescueMissionTemplate.new() end },
		{ label = "FireMission",    ctor = function() return MissionTemplate.FireMissionTemplate and MissionTemplate.FireMissionTemplate.new() end },
	}

	for i, t in ipairs(templates) do
		local btn = makeBtn(contentScroll, t.label,
			UDim2.new(0, 130, 0, 26),
			UDim2.new(0, 10 + (i-1) * 138, 0, y), C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local ok, tmpl = pcall(t.ctor)
			if not ok or not tmpl then
				out.Text = t.label .. " not available in this build.\n\nPattern skeleton:\n  1. validatePlayer(player)     <- subclass overrides\n  2. prepareResources()         <- subclass overrides\n  3. executeMission()           <- subclass overrides\n  4. calculateReward()          <- subclass overrides\n  5. cleanup()                  <- base class (shared)"
				return
			end
			local valid = tmpl:validatePlayer(nil)
			out.Text = string.format(
				"%s.new()\n\nvalidatePlayer(nil)  ->  %s\n\nAlgorithm skeleton (from base class):\n  1. validatePlayer    <- this subclass\n  2. prepareResources  <- this subclass\n  3. executeMission    <- this subclass\n  4. calculateReward   <- this subclass\n  5. cleanup           <- shared base",
				t.label, tostring(valid)
			)
		end)
	end

	y = y + 170
	makeLabel(contentScroll,
		"The base class calls these steps in order.\nSubclasses only override the steps unique to them.",
		UDim2.new(0, PW - 10, 0, 30), UDim2.new(0, 10, 0, y), C.textDim, 11)

	setCanvas(y + 60)
end

-- ── 15. Chain of Responsibility ──────────────────────────────
demos["Chain of Responsibility"] = function()
	local y = drawHeader(
		"Chain of Responsibility",
		"Behavioral",
		"ValidationChain links handlers in sequence. Each handler either handles the request or passes it to the next. The sender does not know which handler processes it."
	)

	local out = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 110), UDim2.new(0, 10, 0, y + 32))

	makeLabel(contentScroll, "Run data through a validation chain:",
		UDim2.new(0, PW, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 20

	local testCases = {
		{
			label  = "Valid job",
			data   = { jobName = "Police" },
			chain  = function()
				return ValidationChain.ValidationChainBuilder.new()
					:addValidator(ValidationChain.JobValidator.new())
					:addValidator(ValidationChain.LevelValidator.new())
					:build()
			end,
		},
		{
			label  = "Bad job name",
			data   = { jobName = "Wizard" },
			chain  = function()
				return ValidationChain.ValidationChainBuilder.new()
					:addValidator(ValidationChain.JobValidator.new())
					:build()
			end,
		},
		{
			label  = "Low balance",
			data   = { jobName = "Police", requiredBalance = 500, currentBalance = 50 },
			chain  = function()
				return ValidationChain.ValidationChainBuilder.new()
					:addValidator(ValidationChain.JobValidator.new())
					:addValidator(ValidationChain.BalanceValidator.new())
					:build()
			end,
		},
		{
			label  = "Full chain pass",
			data   = { jobName = "Civilian", requiredBalance = 0, playerLevel = 3, requiredLevel = 1 },
			chain  = function()
				return ValidationChain.ValidationChainBuilder.new()
					:addValidator(ValidationChain.JobValidator.new())
					:addValidator(ValidationChain.BalanceValidator.new())
					:addValidator(ValidationChain.LevelValidator.new())
					:build()
			end,
		},
	}

	for i, tc in ipairs(testCases) do
		local btn = makeBtn(contentScroll, tc.label,
			UDim2.new(0, 120, 0, 26),
			UDim2.new(0, 10 + (i-1) * 126, 0, y),
			tc.label:find("Bad") or tc.label:find("Low") and C.red or C.accentDim)
		btn.MouseButton1Click:Connect(function()
			local chain = tc.chain()
			local ok, msg = chain:validate(tc.data)

			local dataLines = {}
			for k, v in pairs(tc.data) do
				table.insert(dataLines, string.format("  %s = %s", k, tostring(v)))
			end
			table.sort(dataLines)

			out.Text = string.format(
				"data:\n%s\n\nchain:validate(data)\n->  valid=%s\n    msg=%q",
				table.concat(dataLines, "\n"), tostring(ok), msg
			)
		end)
	end

	setCanvas(y + 160)
end

-- ── LIVE USE CASE: Job Assignment Pipeline ───────────────────
demos["Job Assignment"] = function()
	if liveDemoConnection then
		liveDemoConnection:Disconnect()
		liveDemoConnection = nil
	end

	local y = drawHeader(
		"Job Assignment Pipeline",
		"Live Use Case",
		"ValidationChain + Command + Undo running on real game data. Click a job — the request travels to the server, passes through 4 validators, gets wrapped in a Command, then executes."
	)

	local assignRE  = ReplicatedStorage:FindFirstChild("JobAssignDemoRE")
	local undoRE    = ReplicatedStorage:FindFirstChild("JobUndoRE")
	local resultRE  = ReplicatedStorage:FindFirstChild("JobAssignResultRE")

	if not assignRE or not undoRE or not resultRE then
		makeLabel(contentScroll,
			"RemoteEvents not found.\nStart the server and sync via Rojo, then reopen this panel.",
			UDim2.new(0, PW - 10, 0, 40), UDim2.new(0, 10, 0, y), C.red, 12)
		setCanvas(y + 60)
		return
	end

	-- ── 1. Job selection ────────────────────────────────────────
	makeLabel(contentScroll, "1.  Select a job  (request fires to server):",
		UDim2.new(0, PW - 10, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 22

	local jobDefs = {
		{ name = "Police",      color = Color3.fromRGB(30,  80, 160) },
		{ name = "FireService", color = Color3.fromRGB(160, 60,  30) },
		{ name = "Paramedic",   color = Color3.fromRGB(30, 140,  80) },
		{ name = "Civilian",    color = Color3.fromRGB(75,  75,  75) },
	}

	local resetSteps, updateSteps  -- forward-declare; defined after step rows exist

	for i, jd in ipairs(jobDefs) do
		local btn = makeBtn(contentScroll, jd.name,
			UDim2.new(0, 116, 0, 28),
			UDim2.new(0, 10 + (i - 1) * 124, 0, y),
			jd.color)
		btn.MouseButton1Click:Connect(function()
			resetSteps()
			assignRE:FireServer(jd.name)
		end)
	end
	y = y + 36

	makeSeparator(contentScroll, y)
	y = y + 12

	-- ── 2. Validation chain display ─────────────────────────────
	makeLabel(contentScroll, "2.  ValidationChain  —  4 handlers run in sequence on server:",
		UDim2.new(0, PW - 10, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 22

	local stepNames = { "PlayerValidator", "JobValidator", "LevelValidator", "LocationValidator" }
	local stepRows  = {}

	for _, sname in ipairs(stepNames) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(0, PW - 10, 0, 26)
		row.Position = UDim2.new(0, 10, 0, y)
		row.BackgroundColor3 = C.card
		row.BorderSizePixel = 0
		row.Parent = contentScroll

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0, 155, 1, 0)
		nameL.Position = UDim2.new(0, 8, 0, 0)
		nameL.BackgroundTransparency = 1
		nameL.TextColor3 = C.textDim
		nameL.TextSize = 11
		nameL.Font = Enum.Font.Code
		nameL.Text = sname
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.Parent = row

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 44, 0, 18)
		badge.Position = UDim2.new(0, 163, 0, 4)
		badge.BackgroundColor3 = C.border
		badge.BorderSizePixel = 0
		badge.TextColor3 = C.textDim
		badge.TextSize = 10
		badge.Font = Enum.Font.GothamBold
		badge.Text = "WAIT"
		badge.Parent = row

		local msgL = Instance.new("TextLabel")
		msgL.Size = UDim2.new(0, PW - 232, 1, 0)
		msgL.Position = UDim2.new(0, 215, 0, 0)
		msgL.BackgroundTransparency = 1
		msgL.TextColor3 = C.textDim
		msgL.TextSize = 11
		msgL.Font = Enum.Font.Code
		msgL.Text = "---"
		msgL.TextXAlignment = Enum.TextXAlignment.Left
		msgL.TextWrapped = true
		msgL.Parent = row

		stepRows[sname] = { badge = badge, msgL = msgL }
		y = y + 28
	end

	-- Define helpers now that stepRows is fully built
	resetSteps = function()
		for _, sname in ipairs(stepNames) do
			local r = stepRows[sname]
			r.badge.BackgroundColor3 = C.border
			r.badge.TextColor3 = C.textDim
			r.badge.Text = "WAIT"
			r.msgL.Text = "---"
			r.msgL.TextColor3 = C.textDim
		end
	end

	updateSteps = function(steps)
		for _, step in ipairs(steps) do
			local r = stepRows[step.name]
			if not r then continue end
			if step.passed == true then
				r.badge.BackgroundColor3 = C.green
				r.badge.TextColor3 = Color3.new(1, 1, 1)
				r.badge.Text = "PASS"
				r.msgL.TextColor3 = C.textCode
			elseif step.passed == false then
				r.badge.BackgroundColor3 = C.red
				r.badge.TextColor3 = Color3.new(1, 1, 1)
				r.badge.Text = "FAIL"
				r.msgL.TextColor3 = C.red
			else
				r.badge.BackgroundColor3 = C.border
				r.badge.TextColor3 = C.textDim
				r.badge.Text = "SKIP"
				r.msgL.TextColor3 = C.textDim
			end
			r.msgL.Text = step.msg or "---"
		end
	end

	y = y + 4
	makeSeparator(contentScroll, y)
	y = y + 12

	-- ── 3. Command execution output ──────────────────────────────
	makeLabel(contentScroll, "3.  GameCommand.AssignJobCommand:",
		UDim2.new(0, PW - 10, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 22
	local cmdOut = makeOutput(contentScroll, UDim2.new(0, PW - 10, 0, 50), UDim2.new(0, 10, 0, y))
	cmdOut.Text = "waiting for first action..."
	y = y + 58

	makeSeparator(contentScroll, y)
	y = y + 12

	-- ── 4. CommandInvoker history + undo ────────────────────────
	makeLabel(contentScroll, "4.  CommandInvoker  —  history and undo:",
		UDim2.new(0, PW - 10, 0, 16), UDim2.new(0, 10, 0, y), C.textDim, 11)
	y = y + 22

	local histOut = makeOutput(contentScroll,
		UDim2.new(0, PW - 132, 0, 72),
		UDim2.new(0, 10, 0, y))
	histOut.Text = "(no actions yet)"

	local undoBtn = makeBtn(contentScroll, "Undo last",
		UDim2.new(0, 114, 0, 36),
		UDim2.new(0, PW - 114, 0, y),
		C.amber)
	undoBtn.MouseButton1Click:Connect(function()
		undoRE:FireServer()
	end)

	y = y + 84

	-- ── Result handler ───────────────────────────────────────────
	local clientLog = {}

	local function refreshHistory()
		if #clientLog == 0 then
			histOut.Text = "(no actions yet)"
			return
		end
		local lines = {}
		for i = math.max(1, #clientLog - 3), #clientLog do
			table.insert(lines, string.format("[%d]  %s", i, clientLog[i]))
		end
		histOut.Text = table.concat(lines, "\n")
	end

	liveDemoConnection = resultRE.OnClientEvent:Connect(function(result)
		if result.action == "assign" then
			if result.steps then
				updateSteps(result.steps)
			end
			if result.success then
				cmdOut.Text = string.format(
					"execute()  ->  OK\nAssignJobCommand queued %q  |  history size: %d",
					result.jobName, result.historySize
				)
				table.insert(clientLog,
					string.format("assign(%s)  ->  OK  [history=%d]", result.jobName, result.historySize))
			else
				cmdOut.Text = "execute()  ->  BLOCKED\nValidation failed — command not created"
				table.insert(clientLog, string.format("assign(%s)  ->  BLOCKED", result.jobName))
			end
		elseif result.action == "undo" then
			if result.success then
				cmdOut.Text = string.format(
					"CommandInvoker:undo()  ->  OK\nhistory size now: %d",
					result.historySize
				)
				table.insert(clientLog,
					string.format("undo()  ->  OK  [history=%d]", result.historySize))
				resetSteps()
			else
				cmdOut.Text = "CommandInvoker:undo()  ->  nothing to undo"
				table.insert(clientLog, "undo()  ->  empty")
			end
		end
		refreshHistory()
	end)

	setCanvas(y + 10)
end

-- ── NPC Simulation ───────────────────────────────────────────
demos["NPC Simulation"] = function()
	if simDemoConnection then
		simDemoConnection:Disconnect()
		simDemoConnection = nil
	end

	local simControlRE = ReplicatedStorage:WaitForChild("SimControlRE")
	local simSpawnRE   = ReplicatedStorage:WaitForChild("SimSpawnRE")
	local simStatsRE   = ReplicatedStorage:WaitForChild("SimStatsRE")

	local y = drawHeader(
		"NPC Simulation",
		"Simulation",
		"Multi-agent city simulation. Real Humanoid NPCs navigate via PathfindingService. "
		.. "Agents run in parallel task.spawn workers each tick. "
		.. "Observer pattern streams stats to this panel. Commands support undo."
	)

	-- ── Riot status strip
	local riotStrip = Instance.new("Frame")
	riotStrip.Size              = UDim2.new(0, PW - 10, 0, 26)
	riotStrip.Position          = UDim2.new(0, 10, 0, y)
	riotStrip.BackgroundColor3  = C.green
	riotStrip.BorderSizePixel   = 0
	riotStrip.Parent            = contentScroll
	local riotLbl = Instance.new("TextLabel")
	riotLbl.Size                = UDim2.new(1, -10, 1, 0)
	riotLbl.Position            = UDim2.new(0, 8, 0, 0)
	riotLbl.BackgroundTransparency = 1
	riotLbl.TextColor3          = Color3.new(1, 1, 1)
	riotLbl.Font                = Enum.Font.GothamBold
	riotLbl.TextSize            = 12
	riotLbl.TextXAlignment      = Enum.TextXAlignment.Left
	riotLbl.Text                = "Status: CALM"
	riotLbl.Parent              = riotStrip
	y = y + 32

	-- ── Stat grid (2 × 3)
	local statDefs = {
		{ key = "tick",       lbl = "Tick #"       },
		{ key = "citizens",   lbl = "Citizens"      },
		{ key = "officers",   lbl = "Officers"      },
		{ key = "panicking",  lbl = "Panicking"     },
		{ key = "responding", lbl = "Responding"    },
	}
	local statVals = {}
	local cellW, cellH = math.floor((PW - 10) / 3), 46
	for i, def in ipairs(statDefs) do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		local cell = Instance.new("Frame")
		cell.Size             = UDim2.new(0, cellW - 4, 0, cellH)
		cell.Position         = UDim2.new(0, 10 + col * cellW, 0, y + row * (cellH + 4))
		cell.BackgroundColor3 = C.card
		cell.BorderSizePixel  = 0
		cell.Parent           = contentScroll
		makeLabel(cell, def.lbl,
			UDim2.new(1, -6, 0, 16), UDim2.new(0, 6, 0, 4),
			C.textDim, 10, Enum.Font.Gotham)
		local val = makeLabel(cell, "—",
			UDim2.new(1, -6, 0, 22), UDim2.new(0, 6, 0, 18),
			C.accent, 16, Enum.Font.GothamBold)
		statVals[def.key] = val
	end
	local rowCount = math.ceil(#statDefs / 3)
	y = y + rowCount * (cellH + 4) + 6

	-- ── Intensity bar
	makeLabel(contentScroll, "Panic intensity",
		UDim2.new(0, PW, 0, 14), UDim2.new(0, 10, 0, y), C.textDim, 10)
	y = y + 14
	local barBg = Instance.new("Frame")
	barBg.Size             = UDim2.new(0, PW - 10, 0, 10)
	barBg.Position         = UDim2.new(0, 10, 0, y)
	barBg.BackgroundColor3 = C.border
	barBg.BorderSizePixel  = 0
	barBg.Parent           = contentScroll
	local barFill = Instance.new("Frame")
	barFill.Size             = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = C.green
	barFill.BorderSizePixel  = 0
	barFill.Parent           = barBg
	y = y + 16

	makeSeparator(contentScroll, y)
	y = y + 10

	-- ── Control buttons row
	local ctrlDefs = {
		{ lbl = "▶ Start",   action = "start",  col = C.green       },
		{ lbl = "⏸ Pause",  action = "pause",  col = C.accentDim   },
		{ lbl = "↺ Reset",   action = "reset",  col = C.red         },
		{ lbl = "⎌ Undo",    action = "undo",   col = C.amber       },
		{ lbl = "⚡ 2× Fast", action = "fast",   col = C.accentDim  },
		{ lbl = "⏱ Normal",  action = "normal", col = C.accentDim  },
	}
	local btnW = math.floor((PW - 10) / 3) - 4
	for i, def in ipairs(ctrlDefs) do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		local b = makeBtn(contentScroll, def.lbl,
			UDim2.new(0, btnW, 0, 28),
			UDim2.new(0, 10 + col * (btnW + 6), 0, y + row * 32),
			def.col)
		local act = def.action
		b.MouseButton1Click:Connect(function()
			simControlRE:FireServer(act)
		end)
	end
	y = y + 68

	makeSeparator(contentScroll, y)
	y = y + 10

	-- ── Spawn buttons
	makeLabel(contentScroll, "Spawn NPC into running simulation:",
		UDim2.new(0, PW, 0, 14), UDim2.new(0, 10, 0, y), C.textDim, 10)
	y = y + 16

	local spawnDefs = {
		{ lbl = "+ Spawn Citizen",  type = "Citizen",  col = C.green     },
		{ lbl = "+ Spawn Officer",  type = "Officer",  col = C.accentDim },
	}
	local spawnW = math.floor((PW - 22) / 2)
	for i, def in ipairs(spawnDefs) do
		local b = makeBtn(contentScroll, def.lbl,
			UDim2.new(0, spawnW, 0, 30),
			UDim2.new(0, 10 + (i - 1) * (spawnW + 6), 0, y),
			def.col)
		local agentType = def.type
		b.MouseButton1Click:Connect(function()
			simSpawnRE:FireServer(agentType)
		end)
	end
	y = y + 36

	makeSeparator(contentScroll, y)
	y = y + 10

	-- ── Event log
	makeLabel(contentScroll, "Live event log:",
		UDim2.new(0, PW, 0, 14), UDim2.new(0, 10, 0, y), C.textDim, 10)
	y = y + 16
	local logOut = makeOutput(contentScroll,
		UDim2.new(0, PW - 10, 0, 120),
		UDim2.new(0, 10, 0, y))
	y = y + 126

	local logLines = {}
	local lastRiot = nil
	local function appendLog(msg)
		table.insert(logLines, 1, msg)
		if #logLines > 12 then table.remove(logLines) end
		logOut.Text = table.concat(logLines, "\n")
	end

	-- ── Subscribe to SimStatsRE
	simDemoConnection = simStatsRE.OnClientEvent:Connect(function(stats)
		if not stats then return end

		statVals["tick"].Text       = tostring(stats.tick or 0)
		statVals["citizens"].Text   = tostring(stats.citizens or 0)
		statVals["officers"].Text   = tostring(stats.officers or 0)
		statVals["panicking"].Text  = tostring(stats.panicking or 0)
		statVals["responding"].Text = tostring(stats.responding or 0)

		-- Intensity bar
		local intensity = (stats.citizens and stats.citizens > 0)
			and math.clamp((stats.panicking or 0) / stats.citizens, 0, 1)
			or 0
		barFill.Size             = UDim2.new(intensity, 0, 1, 0)
		barFill.BackgroundColor3 = intensity > 0.4 and C.red or C.green

		-- Riot strip
		if stats.riotActive ~= lastRiot then
			lastRiot = stats.riotActive
			riotStrip.BackgroundColor3 = stats.riotActive and C.red or C.green
			riotLbl.Text = stats.riotActive and "Status: RIOT ACTIVE" or "Status: CALM"
			appendLog(stats.riotActive and "[RIOT] Riot started — officers responding!"
				or "[calm] Riot ended.")
		end
	end)

	setCanvas(y + 10)
end

-- ──────────────────────────────────────────────────────────────
-- Sidebar builder
-- ──────────────────────────────────────────────────────────────
local patternList = {
	{
		category = "Creational",
		patterns = { "Factory Method", "Abstract Factory", "Builder", "Singleton" },
	},
	{
		category = "Structural",
		patterns = { "Decorator", "Adapter", "Facade", "Proxy", "Bridge" },
	},
	{
		category = "Behavioral",
		patterns = { "Strategy", "State", "Command", "Observer", "Template Method", "Chain of Responsibility" },
	},
	{
		category = "Live Use Case",
		patterns = { "Job Assignment" },
	},
	{
		category = "Simulation",
		patterns = { "NPC Simulation" },
	},
}

local activeBtn

local function setActive(btn)
	if activeBtn then
		activeBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		activeBtn.TextColor3 = C.text
	end
	activeBtn = btn
	btn.BackgroundColor3 = C.accent
	btn.TextColor3 = Color3.new(1, 1, 1)
end

for _, group in ipairs(patternList) do
	-- category header
	local catHeader = Instance.new("TextLabel")
	catHeader.LayoutOrder = 0
	catHeader.Size = UDim2.new(1, 0, 0, 28)
	catHeader.BackgroundColor3 = CATEGORY_COLOR[group.category]
	catHeader.BorderSizePixel = 0
	catHeader.TextColor3 = Color3.new(1, 1, 1)
	catHeader.TextSize = 10
	catHeader.Font = Enum.Font.GothamBold
	catHeader.Text = group.category:upper()
	catHeader.TextXAlignment = Enum.TextXAlignment.Left
	local catPad = Instance.new("UIPadding")
	catPad.PaddingLeft = UDim.new(0, 10)
	catPad.Parent = catHeader
	catHeader.Parent = sideScroll

	for _, patName in ipairs(group.patterns) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		btn.BorderSizePixel = 0
		btn.TextColor3 = C.text
		btn.TextSize = 11
		btn.Font = Enum.Font.Gotham
		btn.Text = patName
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.AutoButtonColor = false
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 14)
		pad.Parent = btn
		btn.Parent = sideScroll

		btn.MouseEnter:Connect(function()
			if btn ~= activeBtn then
				btn.BackgroundColor3 = C.btnHover
			end
		end)
		btn.MouseLeave:Connect(function()
			if btn ~= activeBtn then
				btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
			end
		end)
		btn.MouseButton1Click:Connect(function()
			setActive(btn)
			if demos[patName] then
				demos[patName]()
			end
		end)
	end
end

-- ──────────────────────────────────────────────────────────────
-- Toggle (P key)
-- ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.P then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

-- Load first pattern on startup
task.defer(function()
	local firstBtn = sideScroll:FindFirstChildOfClass("TextButton")
	if firstBtn then
		firstBtn.MouseButton1Click:Fire()
	end
end)

print("Patterns UI loaded  |  P to toggle")
