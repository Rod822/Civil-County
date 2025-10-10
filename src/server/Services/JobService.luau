local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayersDataService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("PlayersDataService"))

local JobServise = {}
JobServise.__index = JobServise

JobServise.Jobs = {
	Police = {
		teamName = "Police",
		basePay = 250,
	},
	FireService = {
		teamName = "Fire Service",
		basePay = 230,
	},
	Paramedic = {
		teamName = "Paramedic",
		basePay = 220,
	},
	Civilian = {
		teamName = "Civilian",
		basePay = 50,
	},
}

local function giveServiceTools(player)
	local toolsFolder = player.Team
	for _, item in pairs(toolsFolder:GetChildren()) do
		if item:IsA("Tool") then
			local toolClone = item:Clone()
			toolClone.Parent = player.Backpack
		end
	end
end

local function removeServiceTools(player)
	for _, item in pairs(player.Backpack:GetChildren()) do
		if item:IsA("Tool") then
			for _, teamItem in pairs(player.Team:GetChildren()) do
				if teamItem:IsA("Tool") and teamItem.Name == item.Name then
					item:Destroy()
					break
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		giveServiceTools(player)
	end)
end)

function JobServise:assignJob(player: Player, jobName: string)
	local job = self.Jobs[jobName]
	if not job then
		warn("Job " .. jobName .. " does not exist.")
		return false
	end

	local team = Teams:FindFirstChild(job.teamName)
	if not team then
		warn("Team " .. job.teamName .. " does not exist.")
		return false
	end

	player.Team = team
	giveServiceTools(player)
	PlayersDataService:SetData(player, "job", jobName)
	return true
end

function JobServise:fireFromJob(player: Player, jobName: string)
	local profile = PlayersDataService._profiles[player.UserId]
	if not profile then
		warn("Profile not found for player: " .. player.Name)
		return false
	end

	if profile.session.job ~= jobName then
		warn("Player " .. player.Name .. " is not in job " .. jobName)
		return false
	end

	local civilianJob = self.Jobs["Civilian"]
	if not civilianJob then
		warn("Civilian job does not exist.")
		return false
	end

	local civilianTeam = Teams:FindFirstChild(civilianJob.teamName)
	if not civilianTeam then
		warn("Civilian team does not exist.")
		return false
	end

	removeServiceTools(player)
	player.Team = civilianTeam
	PlayersDataService:SetData(player, "job", "Civilian")
	return true
end

function JobServise:paycheck(player: Player)
	local profile = PlayersDataService._profiles[player.UserId]
	if not profile then
		warn("Profile not found for player: " .. player.Name)
		return
	end

	local jobName = profile.session.job
	local job = self.Jobs[jobName]
	if not job then
		warn("Player " .. player.Name .. " has no valid job for paycheck.")
		return
	end

	local bonus = profile.session.paycheckBonus or 0
	local totalPay = job.basePay + bonus
	bonus = 0
	PlayersDataService:AddMoney(player, totalPay)
end

return JobServise
