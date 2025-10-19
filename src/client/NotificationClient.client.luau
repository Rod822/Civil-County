local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local re = ReplicatedStorage:WaitForChild("NotifyRE") :: RemoteEvent

local function showToast(payload: { [string]: any })
	local title = tostring(payload.title or "Notice")
	local text = tostring(payload.text or "")
	local duration = tonumber(payload.duration) or 5

	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration,
		})
	end)

	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = ("[%s] %s"):format(title, text),
		})
	end)
end

re.OnClientEvent:Connect(showToast)
