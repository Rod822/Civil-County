local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayersDataService = require(ServerScriptService.Services.PlayersDataService)
local BoatTest = require(ReplicatedStorage.Packages.BoatTest)
local PlayerModule = require(script.Parent.player)
local gotPlayer = PlayerModule()

local this = BoatTest.this

return {
	["OnPlayerAdded creates profile"] = function(skip)
		if gotPlayer then
			local p = gotPlayer
			PlayersDataService:OnPlayerAdded(p)

			this(PlayersDataService._profiles[p.UserId]).isA("table")
		else
			skip("No players in the game to test with.")
		end
	end,
	["adds money after OnPlayerAdded"] = function(skip)
		if gotPlayer then
			local p = gotPlayer
			PlayersDataService:OnPlayerAdded(p)
			local before = PlayersDataService._profiles[p.UserId].persistent.Money
			PlayersDataService:AddMoney(p, 500)
			local after = PlayersDataService._profiles[p.UserId].persistent.Money
			this(before + 500).will.equal(after)
		else
			skip("No players in the game to test with.")
		end
	end,
}
