local Players = game:GetService("Players")

local function getPlayer()
	local p = Players:GetChildren()[1]
	if p then
		return p
	end

	local start = os.clock()
	repeat
		p = Players:GetChildren()[1]
		task.wait(0.1)
	until p or os.clock() - start > 5

	return p
end

return getPlayer
