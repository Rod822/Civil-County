--[[
	@module SequentialSort
	@desc Sequential merge sort implementation (single-threaded).
	      Used as the baseline for performance comparisons with ParallelSort.
	@pattern Strategy (implements IAlgorithm)
]]

local IAlgorithm = require(script.Parent.IAlgorithm)

local SequentialSort = setmetatable({}, { __index = IAlgorithm })
SequentialSort.__index = SequentialSort

--[[
	@function new
	@return SequentialSort
]]
function SequentialSort.new()
	local self = IAlgorithm.new()
	setmetatable(self, SequentialSort)
	self._name = "SequentialMergeSort"
	return self
end

-- Internal: merge two sorted halves into one sorted array
local function merge(left: { number }, right: { number }): { number }
	local result = {}
	local i, j = 1, 1
	while i <= #left and j <= #right do
		if left[i] <= right[j] then
			table.insert(result, left[i])
			i += 1
		else
			table.insert(result, right[j])
			j += 1
		end
	end
	while i <= #left do
		table.insert(result, left[i])
		i += 1
	end
	while j <= #right do
		table.insert(result, right[j])
		j += 1
	end
	return result
end

-- Internal: recursive merge sort
local function mergeSort(arr: { number }): { number }
	local n = #arr
	if n <= 1 then
		return arr
	end
	local mid = math.floor(n / 2)
	local left  = {}
	local right = {}
	for i = 1, mid do
		left[i] = arr[i]
	end
	for i = mid + 1, n do
		right[i - mid] = arr[i]
	end
	return merge(mergeSort(left), mergeSort(right))
end

--[[
	@function _execute
	@desc Runs a full sequential merge sort on the input array.
	@param data { number }  Unsorted input
	@return { number }      Sorted copy
]]
function SequentialSort:_execute(data: { number }): { number }
	if #data == 0 then
		return {}
	end
	local copy = table.clone(data)
	return mergeSort(copy)
end

return SequentialSort
