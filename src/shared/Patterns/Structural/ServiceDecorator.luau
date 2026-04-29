--[[
	@class ServiceDecorator
	@desc Decorator pattern for adding functionality to services
	@pattern Decorator
	
	Dynamically adds logging, auditing, performance monitoring to services
	without modifying their core code. Follows the Decorator design pattern.
]]

local ServiceDecorator = {}
ServiceDecorator.__index = ServiceDecorator

export type DecoratedService = {
	_originalService: any,
	_decorators: { string },
	_logs: { string },
	_metrics: { [string]: number },
}

--[[
	@method new
	@desc Creates a new ServiceDecorator for wrapping a service
	@param originalService: any - The service to decorate
	@return ServiceDecorator
]]
function ServiceDecorator.new(originalService: any): ServiceDecorator
	local self = setmetatable({}, ServiceDecorator)
	self._originalService = originalService
	self._decorators = {}
	self._logs = {}
	self._metrics = {}
	self._startTime = 0
	return self
end

--[[
	@method addLoggingDecorator
	@desc Adds logging functionality to track method calls
	@param methodName: string
	@return ServiceDecorator (for chaining)
]]
function ServiceDecorator:addLoggingDecorator(methodName: string): ServiceDecorator
	table.insert(self._decorators, "Logging:" .. methodName)
	return self
end

--[[
	@method addAuditDecorator
	@desc Adds audit functionality to track important operations
	@param methodName: string
	@param auditCategory: string
	@return ServiceDecorator
]]
function ServiceDecorator:addAuditDecorator(methodName: string, auditCategory: string): ServiceDecorator
	table.insert(self._decorators, "Audit:" .. methodName .. ":" .. auditCategory)
	return self
end

--[[
	@method addPerformanceMonitoring
	@desc Adds performance metrics tracking
	@param methodName: string
	@return ServiceDecorator
]]
function ServiceDecorator:addPerformanceMonitoring(methodName: string): ServiceDecorator
	table.insert(self._decorators, "Performance:" .. methodName)
	self._metrics[methodName] = 0
	return self
end

--[[
	@method logOperation
	@desc Logs an operation
	@param operation: string
	@param details: string
]]
function ServiceDecorator:logOperation(operation: string, details: string)
	local logEntry = os.date("%Y-%m-%d %H:%M:%S") .. " | " .. operation .. " | " .. details
	table.insert(self._logs, logEntry)
	print("[ServiceLog] " .. logEntry)
end

--[[
	@method auditOperation
	@desc Records an audit entry
	@param category: string
	@param action: string
	@param details: string
]]
function ServiceDecorator:auditOperation(category: string, action: string, details: string)
	local auditEntry = {
		timestamp = tick(),
		category = category,
		action = action,
		details = details,
	}
	table.insert(self._logs, tostring(auditEntry))
	print("[Audit] [" .. category .. "] " .. action .. ": " .. details)
end

--[[
	@method startMetric
	@desc Starts timing a method
]]
function ServiceDecorator:startMetric()
	self._startTime = tick()
end

--[[
	@method endMetric
	@desc Ends timing and records the metric
	@param methodName: string
]]
function ServiceDecorator:endMetric(methodName: string)
	local duration = tick() - self._startTime
	if not self._metrics[methodName] then
		self._metrics[methodName] = 0
	end
	self._metrics[methodName] = self._metrics[methodName] + duration
end

--[[
	@method getLogs
	@desc Retrieves all log entries
	@return table - Array of log entries
]]
function ServiceDecorator:getLogs(): { string }
	return self._logs
end

--[[
	@method getMetrics
	@desc Retrieves performance metrics
	@return table - Dictionary of method metrics
]]
function ServiceDecorator:getMetrics(): { [string]: number }
	return self._metrics
end

--[[
	@method getDecorators
	@desc Lists all active decorators
	@return table - Array of decorator names
]]
function ServiceDecorator:getDecorators(): { string }
	return self._decorators
end

--[[
	@method clearLogs
	@desc Clears all log entries
]]
function ServiceDecorator:clearLogs()
	self._logs = {}
end

--[[
	@method getOriginalService
	@desc Returns the original undecorated service
	@return any
]]
function ServiceDecorator:getOriginalService(): any
	return self._originalService
end

return ServiceDecorator
