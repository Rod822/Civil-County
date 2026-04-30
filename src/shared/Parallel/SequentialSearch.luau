--[[
	@module SequentialSearch
	@desc Sequential linear search. Scans the array from index 1 to n
	      and returns all matching indices.
	@pattern Strategy (implements IAlgorithm)
]]

local IAlgorithm = require(script.Parent.IAlgorithm)

local SequentialSearch = setmetatable({}, { __index = IAlgorithm })
SequentialSearch.__index = SequentialSearch

--[[
	@function new
	@return SequentialSearch
]]
function SequentialSearch.new()
	local self = IAlgorithm.new()
	setmetatable(self, SequentialSearch)
	self._name = "SequentialSearch"
	return self
end

--[[
	@function _execute
	@desc Scans data linearly for target; returns table of matching indices.
	@param data   { any }   Source array
	@param target any       Value to find
	@return { number }      Sorted list of matching indices (empty if none)
]]
function SequentialSearch:_execute(data: { any }, target: any): { number }
	local found = {}
	for i, v in ipairs(data) do
		if v == target then
			found[#found + 1] = i
		end
	end
	return found
end

return SequentialSearch
