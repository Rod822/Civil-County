local DataStoreService = game:GetService("DataStoreService")
local DS = DataStoreService:GetDataStore("PlayerData")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classes = ReplicatedStorage:WaitForChild("Classes")

local Profile = require(Classes.Profile)

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

	local profile = Profile.new(player.UserId, LoadedData)
	self._profiles[player.UserId] = profile

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

	local PersistentData = profile.persistent
	local success, err = pcall(function()
		DS:SetAsync(tostring(player.UserId), PersistentData)
	end)
	if not success then
		warn("Failed to save data for player: " .. player.UserId .. " Error: " .. err)
	end
	self._profiles[player.UserId] = nil
end

function PlayersDataService:AddMoney(player: Player, amount: number)
	local profile = self._profiles[player.UserId]
	if not profile then
		return
	end
	profile.persistent.Money = profile.persistent.Money + amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Money = leaderstats:FindFirstChild("Money")
		if Money then
			Money.Value = profile.persistent.Money
		end
	end
	print(self._profiles)
end

function PlayersDataService:RemoveMoney(player: Player, amount: number): boolean?
	local profile = self._profiles[player.UserId]
	if not profile then
		return nil -- Profile not found
	end
	if profile.persistent.Money < amount then
		return false -- Not enough money
	end
	profile.persistent.Money = profile.persistent.Money - amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local Money = leaderstats:FindFirstChild("Money")
		if Money then
			Money.Value = profile.persistent.Money
		end
	end
	return true -- Successfully removed money
end

function PlayersDataService:SetData(player: Player, key: string, value: any)
	local profile = self._profiles[player.UserId]
	if not profile then
		warn("Profile not found for" .. player.Name)
		return
	end

	if profile.persistent[key] ~= nil then
		profile.persistent[key] = value
		return
	end
	if profile.session[key] ~= nil then
		profile.session[key] = value
		return
	end
	warn("[PlayersDataService] Unknown data key " .. key)
end

return PlayersDataService
