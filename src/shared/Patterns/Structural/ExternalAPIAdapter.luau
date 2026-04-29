--[[
	@class ExternalAPIAdapter
	@desc Adapter pattern for integrating external APIs and services
	@pattern Adapter
	
	Adapts different external systems (DataStore, HTTP, etc.) to a common interface.
	Allows seamless integration without changing main application code.
]]

local ExternalAPIAdapter = {}
ExternalAPIAdapter.__index = ExternalAPIAdapter

export type AdaptedService = {
	name: string,
	adaptedMethods: { string },
	originalInterface: any,
}

--[[
	@method new
	@desc Creates a new ExternalAPIAdapter
	@param serviceName: string
	@param originalService: any
	@return ExternalAPIAdapter
]]
function ExternalAPIAdapter.new(serviceName: string, originalService: any): ExternalAPIAdapter
	local self = setmetatable({}, ExternalAPIAdapter)
	self.name = serviceName
	self.originalInterface = originalService
	self.adaptedMethods = {}
	return self
end

--[[
	@method adaptDataStore
	@desc Adapts Roblox DataStore API to a common interface
	@param dataStore: any - The DataStore instance
	@return table - Adapted interface
]]
function ExternalAPIAdapter:adaptDataStore(dataStore: any): any
	local adapter = {}

	function adapter:Get(key: string)
		local success, data = pcall(function()
			return dataStore:GetAsync(key)
		end)
		return { success = success, data = data }
	end

	function adapter:Set(key: string, value: any)
		local success, err = pcall(function()
			return dataStore:SetAsync(key, value)
		end)
		return { success = success, error = err }
	end

	function adapter:Increment(key: string, amount: number)
		local success, newValue = pcall(function()
			return dataStore:IncrementAsync(key, amount)
		end)
		return { success = success, newValue = newValue }
	end

	table.insert(self.adaptedMethods, "GetAsync")
	table.insert(self.adaptedMethods, "SetAsync")
	table.insert(self.adaptedMethods, "IncrementAsync")

	return adapter
end

--[[
	@method adaptHTTPService
	@desc Adapts HTTP requests to a common interface
	@param httpService: any
	@return table - Adapted interface
]]
function ExternalAPIAdapter:adaptHTTPService(httpService: any): any
	local adapter = {}

	function adapter:Get(url: string, headers: { [string]: string }?)
		local success, response = pcall(function()
			return httpService:GetAsync(url, false, headers)
		end)
		return { success = success, body = response }
	end

	function adapter:Post(url: string, body: string, contentType: string?, headers: { [string]: string }?)
		local success, response = pcall(function()
			return httpService:PostAsync(url, body, contentType or "application/json", false, headers)
		end)
		return { success = success, body = response }
	end

	table.insert(self.adaptedMethods, "GetAsync")
	table.insert(self.adaptedMethods, "PostAsync")

	return adapter
end

--[[
	@method adaptCustomService
	@desc Generic adapter for custom services
	@param service: any - Any service object
	@param targetInterface: string - Name of the interface to adapt to
	@return table - Adapted interface with error handling
]]
function ExternalAPIAdapter:adaptCustomService(service: any, targetInterface: string): any
	local adapter = {}

	-- Store reference to adapted methods
	setmetatable(adapter, {
		__index = function(_, key)
			if service[key] then
				return service[key]
			end
			return nil
		end,
	})

	table.insert(self.adaptedMethods, targetInterface)

	return adapter
end

--[[
	@method getAdaptedMethods
	@desc Returns list of all adapted methods
	@return table - Array of method names
]]
function ExternalAPIAdapter:getAdaptedMethods(): { string }
	return self.adaptedMethods
end

--[[
	@method getServiceName
	@desc Returns the name of the adapted service
	@return string
]]
function ExternalAPIAdapter:getServiceName(): string
	return self.name
end

--[[
	@method isCompatible
	@desc Checks if the original service can be adapted
	@param requiredMethods: { string } - List of required methods
	@return boolean
]]
function ExternalAPIAdapter:isCompatible(requiredMethods: { string }): boolean
	for _, method in ipairs(requiredMethods) do
		if not table.find(self.adaptedMethods, method) then
			return false
		end
	end
	return true
end

return ExternalAPIAdapter
