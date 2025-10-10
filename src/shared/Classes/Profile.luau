local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local PersistentData = require(Classes.PersistentData)
local SessionData = require(Classes.SessionData)

local Profile = {}
Profile.__index = Profile

export type Profile = {
	persistent: PersistentData.PersistentData,
	session: SessionData.SessionData,
}

function Profile.new(userId: number, tableFromDataStore: { [string]: any }?): Profile
	local self = setmetatable({}, Profile)
	self.persistent = PersistentData.new(tableFromDataStore)
	self.session = SessionData.new()
	return self
end

return Profile
