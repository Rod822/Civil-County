--[[
	@module CitizenAgent
	@desc Civilian simulation agent. Uses CitizenBehavior strategy.
	      The agent owns its logical _targetPosition; the server-side
	      SimulationServer reads that field and drives a real Humanoid NPC
	      via PathfindingService. The agent never moves position directly.
	@pattern Strategy (behavior), State (inherited from SimAgent)
]]

local SimAgent = require(script.Parent.SimAgent)

-- ── Behavior strategy ────────────────────────────────────────────────────────

local CitizenBehavior = {}
CitizenBehavior.__index = CitizenBehavior

function CitizenBehavior.new()
	return setmetatable({ panicChance = 0.15, calmChance = 0.40 }, CitizenBehavior)
end

function CitizenBehavior:decide(agent: any): string?
	local rng = math.random()

	-- Conflict state: stay fighting while provoked, otherwise settle down
	if agent.state == SimAgent.States.Conflict then
		if not agent._provoked then
			return SimAgent.States.Idle
		end
		return nil
	end

	if agent.state == SimAgent.States.Idle then
		if rng < 0.35 then return SimAgent.States.Moving end
		if agent._riotNearby and rng < 0.35 + self.panicChance then
			return SimAgent.States.Reacting
		end
	elseif agent.state == SimAgent.States.Moving then
		if agent._riotNearby and rng < self.panicChance then
			return SimAgent.States.Reacting
		end
	elseif agent.state == SimAgent.States.Reacting then
		if not agent._riotNearby or rng < self.calmChance then
			return SimAgent.States.Idle
		end
	end
	return nil
end

-- ── CitizenAgent ─────────────────────────────────────────────────────────────

local CitizenAgent = setmetatable({}, { __index = SimAgent })
CitizenAgent.__index = CitizenAgent

--[[
	@function new
	@param zoneCenter Vector3?
	@param zoneRadius number?
	@return CitizenAgent
]]
function CitizenAgent.new(zoneCenter: Vector3?, zoneRadius: number?)
	local behavior = CitizenBehavior.new()
	local self = SimAgent.new("Citizen", behavior)
	setmetatable(self, CitizenAgent)

	self._riotNearby  = false
	self._provoked    = false   -- set true by SimulationCore when in a fight
	self._panicEvents = 0
	self._zoneCenter  = zoneCenter or Vector3.new(0, 3, 0)
	self._zoneRadius  = zoneRadius or 40

	-- Random initial position scattered inside zone
	local angle = math.random() * math.pi * 2
	local dist  = math.random() * self._zoneRadius * 0.85
	local c     = self._zoneCenter
	self.position = Vector3.new(
		c.X + math.cos(angle) * dist,
		c.Y,
		c.Z + math.sin(angle) * dist
	)

	return self
end

function CitizenAgent:setRiotNearby(active: boolean)
	self._riotNearby = active
end

function CitizenAgent:_afterTick()
	if self.state == SimAgent.States.Conflict then
		-- Stay in place during a fight; clear any pending movement
		self._targetPosition = nil

	elseif self.state == SimAgent.States.Reacting then
		self._panicEvents += 1
		-- Flee: aim away from zone centre (server moves the NPC)
		if not self._targetPosition then
			local away = self.position - self._zoneCenter
			local dir  = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
			local flee = self.position + dir * self._zoneRadius * 0.6
			local offset = flee - self._zoneCenter
			if offset.Magnitude > self._zoneRadius then
				flee = self._zoneCenter + offset.Unit * self._zoneRadius
			end
			self._targetPosition = flee
		end

	elseif self.state == SimAgent.States.Moving then
		if not self._targetPosition then
			if self._waypoints and #self._waypoints > 0 then
				self._targetPosition = self._waypoints[math.random(#self._waypoints)]
			else
				local angle = math.random() * math.pi * 2
				local dist  = math.random() * self._zoneRadius * 0.8
				local c     = self._zoneCenter
				self._targetPosition = Vector3.new(
					c.X + math.cos(angle) * dist,
					c.Y,
					c.Z + math.sin(angle) * dist
				)
			end
		end
	end
end

--[[
	@function getPanicEvents
	@return number
]]
function CitizenAgent:getPanicEvents(): number
	return self._panicEvents
end

CitizenAgent.Behavior = CitizenBehavior
return CitizenAgent
