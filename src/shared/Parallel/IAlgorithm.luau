--[[
	@module IAlgorithm
	@desc Abstract interface for sequential and parallel algorithm implementations.
	      Provides the contract that all sorting and search algorithms must satisfy.
	@pattern Strategy, Template Method
]]

local IAlgorithm = {}
IAlgorithm.__index = IAlgorithm

--[[
	@function new
	@desc Creates a new IAlgorithm base instance.
	@return IAlgorithm
]]
function IAlgorithm.new()
	local self = setmetatable({}, IAlgorithm)
	self._name = "IAlgorithm"
	self._lastExecutionTime = 0
	return self
end

--[[
	@function run
	@desc Entry point for algorithm execution. Wraps _execute and records timing.
	@param data table  Input data array
	@param ... any     Additional parameters (e.g. target for search)
	@return any        Algorithm result
]]
function IAlgorithm:run(data: { any }, ...: any): any
	local t0 = os.clock()
	local result = self:_execute(data, ...)
	self._lastExecutionTime = os.clock() - t0
	return result
end

--[[
	@function _execute
	@desc Override in subclasses. Core algorithm logic.
	@param _data table
	@return any
]]
function IAlgorithm:_execute(_data: { any }, ...: any): any
	error(self._name .. ": _execute() must be implemented by subclass")
end

--[[
	@function getName
	@return string  Human-readable algorithm identifier
]]
function IAlgorithm:getName(): string
	return self._name
end

--[[
	@function getLastTime
	@return number  Seconds elapsed during last run()
]]
function IAlgorithm:getLastTime(): number
	return self._lastExecutionTime
end

return IAlgorithm
