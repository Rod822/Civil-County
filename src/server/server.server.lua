local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Створення необхідних RemoteEvents в ReplicatedStorage
if not ReplicatedStorage:FindFirstChild("NotifyRE") then
	local notifyRE = Instance.new("RemoteEvent")
	notifyRE.Name = "NotifyRE"
	notifyRE.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("JobServiseRE") then
	local jobRE = Instance.new("RemoteEvent")
	jobRE.Name = "JobServiseRE"
	jobRE.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("JobAssignDemoRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "JobAssignDemoRE"
	re.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("JobUndoRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "JobUndoRE"
	re.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("JobAssignResultRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "JobAssignResultRE"
	re.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("SimControlRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "SimControlRE"
	re.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("SimSpawnRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "SimSpawnRE"
	re.Parent = ReplicatedStorage
end

if not ReplicatedStorage:FindFirstChild("SimStatsRE") then
	local re = Instance.new("RemoteEvent")
	re.Name = "SimStatsRE"
	re.Parent = ReplicatedStorage
end

local JobServiceModule = require(ServerScriptService.Services.JobService)
local PlayersDataService = require(ServerScriptService.Services.PlayersDataService)
local NotificationService = require(ServerScriptService.Services.NotificationService)
local AutocompleteSearchService = require(ReplicatedStorage.Services:WaitForChild("AutocompleteSearchService"))
local EventSystem = require(ReplicatedStorage.Classes.EventSystem)

-- Ініціалізація системи подій
_G.EventSystem = EventSystem.new()

-- Ініціалізація сервісів з dependency injection
_G.JobService = JobServiceModule.new(PlayersDataService, NotificationService)

local jobAssignDemoRE  = ReplicatedStorage:WaitForChild("JobAssignDemoRE")
local jobUndoRE        = ReplicatedStorage:WaitForChild("JobUndoRE")
local jobAssignResultRE = ReplicatedStorage:WaitForChild("JobAssignResultRE")

jobAssignDemoRE.OnServerEvent:Connect(function(player, jobName)
	if typeof(jobName) ~= "string" then return end
	local result = _G.JobService:assignJobValidated(player, jobName)
	jobAssignResultRE:FireClient(player, result)
end)

jobUndoRE.OnServerEvent:Connect(function(player)
	local result = _G.JobService:undoLastAssignment(player)
	jobAssignResultRE:FireClient(player, result)
end)

--AutocompleteSearchService.InitTree(game.Workspace.Name, game.Workspace) -- for testing purposes
--print(AutocompleteSearchService.Search("Workspace", "P")) -- for testing purposes

Players.PlayerAdded:Connect(function(player)
	PlayersDataService:OnPlayerAdded(player)

	_G.JobService:assignJob(player, "Police") -- for testing purposes
	PlayersDataService:AddMoney(player, 200) -- for testing purposes
	_G.JobService:paycheck(player) -- for testing purposes
	local RemoveMoney = PlayersDataService:RemoveMoney(player, 100) -- for testing purposes
	if not RemoveMoney then
		print("Player " .. player.Name .. " does not have enough money to remove 100")
	end

	NotificationService:SendTo(player, "Promotion to Sergeant!", "Police")
	NotificationService:Broadcast("Server restart in 5 minutes", "Server")
	NotificationService:SendToJob("Police", "Fire reported at warehouse", "Dispatch")
	NotificationService:Paycheck(player, 250, 50, 300, "Police")

	task.wait(5) -- for testing purposes
	_G.JobService:fireFromJob(player) -- for testing purposes
end)

Players.PlayerRemoving:Connect(function(player)
	PlayersDataService:OnPlayerRemoving(player)
	if _G.JobService and _G.JobService._invokers then
		_G.JobService._invokers[player.UserId] = nil
	end
end)

coroutine.wrap(function()
	while true do
		task.wait(60)
		for _, player in pairs(Players:GetPlayers()) do
			_G.JobService:paycheck(player)
		end
	end
end)()

-- RIOT
local ServerScriptService = game:GetService("ServerScriptService")
local RiotManager = require(ServerScriptService.Services:WaitForChild("RiotManagerService"))

local riotZone = workspace:WaitForChild("RiotZone")
RiotManager:Init(riotZone)

RiotManager.OnRiotStarted.Event:Connect(function(inZoneCount, totalPlayers)
	print("RIOT STARTED", inZoneCount, totalPlayers)
end)
