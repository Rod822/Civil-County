local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BoatTest = require(ReplicatedStorage.Packages.BoatTest)

BoatTest.run({
	directories = { ServerScriptService.Tests },
})
