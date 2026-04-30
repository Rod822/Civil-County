--[[
	@module ParallelSort
	@desc Parallel merge sort using a coroutine-based ThreadPool.
	      The input is split into N chunks (one per worker), each chunk is
	      sorted sequentially inside its worker, then all sorted chunks are
	      merged together on the calling coroutine.

	      In Roblox's cooperative scheduler the workers share a single OS
	      thread, but the task.spawn + task.wait handshake still demonstrates
	      the parallel work-division pattern and gives measurably different
	      timing characteristics at large input sizes.
	@pattern Strategy (implements IAlgorithm)
]]

local IAlgorithm  = require(script.Parent.IAlgorithm)
local ThreadPool  = require(script.Parent.ThreadPool)

local ParallelSort = setmetatable({}, { __index = IAlgorithm })
ParallelSort.__index = ParallelSort

--[[
	@function new
	@param workerCount number  Number of parallel chunks (default 4)
	@return ParallelSort
]]
function ParallelSort.new(workerCount: number?)
	local self = IAlgorithm.new()
	setmetatable(self, ParallelSort)
	self._name        = "ParallelMergeSort"
	self._workerCount = workerCount or 4
	self._pool        = ThreadPool.new(self._workerCount)
	return self
end

-- Internal: sequential merge sort used inside each worker
local function mergeSort(arr: { number }): { number }
	local n = #arr
	if n <= 1 then return arr end
	local mid   = math.floor(n / 2)
	local left  = table.move(arr, 1, mid, 1, {})
	local right = table.move(arr, mid + 1, n, 1, {})
	local function merge(l, r)
		local out = {}
		local i, j = 1, 1
		while i <= #l and j <= #r do
			if l[i] <= r[j] then
				out[#out + 1] = l[i]; i += 1
			else
				out[#out + 1] = r[j]; j += 1
			end
		end
		while i <= #l do out[#out + 1] = l[i]; i += 1 end
		while j <= #r do out[#out + 1] = r[j]; j += 1 end
		return out
	end
	return merge(mergeSort(left), mergeSort(right))
end

-- Internal: merge an ordered list of already-sorted arrays into one
local function mergeAll(sorted: { { number } }): { number }
	while #sorted > 1 do
		local next = {}
		local i = 1
		while i <= #sorted do
			if i + 1 <= #sorted then
				local merged = {}
				local l, r = sorted[i], sorted[i + 1]
				local li, ri = 1, 1
				while li <= #l and ri <= #r do
					if l[li] <= r[ri] then
						merged[#merged + 1] = l[li]; li += 1
					else
						merged[#merged + 1] = r[ri]; ri += 1
					end
				end
				while li <= #l do merged[#merged + 1] = l[li]; li += 1 end
				while ri <= #r do merged[#merged + 1] = r[ri]; ri += 1 end
				next[#next + 1] = merged
			else
				next[#next + 1] = sorted[i]
			end
			i += 2
		end
		sorted = next
	end
	return sorted[1] or {}
end

--[[
	@function _execute
	@desc Splits data into workerCount chunks, sorts each chunk in a
	      separate task.spawn worker, then merges all chunks together.
	@param data { number }
	@return { number }  Sorted copy
]]
function ParallelSort:_execute(data: { number }): { number }
	local n = #data
	if n == 0 then return {} end

	local workers   = math.min(self._workerCount, n)
	local chunkSize = math.ceil(n / workers)
	local tasks: { () -> { number } } = {}

	for w = 1, workers do
		local startIdx = (w - 1) * chunkSize + 1
		local endIdx   = math.min(w * chunkSize, n)
		local chunk    = table.move(data, startIdx, endIdx, 1, {})
		tasks[w] = function()
			return mergeSort(chunk)
		end
	end

	local sortedChunks = self._pool:dispatch(tasks)
	return mergeAll(sortedChunks)
end

--[[
	@function setWorkerCount
	@param count number  Rebuild pool with new worker capacity
]]
function ParallelSort:setWorkerCount(count: number)
	self._workerCount = count
	self._pool = ThreadPool.new(count)
end

--[[
	@function getWorkerCount
	@return number
]]
function ParallelSort:getWorkerCount(): number
	return self._workerCount
end

return ParallelSort
