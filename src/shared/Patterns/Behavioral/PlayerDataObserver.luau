--[[
	@class PlayerDataObserver
	@desc Observer pattern for reactive data changes
	@pattern Observer
	
	Object maintains a list of dependents (observers) that get notified
	of state changes. Enables loose coupling between objects.
]]

local PlayerDataObserver = {}

--[[
	@class IObserver
	@desc Interface for observers
]]
local IObserver = {}
IObserver.__index = IObserver

function IObserver.new()
	return setmetatable({}, IObserver)
end

function IObserver:onBalanceChanged(_newBalance: number, _oldBalance: number)
	error("onBalanceChanged must be implemented")
end

function IObserver:onJobChanged(_newJob: string, _oldJob: string)
	error("onJobChanged must be implemented")
end

function IObserver:onLevelUp(_newLevel: number)
	error("onLevelUp must be implemented")
end

function IObserver:getName(): string
	error("getName must be implemented")
end

--[[
	@class NotificationObserver
	@desc Observer that sends notifications on data changes
]]
local NotificationObserver = setmetatable({}, IObserver)
NotificationObserver.__index = NotificationObserver

function NotificationObserver.new(notificationService: any, player: Player?): NotificationObserver
	local self = setmetatable({}, NotificationObserver)
	self.notificationService = notificationService
	self.player = player
	return self
end

function NotificationObserver:onBalanceChanged(newBalance: number, oldBalance: number)
	local change = newBalance - oldBalance
	local message = ""

	if change > 0 then
		message = "You gained " .. change .. " currency!"
	elseif change < 0 then
		message = "You spent " .. -change .. " currency."
	else
		return
	end

	if self.player then
		self.notificationService:SendTo(self.player, "Balance Update", message)
	end
end

function NotificationObserver:onJobChanged(newJob: string, _oldJob: string)
	if self.player then
		self.notificationService:SendTo(self.player, "Job Change", "Your job is now: " .. newJob)
	end
end

function NotificationObserver:onLevelUp(newLevel: number)
	if self.player then
		self.notificationService:SendTo(self.player, "Level Up!", "You reached level " .. newLevel)
	end
end

function NotificationObserver:getName(): string
	return "NotificationObserver"
end

--[[
	@class LoggingObserver
	@desc Observer that logs data changes
]]
local LoggingObserver = setmetatable({}, IObserver)
LoggingObserver.__index = LoggingObserver

function LoggingObserver.new(): LoggingObserver
	local self = setmetatable({}, LoggingObserver)
	self.logs = {}
	return self
end

function LoggingObserver:onBalanceChanged(newBalance: number, oldBalance: number)
	local change = newBalance - oldBalance
	local logEntry = "Balance changed: " .. oldBalance .. " -> " .. newBalance .. " (change: " .. change .. ")"
	table.insert(self.logs, logEntry)
	print("[Log] " .. logEntry)
end

function LoggingObserver:onJobChanged(newJob: string, oldJob: string)
	local logEntry = "Job changed: " .. oldJob .. " -> " .. newJob
	table.insert(self.logs, logEntry)
	print("[Log] " .. logEntry)
end

function LoggingObserver:onLevelUp(newLevel: number)
	local logEntry = "Level up: " .. newLevel
	table.insert(self.logs, logEntry)
	print("[Log] " .. logEntry)
end

function LoggingObserver:getName(): string
	return "LoggingObserver"
end

function LoggingObserver:getLogs(): { string }
	return self.logs
end

--[[
	@class AuditObserver
	@desc Observer that tracks all changes for audit purposes
]]
local AuditObserver = setmetatable({}, IObserver)
AuditObserver.__index = AuditObserver

function AuditObserver.new(): AuditObserver
	local self = setmetatable({}, AuditObserver)
	self.auditTrail = {}
	return self
end

function AuditObserver:onBalanceChanged(newBalance: number, oldBalance: number)
	table.insert(self.auditTrail, {
		event = "BalanceChanged",
		timestamp = tick(),
		oldValue = oldBalance,
		newValue = newBalance,
	})
end

function AuditObserver:onJobChanged(newJob: string, oldJob: string)
	table.insert(self.auditTrail, {
		event = "JobChanged",
		timestamp = tick(),
		oldValue = oldJob,
		newValue = newJob,
	})
end

function AuditObserver:onLevelUp(newLevel: number)
	table.insert(self.auditTrail, {
		event = "LevelUp",
		timestamp = tick(),
		newLevel = newLevel,
	})
end

function AuditObserver:getName(): string
	return "AuditObserver"
end

function AuditObserver:getAuditTrail(): { any }
	return self.auditTrail
end

--[[
	@class PlayerDataSubject
	@desc Subject that notifies observers of changes
]]
local PlayerDataSubject = {}
PlayerDataSubject.__index = PlayerDataSubject

export type PlayerDataSubject = {
	_observers: { any },
	_balance: number,
	_job: string,
	_level: number,
}

function PlayerDataSubject.new(): PlayerDataSubject
	local self = setmetatable({}, PlayerDataSubject)
	self._observers = {}
	self._balance = 0
	self._job = "Civilian"
	self._level = 1
	return self
end

function PlayerDataSubject:attach(observer: any): boolean
	if not observer then
		return false
	end

	-- Check if observer already attached
	for _, obs in ipairs(self._observers) do
		if obs:getName() == observer:getName() then
			return false
		end
	end

	table.insert(self._observers, observer)
	return true
end

function PlayerDataSubject:detach(observerName: string): boolean
	for i, observer in ipairs(self._observers) do
		if observer:getName() == observerName then
			table.remove(self._observers, i)
			return true
		end
	end
	return false
end

function PlayerDataSubject:notifyBalanceChange(newBalance: number)
	local oldBalance = self._balance
	self._balance = newBalance

	for _, observer in ipairs(self._observers) do
		observer:onBalanceChanged(newBalance, oldBalance)
	end
end

function PlayerDataSubject:notifyJobChange(newJob: string)
	local oldJob = self._job
	self._job = newJob

	for _, observer in ipairs(self._observers) do
		observer:onJobChanged(newJob, oldJob)
	end
end

function PlayerDataSubject:notifyLevelUp(newLevel: number)
	self._level = newLevel

	for _, observer in ipairs(self._observers) do
		observer:onLevelUp(newLevel)
	end
end

function PlayerDataSubject:getObserverCount(): number
	return #self._observers
end

function PlayerDataSubject:getObservers(): { any }
	return self._observers
end

-- Export all classes
PlayerDataObserver.IObserver = IObserver
PlayerDataObserver.NotificationObserver = NotificationObserver
PlayerDataObserver.LoggingObserver = LoggingObserver
PlayerDataObserver.AuditObserver = AuditObserver
PlayerDataObserver.PlayerDataSubject = PlayerDataSubject

return PlayerDataObserver
