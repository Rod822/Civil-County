--[[
	@class PaymentStrategy
	@desc Strategy pattern for different payment calculation methods
	@pattern Strategy
	
	Different algorithms can be swapped at runtime without changing
	the context code. Useful for different job pay structures.
]]

local PaymentStrategy = {}

--[[
	@class IPaymentStrategy
	@desc Interface for payment strategies
]]
local IPaymentStrategy = {}
IPaymentStrategy.__index = IPaymentStrategy

function IPaymentStrategy.new()
	return setmetatable({}, IPaymentStrategy)
end

function IPaymentStrategy:calculate(_basePay: number, _hoursWorked: number, _bonusMultiplier: number): number
	error("calculate must be implemented by subclass")
end

function IPaymentStrategy:getName(): string
	error("getName must be implemented by subclass")
end

--[[
	@class BasicPaymentStrategy
	@desc Simple hourly payment
]]
local BasicPaymentStrategy = setmetatable({}, IPaymentStrategy)
BasicPaymentStrategy.__index = BasicPaymentStrategy

function BasicPaymentStrategy.new(): BasicPaymentStrategy
	return setmetatable({}, BasicPaymentStrategy)
end

function BasicPaymentStrategy:calculate(basePay: number, _hoursWorked: number, _bonusMultiplier: number): number
	return basePay
end

function BasicPaymentStrategy:getName(): string
	return "Basic"
end

--[[
	@class OvertimePaymentStrategy
	@desc Payment with overtime bonuses
]]
local OvertimePaymentStrategy = setmetatable({}, IPaymentStrategy)
OvertimePaymentStrategy.__index = OvertimePaymentStrategy

function OvertimePaymentStrategy.new(): OvertimePaymentStrategy
	return setmetatable({}, OvertimePaymentStrategy)
end

function OvertimePaymentStrategy:calculate(basePay: number, hoursWorked: number, _bonusMultiplier: number): number
	local regularHours = 8
	local overtimeRate = 1.5

	if hoursWorked > regularHours then
		local regularPay = (regularHours / 24) * basePay
		local overtimePay = ((hoursWorked - regularHours) / 24) * basePay * overtimeRate
		return regularPay + overtimePay
	end

	return (hoursWorked / 24) * basePay
end

function OvertimePaymentStrategy:getName(): string
	return "Overtime"
end

--[[
	@class PerformancePaymentStrategy
	@desc Payment based on performance bonus
]]
local PerformancePaymentStrategy = setmetatable({}, IPaymentStrategy)
PerformancePaymentStrategy.__index = PerformancePaymentStrategy

function PerformancePaymentStrategy.new(): PerformancePaymentStrategy
	return setmetatable({}, PerformancePaymentStrategy)
end

function PerformancePaymentStrategy:calculate(basePay: number, _hoursWorked: number, bonusMultiplier: number): number
	bonusMultiplier = bonusMultiplier or 1.0
	return basePay * bonusMultiplier
end

function PerformancePaymentStrategy:getName(): string
	return "Performance"
end

--[[
	@class HazardPayPaymentStrategy
	@desc Payment with hazard bonuses for dangerous jobs
]]
local HazardPayPaymentStrategy = setmetatable({}, IPaymentStrategy)
HazardPayPaymentStrategy.__index = HazardPayPaymentStrategy

function HazardPayPaymentStrategy.new(): HazardPayPaymentStrategy
	return setmetatable({}, HazardPayPaymentStrategy)
end

function HazardPayPaymentStrategy:calculate(basePay: number, hoursWorked: number, bonusMultiplier: number): number
	bonusMultiplier = bonusMultiplier or 1.0
	local hazardBonus = 1.25 -- 25% hazard bonus

	local performancePay = (hoursWorked / 24) * basePay * bonusMultiplier
	return performancePay * hazardBonus
end

function HazardPayPaymentStrategy:getName(): string
	return "HazardPay"
end

--[[
	@class PaymentContext
	@desc Executes payment using selected strategy
]]
local PaymentContext = {}
PaymentContext.__index = PaymentContext

function PaymentContext.new(strategy: any): PaymentContext
	local self = setmetatable({}, PaymentContext)
	self._strategy = strategy or BasicPaymentStrategy.new()
	return self
end

function PaymentContext:setStrategy(strategy: any)
	self._strategy = strategy
end

function PaymentContext:getStrategyName(): string
	return self._strategy:getName()
end

function PaymentContext:calculatePayment(basePay: number, hoursWorked: number, bonusMultiplier: number): number
	return self._strategy:calculate(basePay, hoursWorked, bonusMultiplier)
end

-- Export all strategies
PaymentStrategy.IPaymentStrategy = IPaymentStrategy
PaymentStrategy.BasicPaymentStrategy = BasicPaymentStrategy
PaymentStrategy.OvertimePaymentStrategy = OvertimePaymentStrategy
PaymentStrategy.PerformancePaymentStrategy = PerformancePaymentStrategy
PaymentStrategy.HazardPayPaymentStrategy = HazardPayPaymentStrategy
PaymentStrategy.PaymentContext = PaymentContext

return PaymentStrategy
