--[[
	@class JobInterface & JobImplementation
	@desc Bridge pattern separating abstraction from implementation
	@pattern Bridge
	
	Allows varying both abstractions and implementations independently.
	Job systems can be extended without tying to specific platforms/behaviors.
]]

local JobBridge = {}

--[[
	@class IJobAbstraction
	@desc Abstract interface for job operations
]]
local IJobAbstraction = {}
IJobAbstraction.__index = IJobAbstraction

export type IJobAbstraction = {
	_implementation: any,
	name: string,
}

--[[
	@method new
	@desc Creates a new Job abstraction
	@param implementation: any - The job implementation
	@return IJobAbstraction
]]
function IJobAbstraction.new(implementation: any, jobName: string): IJobAbstraction
	local self = setmetatable({}, IJobAbstraction)
	self._implementation = implementation
	self.name = jobName
	return self
end

--[[
	@method assign
	@desc Assigns a player to this job
	@param player: Player
	@return boolean
]]
function IJobAbstraction:assign(player: Player): boolean
	return self._implementation:assign(player)
end

--[[
	@method fire
	@desc Fires a player from this job
	@param player: Player
	@return boolean
]]
function IJobAbstraction:fire(player: Player): boolean
	return self._implementation:fire(player)
end

--[[
	@method pay
	@desc Pays a player for this job
	@param player: Player
	@param baseAmount: number
	@return number - Amount paid
]]
function IJobAbstraction:pay(player: Player, baseAmount: number): number
	return self._implementation:pay(player, baseAmount)
end

--[[
	@method giveTools
	@desc Gives job-specific tools
	@param player: Player
]]
function IJobAbstraction:giveTools(player: Player)
	self._implementation:giveTools(player)
end

--[[
	@method removeTools
	@desc Removes job-specific tools
	@param player: Player
]]
function IJobAbstraction:removeTools(player: Player)
	self._implementation:removeTools(player)
end

--[[
	@method getJobInfo
	@desc Gets job information
	@return table - Job info
]]
function IJobAbstraction:getJobInfo(): { [string]: any }
	return {
		name = self.name,
		implementation = self._implementation:getType(),
		description = self._implementation:getDescription(),
	}
end

--[[
	@class ServerJobImplementation
	@desc Server-side job implementation
]]
local ServerJobImplementation = {}
ServerJobImplementation.__index = ServerJobImplementation

function ServerJobImplementation.new(jobName: string, basePay: number): ServerJobImplementation
	local self = setmetatable({}, ServerJobImplementation)
	self.jobName = jobName
	self.basePay = basePay
	self.assignedPlayers = {}
	return self
end

function ServerJobImplementation:assign(player: Player): boolean
	if not self.assignedPlayers[player.UserId] then
		self.assignedPlayers[player.UserId] = {
			player = player,
			assignedAt = tick(),
			hoursWorked = 0,
		}
		return true
	end
	return false
end

function ServerJobImplementation:fire(player: Player): boolean
	if self.assignedPlayers[player.UserId] then
		self.assignedPlayers[player.UserId] = nil
		return true
	end
	return false
end

function ServerJobImplementation:pay(player: Player, baseAmount: number): number
	if self.assignedPlayers[player.UserId] then
		local hourlyRate = baseAmount / 3600
		return math.floor(hourlyRate * 3600)
	end
	return 0
end

function ServerJobImplementation:giveTools(_player: Player)
	-- Server implementation: would give tools
end

function ServerJobImplementation:removeTools(_player: Player)
	-- Server implementation: would remove tools
end

function ServerJobImplementation:getType(): string
	return "Server"
end

function ServerJobImplementation:getDescription(): string
	return "Server-side implementation of job: " .. self.jobName
end

--[[
	@class ClientJobImplementation
	@desc Client-side job implementation
]]
local ClientJobImplementation = {}
ClientJobImplementation.__index = ClientJobImplementation

function ClientJobImplementation.new(jobName: string): ClientJobImplementation
	local self = setmetatable({}, ClientJobImplementation)
	self.jobName = jobName
	self.localData = {}
	return self
end

function ClientJobImplementation:assign(_player: Player): boolean
	-- Client-side would update local state
	return true
end

function ClientJobImplementation:fire(_player: Player): boolean
	-- Client-side would update local state
	return true
end

function ClientJobImplementation:pay(_player: Player, _baseAmount: number): number
	-- Client doesn't actually give money
	return 0
end

function ClientJobImplementation:giveTools(_player: Player)
	-- Client implementation would display tools
end

function ClientJobImplementation:removeTools(_player: Player)
	-- Client implementation would hide tools
end

function ClientJobImplementation:getType(): string
	return "Client"
end

function ClientJobImplementation:getDescription(): string
	return "Client-side implementation of job: " .. self.jobName
end

-- Export factory methods
JobBridge.createServerJobAbstraction = function(jobName: string, basePay: number): IJobAbstraction
	local implementation = ServerJobImplementation.new(jobName, basePay)
	return IJobAbstraction.new(implementation, jobName)
end

JobBridge.createClientJobAbstraction = function(jobName: string): IJobAbstraction
	local implementation = ClientJobImplementation.new(jobName)
	return IJobAbstraction.new(implementation, jobName)
end

return JobBridge
