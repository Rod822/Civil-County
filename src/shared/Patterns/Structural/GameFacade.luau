--[[
	@class GameFacade
	@desc Facade pattern providing a unified interface to complex subsystems
	@pattern Facade
	
	Simplifies interaction with multiple services by providing a single,
	high-level interface. Hides the complexity of service coordination.
]]

local GameFacade = {}
GameFacade.__index = GameFacade

export type GameFacade = {
	_jobService: any,
	_playersDataService: any,
	_notificationService: any,
}

--[[
	@method new
	@desc Creates a new GameFacade instance
	@param jobService: any
	@param playersDataService: any
	@param notificationService: any
	@return GameFacade
]]
function GameFacade.new(jobService: any, playersDataService: any, notificationService: any): GameFacade
	local self = setmetatable({}, GameFacade)
	self._jobService = jobService
	self._playersDataService = playersDataService
	self._notificationService = notificationService
	self._cache = {}
	return self
end

--[[
	@method hirerPlayer
	@desc Complex workflow: Hire a player to a job
	Combines multiple service calls into one simple method
	@param player: Player - The player to hire
	@param jobName: string - The job to assign
	@return boolean - Success status
]]
function GameFacade:hirePlayer(player: Player, jobName: string): boolean
	-- Check if player exists
	if not player then
		return false
	end

	-- Attempt to assign job through JobService
	local success = self._jobService:assignJob(player, jobName)

	if success then
		-- Send welcome notification
		local jobTitle = jobName or "Unknown"
		self._notificationService:SendTo(player, "Welcome to " .. jobTitle .. "!", "You have been successfully hired.")

		-- Give signing bonus
		self._playersDataService:AddMoney(player, 50)

		-- Send bonus notification
		self._notificationService:SendTo(player, "Signing Bonus", "You received 50 currency!")

		return true
	else
		self._notificationService:SendTo(player, "Hire Failed", "Could not assign job: " .. jobName)
		return false
	end
end

--[[
	@method firePlayer
	@desc Complex workflow: Fire a player from their job
	@param player: Player
	@return boolean - Success status
]]
function GameFacade:firePlayer(player: Player): boolean
	if not player then
		return false
	end

	local success = self._jobService:fireFromJob(player)

	if success then
		self._notificationService:SendTo(player, "Termination Notice", "You have been terminated from your position.")
		return true
	end

	return false
end

--[[
	@method payPlayer
	@desc Complex workflow: Process paycheck for player
	@param player: Player
	@param bonusMultiplier: number - Multiplier for bonus pay
	@return boolean - Success status
]]
function GameFacade:payPlayer(player: Player, bonusMultiplier: number?): boolean
	bonusMultiplier = bonusMultiplier or 1.0

	if not player then
		return false
	end

	local success = self._jobService:paycheck(player, bonusMultiplier)

	if success then
		local profile = self._playersDataService._profiles[player.UserId]
		if profile then
			local amount = profile.persistent.Money
			self._notificationService:Paycheck(player, amount, 0, amount, "Payroll")
		end
		return true
	end

	return false
end

--[[
	@method getPlayerProfile
	@desc Simplified way to get player's full profile
	@param player: Player
	@return table - Player profile or nil
]]
function GameFacade:getPlayerProfile(player: Player): any?
	if not player then
		return nil
	end

	return self._playersDataService._profiles[player.UserId]
end

--[[
	@method getPlayerBalance
	@desc Get player's current balance
	@param player: Player
	@return number - Current balance
]]
function GameFacade:getPlayerBalance(player: Player): number?
	local profile = self:getPlayerProfile(player)
	if not profile then
		return nil
	end
	return profile.persistent.Money
end

--[[
	@method transferMoney
	@desc Transfer money between two players
	@param fromPlayer: Player
	@param toPlayer: Player
	@param amount: number
	@return boolean - Success status
]]
function GameFacade:transferMoney(fromPlayer: Player, toPlayer: Player, amount: number): boolean
	if not fromPlayer or not toPlayer or amount <= 0 then
		return false
	end

	-- Remove from sender
	local removed = self._playersDataService:RemoveMoney(fromPlayer, amount)

	if removed then
		-- Add to receiver
		self._playersDataService:AddMoney(toPlayer, amount)

		-- Notify both players
		self._notificationService:SendTo(fromPlayer, "Money Transfer", "Sent " .. amount .. " to " .. toPlayer.Name)
		self._notificationService:SendTo(
			toPlayer,
			"Money Transfer",
			"Received " .. amount .. " from " .. fromPlayer.Name
		)

		return true
	end

	self._notificationService:SendTo(fromPlayer, "Transfer Failed", "Insufficient funds")
	return false
end

--[[
	@method broadcastAnnouncement
	@desc Send announcement to all players
	@param title: string
	@param message: string
	@param priority: string - "Low", "Medium", "High"
]]
function GameFacade:broadcastAnnouncement(title: string, message: string, priority: string?)
	self._notificationService:Broadcast(title .. ": " .. message, "Announcement", priority or "Medium")
end

--[[
	@method getServiceStatus
	@desc Get status of all services
	@return table - Status information
]]
function GameFacade:getServiceStatus(): { [string]: string }
	return {
		jobService = "Active",
		playersDataService = "Active",
		notificationService = "Active",
	}
end

return GameFacade
