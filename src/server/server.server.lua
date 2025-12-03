local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JobService = require(ServerScriptService.Services.JobService)
local PlayersDataService = require(ServerScriptService.Services.PlayersDataService)
local NotificationService = require(ServerScriptService.Services.NotificationService)
local AutocompleteSearchService = require(ReplicatedStorage.Services:WaitForChild("AutocompleteSearchService"))

--AutocompleteSearchService.InitTree(game.Workspace.Name, game.Workspace) -- for testing purposes
--print(AutocompleteSearchService.Search("Workspace", "P")) -- for testing purposes

Players.PlayerAdded:Connect(function(player)
	PlayersDataService:OnPlayerAdded(player)

	JobService:assignJob(player, "Police") -- for testing purposes
	PlayersDataService:AddMoney(player, 200) -- for testing purposes
	JobService:paycheck(player) -- for testing purposes
	local RemoveMoney = PlayersDataService:RemoveMoney(player, 100) -- for testing purposes
	if not RemoveMoney then
		print("Player " .. player.Name .. " does not have enough money to remove 100")
	end

	NotificationService:SendTo(player, "Promotion to Sergeant!", "Police")
	NotificationService:Broadcast("Server restart in 5 minutes", "Server")
	NotificationService:SendToJob("Police", "Fire reported at warehouse", "Dispatch")
	NotificationService:Paycheck(player, 250, 50, 300, "Police")

	task.wait(5) -- for testing purposes
	JobService:fireFromJob(player, "Police") -- for testing purposes
end)

Players.PlayerRemoving:Connect(function(player)
	PlayersDataService:OnPlayerRemoving(player)
end)

coroutine.wrap(function()
	while true do
		task.wait(60)
		for _, player in pairs(Players:GetPlayers()) do
			JobService:paycheck(player)
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
