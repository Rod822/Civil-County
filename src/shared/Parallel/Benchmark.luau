--[[
	@module Benchmark
	@desc Timing utilities for comparing sequential vs parallel algorithm runs.
	      Stores results per algorithm and produces summary tables.
]]

local Benchmark = {}
Benchmark.__index = Benchmark

--[[
	@function new
	@return Benchmark
]]
function Benchmark.new()
	local self = setmetatable({}, Benchmark)
	self._records = {}
	return self
end

--[[
	@function measure
	@desc Runs algorithm.run(data, ...) and records the elapsed time.
	@param label     string       Identifier used in the report (e.g. "Sequential/1000")
	@param algorithm IAlgorithm   Any object with :run() and :getLastTime()
	@param data      { any }
	@param ...       any          Forwarded to algorithm:run()
	@return any      The algorithm result (pass-through)
]]
function Benchmark:measure(label: string, algorithm: any, data: { any }, ...: any): any
	local result = algorithm:run(data, ...)
	local elapsed = algorithm:getLastTime()
	table.insert(self._records, {
		label   = label,
		time    = elapsed,
		size    = #data,
		algo    = algorithm:getName(),
	})
	return result
end

--[[
	@function getRecords
	@return { { label, time, size, algo } }
]]
function Benchmark:getRecords(): { any }
	return self._records
end

--[[
	@function clear
]]
function Benchmark:clear()
	self._records = {}
end

--[[
	@function summarize
	@desc Returns a human-readable string table of all recorded measurements.
	@return string
]]
function Benchmark:summarize(): string
	local lines = { string.format("%-40s %-25s %12s %10s", "Label", "Algorithm", "Input Size", "Time (ms)") }
	table.insert(lines, string.rep("-", 92))
	for _, r in ipairs(self._records) do
		table.insert(lines, string.format(
			"%-40s %-25s %12d %10.4f",
			r.label, r.algo, r.size, r.time * 1000
		))
	end
	return table.concat(lines, "\n")
end

--[[
	@function speedupRatio
	@desc Given two labels, computes parallel speedup = seqTime / parTime.
	@param seqLabel string
	@param parLabel string
	@return number | nil
]]
function Benchmark:speedupRatio(seqLabel: string, parLabel: string): number?
	local seqTime, parTime
	for _, r in ipairs(self._records) do
		if r.label == seqLabel then seqTime = r.time end
		if r.label == parLabel then parTime = r.time end
	end
	if seqTime and parTime and parTime > 0 then
		return seqTime / parTime
	end
	return nil
end

return Benchmark
