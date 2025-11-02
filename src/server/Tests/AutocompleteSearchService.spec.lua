local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AutocompleteSearchService = require(ReplicatedStorage.Services:WaitForChild("AutocompleteSearchService"))
local BoatTest = require(ReplicatedStorage.Packages.BoatTest)

local this = BoatTest.this

local function createTestFolder()
	local folder = Instance.new("Folder")
	folder.Name = "TestFolder"
	folder.Parent = workspace

	local child1 = Instance.new("Part")
	child1.Name = "Apple"
	child1.Parent = folder

	local child2 = Instance.new("Part")
	child2.Name = "Banana"
	child2.Parent = folder

	local child3 = Instance.new("Part")
	child3.Name = "Apachi"
	child3.Parent = folder

	return folder
end
createTestFolder().Parent = workspace

return {
	["Tree initialization and remove"] = function(skip)
		local folder = createTestFolder()
		folder.Parent = workspace
		AutocompleteSearchService.InitTree("Fruits", folder)
		local removed = AutocompleteSearchService.RemoveTree("Fruits")
		this(removed).will.equal(true)
		local removedAgain = AutocompleteSearchService.RemoveTree("Fruits")
		this(removedAgain).will.equal(false)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Prefix search"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)

		local results = AutocompleteSearchService.Search("Fruits", "App")
		this(tostring(results[1])).will.equal(tostring("Apple"))
		this(#results).will.equal(1)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Registr check"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)

		local result1 = AutocompleteSearchService.Search("Fruits", "App")
		local result2 = AutocompleteSearchService.Search("Fruits", "APP")

		this(tostring(result1[1])).will.equal(tostring(result2[1]))
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Empty result"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)

		local result = AutocompleteSearchService.Search("Fruits", "BAkof")
		this(#result).will.equal(0)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Search in removed tree"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)
		AutocompleteSearchService.RemoveTree("Fruits")

		local result = AutocompleteSearchService.Search("Fruits", "A")
		this(#result).will.equal(0)
		folder:Destroy()
	end,
	["Adding a new child to the initializated folder"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)

		local newChild = Instance.new("Part")
		newChild.Name = "Avocado"
		newChild.Parent = folder

		local result = AutocompleteSearchService.Search("Fruits", "Avo")
		this(#result).will.equal(1)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Removing a child from the initializated folder"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)

		folder:FindFirstChild("Apple"):Destroy()

		local result = AutocompleteSearchService.Search("Fruits", "App")
		this(#result).will.equal(0)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Create two trees and check if they are separate"] = function(skip)
		local folder1 = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits1", folder1)
		local folder2 = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits2", folder2)

		local result = AutocompleteSearchService.Search("Fruits1", "App")
		this(#result).will.equal(1)
		folder1:Destroy()
		folder2:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits1")
		AutocompleteSearchService.RemoveTree("Fruits2")
	end,
	["Search in empty folder"] = function(skip)
		local folder = createTestFolder()
		for i, v in ipairs(folder:GetChildren()) do
			v:Destroy()
		end
		AutocompleteSearchService.InitTree("Fruits", folder)

		local result = AutocompleteSearchService.Search("Fruits", "App")
		this(#result).will.equal(0)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
	["Tree initialization twise"] = function(skip)
		local folder = createTestFolder()
		AutocompleteSearchService.InitTree("Fruits", folder)
		AutocompleteSearchService.InitTree("Fruits", folder)

		local results = AutocompleteSearchService.Search("Fruits", "App")
		this(tostring(results[1])).will.equal(tostring("Apple"))
		this(#results).will.equal(1)
		folder:Destroy()
		AutocompleteSearchService.RemoveTree("Fruits")
	end,
}
