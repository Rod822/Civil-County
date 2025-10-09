local DataStoreService = game:GetService("DataStoreService")
local DS = DataStoreService:GetDataStore("PlayerData")

local PlayersDataService = {}
PlayersDataService.__index = PlayersDataService

PlayersDataService._profiles = {}

function PlayersDataService:OnPlayerAdded(player: Player)
	local LoadedData: { Money: number }? = nil
	local success, result = pcall(function()
		return DS:GetAsync(tostring(player.UserId))
	end)

	if success and result and typeof(result) == "table" and typeof(result.Money) == "number" then
		LoadedData = result
	else
		LoadedData = { Money = 200 }
	end

	self._profiles[player.UserId] = setmetatable(LoadedData, PlayersDataService)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Money = Instance.new("IntValue")
	Money.Name = "Money"
	Money.Value = LoadedData.Money
	Money.Parent = leaderstats
end

function PlayersDataService:OnPlayerRemoving(player: Player)
	local profile = self._profiles[player.UserId]
	if not profile then
		return
	end

	local success, err = pcall(function()
		DS:SetAsync(tostring(player.UserId), {
			Money = profile.Money,
		})
	end)
	if not success then
		warn("Failed to save data for player: " .. player.UserId .. " Error: " .. err .. " Data: " .. profile.Money)
	end
	self._profiles[player.UserId] = nil
end

function PlayersDataService:AddMoney(player: Player, amount: number)
	local profile = self._profiles[player.UserId]
	if not profile then
		return
	end
	profile.Money = profile.Money + amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Money = leaderstats:FindFirstChild("Money")
		if Money then
			Money.Value = profile.Money
		end
	end
end

function PlayersDataService:RemoveMoney(player: Player, amount: number): boolean?
	local profile = self._profiles[player.UserId]
	if not profile then
		return nil -- Profile not found
	end
	if profile.Money < amount then
		return false -- Not enough money
	end
	profile.Money = profile.Money - amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Money = leaderstats:FindFirstChild("Money")
		if Money then
			Money.Value = profile.Money
		end
	end
	return true -- Successfully removed money
end

return PlayersDataService
