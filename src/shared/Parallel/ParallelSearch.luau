--[[
	@module ParallelSearch
	@desc Parallel linear search. Divides the array into chunks and
	      searches each chunk in a separate task.spawn worker.
	      Results from all workers are merged and returned sorted by index.
	@pattern Strategy (implements IAlgorithm)
]]

local IAlgorithm = require(script.Parent.IAlgorithm)
local ThreadPool  = require(script.Parent.ThreadPool)

local ParallelSearch = setmetatable({}, { __index = IAlgorithm })
ParallelSearch.__index = ParallelSearch

--[[
	@function new
	@param workerCount number  (default 4)
	@return ParallelSearch
]]
function ParallelSearch.new(workerCount: number?)
	local self = IAlgorithm.new()
	setmetatable(self, ParallelSearch)
	self._name        = "ParallelSearch"
	self._workerCount = workerCount or 4
	self._pool        = ThreadPool.new(self._workerCount)
	return self
end

--[[
	@function _execute
	@param data   { any }
	@param target any
	@return { number }  All matching indices, sorted ascending
]]
function ParallelSearch:_execute(data: { any }, target: any): { number }
	local n = #data
	if n == 0 then return {} end

	local workers   = math.min(self._workerCount, n)
	local chunkSize = math.ceil(n / workers)
	local tasks: { () -> { number } } = {}

	for w = 1, workers do
		local startIdx = (w - 1) * chunkSize + 1
		local endIdx   = math.min(w * chunkSize, n)
		tasks[w] = function()
			local hits = {}
			for i = startIdx, endIdx do
				if data[i] == target then
					hits[#hits + 1] = i
				end
			end
			return hits
		end
	end

	local chunkResults = self._pool:dispatch(tasks)

	local found = {}
	for _, hits in ipairs(chunkResults) do
		for _, idx in ipairs(hits) do
			found[#found + 1] = idx
		end
	end
	table.sort(found)
	return found
end

--[[
	@function setWorkerCount
	@param count number
]]
function ParallelSearch:setWorkerCount(count: number)
	self._workerCount = count
	self._pool = ThreadPool.new(count)
end

return ParallelSearch
