--[[
	@class PlayerState
	@desc State pattern for player status management
	@pattern State
	
	Allows an object to alter its behavior when internal state changes.
	Player states (Idle, Working, InMission, etc.) change behavior.
]]

local PlayerState = {}

--[[
	@class IPlayerState
	@desc Interface for player states
]]
local IPlayerState = {}
IPlayerState.__index = IPlayerState

function IPlayerState.new()
	return setmetatable({}, IPlayerState)
end

function IPlayerState:onEnter(_context: any)
	error("onEnter must be implemented")
end

function IPlayerState:onExit(_context: any)
	error("onExit must be implemented")
end

function IPlayerState:canTransitionTo(_stateName: string): boolean
	return false
end

function IPlayerState:getName(): string
	error("getName must be implemented")
end

--[[
	@class IdleState
	@desc Player is idle/offline
]]
local IdleState = setmetatable({}, IPlayerState)
IdleState.__index = IdleState

function IdleState.new(): IdleState
	return setmetatable({}, IdleState)
end

function IdleState:onEnter(_context: any)
	-- Stop any active tasks
end

function IdleState:onExit(_context: any)
	-- Prepare for next state
end

function IdleState:canTransitionTo(stateName: string): boolean
	return stateName == "OnDuty" or stateName == "InMission"
end

function IdleState:getName(): string
	return "Idle"
end

--[[
	@class OnDutyState
	@desc Player is on duty at their job location
]]
local OnDutyState = setmetatable({}, IPlayerState)
OnDutyState.__index = OnDutyState

function OnDutyState.new(): OnDutyState
	return setmetatable({}, OnDutyState)
end

function OnDutyState:onEnter(_context: any)
	-- Start earning money
	-- Give job tools
end

function OnDutyState:onExit(_context: any)
	-- Stop earning
	-- Remove tools
end

function OnDutyState:canTransitionTo(stateName: string): boolean
	return stateName == "InMission" or stateName == "Idle" or stateName == "Resting"
end

function OnDutyState:getName(): string
	return "OnDuty"
end

--[[
	@class InMissionState
	@desc Player is actively on a mission
]]
local InMissionState = setmetatable({}, IPlayerState)
InMissionState.__index = InMissionState

function InMissionState.new(): InMissionState
	return setmetatable({}, InMissionState)
end

function InMissionState:onEnter(_context: any)
	-- Start mission
	-- Activate mission UI
	-- Start mission timer
end

function InMissionState:onExit(_context: any)
	-- End mission
	-- Calculate reward
	-- Clean up mission UI
end

function InMissionState:canTransitionTo(stateName: string): boolean
	return stateName == "OnDuty" or stateName == "Resting" or stateName == "Idle"
end

function InMissionState:getName(): string
	return "InMission"
end

--[[
	@class RestingState
	@desc Player is resting/at base
]]
local RestingState = setmetatable({}, IPlayerState)
RestingState.__index = RestingState

function RestingState.new(): RestingState
	return setmetatable({}, RestingState)
end

function RestingState:onEnter(_context: any)
	-- Restore health/stamina
	-- Show rest UI
end

function RestingState:onExit(_context: any)
	-- End rest
	-- Hide rest UI
end

function RestingState:canTransitionTo(stateName: string): boolean
	return stateName == "OnDuty" or stateName == "InMission" or stateName == "Idle"
end

function RestingState:getName(): string
	return "Resting"
end

--[[
	@class OfflineState
	@desc Player is offline
]]
local OfflineState = setmetatable({}, IPlayerState)
OfflineState.__index = OfflineState

function OfflineState.new(): OfflineState
	return setmetatable({}, OfflineState)
end

function OfflineState:onEnter(_context: any)
	-- Save progress
	-- Disconnect
end

function OfflineState:onExit(_context: any)
	-- Restore from save
end

function OfflineState:canTransitionTo(stateName: string): boolean
	return stateName == "Idle"
end

function OfflineState:getName(): string
	return "Offline"
end

--[[
	@class PlayerStateContext
	@desc Manages player state transitions
]]
local PlayerStateContext = {}
PlayerStateContext.__index = PlayerStateContext

export type PlayerStateContext = {
	_currentState: any,
	_player: Player?,
	_stateHistory: { string },
}

function PlayerStateContext.new(initialState: any, player: Player?): PlayerStateContext
	local self = setmetatable({}, PlayerStateContext)
	self._currentState = initialState
	self._player = player
	self._stateHistory = {}
	self._metadata = {}

	if initialState then
		self._currentState:onEnter(self)
		table.insert(self._stateHistory, initialState:getName())
	end

	return self
end

function PlayerStateContext:transitionTo(newState: any): boolean
	if not self._currentState:canTransitionTo(newState:getName()) then
		warn("Cannot transition from " .. self._currentState:getName() .. " to " .. newState:getName())
		return false
	end

	self._currentState:onExit(self)
	self._currentState = newState
	self._currentState:onEnter(self)

	table.insert(self._stateHistory, newState:getName())
	return true
end

function PlayerStateContext:getCurrentState(): any
	return self._currentState
end

function PlayerStateContext:getCurrentStateName(): string
	return self._currentState:getName()
end

function PlayerStateContext:getStateHistory(): { string }
	return self._stateHistory
end

function PlayerStateContext:canTransitionTo(stateName: string): boolean
	-- Find state by name and check if transition is allowed
	return true -- Simplified for this implementation
end

-- Export states
PlayerState.IPlayerState = IPlayerState
PlayerState.IdleState = IdleState
PlayerState.OnDutyState = OnDutyState
PlayerState.InMissionState = InMissionState
PlayerState.RestingState = RestingState
PlayerState.OfflineState = OfflineState
PlayerState.PlayerStateContext = PlayerStateContext

return PlayerState
