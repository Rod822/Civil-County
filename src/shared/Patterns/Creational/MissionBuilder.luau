--[[
	@class MissionBuilder
	@desc Builder pattern for constructing complex Mission objects
	@pattern Builder
	
	The Builder pattern allows step-by-step construction of complex objects.
	This is useful for creating missions with many optional parameters.
	Separates the construction logic from the representation.
]]

local MissionBuilder = {}
MissionBuilder.__index = MissionBuilder

export type Mission = {
	id: string,
	title: string,
	description: string,
	assignedJob: string,
	reward: number,
	bonusReward: number,
	timeLimit: number,
	difficulty: "Easy" | "Medium" | "Hard",
	requirements: { string },
	objectives: { string },
	status: "Pending" | "Active" | "Completed" | "Failed",
	createdAt: number,
}

--[[
	@method new
	@desc Initializes a new MissionBuilder
	@return MissionBuilder
]]
function MissionBuilder.new()
	local self = setmetatable({}, MissionBuilder)
	self._mission = {
		id = "mission_" .. tostring(tick()):gsub("%.", ""),
		title = "Untitled Mission",
		description = "",
		assignedJob = "Civilian",
		reward = 0,
		bonusReward = 0,
		timeLimit = 300,
		difficulty = "Medium",
		requirements = {},
		objectives = {},
		status = "Pending",
		createdAt = tick(),
	}
	return self
end

--[[
	@method setTitle
	@desc Sets the mission title
	@param title: string
	@return MissionBuilder (for chaining)
]]
function MissionBuilder:setTitle(title: string): MissionBuilder
	self._mission.title = title
	return self
end

--[[
	@method setDescription
	@desc Sets the mission description
	@param description: string
	@return MissionBuilder
]]
function MissionBuilder:setDescription(description: string): MissionBuilder
	self._mission.description = description
	return self
end

--[[
	@method setAssignedJob
	@desc Sets the required job for this mission
	@param job: string
	@return MissionBuilder
]]
function MissionBuilder:setAssignedJob(job: string): MissionBuilder
	self._mission.assignedJob = job
	return self
end

--[[
	@method setReward
	@desc Sets the base reward for completing the mission
	@param reward: number
	@return MissionBuilder
]]
function MissionBuilder:setReward(reward: number): MissionBuilder
	self._mission.reward = math.max(0, reward)
	return self
end

--[[
	@method setBonusReward
	@desc Sets the bonus reward
	@param bonus: number
	@return MissionBuilder
]]
function MissionBuilder:setBonusReward(bonus: number): MissionBuilder
	self._mission.bonusReward = math.max(0, bonus)
	return self
end

--[[
	@method setTimeLimit
	@desc Sets the time limit in seconds
	@param seconds: number
	@return MissionBuilder
]]
function MissionBuilder:setTimeLimit(seconds: number): MissionBuilder
	self._mission.timeLimit = math.max(60, seconds)
	return self
end

--[[
	@method setDifficulty
	@desc Sets the difficulty level
	@param difficulty: string - "Easy", "Medium", or "Hard"
	@return MissionBuilder
]]
function MissionBuilder:setDifficulty(difficulty: string): MissionBuilder
	if difficulty == "Easy" or difficulty == "Medium" or difficulty == "Hard" then
		self._mission.difficulty = difficulty
	end
	return self
end

--[[
	@method addRequirement
	@desc Adds a requirement to the mission
	@param requirement: string
	@return MissionBuilder
]]
function MissionBuilder:addRequirement(requirement: string): MissionBuilder
	table.insert(self._mission.requirements, requirement)
	return self
end

--[[
	@method addObjective
	@desc Adds an objective to the mission
	@param objective: string
	@return MissionBuilder
]]
function MissionBuilder:addObjective(objective: string): MissionBuilder
	table.insert(self._mission.objectives, objective)
	return self
end

--[[
	@method clearRequirements
	@desc Clears all requirements
	@return MissionBuilder
]]
function MissionBuilder:clearRequirements(): MissionBuilder
	self._mission.requirements = {}
	return self
end

--[[
	@method clearObjectives
	@desc Clears all objectives
	@return MissionBuilder
]]
function MissionBuilder:clearObjectives(): MissionBuilder
	self._mission.objectives = {}
	return self
end

--[[
	@method build
	@desc Builds and returns the final Mission object
	@return Mission
]]
function MissionBuilder:build(): Mission
	local mission: Mission = {
		id = self._mission.id,
		title = self._mission.title,
		description = self._mission.description,
		assignedJob = self._mission.assignedJob,
		reward = self._mission.reward,
		bonusReward = self._mission.bonusReward,
		timeLimit = self._mission.timeLimit,
		difficulty = self._mission.difficulty,
		requirements = table.clone(self._mission.requirements),
		objectives = table.clone(self._mission.objectives),
		status = self._mission.status,
		createdAt = self._mission.createdAt,
	}

	-- Validate the mission
	if #mission.objectives == 0 then
		warn("MissionBuilder: Mission '" .. mission.title .. "' has no objectives")
	end

	return mission
end

--[[
	@method reset
	@desc Resets the builder to create a new mission
	@return MissionBuilder
]]
function MissionBuilder:reset(): MissionBuilder
	self._mission = {
		id = "mission_" .. tostring(tick()):gsub("%.", ""),
		title = "Untitled Mission",
		description = "",
		assignedJob = "Civilian",
		reward = 0,
		bonusReward = 0,
		timeLimit = 300,
		difficulty = "Medium",
		requirements = {},
		objectives = {},
		status = "Pending",
		createdAt = tick(),
	}
	return self
end

return MissionBuilder
