--[[
	@module SimulationObserver
	@desc Observer pattern implementation for the city simulation.
	      SimulationCore (subject) notifies attached observers on every
	      tick and on state-change events (riot started/stopped, agent count changed).
	@pattern Observer
]]

-- ── ISimObserver ──────────────────────────────────────────────────────────────

local ISimObserver = {}
ISimObserver.__index = ISimObserver

function ISimObserver.new(name: string)
	return setmetatable({ _name = name }, ISimObserver)
end

function ISimObserver:getName(): string
	return self._name
end

--[[
	@function onTick
	@desc Called every simulation tick with a snapshot of current stats.
	@param stats { citizens, officers, panicking, responding, riotActive, tick }
]]
function ISimObserver:onTick(_stats: any) end

--[[
	@function onRiotChanged
	@param active boolean
]]
function ISimObserver:onRiotChanged(_active: boolean) end

--[[
	@function onAgentAdded
	@param agent SimAgent
]]
function ISimObserver:onAgentAdded(_agent: any) end

-- ── StatsCollectorObserver ────────────────────────────────────────────────────

local StatsCollectorObserver = setmetatable({}, { __index = ISimObserver })
StatsCollectorObserver.__index = StatsCollectorObserver

--[[
	@function new
	@desc Observer that accumulates per-tick snapshots for later analysis.
	@return StatsCollectorObserver
]]
function StatsCollectorObserver.new()
	local self = ISimObserver.new("StatsCollector")
	setmetatable(self, StatsCollectorObserver)
	self._history = {}
	self._riotEvents = 0
	return self
end

function StatsCollectorObserver:onTick(stats: any)
	self._history[#self._history + 1] = {
		tick        = stats.tick,
		citizens    = stats.citizens,
		officers    = stats.officers,
		panicking   = stats.panicking,
		responding  = stats.responding,
		riotActive  = stats.riotActive,
	}
end

function StatsCollectorObserver:onRiotChanged(active: boolean)
	if active then self._riotEvents += 1 end
end

--[[
	@function getHistory
	@return { any }  All recorded tick snapshots
]]
function StatsCollectorObserver:getHistory(): { any }
	return self._history
end

--[[
	@function getRiotEventCount
	@return number
]]
function StatsCollectorObserver:getRiotEventCount(): number
	return self._riotEvents
end

--[[
	@function getLastSnapshot
	@return any | nil
]]
function StatsCollectorObserver:getLastSnapshot(): any
	return self._history[#self._history]
end

-- ── UIObserver ────────────────────────────────────────────────────────────────

local UIObserver = setmetatable({}, { __index = ISimObserver })
UIObserver.__index = UIObserver

--[[
	@function new
	@desc Observer that calls user-supplied callbacks for GUI updates.
	@param callbacks { onTick?, onRiotChanged? }
	@return UIObserver
]]
function UIObserver.new(callbacks: { onTick: ((any) -> ())?, onRiotChanged: ((boolean) -> ())? })
	local self = ISimObserver.new("UIObserver")
	setmetatable(self, UIObserver)
	self._onTick         = callbacks.onTick
	self._onRiotChanged  = callbacks.onRiotChanged
	return self
end

function UIObserver:onTick(stats: any)
	if self._onTick then self._onTick(stats) end
end

function UIObserver:onRiotChanged(active: boolean)
	if self._onRiotChanged then self._onRiotChanged(active) end
end

-- ── Exports ───────────────────────────────────────────────────────────────────

return {
	ISimObserver            = ISimObserver,
	StatsCollectorObserver  = StatsCollectorObserver,
	UIObserver              = UIObserver,
}
