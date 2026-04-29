--[[
	@class DataProxy
	@desc Proxy pattern for controlling access to data with caching
	@pattern Proxy
	
	Acts as a surrogate or placeholder for the real data object.
	Implements lazy loading, caching, and access control.
]]

local DataProxy = {}
DataProxy.__index = DataProxy

export type CachedData = {
	value: any,
	timestamp: number,
	hits: number,
	valid: boolean,
}

--[[
	@method new
	@desc Creates a new DataProxy instance
	@param realService: any - The actual service to proxy
	@param cacheDuration: number - How long to cache in seconds (default: 300)
	@return DataProxy
]]
function DataProxy.new(realService: any, cacheDuration: number?): DataProxy
	local self = setmetatable({}, DataProxy)
	self._realService = realService
	self._cache = {}
	self._cacheDuration = cacheDuration or 300
	self._accessLog = {}
	self._stats = {
		cacheHits = 0,
		cacheMisses = 0,
		evictions = 0,
	}
	return self
end

--[[
	@method get
	@desc Retrieves data with automatic caching
	@param key: string - The data key
	@param fetchFunction: function - Function to fetch data if not cached
	@return any - The cached or fetched data
]]
function DataProxy:get(key: string, fetchFunction: (string) -> any): any
	local cachedData = self._cache[key]

	-- Check if cache is still valid
	if cachedData and cachedData.valid then
		local age = tick() - cachedData.timestamp
		if age < self._cacheDuration then
			cachedData.hits = cachedData.hits + 1
			self._stats.cacheHits = self._stats.cacheHits + 1
			self:_logAccess(key, "HIT")
			return cachedData.value
		else
			-- Cache expired
			cachedData.valid = false
		end
	end

	-- Cache miss - fetch fresh data
	self._stats.cacheMisses = self._stats.cacheMisses + 1
	self:_logAccess(key, "MISS")

	local value = fetchFunction(key)

	-- Store in cache
	self._cache[key] = {
		value = value,
		timestamp = tick(),
		hits = 0,
		valid = true,
	}

	return value
end

--[[
	@method set
	@desc Sets data and updates cache
	@param key: string
	@param value: any
	@param updateFunction: function - Optional function to persist data
]]
function DataProxy:set(key: string, value: any, updateFunction: ((string, any) -> boolean)?): boolean
	-- Update through real service if function provided
	if updateFunction then
		local success = updateFunction(key, value)
		if not success then
			return false
		end
	end

	-- Update cache
	self._cache[key] = {
		value = value,
		timestamp = tick(),
		hits = 0,
		valid = true,
	}

	self:_logAccess(key, "SET")
	return true
end

--[[
	@method invalidate
	@desc Invalidates a cache entry
	@param key: string
	@return boolean - true if entry was invalidated
]]
function DataProxy:invalidate(key: string): boolean
	if self._cache[key] then
		self._cache[key].valid = false
		self._stats.evictions = self._stats.evictions + 1
		self:_logAccess(key, "INVALIDATE")
		return true
	end
	return false
end

--[[
	@method invalidateAll
	@desc Invalidates all cached entries
]]
function DataProxy:invalidateAll()
	for key, _ in pairs(self._cache) do
		self._cache[key].valid = false
	end
	self._stats.evictions = self._stats.evictions + 1
end

--[[
	@method isCached
	@desc Checks if data is in valid cache
	@param key: string
	@return boolean
]]
function DataProxy:isCached(key: string): boolean
	local cached = self._cache[key]
	if not cached or not cached.valid then
		return false
	end

	local age = tick() - cached.timestamp
	return age < self._cacheDuration
end

--[[
	@method getCacheStats
	@desc Returns cache statistics
	@return table - Cache performance stats
]]
function DataProxy:getCacheStats(): { [string]: number }
	local totalAccesses = self._stats.cacheHits + self._stats.cacheMisses
	local hitRate = totalAccesses > 0 and (self._stats.cacheHits / totalAccesses) or 0

	return {
		cacheHits = self._stats.cacheHits,
		cacheMisses = self._stats.cacheMisses,
		evictions = self._stats.evictions,
		hitRate = hitRate,
		totalEntries = self:_countValidEntries(),
	}
end

--[[
	@method setCacheDuration
	@desc Changes cache duration
	@param duration: number - New duration in seconds
]]
function DataProxy:setCacheDuration(duration: number)
	self._cacheDuration = math.max(1, duration)
end

--[[
	@method _logAccess
	@desc Internal: Logs cache access
	@param key: string
	@param accessType: string
]]
function DataProxy:_logAccess(key: string, accessType: string)
	table.insert(self._accessLog, {
		key = key,
		type = accessType,
		timestamp = tick(),
	})

	-- Keep log bounded
	if #self._accessLog > 1000 then
		table.remove(self._accessLog, 1)
	end
end

--[[
	@method _countValidEntries
	@desc Internal: Counts valid cache entries
	@return number
]]
function DataProxy:_countValidEntries(): number
	local count = 0
	for _, entry in pairs(self._cache) do
		if entry.valid then
			count = count + 1
		end
	end
	return count
end

--[[
	@method getAccessLog
	@desc Returns the access log
	@return table - Recent access log entries
]]
function DataProxy:getAccessLog(): { any }
	return self._accessLog
end

return DataProxy
