--[[
	@class MissionTemplate
	@desc Template Method pattern for mission execution
	@pattern Template Method
	
	Defines the skeleton of an algorithm in the base class and lets
	subclasses override specific steps. Useful for different mission types.
]]

local MissionTemplate = {}

--[[
	@class IMissionTemplate
	@desc Abstract base class for mission templates
]]
local IMissionTemplate = {}
IMissionTemplate.__index = IMissionTemplate

function IMissionTemplate.new()
	return setmetatable({}, IMissionTemplate)
end

-- Template method - defines the algorithm structure
function IMissionTemplate:executeMission(player: Player): boolean
	-- Step 1: Validate player can do mission
	if not self:validatePlayer(player) then
		print("Validation failed for player: " .. player.Name)
		return false
	end

	-- Step 2: Setup mission
	self:setupMission(player)

	-- Step 3: Run mission (override in subclass)
	local success = self:runMission(player)

	-- Step 4: Calculate rewards (override in subclass)
	local reward = self:calculateReward(success)

	-- Step 5: Give rewards
	if success then
		self:giveRewards(player, reward)
	end

	-- Step 6: Cleanup
	self:cleanupMission(player)

	return success
end

-- Methods to be overridden in subclasses
function IMissionTemplate:validatePlayer(_player: Player): boolean
	error("validatePlayer must be implemented")
end

function IMissionTemplate:setupMission(_player: Player)
	error("setupMission must be implemented")
end

function IMissionTemplate:runMission(_player: Player): boolean
	error("runMission must be implemented")
end

function IMissionTemplate:calculateReward(_success: boolean): number
	error("calculateReward must be implemented")
end

function IMissionTemplate:giveRewards(_player: Player, _reward: number)
	error("giveRewards must be implemented")
end

function IMissionTemplate:cleanupMission(_player: Player)
	error("cleanupMission must be implemented")
end

--[[
	@class PatrolMissionTemplate
	@desc Template for patrol-type missions
]]
local PatrolMissionTemplate = setmetatable({}, IMissionTemplate)
PatrolMissionTemplate.__index = PatrolMissionTemplate

function PatrolMissionTemplate.new(): PatrolMissionTemplate
	return setmetatable({}, PatrolMissionTemplate)
end

function PatrolMissionTemplate:validatePlayer(player: Player): boolean
	-- Check if player is Police job
	return player.Team and player.Team.Name == "Police"
end

function PatrolMissionTemplate:setupMission(_player: Player)
	print("Setting up patrol mission...")
	-- Load patrol waypoints
	-- Display patrol route
end

function PatrolMissionTemplate:runMission(player: Player): boolean
	print("Patrol mission running for: " .. player.Name)
	-- Simulate patrol
	task.wait(2) -- Would actually run patrol logic
	return math.random() > 0.2 -- 80% success rate
end

function PatrolMissionTemplate:calculateReward(success: boolean): number
	return success and 150 or 50
end

function PatrolMissionTemplate:giveRewards(_player: Player, reward: number)
	print("Giving patrol reward: " .. reward)
	-- Give money
end

function PatrolMissionTemplate:cleanupMission(_player: Player)
	print("Cleaning up patrol mission...")
	-- Remove patrol UI
	-- Save data
end

--[[
	@class RescueMissionTemplate
	@desc Template for rescue-type missions
]]
local RescueMissionTemplate = setmetatable({}, IMissionTemplate)
RescueMissionTemplate.__index = RescueMissionTemplate

function RescueMissionTemplate.new(): RescueMissionTemplate
	return setmetatable({}, RescueMissionTemplate)
end

function RescueMissionTemplate:validatePlayer(player: Player): boolean
	-- Check if player is Fire Service or Paramedic
	return player.Team and (player.Team.Name == "Fire Service" or player.Team.Name == "Paramedic")
end

function RescueMissionTemplate:setupMission(_player: Player)
	print("Setting up rescue mission...")
	-- Load rescue location
	-- Brief on rescue type
end

function RescueMissionTemplate:runMission(player: Player): boolean
	print("Rescue mission running for: " .. player.Name)
	-- Simulate rescue
	task.wait(3)
	return math.random() > 0.1 -- 90% success rate
end

function RescueMissionTemplate:calculateReward(success: boolean): number
	return success and 200 or 100
end

function RescueMissionTemplate:giveRewards(_player: Player, reward: number)
	print("Giving rescue reward: " .. reward)
	-- Give money and reputation
end

function RescueMissionTemplate:cleanupMission(_player: Player)
	print("Cleaning up rescue mission...")
	-- Update rescue stats
end

--[[
	@class InvestigationMissionTemplate
	@desc Template for investigation missions
]]
local InvestigationMissionTemplate = setmetatable({}, IMissionTemplate)
InvestigationMissionTemplate.__index = InvestigationMissionTemplate

function InvestigationMissionTemplate.new(): InvestigationMissionTemplate
	return setmetatable({}, InvestigationMissionTemplate)
end

function InvestigationMissionTemplate:validatePlayer(player: Player): boolean
	-- Check if player is Police
	return player.Team and player.Team.Name == "Police"
end

function InvestigationMissionTemplate:setupMission(_player: Player)
	print("Setting up investigation mission...")
	-- Load evidence
	-- Display investigation objectives
end

function InvestigationMissionTemplate:runMission(player: Player): boolean
	print("Investigation mission running for: " .. player.Name)
	-- Simulate investigation
	task.wait(4)
	return math.random() > 0.3 -- 70% success rate
end

function InvestigationMissionTemplate:calculateReward(success: boolean): number
	return success and 250 or 75
end

function InvestigationMissionTemplate:giveRewards(_player: Player, reward: number)
	print("Giving investigation reward: " .. reward)
	-- Give money and evidence
end

function InvestigationMissionTemplate:cleanupMission(_player: Player)
	print("Cleaning up investigation mission...")
	-- Record findings
end

-- Export all mission templates
MissionTemplate.IMissionTemplate = IMissionTemplate
MissionTemplate.PatrolMissionTemplate = PatrolMissionTemplate
MissionTemplate.RescueMissionTemplate = RescueMissionTemplate
MissionTemplate.InvestigationMissionTemplate = InvestigationMissionTemplate

return MissionTemplate
