--[[
	@module ThreadPool
	@desc Coroutine-based worker pool. Dispatches tasks to a fixed set of
	      coroutine workers and collects results once all workers finish.
	      Models a thread pool using Roblox's cooperative scheduler.
]]

local ThreadPool = {}
ThreadPool.__index = ThreadPool

--[[
	@function new
	@param size number  Number of worker slots (default 4)
	@return ThreadPool
]]
function ThreadPool.new(size: number?)
	local self = setmetatable({}, ThreadPool)
	self._size = size or 4
	self._pendingCount = 0
	self._results = {}
	return self
end

--[[
	@function dispatch
	@desc Runs tasks concurrently using task.spawn. Each task receives its
	      index and stores its return value in the shared results table.
	      Blocks (via task.wait polling) until every task has finished.
	@param tasks { () -> any }  Table of zero-argument callables
	@return { any }             Results in the same index order as tasks
]]
function ThreadPool:dispatch(tasks: { () -> any }): { any }
	local results: { any } = {}
	local done = 0
	local total = #tasks

	for i, taskFn in ipairs(tasks) do
		task.spawn(function()
			results[i] = taskFn()
			done += 1
		end)
	end

	-- Yield until all workers report back
	while done < total do
		task.wait()
	end

	return results
end

--[[
	@function getSize
	@return number  Pool worker capacity
]]
function ThreadPool:getSize(): number
	return self._size
end

--[[
	@function map
	@desc Applies fn to every element of data in parallel chunks.
	      Splits data into self._size chunks, one per worker.
	@param data  { any }
	@param fn    (item: any, index: number) -> any
	@return { any }  Transformed array, order preserved
]]
function ThreadPool:map(data: { any }, fn: (any, number) -> any): { any }
	local n = #data
	if n == 0 then
		return {}
	end

	local chunkSize = math.max(1, math.ceil(n / self._size))
	local tasks: { () -> any } = {}
	local chunkCount = math.ceil(n / chunkSize)

	for c = 1, chunkCount do
		local startIdx = (c - 1) * chunkSize + 1
		local endIdx   = math.min(c * chunkSize, n)
		tasks[c] = function()
			local chunk = {}
			for i = startIdx, endIdx do
				chunk[i - startIdx + 1] = fn(data[i], i)
			end
			return chunk
		end
	end

	local chunkResults = self:dispatch(tasks)

	-- Flatten ordered chunks back into a single array
	local out = {}
	for c = 1, chunkCount do
		local startIdx = (c - 1) * chunkSize + 1
		if chunkResults[c] then
			for j, v in ipairs(chunkResults[c]) do
				out[startIdx + j - 1] = v
			end
		end
	end

	return out
end

return ThreadPool
