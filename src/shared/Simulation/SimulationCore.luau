--[[
	@module SimulationCore
	@desc Orchestrates the multi-agent city simulation.
	      Each agent runs its tick() inside a task.spawn worker; the main
	      loop fires every _tickInterval seconds using task.delay.
	      Implements the Subject side of the Observer pattern: observers
	      receive a stats snapshot after every tick.

	      Sequential mode (for benchmarking): agents are ticked in a plain
	      for-loop on the calling thread instead of via task.spawn.
	@pattern Observer (subject), Command (receiver)
]]

local SimAgent               = require(script.Parent.SimAgent)
local CitizenAgent           = require(script.Parent.CitizenAgent)
local OfficerAgent           = require(script.Parent.OfficerAgent)

local SimulationCore = {}
SimulationCore.__index = SimulationCore

--[[
	@function new
	@param config { citizenCount, officerCount, tickInterval, parallel }
	@return SimulationCore
]]
function SimulationCore.new(config: {
	citizenCount:  number?,
	officerCount:  number?,
	tickInterval:  number?,
	parallel:      boolean?,
	zoneCenter:    Vector3?,
	zoneRadius:    number?,
	waypoints:     { Vector3 }?,
}?)
	config = config or {}
	local self = setmetatable({}, SimulationCore)

	self._citizenCount  = config.citizenCount  or 10
	self._officerCount  = config.officerCount  or 3
	self._tickInterval  = config.tickInterval  or 1.0
	self._parallel      = config.parallel      ~= false
	self._zoneCenter    = config.zoneCenter    or Vector3.new(0, 3, 0)
	self._zoneRadius    = config.zoneRadius    or 40
	self._waypoints     = config.waypoints     or nil

	self._agents    = {}
	self._observers = {}
	self._running   = false
	self._riotActive = false
	self._tickNum   = 0
	self._loopHandle = nil

	-- Benchmark: seconds spent on the last full tick across all agents
	self._lastTickTime = 0

	self:_populate()
	return self
end

function SimulationCore:_injectWaypoints(agent: any)
	if self._waypoints then
		agent._waypoints = self._waypoints
	end
end

