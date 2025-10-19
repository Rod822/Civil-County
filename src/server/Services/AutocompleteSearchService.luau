local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classes = ReplicatedStorage:WaitForChild("Classes")

local TrieNode = require(Classes:WaitForChild("TrieNode"))
local TrieTreeRecord = require(Classes:WaitForChild("TrieTreeRecord"))

local AutocompleteSearchService = {}

local Trees = {}

function AutocompleteSearchService.InitTree(name: string, folder: Instance)
	assert(typeof(name) == "string" and name ~= "", "InitTree: name must be non-empty string")
	assert(typeof(folder) == "Instance", "InitTree: folder must be an Instance")

	if Trees[name] ~= nil then
		AutocompleteSearchService.RemoveTree(name)
	end

	local tree = TrieTreeRecord.new(folder)

	for _, child in ipairs(folder:GetChildren()) do
		tree:AddInstance(child)
	end

	tree.conns[#tree.conns + 1] = folder.ChildAdded:Connect(function(child)
		tree:AddInstance(child)
	end)
	tree.conns[#tree.conns + 1] = folder.ChildRemoved:Connect(function(child)
		tree:RemoveInstance(child)
	end)

	Trees[name] = tree
end

function AutocompleteSearchService.Search(name: string, prefix: string, limit: number?): { Instance }
	local tree = Trees[name]
	if not tree then
		return {}
	end
	return tree:Search(prefix, limit)
end

function AutocompleteSearchService.RemoveTree(name: string): boolean
	local tree = Trees[name]
	if not tree then
		return false
	end
	for _, c in ipairs(tree.conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	Trees[name] = nil
	return true
end

return AutocompleteSearchService
