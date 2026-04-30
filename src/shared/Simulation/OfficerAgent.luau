--[[
	@module OfficerAgent
	@desc Police/fire officer simulation agent.
	      Sets _targetPosition each tick; actual Humanoid movement is
	      handled server-side by SimulationServer via PathfindingService.
	@pattern Strategy (behavior), State (inherited from SimAgent)
]]

local SimAgent = require(script.Parent.SimAgent)

-- ── Behavior strategy ────────────────────────────────────────────────────────

local OfficerBehavior = {}
OfficerBehavior.__index = OfficerBehavior

function OfficerBehavior.new()
	return setmetatable({ responseChance = 0.70 }, OfficerBehavior)
end

function OfficerBehavior:decide(agent: any): string?
	local rng = math.random()
	-- Respond to a specific street conflict OR a full riot
	local shouldRespond = agent._riotActive or agent._conflictTarget ~= nil

	if shouldRespond then
		if agent.state ~= SimAgent.States.Acting then
			if rng < self.responseChance then
				return SimAgent.States.Acting
			end
		end
	else
		if agent.state == SimAgent.States.Acting then
			return SimAgent.States.Moving
		elseif agent.state == SimAgent.States.Idle then
			if rng < 0.50 then return SimAgent.States.Moving end
		end
	end
	return nil
end

-- ── OfficerAgent ─────────────────────────────────────────────────────────────

local OfficerAgent = setmetatable({}, { __index = SimAgent })
OfficerAgent.__index = OfficerAgent

--[[
	@function new
	@param rank       string?
	@param zoneCenter Vector3?
	@param zoneRadius number?
	@return OfficerAgent
]]
function OfficerAgent.new(rank: string?, zoneCenter: Vector3?, zoneRadius: number?)
	local behavior = OfficerBehavior.new()
	local self = SimAgent.new("Officer", behavior)
	setmetatable(self, OfficerAgent)

	self.rank             = rank or "Police"
	self._riotActive      = false
	self._conflictTarget  = nil   -- Vector3 set by SimulationCore when a fight is nearby
	self._responseTicks   = 0
	self._zoneCenter      = zoneCenter or Vector3.new(0, 3, 0)
	self._zoneRadius      = zoneRadius or 40
	self.moveSpeed        = 10

	-- Officers start near the perimeter
	local angle = math.random() * math.pi * 2
	local dist  = self._zoneRadius * (0.7 + math.random() * 0.25)
	local c     = self._zoneCenter
	self.position = Vector3.new(
		c.X + math.cos(angle) * dist,
		c.Y,
		c.Z + math.sin(angle) * dist
	)

	return self
end

function OfficerAgent:setRiotActive(active: boolean)
	self._riotActive = active
end

function OfficerAgent:_afterTick()
	if self.state == SimAgent.States.Acting then
		self._responseTicks += 1
		-- Head toward the specific fight location, or zone centre during a riot
		self._targetPosition = self._conflictTarget or self._zoneCenter

	elseif self.state == SimAgent.States.Moving then
		if not self._targetPosition then
			if self._waypoints and #self._waypoints > 0 then
				self._targetPosition = self._waypoints[math.random(#self._waypoints)]
			else
				local angle = math.random() * math.pi * 2
				local dist  = self._zoneRadius * (0.3 + math.random() * 0.55)
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
	@function getResponseTicks
	@return number
]]
function OfficerAgent:getResponseTicks(): number
	return self._responseTicks
end

OfficerAgent.Behavior = OfficerBehavior
return OfficerAgent
