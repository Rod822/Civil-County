--[[
	@class GameCommand
	@desc Command pattern for encapsulating requests as objects
	@pattern Command
	
	Encapsulates requests as objects allowing parameterization of clients
	with different requests, queuing, and logging of requests.
]]

local GameCommand = {}

--[[
	@class ICommand
	@desc Interface for all commands
]]
local ICommand = {}
ICommand.__index = ICommand

function ICommand.new()
	return setmetatable({}, ICommand)
end

function ICommand:execute(): boolean
	error("execute must be implemented")
end

function ICommand:undo(): boolean
	error("undo must be implemented")
end

function ICommand:getName(): string
	error("getName must be implemented")
end

--[[
	@class AssignJobCommand
	@desc Command for assigning a job to a player
]]
local AssignJobCommand = setmetatable({}, ICommand)
AssignJobCommand.__index = AssignJobCommand

function AssignJobCommand.new(jobService: any, player: Player, jobName: string): AssignJobCommand
	local self = setmetatable({}, AssignJobCommand)
	self.jobService = jobService
	self.player = player
	self.jobName = jobName
	self.previousJob = nil
	self.executed = false
	return self
end

function AssignJobCommand:execute(): boolean
	if self.executed then
		return false
	end

	-- Store previous state for undo
	local profile = self.jobService._playersDataService._profiles[self.player.UserId]
	if profile then
		self.previousJob = profile.session.job
	end

	local success = self.jobService:assignJob(self.player, self.jobName)
	if success then
		self.executed = true
	end
	return success
end

function AssignJobCommand:undo(): boolean
	if not self.executed or not self.previousJob then
		return false
	end

	local success = self.jobService:assignJob(self.player, self.previousJob)
	if success then
		self.executed = false
	end
	return success
end

function AssignJobCommand:getName(): string
	return "AssignJob:" .. self.jobName
end

--[[
	@class PaycheckCommand
	@desc Command for processing paychecks
]]
local PaycheckCommand = setmetatable({}, ICommand)
PaycheckCommand.__index = PaycheckCommand

function PaycheckCommand.new(jobService: any, player: Player): PaycheckCommand
	local self = setmetatable({}, PaycheckCommand)
	self.jobService = jobService
	self.player = player
	self.amountPaid = 0
	self.executed = false
	return self
end

function PaycheckCommand:execute(): boolean
	if self.executed then
		return false
	end

	local success = self.jobService:paycheck(self.player)
	if success then
		self.executed = true
		-- In real implementation, would get actual amount paid
		self.amountPaid = 250
	end
	return success
end

function PaycheckCommand:undo(): boolean
	if not self.executed or self.amountPaid <= 0 then
		return false
	end

	local success = self.jobService._playersDataService:RemoveMoney(self.player, self.amountPaid)
	if success then
		self.executed = false
	end
	return success
end

function PaycheckCommand:getName(): string
	return "Paycheck:" .. self.player.Name
end

--[[
	@class SendNotificationCommand
	@desc Command for sending notifications
]]
local SendNotificationCommand = setmetatable({}, ICommand)
SendNotificationCommand.__index = SendNotificationCommand

function SendNotificationCommand.new(
	notificationService: any,
	player: Player,
	title: string,
	message: string
): SendNotificationCommand
	local self = setmetatable({}, SendNotificationCommand)
	self.notificationService = notificationService
	self.player = player
	self.title = title
	self.message = message
	self.executed = false
	return self
end

function SendNotificationCommand:execute(): boolean
	if self.executed then
		return false
	end

	self.notificationService:SendTo(self.player, self.title, self.message)
	self.executed = true
	return true
end

function SendNotificationCommand:undo(): boolean
	-- Notifications can't really be undone
	return false
end

function SendNotificationCommand:getName(): string
	return "SendNotification:" .. self.title
end

--[[
	@class CommandInvoker
	@desc Manages command execution history and undo
]]
local CommandInvoker = {}
CommandInvoker.__index = CommandInvoker

export type CommandInvoker = {
	_commandHistory: { any },
	_undoStack: { any },
	_maxHistorySize: number,
}

function CommandInvoker.new(maxHistorySize: number?): CommandInvoker
	local self = setmetatable({}, CommandInvoker)
	self._commandHistory = {}
	self._undoStack = {}
	self._maxHistorySize = maxHistorySize or 100
	return self
end

function CommandInvoker:execute(command: any): boolean
	local success = command:execute()

	if success then
		table.insert(self._commandHistory, command)

		-- Limit history size
		if #self._commandHistory > self._maxHistorySize then
			table.remove(self._commandHistory, 1)
		end

		-- Clear undo stack on new command
		self._undoStack = {}
	end

	return success
end

function CommandInvoker:undo(): boolean
	if #self._commandHistory == 0 then
		return false
	end

	local lastCommand = table.remove(self._commandHistory)
	local success = lastCommand:undo()

	if success then
		table.insert(self._undoStack, lastCommand)
	end

	return success
end

function CommandInvoker:redo(): boolean
	if #self._undoStack == 0 then
		return false
	end

	local command = table.remove(self._undoStack)
	local success = command:execute()

	if success then
		table.insert(self._commandHistory, command)
	end

	return success
end

function CommandInvoker:getHistory(): { any }
	return self._commandHistory
end

function CommandInvoker:getHistorySize(): number
	return #self._commandHistory
end

function CommandInvoker:clearHistory()
	self._commandHistory = {}
	self._undoStack = {}
end

-- Export all commands
GameCommand.ICommand = ICommand
GameCommand.AssignJobCommand = AssignJobCommand
GameCommand.PaycheckCommand = PaycheckCommand
GameCommand.SendNotificationCommand = SendNotificationCommand
GameCommand.CommandInvoker = CommandInvoker

return GameCommand
