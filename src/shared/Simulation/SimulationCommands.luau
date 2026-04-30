--[[
	@module SimulationCommands
	@desc Command pattern for simulation control.
	      Each command encapsulates a reversible operation on SimulationCore
	      (start, pause, reset, change speed). An Invoker tracks history
	      and supports undo.
	@pattern Command
]]

-- ── ISimCommand ───────────────────────────────────────────────────────────────

local ISimCommand = {}
ISimCommand.__index = ISimCommand

function ISimCommand.new(name: string)
	return setmetatable({ _name = name, _executed = false }, ISimCommand)
end

function ISimCommand:execute(_core: any): boolean
	error(self._name .. ": execute() must be implemented")
end

function ISimCommand:undo(_core: any): boolean
	return false
end

function ISimCommand:getName(): string
	return self._name
end

-- ── StartCommand ──────────────────────────────────────────────────────────────

local StartCommand = setmetatable({}, { __index = ISimCommand })
StartCommand.__index = StartCommand

function StartCommand.new()
	local self = ISimCommand.new("StartSimulation")
	setmetatable(self, StartCommand)
	return self
end

function StartCommand:execute(core: any): boolean
	if self._executed or core:isRunning() then return false end
	core:start()
	self._executed = true
	return true
end

function StartCommand:undo(core: any): boolean
	if not self._executed then return false end
	core:pause()
	self._executed = false
	return true
end

-- ── PauseCommand ──────────────────────────────────────────────────────────────

local PauseCommand = setmetatable({}, { __index = ISimCommand })
PauseCommand.__index = PauseCommand

function PauseCommand.new()
	local self = ISimCommand.new("PauseSimulation")
	setmetatable(self, PauseCommand)
	return self
end

function PauseCommand:execute(core: any): boolean
	if not core:isRunning() then return false end
	core:pause()
	self._executed = true
	return true
end

function PauseCommand:undo(core: any): boolean
	if not self._executed then return false end
	core:start()
	self._executed = false
	return true
end

-- ── ResetCommand ──────────────────────────────────────────────────────────────

local ResetCommand = setmetatable({}, { __index = ISimCommand })
ResetCommand.__index = ResetCommand

function ResetCommand.new()
	local self = ISimCommand.new("ResetSimulation")
	setmetatable(self, ResetCommand)
	self._wasRunning = false
	return self
end

function ResetCommand:execute(core: any): boolean
	self._wasRunning = core:isRunning()
	core:reset()
	self._executed = true
	return true
end

function ResetCommand:undo(core: any): boolean
	-- Undo of reset re-starts if it was running before reset
	if self._wasRunning then core:start() end
	return true
end

-- ── SetSpeedCommand ───────────────────────────────────────────────────────────

local SetSpeedCommand = setmetatable({}, { __index = ISimCommand })
SetSpeedCommand.__index = SetSpeedCommand

--[[
	@function new
	@param speed number  Tick interval multiplier (1.0 = normal, 0.5 = 2x faster)
]]
function SetSpeedCommand.new(speed: number)
	local self = ISimCommand.new("SetSpeed")
	setmetatable(self, SetSpeedCommand)
	self._newSpeed  = speed
	self._prevSpeed = nil
	return self
end

function SetSpeedCommand:execute(core: any): boolean
	self._prevSpeed = core:getTickInterval()
	core:setTickInterval(self._newSpeed)
	self._executed = true
	return true
end

function SetSpeedCommand:undo(core: any): boolean
	if self._prevSpeed then
		core:setTickInterval(self._prevSpeed)
		return true
	end
	return false
end

-- ── SimCommandInvoker ─────────────────────────────────────────────────────────

local SimCommandInvoker = {}
SimCommandInvoker.__index = SimCommandInvoker

--[[
	@function new
	@param core SimulationCore  The simulation instance commands operate on
	@return SimCommandInvoker
]]
function SimCommandInvoker.new(core: any)
	return setmetatable({
		_core    = core,
		_history = {},
		_undo    = {},
	}, SimCommandInvoker)
end

--[[
	@function execute
	@param cmd ISimCommand
	@return boolean
]]
function SimCommandInvoker:execute(cmd: any): boolean
	local ok = cmd:execute(self._core)
	if ok then
		self._history[#self._history + 1] = cmd
		self._undo = {}
	end
	return ok
end

--[[
	@function undo
	@return boolean
]]
function SimCommandInvoker:undo(): boolean
	if #self._history == 0 then return false end
	local cmd = table.remove(self._history)
	local ok = cmd:undo(self._core)
	if ok then self._undo[#self._undo + 1] = cmd end
	return ok
end

--[[
	@function redo
	@return boolean
]]
function SimCommandInvoker:redo(): boolean
	if #self._undo == 0 then return false end
	local cmd = table.remove(self._undo)
	local ok = cmd:execute(self._core)
	if ok then self._history[#self._history + 1] = cmd end
	return ok
end

--[[
	@function getHistorySize
	@return number
]]
function SimCommandInvoker:getHistorySize(): number
	return #self._history
end

return {
	ISimCommand      = ISimCommand,
	StartCommand     = StartCommand,
	PauseCommand     = PauseCommand,
	ResetCommand     = ResetCommand,
	SetSpeedCommand  = SetSpeedCommand,
	SimCommandInvoker = SimCommandInvoker,
}
