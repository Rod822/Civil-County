local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JobConfig       = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("JobConfig"))
local EventSystem     = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("EventSystem"))
local ValidationChain = require(ReplicatedStorage:WaitForChild("Patterns").Behavioral.ValidationChain)
local GameCommand     = require(ReplicatedStorage:WaitForChild("Patterns").Behavioral.GameCommand)

local function getRemote(): RemoteEvent
	local re = ReplicatedStorage:FindFirstChild("JobServiseRE")
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name = "JobServiseRE"
		re.Parent = ReplicatedStorage
	end
	return re :: RemoteEvent
end

local JobService = {}
JobService.__index = JobService

function JobService.new(playersDataService, notificationsService)
	local self = setmetatable({}, JobService)
	self._playersDataService = playersDataService
	self._notificationsService = notificationsService
	self._eventSystem = EventSystem.new()
	self._jobs = JobConfig
	self._invokers = {}

	-- Підписка на події
	self._eventSystem:Connect("PlayerJoined", function(player)
		getRemote():FireClient(player, self._jobs)
	end)

	self._eventSystem:Connect("PlayerCharacterAdded", function(player)
		self:_giveServiceTools(player)
	end)

	return self
end
getRemote().OnServerEvent:Connect(function(player: Player, jobName: string)
	local success = _G.JobService:assignJob(player, jobName)
	if not success then
		warn("Failed to assign job " .. jobName .. " to player " .. player.Name)
	end
end)

function JobService:assignJob(player: Player, jobName: string)
	local job = self._jobs[jobName]
	if not job then
		warn("Job " .. jobName .. " does not exist.")
		return false
	end

	local team = Teams:FindFirstChild(job.teamName)
	if not team then
		warn("Team " .. job.teamName .. " does not exist.")
		return false
	end
	self:fireFromJob(player)
	player.Team = team
	self:_giveServiceTools(player)
	self._playersDataService:SetData(player, "job", jobName)
	self._notificationsService:SendTo(player, "You have been assigned to the " .. jobName .. " job.")
	return true
end

function JobService:fireFromJob(player: Player)
	local profile = self._playersDataService._profiles[player.UserId]
	if not profile then
		warn("Profile not found for player: " .. player.Name)
		return false
	end

	local jobName = profile.session.job
	if not jobName then
		return false
	end

	local civilianJob = self._jobs["Civilian"]
	if not civilianJob then
		warn("Civilian job does not exist.")
		return false
	end

	local civilianTeam = Teams:FindFirstChild(civilianJob.teamName)
	if not civilianTeam then
		warn("Civilian team does not exist.")
		return false
	end

	if player.Team == civilianTeam then
		return false
	end

	self:_removeServiceTools(player)
	player.Team = civilianTeam
	self._playersDataService:SetData(player, "job", "Civilian")
	self._notificationsService:SendTo(player, "You have been fired from the " .. jobName .. " job.")
	return true
end

function JobService:paycheck(player: Player)
	local profile = self._playersDataService._profiles[player.UserId]
	if not profile then
		warn("Profile not found for player: " .. player.Name)
		return
	end

	local jobName = profile.session.job
	local job = self._jobs[jobName]
	if not job then
		warn("Player " .. player.Name .. " has no valid job for paycheck.")
		return
	end

	local bonus = profile.session.paycheckBonus or 0
	local totalPay = job.basePay + bonus
	bonus = 0
	self._playersDataService:AddMoney(player, totalPay)
	self._notificationsService:Paycheck(player, job.basePay, bonus, totalPay, jobName)
end

function JobService:_giveServiceTools(player)
	local toolsFolder = player.Team
	for _, item in pairs(toolsFolder:GetChildren()) do
		if item:IsA("Tool") then
			local toolClone = item:Clone()
			toolClone.Parent = player.Backpack
		end
	end
end

function JobService:_removeServiceTools(player)
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

-- Runs the full ValidationChain → AssignJobCommand → CommandInvoker pipeline.
-- Returns a result table consumed by the live demo RemoteEvent.
function JobService:assignJobValidated(player: Player, jobName: string)
	local data = { player = player, jobName = jobName }

	local validatorDefs = {
		{ name = "PlayerValidator",   v = ValidationChain.PlayerValidator.new() },
		{ name = "JobValidator",      v = ValidationChain.JobValidator.new() },
		{ name = "LevelValidator",    v = ValidationChain.LevelValidator.new() },
		{ name = "LocationValidator", v = ValidationChain.LocationValidator.new() },
	}

	local steps = {}
	local chainPassed = true

	for _, def in ipairs(validatorDefs) do
		if not chainPassed then
			table.insert(steps, { name = def.name, passed = nil, msg = "skipped" })
		else
			local ok, msg = def.v:validate(data)
			table.insert(steps, { name = def.name, passed = ok, msg = msg })
			if not ok then
				chainPassed = false
			end
		end
	end

	local existingInvoker = self._invokers[player.UserId]
	local hSize = existingInvoker and existingInvoker:getHistorySize() or 0

	if not chainPassed then
		return { action = "assign", steps = steps, success = false, jobName = jobName, historySize = hSize }
	end

	if not existingInvoker then
		self._invokers[player.UserId] = GameCommand.CommandInvoker.new(10)
	end
	local invoker = self._invokers[player.UserId]

	local cmd = GameCommand.AssignJobCommand.new(self, player, jobName)
	local success = invoker:execute(cmd)

	return { action = "assign", steps = steps, success = success, jobName = jobName, historySize = invoker:getHistorySize() }
end

function JobService:undoLastAssignment(player: Player)
	local invoker = self._invokers[player.UserId]
	if not invoker or invoker:getHistorySize() == 0 then
		return { action = "undo", success = false, historySize = 0 }
	end
	local ok = invoker:undo()
	return { action = "undo", success = ok, historySize = invoker:getHistorySize() }
end

return JobService
