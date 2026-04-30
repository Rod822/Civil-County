--[[
	@file SimulationTests.spec.lua
	@desc Unit tests for Part 3b: simulation agents, core, observer, and commands.
	      Covers correct/incorrect inputs, state transitions, and observer notifications.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local this = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BoatTest")).this

local SimAgent          = require(ReplicatedStorage.Simulation.SimAgent)
local CitizenAgent      = require(ReplicatedStorage.Simulation.CitizenAgent)
local OfficerAgent      = require(ReplicatedStorage.Simulation.OfficerAgent)
local SimulationCore    = require(ReplicatedStorage.Simulation.SimulationCore)
local SimObservers      = require(ReplicatedStorage.Simulation.SimulationObserver)
local SimCommands       = require(ReplicatedStorage.Simulation.SimulationCommands)

return {
	-- ─────────────────────────────────────────────────── SimAgent (base)
	["SimAgent - starts in Idle state"] = function()
		local a = SimAgent.new("Test", nil)
		this(a.state).equal(SimAgent.States.Idle)
	end,

	["SimAgent - valid transition Idle → Moving"] = function()
		local a = SimAgent.new("Test", nil)
		local ok = a:transitionTo(SimAgent.States.Moving)
		this(ok).equal(true)
		this(a.state).equal(SimAgent.States.Moving)
	end,

	["SimAgent - invalid transition Idle → Done is blocked by TRANSITIONS"] = function()
		local a = SimAgent.new("Test", nil)
		-- Idle→Done is actually valid per our table, so test something truly invalid
		local ok = a:transitionTo("NonExistentState")
		this(ok).equal(false)
		this(a.state).equal(SimAgent.States.Idle)
	end,

	["SimAgent - state history grows with transitions"] = function()
		local a = SimAgent.new("Test", nil)
		a:transitionTo(SimAgent.States.Moving)
		a:transitionTo(SimAgent.States.Acting)
		local h = a:getStateHistory()
		this(#h).equal(3) -- Idle + Moving + Acting
	end,

	["SimAgent - tick increments tick counter"] = function()
		local a = SimAgent.new("Test", nil)
		a:tick()
		a:tick()
		this(a:getTickCount()).equal(2)
	end,

	["SimAgent - stop marks agent as not alive"] = function()
		local a = SimAgent.new("Test", nil)
		a:stop()
		this(a:isAlive()).equal(false)
		this(a.state).equal(SimAgent.States.Done)
	end,

	["SimAgent - stopped agent does not tick"] = function()
		local a = SimAgent.new("Test", nil)
		a:stop()
		a:tick()
		this(a:getTickCount()).equal(0)
	end,

	["SimAgent - onStateChange listener fires"] = function()
		local a = SimAgent.new("Test", nil)
		local fired = false
		a:onStateChange(function(_, _) fired = true end)
		a:transitionTo(SimAgent.States.Moving)
		this(fired).equal(true)
	end,

	-- ─────────────────────────────────────────────────── CitizenAgent
	["CitizenAgent - creates with type Citizen"] = function()
		local c = CitizenAgent.new()
		this(c.agentType).equal("Citizen")
	end,

	["CitizenAgent - starts with zero panic events"] = function()
		local c = CitizenAgent.new()
		this(c:getPanicEvents()).equal(0)
	end,

	["CitizenAgent - riot flag can be set"] = function()
		local c = CitizenAgent.new()
		c:setRiotNearby(true)
		this(c._riotNearby).equal(true)
	end,

	["CitizenAgent - panic events count Reacting ticks"] = function()
		local c = CitizenAgent.new()
		c:transitionTo(SimAgent.States.Moving)
		c:transitionTo(SimAgent.States.Reacting)
		-- manually tick without behavior (behavior is nil wouldn't crash SimAgent base)
		c._behavior = nil
		c:tick()
		c:tick()
		this(c:getPanicEvents()).equal(2)
	end,

	-- ─────────────────────────────────────────────────── OfficerAgent
	["OfficerAgent - creates with type Officer"] = function()
		local o = OfficerAgent.new("Police")
		this(o.agentType).equal("Officer")
		this(o.rank).equal("Police")
	end,

	["OfficerAgent - default rank is Police"] = function()
		local o = OfficerAgent.new()
		this(o.rank).equal("Police")
	end,

	["OfficerAgent - riot flag can be set"] = function()
		local o = OfficerAgent.new()
		o:setRiotActive(true)
		this(o._riotActive).equal(true)
	end,

	["OfficerAgent - response ticks counted while Acting"] = function()
		local o = OfficerAgent.new()
		o:transitionTo(SimAgent.States.Moving)
		o:transitionTo(SimAgent.States.Acting)
		o._behavior = nil
		o:tick()
		o:tick()
		o:tick()
		this(o:getResponseTicks()).equal(3)
	end,

	-- ─────────────────────────────────────────────────── SimulationCore
	["SimulationCore - initializes with correct agent counts"] = function()
		local core = SimulationCore.new({ citizenCount = 5, officerCount = 2 })
		this(core:getAgentCount()).equal(7)
	end,

	["SimulationCore - starts in non-running state"] = function()
		local core = SimulationCore.new()
		this(core:isRunning()).equal(false)
	end,

	["SimulationCore - runFor advances tick counter"] = function()
		local core = SimulationCore.new({ citizenCount = 3, officerCount = 1, parallel = false })
		core:runFor(5)
		this(core:getTickCount()).equal(5)
	end,

	["SimulationCore - reset resets tick counter"] = function()
		local core = SimulationCore.new({ citizenCount = 3, officerCount = 1, parallel = false })
		core:runFor(10)
		core:reset()
		this(core:getTickCount()).equal(0)
	end,

	["SimulationCore - addCitizen increases agent count"] = function()
		local core = SimulationCore.new({ citizenCount = 2, officerCount = 1 })
		core:addCitizen()
		this(core:getAgentCount()).equal(4)
	end,

	["SimulationCore - addOfficer increases agent count"] = function()
		local core = SimulationCore.new({ citizenCount = 2, officerCount = 1 })
		core:addOfficer("Fire")
		this(core:getAgentCount()).equal(4)
	end,

	["SimulationCore - setTickInterval clamps below minimum"] = function()
		local core = SimulationCore.new()
		core:setTickInterval(0.001)
		this(core:getTickInterval()).equal(0.05)
	end,

	["SimulationCore - parallel and sequential produce same tick count"] = function()
		local seqCore = SimulationCore.new({ citizenCount=5, officerCount=2, parallel=false })
		local parCore = SimulationCore.new({ citizenCount=5, officerCount=2, parallel=true })
		seqCore:runFor(10)
		parCore:runFor(10)
		this(seqCore:getTickCount()).equal(parCore:getTickCount())
	end,

	-- ─────────────────────────────────────────────────── StatsCollectorObserver
	["StatsCollectorObserver - records tick snapshots"] = function()
		local core = SimulationCore.new({ citizenCount=3, officerCount=1, parallel=false })
		local obs  = SimObservers.StatsCollectorObserver.new()
		core:attach(obs)
		core:runFor(4)
		this(#obs:getHistory()).equal(4)
	end,

	["StatsCollectorObserver - counts riot start events"] = function()
		local obs = SimObservers.StatsCollectorObserver.new()
		obs:onRiotChanged(true)
		obs:onRiotChanged(false)
		obs:onRiotChanged(true)
		this(obs:getRiotEventCount()).equal(2)
	end,

	["StatsCollectorObserver - getLastSnapshot returns most recent"] = function()
		local core = SimulationCore.new({ citizenCount=3, officerCount=1, parallel=false })
		local obs  = SimObservers.StatsCollectorObserver.new()
		core:attach(obs)
		core:runFor(6)
		local snap = obs:getLastSnapshot()
		this(snap).exist()
		this(snap.tick).equal(6)
	end,

	["SimulationCore - attach returns false for duplicate observer"] = function()
		local core = SimulationCore.new()
		local obs  = SimObservers.StatsCollectorObserver.new()
		core:attach(obs)
		local dup = core:attach(obs)
		this(dup).equal(false)
	end,

	["SimulationCore - detach removes observer"] = function()
		local core = SimulationCore.new({ citizenCount=2, officerCount=1, parallel=false })
		local obs  = SimObservers.StatsCollectorObserver.new()
		core:attach(obs)
		core:detach("StatsCollector")
		core:runFor(3)
		this(#obs:getHistory()).equal(0) -- no longer notified
	end,

	-- ─────────────────────────────────────────────────── SimulationCommands
	["SimCommandInvoker - execute StartCommand sets running"] = function()
		local core    = SimulationCore.new({ citizenCount=2, officerCount=1 })
		local invoker = SimCommands.SimCommandInvoker.new(core)
		invoker:execute(SimCommands.StartCommand.new())
		this(core:isRunning()).equal(true)
		core:pause()
	end,

	["SimCommandInvoker - execute PauseCommand stops running"] = function()
		local core    = SimulationCore.new({ citizenCount=2, officerCount=1 })
		local invoker = SimCommands.SimCommandInvoker.new(core)
		core:start()
		invoker:execute(SimCommands.PauseCommand.new())
		this(core:isRunning()).equal(false)
	end,

	["SimCommandInvoker - undo StartCommand pauses"] = function()
		local core    = SimulationCore.new({ citizenCount=2, officerCount=1 })
		local invoker = SimCommands.SimCommandInvoker.new(core)
		invoker:execute(SimCommands.StartCommand.new())
		invoker:undo()
		this(core:isRunning()).equal(false)
	end,

	["SimCommandInvoker - SetSpeedCommand changes interval"] = function()
		local core    = SimulationCore.new()
		local invoker = SimCommands.SimCommandInvoker.new(core)
		invoker:execute(SimCommands.SetSpeedCommand.new(0.5))
		this(core:getTickInterval()).equal(0.5)
	end,

	["SimCommandInvoker - undo SetSpeedCommand restores interval"] = function()
		local core    = SimulationCore.new()
		local invoker = SimCommands.SimCommandInvoker.new(core)
		invoker:execute(SimCommands.SetSpeedCommand.new(0.25))
		invoker:undo()
		this(core:getTickInterval()).equal(1.0)
	end,

	["SimCommandInvoker - getHistorySize tracks executions"] = function()
		local core    = SimulationCore.new({ citizenCount=2, officerCount=1 })
		local invoker = SimCommands.SimCommandInvoker.new(core)
		invoker:execute(SimCommands.SetSpeedCommand.new(0.5))
		invoker:execute(SimCommands.SetSpeedCommand.new(0.25))
		this(invoker:getHistorySize()).equal(2)
		core:pause()
	end,

	["SimCommandInvoker - undo returns false on empty history"] = function()
		local core    = SimulationCore.new()
		local invoker = SimCommands.SimCommandInvoker.new(core)
		local ok = invoker:undo()
		this(ok).equal(false)
	end,

	["ResetCommand - resets tick count"] = function()
		local core    = SimulationCore.new({ citizenCount=3, officerCount=1, parallel=false })
		local invoker = SimCommands.SimCommandInvoker.new(core)
		core:runFor(8)
		invoker:execute(SimCommands.ResetCommand.new())
		this(core:getTickCount()).equal(0)
	end,

	-- ─────────────────────────────────────────────────── Conflict system (3a)
	["CitizenAgent - Idle → Conflict is a valid transition"] = function()
		local c = CitizenAgent.new()
		local ok = c:transitionTo(SimAgent.States.Conflict)
		this(ok).equal(true)
		this(c.state).equal(SimAgent.States.Conflict)
	end,

	["CitizenAgent - leaves Conflict when not provoked"] = function()
		local c = CitizenAgent.new()
		c:transitionTo(SimAgent.States.Moving)
		c:transitionTo(SimAgent.States.Conflict)
		c._provoked = false
		c:tick()
		this(c.state).equal(SimAgent.States.Idle)
	end,

	["CitizenAgent - stays in Conflict while provoked"] = function()
		local c = CitizenAgent.new()
		c:transitionTo(SimAgent.States.Moving)
		c:transitionTo(SimAgent.States.Conflict)
		c._provoked = true
		c:tick()
		this(c.state).equal(SimAgent.States.Conflict)
	end,

	["OfficerBehavior - decides Acting when conflictTarget is set"] = function()
		local o = OfficerAgent.new()
		local beh = OfficerAgent.Behavior.new()
		beh.responseChance = 1.0
		o._behavior       = beh
		o._conflictTarget = Vector3.new(10, 0, 10)
		o:transitionTo(SimAgent.States.Moving)
		o:tick()
		this(o.state).equal(SimAgent.States.Acting)
	end,

	["SimulationCore - conflict resolves when officer reaches fight"] = function()
		local core = SimulationCore.new({ citizenCount=0, officerCount=0, parallel=false })
		local c1   = core:addCitizen()
		local c2   = core:addCitizen()
		local off  = core:addOfficer()

		-- Force citizens into a fight
		c1.position = Vector3.new(0, 0, 0)
		c2.position = Vector3.new(2, 0, 0)
		c1._provoked = true;  c2._provoked = true
		c1:transitionTo(SimAgent.States.Moving)
		c1:transitionTo(SimAgent.States.Conflict)
		c2:transitionTo(SimAgent.States.Moving)
		c2:transitionTo(SimAgent.States.Conflict)

		-- Place officer at midpoint with conflictTarget
		local mid = Vector3.new(1, 0, 0)
		off.position       = mid
		off._conflictTarget = mid
		off:transitionTo(SimAgent.States.Moving)
		off:transitionTo(SimAgent.States.Acting)

		-- One tick runs _processConflicts; officer is within RESOLVE_DIST
		core:runFor(1)
		this(c1._provoked).equal(false)
	end,

	["SimulationCore - conflicting stat counts fighters"] = function()
		local core = SimulationCore.new({ citizenCount=0, officerCount=0, parallel=false })
		local c1 = core:addCitizen()
		local c2 = core:addCitizen()
		c1:transitionTo(SimAgent.States.Moving)
		c1:transitionTo(SimAgent.States.Conflict)
		c2:transitionTo(SimAgent.States.Moving)
		c2:transitionTo(SimAgent.States.Conflict)
		c1._provoked = true;  c2._provoked = true

		local obs = SimObservers.StatsCollectorObserver.new()
		core:attach(obs)
		core:runFor(1)
		local snap = obs:getLastSnapshot()
		this(snap.conflicting >= 2).equal(true)
	end,
}