function SimulationCore:_populate()
	self._agents = {}
	for _ = 1, self._citizenCount do
		local a = CitizenAgent.new(self._zoneCenter, self._zoneRadius)
		self:_injectWaypoints(a)
		self._agents[#self._agents + 1] = a
	end
	for _ = 1, self._officerCount do
		local a = OfficerAgent.new(nil, self._zoneCenter, self._zoneRadius)
		self:_injectWaypoints(a)
		self._agents[#self._agents + 1] = a
	end
end

-- ── Observer management ───────────────────────────────────────────────────────

--[[
	@function attach
	@param observer ISimObserver
	@return boolean
]]
function SimulationCore:attach(observer: any): boolean
	for _, o in ipairs(self._observers) do
		if o:getName() == observer:getName() then return false end
	end
	self._observers[#self._observers + 1] = observer
	return true
end

--[[
	@function detach
	@param name string  Observer name
	@return boolean
]]
function SimulationCore:detach(name: string): boolean
	for i, o in ipairs(self._observers) do
		if o:getName() == name then
			table.remove(self._observers, i)
			return true
		end
	end
	return false
end

function SimulationCore:_notify(event: string, data: any)
	for _, o in ipairs(self._observers) do
		if o[event] then
			pcall(o[event], o, data)
		end
	end
end

-- ── Tick logic ────────────────────────────────────────────────────────────────

function SimulationCore:_buildStats(): any
	local panicking, responding, conflicting = 0, 0, 0
	local citizens, officers                 = 0, 0
	for _, agent in ipairs(self._agents) do
		if agent.agentType == "Citizen" then
			citizens += 1
			if agent.state == SimAgent.States.Reacting  then panicking  += 1 end
			if agent.state == SimAgent.States.Conflict  then conflicting += 1 end
		elseif agent.agentType == "Officer" then
			officers += 1
			if agent.state == SimAgent.States.Acting then responding += 1 end
		end
	end
	return {
		tick        = self._tickNum,
		citizens    = citizens,
		officers    = officers,
		panicking   = panicking,
		responding  = responding,
		conflicting = conflicting,
		riotActive  = self._riotActive,
	}
end

-- ── Conflict detection & resolution ──────────────────────────────────────────

-- 4 % chance a pair of close citizens starts fighting each tick
local CONFLICT_CHANCE    = 0.04
local FIGHT_DIST         = 6    -- studs; citizens this close can fight
local RESOLVE_DIST       = 8    -- studs; officer this close breaks up the fight

function SimulationCore:_processConflicts()
	-- Collect relevant agents
	local citizens = {}
	local officers = {}
	for _, a in ipairs(self._agents) do
		if a.agentType == "Citizen" and a:isAlive() then
			citizens[#citizens + 1] = a
		elseif a.agentType == "Officer" and a:isAlive() then
			officers[#officers + 1] = a
		end
	end

	-- Spawn new conflicts between idle/moving citizen pairs
	for i = 1, #citizens do
		local a = citizens[i]
		if a.state == SimAgent.States.Conflict then continue end
		for j = i + 1, #citizens do
			local b = citizens[j]
			if b.state == SimAgent.States.Conflict then continue end
			local dist = (a.position - b.position).Magnitude
			if dist <= FIGHT_DIST and math.random() < CONFLICT_CHANCE then
				a._provoked = true
				b._provoked = true
				a:transitionTo(SimAgent.States.Conflict)
				b:transitionTo(SimAgent.States.Conflict)
				-- Notify the nearest idle/moving officer
				local midpoint = (a.position + b.position) * 0.5
				local nearest, bestDist = nil, math.huge
				for _, off in ipairs(officers) do
					if off.state ~= SimAgent.States.Acting then
						local d = (off.position - midpoint).Magnitude
						if d < bestDist then bestDist = d; nearest = off end
					end
				end
				if nearest then
					nearest._conflictTarget = midpoint
				end
			end
		end
	end

	-- Resolve conflicts when an officer is close enough
	for _, off in ipairs(officers) do
		if off.state ~= SimAgent.States.Acting or not off._conflictTarget then continue end
		local offPos = off.position
		if (offPos - off._conflictTarget).Magnitude <= RESOLVE_DIST then
			-- Clear provoked flag on all nearby fighters
			for _, a in ipairs(citizens) do
				if a.state == SimAgent.States.Conflict then
					local d = (a.position - off._conflictTarget).Magnitude
					if d <= RESOLVE_DIST * 1.5 then
						a._provoked = false
					end
				end
			end
			off._conflictTarget = nil
		end
	end
end

--[[
	@function _doTick
	@desc Runs one simulation tick. In parallel mode each agent is spawned
	      into its own task.spawn; results are awaited before building stats.
	      In sequential mode agents are ticked in a plain for-loop.
]]
function SimulationCore:_doTick()
	self._tickNum += 1

	-- Derive riot state from officer-to-citizen ratio and panic rate
	local stats0 = self:_buildStats()
	local prevRiot = self._riotActive
	if stats0.citizens > 0 then
		local panicRate = stats0.panicking / stats0.citizens
		self._riotActive = panicRate >= 0.40
	end
	if self._riotActive ~= prevRiot then
		self:_notify("onRiotChanged", self._riotActive)
	end

	-- Propagate riot flag to agents
	for _, agent in ipairs(self._agents) do
		if agent.agentType == "Citizen" then
			agent:setRiotNearby(self._riotActive)
		elseif agent.agentType == "Officer" then
			agent:setRiotActive(self._riotActive)
		end
	end

	local t0 = os.clock()

	if self._parallel then
		local done = 0
		local total = #self._agents
		for _, agent in ipairs(self._agents) do
			task.spawn(function()
				agent:tick()
				done += 1
			end)
		end
		while done < total do
			task.wait()
		end
	else
		for _, agent in ipairs(self._agents) do
			agent:tick()
		end
	end

	self._lastTickTime = os.clock() - t0

	-- Detect new fights and let officers resolve existing ones
	self:_processConflicts()

	self:_notify("onTick", self:_buildStats())
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

--[[
	@function start
	@desc Begins the simulation loop using recurring task.delay calls.
]]
function SimulationCore:start()
	if self._running then return end
	self._running = true
	local function loop()
		if not self._running then return end
		self:_doTick()
		task.delay(self._tickInterval, loop)
	end
	task.delay(0, loop)
end

--[[
	@function pause
	@desc Halts the loop without resetting agent state.
]]
function SimulationCore:pause()
	self._running = false
end

--[[
	@function reset
	@desc Pauses, re-creates all agents, and resets counters.
]]
function SimulationCore:reset()
	self._running    = false
	self._tickNum    = 0
	self._riotActive = false
	self:_populate()
end

--[[
	@function runFor
	@desc Synchronously runs N ticks (blocking, no task.delay). Useful for
	      benchmarking and tests where async scheduling is inconvenient.
	@param n number
]]
function SimulationCore:runFor(n: number)
	for _ = 1, n do
		self:_doTick()
	end
end

-- ── Accessors (Command receiver interface) ────────────────────────────────────

function SimulationCore:isRunning():      boolean return self._running       end
function SimulationCore:getTickInterval(): number  return self._tickInterval  end
function SimulationCore:getTickCount():    number  return self._tickNum       end
function SimulationCore:isRiotActive():   boolean return self._riotActive    end
function SimulationCore:getLastTickTime(): number  return self._lastTickTime  end
function SimulationCore:getAgentCount():  number  return #self._agents       end

function SimulationCore:setTickInterval(v: number)
	self._tickInterval = math.max(0.05, v)
end

function SimulationCore:setParallel(v: boolean)
	self._parallel = v
end

function SimulationCore:isParallel(): boolean
	return self._parallel
end

-- ── Agent factory helpers (for tests / dynamic spawning) ─────────────────────

--[[
	@function addCitizen
	@return CitizenAgent
]]
function SimulationCore:addCitizen(): any
	local a = CitizenAgent.new(self._zoneCenter, self._zoneRadius)
	self:_injectWaypoints(a)
	self._agents[#self._agents + 1] = a
	self:_notify("onAgentAdded", a)
	return a
end

--[[
	@function addOfficer
	@param rank string?
	@return OfficerAgent
]]
function SimulationCore:addOfficer(rank: string?): any
	local a = OfficerAgent.new(rank, self._zoneCenter, self._zoneRadius)
	self:_injectWaypoints(a)
	self._agents[#self._agents + 1] = a
	self:_notify("onAgentAdded", a)
	return a
end

--[[
	@function getAgents
	@desc Exposes the agent list for server-side NPC rendering.
	@return { any }
]]
function SimulationCore:getAgents(): { any }
	return self._agents
end

return SimulationCore
