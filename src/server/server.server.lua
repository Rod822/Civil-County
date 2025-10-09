local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayersDataService = require(ServerScriptService.Services.PlayersDataService)

Players.PlayerAdded:Connect(function(player)
	PlayersDataService:OnPlayerAdded(player)
	PlayersDataService:AddMoney(player, 200)
	local RemoveMoney = PlayersDataService:RemoveMoney(player, 100)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayersDataService:OnPlayerRemoving(player)
end)

coroutine.wrap(function() -- for testing purposes
	while true do
		task.wait(60)
		for _, player in pairs(Players:GetPlayers()) do
			PlayersDataService:AddMoney(player, 200)

			local RemoveMoney = PlayersDataService:RemoveMoney(player, 100)
			if not RemoveMoney then
				print("Player " .. player.Name .. " does not have enough money to remove 100")
			end
		end
	end
end)()
