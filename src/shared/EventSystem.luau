local EventSystem = {}
EventSystem.__index = EventSystem

EventSystem._listeners = {}

function EventSystem:Connect(eventName: string, callback: (...any) -> ())
	if not self._listeners[eventName] then
		self._listeners[eventName] = {}
	end
	table.insert(self._listeners[eventName], callback)
end

function EventSystem:Fire(eventName: string, ...: any)
	local listeners = self._listeners[eventName]
	if listeners then
		for _, callback in ipairs(listeners) do
			callback(...)
		end
	end
end

function EventSystem:Disconnect(eventName: string, callback: (...any) -> ())
	local listeners = self._listeners[eventName]
	if listeners then
		for i, cb in ipairs(listeners) do
			if cb == callback then
				table.remove(listeners, i)
				break
			end
		end
	end
end

return EventSystem