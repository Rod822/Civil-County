local PersistentData = {}
PersistentData.__index = PersistentData

export type PersistentData = {
	Money: number,
}

local DEFAULTS = {
	Money = 200,
}

function PersistentData.new(tableFromDataStore: { [string]: any }?): PersistentData
	local obj = {
		Money = (tableFromDataStore and tonumber(tableFromDataStore.Money)) or DEFAULTS.Money,
	}
	return setmetatable(obj, PersistentData)
end

return PersistentData
