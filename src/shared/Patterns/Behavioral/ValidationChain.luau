--[[
	@class ValidationChain
	@desc Chain of Responsibility pattern for validation
	@pattern Chain of Responsibility
	
	Pass requests along a chain of handlers where each handler decides
	to process or pass it to next. Useful for complex validation rules.
]]

local ValidationChain = {}

--[[
	@class IValidator
	@desc Interface for validators in the chain
]]
local IValidator = {}
IValidator.__index = IValidator

function IValidator.new()
	return setmetatable({}, IValidator)
end

function IValidator:validate(_data: any): (boolean, string)
	error("validate must be implemented")
end

function IValidator:setNext(_validator: any)
	error("setNext must be implemented")
end

function IValidator:getName(): string
	error("getName must be implemented")
end

--[[
	@class PlayerValidator
	@desc Validates that player exists and is valid
]]
local PlayerValidator = setmetatable({}, IValidator)
PlayerValidator.__index = PlayerValidator

function PlayerValidator.new(): PlayerValidator
	local self = setmetatable({}, PlayerValidator)
	self._nextValidator = nil
	return self
end

function PlayerValidator:validate(data: any): (boolean, string)
	if not data or not data.player then
		return false, "Player object is required"
	end

	if typeof(data.player) ~= "Instance" or not data.player:IsA("Player") then
		return false, "Invalid player object"
	end

	if self._nextValidator then
		return self._nextValidator:validate(data)
	end

	return true, "Player is valid"
end

function PlayerValidator:setNext(validator: any)
	self._nextValidator = validator
end

function PlayerValidator:getName(): string
	return "PlayerValidator"
end

--[[
	@class JobValidator
	@desc Validates job assignment rules
]]
local JobValidator = setmetatable({}, IValidator)
JobValidator.__index = JobValidator

function JobValidator.new(): JobValidator
	local self = setmetatable({}, JobValidator)
	self._nextValidator = nil
	self._validJobs = { Police = true, FireService = true, Paramedic = true, Civilian = true }
	return self
end

function JobValidator:validate(data: any): (boolean, string)
	if not data.jobName then
		return false, "Job name is required"
	end

	if not self._validJobs[data.jobName] then
		return false, "Job '" .. data.jobName .. "' does not exist"
	end

	if self._nextValidator then
		return self._nextValidator:validate(data)
	end

	return true, "Job is valid"
end

function JobValidator:setNext(validator: any)
	self._nextValidator = validator
end

function JobValidator:getName(): string
	return "JobValidator"
end

--[[
	@class BalanceValidator
	@desc Validates player has sufficient balance
]]
local BalanceValidator = setmetatable({}, IValidator)
BalanceValidator.__index = BalanceValidator

function BalanceValidator.new(): BalanceValidator
	local self = setmetatable({}, BalanceValidator)
	self._nextValidator = nil
	return self
end

function BalanceValidator:validate(data: any): (boolean, string)
	if data.requiredBalance and data.requiredBalance > 0 then
		if not data.currentBalance or data.currentBalance < data.requiredBalance then
			return false, "Insufficient balance. Required: " .. data.requiredBalance
		end
	end

	if self._nextValidator then
		return self._nextValidator:validate(data)
	end

	return true, "Balance is sufficient"
end

function BalanceValidator:setNext(validator: any)
	self._nextValidator = validator
end

function BalanceValidator:getName(): string
	return "BalanceValidator"
end

--[[
	@class LevelValidator
	@desc Validates player is high enough level
]]
local LevelValidator = setmetatable({}, IValidator)
LevelValidator.__index = LevelValidator

function LevelValidator.new(): LevelValidator
	local self = setmetatable({}, LevelValidator)
	self._nextValidator = nil
	return self
end

function LevelValidator:validate(data: any): (boolean, string)
	if data.requiredLevel and data.requiredLevel > 1 then
		if not data.playerLevel or data.playerLevel < data.requiredLevel then
			return false, "Player level too low. Required: " .. data.requiredLevel
		end
	end

	if self._nextValidator then
		return self._nextValidator:validate(data)
	end

	return true, "Player level is sufficient"
end

function LevelValidator:setNext(validator: any)
	self._nextValidator = validator
end

function LevelValidator:getName(): string
	return "LevelValidator"
end

--[[
	@class LocationValidator
	@desc Validates player is in correct location
]]
local LocationValidator = setmetatable({}, IValidator)
LocationValidator.__index = LocationValidator

function LocationValidator.new(): LocationValidator
	local self = setmetatable({}, LocationValidator)
	self._nextValidator = nil
	return self
end

function LocationValidator:validate(data: any): (boolean, string)
	if data.requiredLocation then
		if not data.playerLocation or data.playerLocation ~= data.requiredLocation then
			return false, "Player must be at: " .. data.requiredLocation
		end
	end

	if self._nextValidator then
		return self._nextValidator:validate(data)
	end

	return true, "Player is in valid location"
end

function LocationValidator:setNext(validator: any)
	self._nextValidator = validator
end

function LocationValidator:getName(): string
	return "LocationValidator"
end

--[[
	@class ValidationChainBuilder
	@desc Builds and manages validation chains
]]
local ValidationChainBuilder = {}
ValidationChainBuilder.__index = ValidationChainBuilder

function ValidationChainBuilder.new(): ValidationChainBuilder
	local self = setmetatable({}, ValidationChainBuilder)
	self._validators = {}
	return self
end

function ValidationChainBuilder:addValidator(validator: any): ValidationChainBuilder
	table.insert(self._validators, validator)
	return self
end

function ValidationChainBuilder:build(): any
	if #self._validators == 0 then
		return nil
	end

	-- Link validators in chain
	for i = 1, #self._validators - 1 do
		self._validators[i]:setNext(self._validators[i + 1])
	end

	return self._validators[1]
end

function ValidationChainBuilder:validate(data: any): (boolean, string)
	local chain = self:build()
	if not chain then
		return false, "No validators in chain"
	end

	return chain:validate(data)
end

--[[
	@method createJobAssignmentValidator
	@desc Creates a chain for job assignment validation
	@return any - First validator in chain
]]
local function createJobAssignmentValidator(): any
	local builder = ValidationChainBuilder.new()
	return builder
		:addValidator(PlayerValidator.new())
		:addValidator(JobValidator.new())
		:addValidator(LevelValidator.new())
		:addValidator(LocationValidator.new())
		:build()
end

--[[
	@method createPurchaseValidator
	@desc Creates a chain for purchase validation
	@return any
]]
local function createPurchaseValidator(): any
	local builder = ValidationChainBuilder.new()
	return builder
		:addValidator(PlayerValidator.new())
		:addValidator(BalanceValidator.new())
		:addValidator(LevelValidator.new())
		:build()
end

-- Export all validators and builders
ValidationChain.IValidator = IValidator
ValidationChain.PlayerValidator = PlayerValidator
ValidationChain.JobValidator = JobValidator
ValidationChain.BalanceValidator = BalanceValidator
ValidationChain.LevelValidator = LevelValidator
ValidationChain.LocationValidator = LocationValidator
ValidationChain.ValidationChainBuilder = ValidationChainBuilder
ValidationChain.createJobAssignmentValidator = createJobAssignmentValidator
ValidationChain.createPurchaseValidator = createPurchaseValidator

return ValidationChain
