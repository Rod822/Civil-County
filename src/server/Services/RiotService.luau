local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Zone = require(Packages:WaitForChild("Zone"))

local RiotManager = {}
RiotManager.__index = RiotManager

local function updateRiotState(self)
	local totalPlayers = #Players:GetPlayers()

	local inZoneCount = 0
	for _ in pairs(self.playersInZone) do
		inZoneCount += 1
	end

	local requiredCount = math.max(self.minPlayers, math.ceil(totalPlayers * self.minFraction))

	if self.textLabel then
		self.textLabel.Text = inZoneCount .. "/" .. requiredCount
	end

	if totalPlayers == 0 then
		self.riotActive = false
		return
	end

	local shouldRiot = inZoneCount >= requiredCount

	if shouldRiot and not self.riotActive then
		self.riotActive = true
		self.OnRiotStarted:Fire(inZoneCount)
	elseif not shouldRiot and self.riotActive then
		self.riotActive = false
	end
end

local manager = setmetatable({
	minFraction = 0.5,
	minPlayers = 2,
	zone = nil,
	textLabel = nil,
	playersInZone = {},
	riotActive = false,
	OnRiotStarted = Instance.new("BindableEvent"),
}, RiotManager)

function RiotManager:Init(zonePart)
	if self.zone then
		return
	end

	local attachment = zonePart:FindFirstChild("Attachment")
	if attachment then
		local billboard = attachment:FindFirstChild("BillboardGui")
		if billboard then
			self.textLabel = billboard:FindFirstChild("TextLabel")
		end
	end

	self.zone = Zone.new(zonePart)

	self.zone.playerEntered:Connect(function(player)
		if player and player:IsA("Player") then
			self.playersInZone[player] = true
			updateRiotState(self)
		end
	end)

	self.zone.playerExited:Connect(function(player)
		if player and player:IsA("Player") then
			self.playersInZone[player] = nil
			updateRiotState(self)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if self.playersInZone[player] then
			self.playersInZone[player] = nil
			updateRiotState(self)
		end
	end)

	updateRiotState(self)
end

function RiotManager:IsRiotActive()
	return self.riotActive
end

return manager
