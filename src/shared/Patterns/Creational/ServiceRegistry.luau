--[[
	@class ServiceRegistry
	@desc Singleton pattern for managing all services in the application
	@pattern Singleton
	
	Ensures only one instance exists and provides global access to all services.
	This is particularly useful for dependency injection and service locator pattern.
]]

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

local _instance: ServiceRegistry? = nil
local _lock = false

export type ServiceRegistry = {
	_services: { [string]: any },
	_initialized: boolean,
}

--[[
	@method getInstance
	@desc Gets the singleton instance of ServiceRegistry
	@return ServiceRegistry
]]
function ServiceRegistry.getInstance(): ServiceRegistry
	if _instance == nil then
		_instance = setmetatable({}, ServiceRegistry)
		_instance._services = {}
		_instance._initialized = false
	end
	return _instance
end

--[[
	@method register
	@desc Registers a service in the registry
	@param serviceName: string - Unique identifier for the service
	@param service: any - The service instance
	@return boolean - true if successful, false if already registered
]]
function ServiceRegistry:register(serviceName: string, service: any): boolean
	if self._services[serviceName] ~= nil then
		warn("ServiceRegistry: Service '" .. serviceName .. "' is already registered")
		return false
	end

	self._services[serviceName] = service
	return true
end

--[[
	@method get
	@desc Retrieves a registered service
	@param serviceName: string
	@return any - The service instance or nil if not found
]]
function ServiceRegistry:get(serviceName: string): any?
	if self._services[serviceName] == nil then
		warn("ServiceRegistry: Service '" .. serviceName .. "' is not registered")
		return nil
	end
	return self._services[serviceName]
end

--[[
	@method unregister
	@desc Unregisters a service
	@param serviceName: string
	@return boolean - true if found and unregistered
]]
function ServiceRegistry:unregister(serviceName: string): boolean
	if self._services[serviceName] == nil then
		return false
	end
	self._services[serviceName] = nil
	return true
end

--[[
	@method getAllServices
	@desc Returns all registered services
	@return table - Dictionary of all services
]]
function ServiceRegistry:getAllServices(): { [string]: any }
	return table.clone(self._services)
end

--[[
	@method hasService
	@desc Checks if a service is registered
	@param serviceName: string
	@return boolean
]]
function ServiceRegistry:hasService(serviceName: string): boolean
	return self._services[serviceName] ~= nil
end

--[[
	@method isInitialized
	@desc Checks if the registry has been initialized
	@return boolean
]]
function ServiceRegistry:isInitialized(): boolean
	return self._initialized
end

--[[
	@method setInitialized
	@desc Marks the registry as initialized
	@param initialized: boolean
]]
function ServiceRegistry:setInitialized(initialized: boolean)
	self._initialized = initialized
end

--[[
	@method clear
	@desc Clears all services (use with caution - mainly for testing)
]]
function ServiceRegistry:clear()
	self._services = {}
	self._initialized = false
end

return ServiceRegistry
