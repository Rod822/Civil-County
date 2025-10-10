local SessionData = {}
SessionData.__index = SessionData

export type SessionData = {
	paycheckBonus: number,
	job: string,
}

local DEFAULTS = {
	paycheckBonus = 0,
	job = "Civilian",
}

function SessionData.new(): SessionData
	local obj = table.clone(DEFAULTS)
	return setmetatable(obj, SessionData)
end

return SessionData
