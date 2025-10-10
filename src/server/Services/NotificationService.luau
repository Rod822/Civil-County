--!strict
-- NotificationService: глобальные/личные сообщения + пейчек
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayersDataService = require(ServerScriptService.Services.PlayersDataService)

local NotificationService = {}
NotificationService.__index = NotificationService

local DEFAULT_DURATION = 5

local function getRemote(): RemoteEvent
	local re = ReplicatedStorage:FindFirstChild("NotifyRE")
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name = "NotifyRE"
		re.Parent = ReplicatedStorage
	end
	return re :: RemoteEvent
end

local function dispatchTo(player: Player, payload: { [string]: any })
	getRemote():FireClient(player, payload)
end

function NotificationService:Broadcast(text: string, title: string?, duration: number?)
	for _, plr in ipairs(Players:GetPlayers()) do
		dispatchTo(plr, {
			title = title or "Notice",
			text = text,
			duration = duration or DEFAULT_DURATION,
			kind = "broadcast",
		})
	end
end

function NotificationService:SendTo(player: Player, text: string, title: string?, duration: number?)
	dispatchTo(player, {
		title = title or "Message",
		text = text,
		duration = duration or DEFAULT_DURATION,
		kind = "direct",
	})
end

function NotificationService:SendToJob(jobName: string, text: string, title: string?, duration: number?)
	for _, plr in ipairs(Players:GetPlayers()) do
		local profile = PlayersDataService._profiles[plr.UserId]
		if profile and profile.session.job == jobName then
			dispatchTo(plr, {
				title = title or jobName,
				text = text,
				duration = duration or DEFAULT_DURATION,
				kind = "job",
			})
		end
	end
end

function NotificationService:Paycheck(player: Player, base: number, bonus: number, total: number, jobName: string)
	local title = "Paycheck"
	local parts = {}
	table.insert(parts, ("Job: %s"):format(jobName))
	table.insert(parts, ("Base: $%d"):format(base))
	if (bonus or 0) > 0 then
		table.insert(parts, ("Bonus: $%d"):format(bonus))
	end
	table.insert(parts, ("Total: $%d"):format(total))
	self:SendTo(player, table.concat(parts, " | "), title, 6)
end

return NotificationService
