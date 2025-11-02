local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local AutocompleteSearchService = require(ReplicatedStorage.Services:WaitForChild("AutocompleteSearchService"))

local player = Players.LocalPlayer

local money = player:WaitForChild("leaderstats").Money.Value

local MainGUI = playerGui:WaitForChild("MainGUI")
local TeamSelectFrame = MainGUI:WaitForChild("TeamSelectFrame")
local LeftMenu = MainGUI.LeftMenu

function formattedCost(cost)
	local formattedCost = string.format("%0.0f", cost)
	formattedCost = formattedCost:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formattedCost:sub(1, 1) == "," then
		formattedCost = formattedCost:sub(2)
	end
	return formattedCost
end

-- Left Menu
LeftMenu.JobSelect.MouseButton1Click:Connect(function()
	TeamSelectFrame.Visible = not TeamSelectFrame.Visible
end)

LeftMenu.SearchTest.MouseButton1Click:Connect(function()
	MainGUI:WaitForChild("TestSearchFrame").Visible = not MainGUI:WaitForChild("TestSearchFrame").Visible
end)

LeftMenu.ShopTest.MouseButton1Click:Connect(function()
	playerGui:WaitForChild("FoodShop").Enabled = not playerGui:WaitForChild("FoodShop").Enabled
end)

-- Search Test Frame
local TestSearchFrame = MainGUI:WaitForChild("TestSearchFrame")
local SearchBox = TestSearchFrame:WaitForChild("SearchBox")
local ResultsFrame = TestSearchFrame:WaitForChild("ResultsFrame")
local OriginalFolder = TestSearchFrame:WaitForChild("OriginalFolder")

AutocompleteSearchService.InitTree("Fruits", game.Workspace:WaitForChild("TestFolder"))
local results = game.Workspace:WaitForChild("TestFolder"):GetChildren()
for _1, item1 in pairs(ResultsFrame:GetChildren()) do
	if item1:IsA("TextButton") then
		item1:Destroy()
	end
end

for _, item in pairs(results) do
	local resultLabel = ReplicatedStorage.UIs.JobListTextButton:Clone()
	resultLabel.Text = item.Name
	resultLabel.Parent = OriginalFolder
end

SearchBox.Changed:Connect(function()
	print("SearchBox changed")
	local searchText = SearchBox.Text
	for _, item in pairs(ResultsFrame:GetChildren()) do
		if item:IsA("TextButton") then
			item:Destroy()
		end
	end
	local results = AutocompleteSearchService.Search("Fruits", searchText)
	for _, item in pairs(results) do
		local resultLabel = ReplicatedStorage.UIs.JobListTextButton:Clone()
		resultLabel.Text = item.Name
		resultLabel.Parent = ResultsFrame
	end
end)

-- Balance Frame

player:WaitForChild("leaderstats").Money.Changed:Connect(function(NewValue)
	MainGUI.Balance.BalanceText.Text = "$" .. formattedCost(NewValue)
end)
MainGUI.Balance.BalanceText.Text = "$" .. formattedCost(player:WaitForChild("leaderstats").Money.Value)

-- TeamSelect Frame
local conn
ReplicatedStorage:FindFirstChild("JobServiseRE").OnClientEvent:Connect(function(jobs: table)
	if typeof(jobs) == "table" then
		for jobName, jobInfo in pairs(jobs) do
			local button = ReplicatedStorage.UIs.JobListTextButton:Clone()
			button.Name = jobName .. "Button"
			button.Text = jobInfo.teamName
			button.Parent = TeamSelectFrame.JobList
			button.MouseButton1Click:Connect(function()
				if conn then
					conn:Disconnect()
				end
				TeamSelectFrame.JobInfo.Frame.Visible = true
				TeamSelectFrame.JobInfo.Frame.JobName.Text = jobInfo.teamName
				TeamSelectFrame.JobInfo.Frame.WageFrame.Wage.Text = "$" .. tostring(jobInfo.basePay)
				TeamSelectFrame.JobInfo.Frame.DescriptionText.Text = jobInfo.jobDescription

				conn = TeamSelectFrame.JobInfo.Frame.JoinButton.MouseButton1Click:Connect(function()
					ReplicatedStorage:FindFirstChild("JobServiseRE"):FireServer(jobName)
					TeamSelectFrame.Visible = false
					TeamSelectFrame.JobInfo.Frame.Visible = false
				end)
			end)
		end
	end
end)
