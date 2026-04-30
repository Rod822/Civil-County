--[[
	@file ParallelTests.spec.lua
	@desc Unit tests for Part 3a: sequential and parallel sorting/search algorithms,
	      ThreadPool, Benchmark. Covers correct output, edge cases, and verifies
	      that parallel results match their sequential counterparts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local this = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BoatTest")).this

local IAlgorithm      = require(ReplicatedStorage.Parallel.IAlgorithm)
local ThreadPool      = require(ReplicatedStorage.Parallel.ThreadPool)
local Benchmark       = require(ReplicatedStorage.Parallel.Benchmark)
local SequentialSort  = require(ReplicatedStorage.Parallel.SequentialSort)
local ParallelSort    = require(ReplicatedStorage.Parallel.ParallelSort)
local SequentialSearch = require(ReplicatedStorage.Parallel.SequentialSearch)
local ParallelSearch  = require(ReplicatedStorage.Parallel.ParallelSearch)

-- Helpers
local function makeRandom(n: number, max: number?): { number }
	max = max or 1000
	local t = {}
	for i = 1, n do t[i] = math.random(1, max) end
	return t
end

local function isSorted(arr: { number }): boolean
	for i = 2, #arr do
		if arr[i] < arr[i - 1] then return false end
	end
	return true
end

local function arraysEqual(a: { any }, b: { any }): boolean
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

return {
	-- ------------------------------------------------------------------ IAlgorithm
	["IAlgorithm - should record zero time before first run"] = function()
		local alg = IAlgorithm.new()
		this(alg:getLastTime()).equal(0)
	end,

	["IAlgorithm - getName returns class name"] = function()
		local alg = IAlgorithm.new()
		this(alg:getName()).equal("IAlgorithm")
	end,

	-- ------------------------------------------------------------------ ThreadPool
	["ThreadPool - dispatch collects all results"] = function()
		local pool = ThreadPool.new(4)
		local tasks = {
			function() return 10 end,
			function() return 20 end,
			function() return 30 end,
		}
		local results = pool:dispatch(tasks)
		this(results[1]).equal(10)
		this(results[2]).equal(20)
		this(results[3]).equal(30)
	end,

	["ThreadPool - dispatch handles empty task list"] = function()
		local pool = ThreadPool.new(4)
		local results = pool:dispatch({})
		this(#results).equal(0)
	end,

	["ThreadPool - map transforms array in parallel"] = function()
		local pool = ThreadPool.new(4)
		local data = {1, 2, 3, 4, 5, 6, 7, 8}
		local result = pool:map(data, function(v) return v * 2 end)
		this(result[1]).equal(2)
		this(result[4]).equal(8)
		this(result[8]).equal(16)
	end,

	["ThreadPool - map on empty array returns empty"] = function()
		local pool = ThreadPool.new(4)
		local result = pool:map({}, function(v) return v end)
		this(#result).equal(0)
	end,

	["ThreadPool - getSize returns configured capacity"] = function()
		local pool = ThreadPool.new(8)
		this(pool:getSize()).equal(8)
	end,

	-- ------------------------------------------------------------------ Benchmark
	["Benchmark - measure records entry"] = function()
		local bench  = Benchmark.new()
		local seqSort = SequentialSort.new()
		bench:measure("Test/10", seqSort, {5, 3, 1, 4, 2})
		local records = bench:getRecords()
		this(#records).equal(1)
		this(records[1].label).equal("Test/10")
	end,

	["Benchmark - summarize returns non-empty string"] = function()
		local bench  = Benchmark.new()
		local seqSort = SequentialSort.new()
		bench:measure("Seq/5", seqSort, {5, 3, 1, 4, 2})
		local s = bench:summarize()
		this(type(s)).equal("string")
		assert(#s > 0, "summarize should not return empty string")
	end,

	["Benchmark - clear resets records"] = function()
		local bench = Benchmark.new()
		local seqSort = SequentialSort.new()
		bench:measure("A", seqSort, {1, 2})
		bench:clear()
		this(#bench:getRecords()).equal(0)
	end,

	["Benchmark - speedupRatio returns number when both labels exist"] = function()
		local bench   = Benchmark.new()
		local seqSort = SequentialSort.new()
		local parSort = ParallelSort.new(4)
		local data    = makeRandom(500)
		bench:measure("Seq/500", seqSort, table.clone(data))
		bench:measure("Par/500", parSort, table.clone(data))
		local ratio = bench:speedupRatio("Seq/500", "Par/500")
		this(type(ratio)).equal("number")
	end,

	["Benchmark - speedupRatio returns nil for unknown label"] = function()
		local bench = Benchmark.new()
		local ratio = bench:speedupRatio("missing-a", "missing-b")
		this(ratio).never.exist()
	end,

	-- ------------------------------------------------------------------ SequentialSort
	["SequentialSort - sorts small array correctly"] = function()
		local s = SequentialSort.new()
		local result = s:run({5, 3, 8, 1, 9, 2})
		this(isSorted(result)).equal(true)
		this(#result).equal(6)
	end,

	["SequentialSort - handles empty array"] = function()
		local s = SequentialSort.new()
		local result = s:run({})
		this(#result).equal(0)
	end,

	["SequentialSort - handles single element"] = function()
		local s = SequentialSort.new()
		local result = s:run({42})
		this(result[1]).equal(42)
	end,

	["SequentialSort - handles already sorted input"] = function()
		local s = SequentialSort.new()
		local result = s:run({1, 2, 3, 4, 5})
		this(isSorted(result)).equal(true)
	end,

	["SequentialSort - handles reverse sorted input"] = function()
		local s = SequentialSort.new()
		local result = s:run({9, 8, 7, 6, 5, 4, 3, 2, 1})
		this(isSorted(result)).equal(true)
	end,

	["SequentialSort - handles duplicates"] = function()
		local s = SequentialSort.new()
		local result = s:run({3, 1, 4, 1, 5, 9, 2, 6, 5})
		this(isSorted(result)).equal(true)
		this(#result).equal(9)
	end,

	["SequentialSort - records elapsed time after run"] = function()
		local s = SequentialSort.new()
		s:run(makeRandom(1000))
		assert(s:getLastTime() >= 0, "Expected non-negative elapsed time")
	end,

	-- ------------------------------------------------------------------ ParallelSort
	["ParallelSort - sorts small array correctly"] = function()
		local p = ParallelSort.new(2)
		local result = p:run({5, 3, 8, 1, 9, 2})
		this(isSorted(result)).equal(true)
		this(#result).equal(6)
	end,

	["ParallelSort - handles empty array"] = function()
		local p = ParallelSort.new(4)
		local result = p:run({})
		this(#result).equal(0)
	end,

	["ParallelSort - handles single element"] = function()
		local p = ParallelSort.new(4)
		local result = p:run({7})
		this(result[1]).equal(7)
	end,

	["ParallelSort - result matches SequentialSort on 500 random elements"] = function()
		local data = makeRandom(500)
		local seqResult = SequentialSort.new():run(table.clone(data))
		local parResult = ParallelSort.new(4):run(table.clone(data))
		this(arraysEqual(seqResult, parResult)).equal(true)
	end,

	["ParallelSort - result matches SequentialSort on 1000 elements"] = function()
		local data = makeRandom(1000)
		local seqResult = SequentialSort.new():run(table.clone(data))
		local parResult = ParallelSort.new(8):run(table.clone(data))
		this(arraysEqual(seqResult, parResult)).equal(true)
	end,

	["ParallelSort - setWorkerCount changes pool size"] = function()
		local p = ParallelSort.new(2)
		p:setWorkerCount(8)
		this(p:getWorkerCount()).equal(8)
	end,

	["ParallelSort - handles more workers than elements"] = function()
		local p = ParallelSort.new(16)
		local result = p:run({3, 1, 2})
		this(isSorted(result)).equal(true)
	end,

	-- ------------------------------------------------------------------ SequentialSearch
	["SequentialSearch - finds existing value"] = function()
		local s = SequentialSearch.new()
		local result = s:run({10, 20, 30, 20, 40}, 20)
		this(#result).equal(2)
		this(result[1]).equal(2)
		this(result[2]).equal(4)
	end,

	["SequentialSearch - returns empty for missing value"] = function()
		local s = SequentialSearch.new()
		local result = s:run({1, 2, 3}, 99)
		this(#result).equal(0)
	end,

	["SequentialSearch - handles empty array"] = function()
		local s = SequentialSearch.new()
		local result = s:run({}, 5)
		this(#result).equal(0)
	end,

	["SequentialSearch - finds all duplicates"] = function()
		local s = SequentialSearch.new()
		local data = {7, 7, 7, 7, 7}
		local result = s:run(data, 7)
		this(#result).equal(5)
	end,

	-- ------------------------------------------------------------------ ParallelSearch
	["ParallelSearch - finds existing value"] = function()
		local p = ParallelSearch.new(4)
		local result = p:run({10, 20, 30, 20, 40}, 20)
		this(#result).equal(2)
		this(result[1]).equal(2)
		this(result[2]).equal(4)
	end,

	["ParallelSearch - returns empty for missing value"] = function()
		local p = ParallelSearch.new(4)
		local result = p:run({1, 2, 3}, 99)
		this(#result).equal(0)
	end,

	["ParallelSearch - result matches SequentialSearch on 1000 elements"] = function()
		local data = makeRandom(1000, 50)  -- small max -> lots of duplicates
		local target = 25
		local seqResult = SequentialSearch.new():run(data, target)
		local parResult = ParallelSearch.new(4):run(data, target)
		this(arraysEqual(seqResult, parResult)).equal(true)
	end,

	["ParallelSearch - handles empty array"] = function()
		local p = ParallelSearch.new(4)
		local result = p:run({}, 5)
		this(#result).equal(0)
	end,

	["ParallelSearch - results are sorted by index"] = function()
		local p = ParallelSearch.new(4)
		local data = {}
		for i = 1, 40 do data[i] = (i % 3 == 0) and 99 or i end
		local result = p:run(data, 99)
		for i = 2, #result do
			assert(result[i] > result[i-1], "Expected results sorted ascending")
		end
	end,
}
