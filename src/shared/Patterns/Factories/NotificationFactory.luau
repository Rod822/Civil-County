--[[
	@class NotificationFactory (Abstract Factory)
	@desc Abstract Factory pattern for creating different notification types
	@pattern Abstract Factory
	
	This factory provides a system for creating families of related notification
	objects (In-Game, UI, Console). The abstract factory pattern allows switching
	between different notification strategies without changing client code.
]]

local NotificationFactory = {}
NotificationFactory.__index = NotificationFactory

export type NotificationMessage = {
	recipient: string | { string }, -- Player name or list of names
	title: string,
	message: string,
	notificationType: string, -- "InGame", "UI", "Console"
	priority: "Low" | "Medium" | "High",
	timestamp: number,
}

--[[
	@class InGameNotification
	@desc Notification delivered in-game to the player
]]
local InGameNotification = {}
InGameNotification.__index = InGameNotification

function InGameNotification.new(recipient: string, title: string, message: string, priority: string)
	local self = setmetatable({}, InGameNotification)
	self.recipient = recipient
	self.title = title
	self.message = message
	self.priority = priority or "Medium"
	self.timestamp = tick()
	self.type = "InGame"
	return self
end

function InGameNotification:deliver()
	return {
		type = self.type,
		recipient = self.recipient,
		title = self.title,
		message = self.message,
		priority = self.priority,
		timestamp = self.timestamp,
	}
end

--[[
	@class UINotification
	@desc Notification delivered through UI overlay
]]
local UINotification = {}
UINotification.__index = UINotification

function UINotification.new(recipient: string, title: string, message: string, priority: string)
	local self = setmetatable({}, UINotification)
	self.recipient = recipient
	self.title = title
	self.message = message
	self.priority = priority or "Medium"
	self.timestamp = tick()
	self.type = "UI"
	return self
end

function UINotification:deliver()
	return {
		type = self.type,
		recipient = self.recipient,
		title = self.title,
		message = self.message,
		priority = self.priority,
		dismissible = true,
		duration = 5,
		timestamp = self.timestamp,
	}
end

--[[
	@class ConsoleNotification
	@desc Notification logged to console (for debugging/admin)
]]
local ConsoleNotification = {}
ConsoleNotification.__index = ConsoleNotification

function ConsoleNotification.new(recipient: string, title: string, message: string, priority: string)
	local self = setmetatable({}, ConsoleNotification)
	self.recipient = recipient
	self.title = title
	self.message = message
	self.priority = priority or "Low"
	self.timestamp = tick()
	self.type = "Console"
	return self
end

function ConsoleNotification:deliver()
	return {
		type = self.type,
		recipient = self.recipient,
		title = self.title,
		message = self.message,
		priority = self.priority,
		timestamp = self.timestamp,
	}
end

--[[
	@method new
	@desc Creates a new NotificationFactory instance
	@return NotificationFactory
]]
function NotificationFactory.new()
	local self = setmetatable({}, NotificationFactory)
	self._notificationsQueue = {}
	return self
end

--[[
	@method createNotification
	@desc Abstract factory method to create appropriate notification type
	@param notificationType: string - "InGame", "UI", or "Console"
	@param recipient: string - Target recipient
	@param title: string - Notification title
	@param message: string - Notification message
	@param priority: string - "Low", "Medium", or "High"
	@return NotificationMessage
]]
function NotificationFactory:createNotification(
	notificationType: string,
	recipient: string,
	title: string,
	message: string,
	priority: string
)
	priority = priority or "Medium"

	if notificationType == "InGame" then
		return InGameNotification.new(recipient, title, message, priority)
	elseif notificationType == "UI" then
		return UINotification.new(recipient, title, message, priority)
	elseif notificationType == "Console" then
		return ConsoleNotification.new(recipient, title, message, priority)
	else
		warn("NotificationFactory: Unknown notification type: " .. tostring(notificationType))
		return nil
	end
end

--[[
	@method createBatchNotifications
	@desc Creates multiple notifications for different recipients
	@param notificationType: string
	@param recipients: table - List of recipient names
	@param title: string
	@param message: string
	@param priority: string
	@return table - Array of notification objects
]]
function NotificationFactory:createBatchNotifications(
	notificationType: string,
	recipients: { string },
	title: string,
	message: string,
	priority: string
)
	local notifications = {}
	for _, recipient in ipairs(recipients) do
		local notification = self:createNotification(notificationType, recipient, title, message, priority)
		if notification then
			table.insert(notifications, notification)
		end
	end
	return notifications
end

return NotificationFactory
