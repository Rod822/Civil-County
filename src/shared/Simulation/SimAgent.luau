--[[
	@module SimAgent
	@desc Abstract base class for simulation agents.
	      Each agent maintains a state machine (Idle → Moving → Acting → Reacting)
	      and runs its update loop inside a task.spawn coroutine managed by SimulationCore.
	@pattern State, Template Method
]]

local SimAgent = {}
SimAgent.__index = SimAgent

-- Valid states
SimAgent.States = {
	Idle     = "Idle",
	Moving   = "Moving",
	Acting   = "Acting",
	Reacting = "Reacting",
	Conflict = "Conflict",   -- actively fighting another agent
	Done     = "Done",
}

-- Allowed state transitions
local TRANSITIONS = {
	Idle     = { Moving = true, Reacting = true, Conflict = true, Done = true },
	Moving   = { Idle = true, Acting = true, Reacting = true, Conflict = true, Done = true },
	Acting   = { Idle = true, Moving = true, Reacting = true, Done = true },
	Reacting = { Idle = true, Moving = true, Done = true },
	Conflict = { Idle = true, Moving = true, Done = true },
	Done     = {},
}

local _nextId = 0
local function newId()
	_nextId += 1
	return _nextId
end

--[[
	@function new
	@param agentType string  "Citizen" | "Officer"
	@param behavior  table   Strategy object with :decide(agent) -> nextState
	@return SimAgent
]]
function SimAgent.new(agentType: string, behavior: any)
	local self = setmetatable({}, SimAgent)
	self.id               = newId()
	self.agentType        = agentType
	self.state            = SimAgent.States.Idle
	self._behavior        = behavior
	self._stateHistory    = { SimAgent.States.Idle }
	self._tickCount       = 0
	self._alive           = true
	self._listeners       = {}
	-- World position — set by subclasses after zone info is known
	self.position         = Vector3.new(0, 3, 0)
	self.moveSpeed        = 8   -- studs per tick
	self._targetPosition  = nil :: Vector3?
	return self
end

--[[
	@function transitionTo
	@desc Attempts a state transition. Fires listeners on success.
	@param newState string
	@return boolean
]]
function SimAgent:transitionTo(newState: string): boolean
	if not SimAgent.States[newState] then
		return false
	end
	local allowed = TRANSITIONS[self.state]
	if not allowed or not allowed[newState] then
		return false
	end
	self.state = newState
	self._stateHistory[#self._stateHistory + 1] = newState
	for _, fn in ipairs(self._listeners) do
		pcall(fn, self, newState)
	end
	return true
end

--[[
	@function onStateChange
	@desc Registers a listener called whenever the state changes.
	@param fn (agent, newState) -> ()
]]
function SimAgent:onStateChange(fn: (any, string) -> ())
	self._listeners[#self._listeners + 1] = fn
end

--[[
	@function tick
	@desc Called once per simulation frame. Delegates to the behavior strategy.
	      Subclasses can override _beforeTick / _afterTick for hooks.
]]
function SimAgent:tick()
	if not self._alive then return end
	self._tickCount += 1
	self:_beforeTick()
	if self._behavior then
		local nextState = self._behavior:decide(self)
		if nextState and nextState ~= self.state then
			self:transitionTo(nextState)
		end
	end
	self:_afterTick()
end

function SimAgent:_beforeTick() end
function SimAgent:_afterTick()  end

--[[
	@function stop
	@desc Marks the agent as done and transitions to Done state.
]]
function SimAgent:stop()
	self._alive = false
	self.state  = SimAgent.States.Done
end

--[[
	@function getStateHistory
	@return { string }
]]
function SimAgent:getStateHistory(): { string }
	return self._stateHistory
end

--[[
	@function getTickCount
	@return number
]]
function SimAgent:getTickCount(): number
	return self._tickCount
end

--[[
	@function isAlive
	@return boolean
]]
function SimAgent:isAlive(): boolean
	return self._alive
end

return SimAgent
