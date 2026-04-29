--[[
	@file PatternsTests.spec.lua
	@desc Comprehensive unit tests for all design patterns
	@coverage Testing all 15 design patterns
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local this = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("BoatTest")).this

local JobFactory = require(ReplicatedStorage.Patterns.Factories.JobFactory)
local NotificationFactory = require(ReplicatedStorage.Patterns.Factories.NotificationFactory)
local MissionBuilder = require(ReplicatedStorage.Patterns.Creational.MissionBuilder)
local ServiceRegistry = require(ReplicatedStorage.Patterns.Creational.ServiceRegistry)
local ServiceDecorator = require(ReplicatedStorage.Patterns.Structural.ServiceDecorator)
local ExternalAPIAdapter = require(ReplicatedStorage.Patterns.Structural.ExternalAPIAdapter)
local GameFacade = require(ReplicatedStorage.Patterns.Structural.GameFacade)
local DataProxy = require(ReplicatedStorage.Patterns.Structural.DataProxy)
local JobBridge = require(ReplicatedStorage.Patterns.Structural.JobBridge)
local PaymentStrategy = require(ReplicatedStorage.Patterns.Behavioral.PaymentStrategy)
local PlayerState = require(ReplicatedStorage.Patterns.Behavioral.PlayerState)
local GameCommand = require(ReplicatedStorage.Patterns.Behavioral.GameCommand)
local PlayerDataObserver = require(ReplicatedStorage.Patterns.Behavioral.PlayerDataObserver)
local MissionTemplate = require(ReplicatedStorage.Patterns.Behavioral.MissionTemplate)
local ValidationChain = require(ReplicatedStorage.Patterns.Behavioral.ValidationChain)

return {
	-- CREATIONAL: Factory Method - JobFactory
	["JobFactory - should create a police job"] = function()
		local factory = JobFactory.new()
		local job = factory:createJob("Police")
		this(job).exist()
		this(job.name).equal("Police")
		this(job.teamName).equal("Police")
		this(job.basePay).equal(250)
	end,

	["JobFactory - should return nil for invalid job"] = function()
		local factory = JobFactory.new()
		local job = factory:createJob("InvalidJob")
		this(job).never.exist()
	end,

	["JobFactory - should cache job instances"] = function()
		local factory = JobFactory.new()
		local job1 = factory:createJob("Fire")
		local job2 = factory:createJob("Fire")
		this(job1).equal(job2)
	end,

	["JobFactory - should validate jobs"] = function()
		local factory = JobFactory.new()
		this(factory:validateJob("Police")).equal(true)
		this(factory:validateJob("Civilian")).equal(true)
		this(factory:validateJob("Unknown")).equal(false)
	end,

	["JobFactory - should return all jobs"] = function()
		local factory = JobFactory.new()
		local allJobs = factory:getAllJobs()
		this(allJobs.Police).exist()
	end,

	-- CREATIONAL: Abstract Factory - NotificationFactory
	["NotificationFactory - should create InGame notification"] = function()
		local factory = NotificationFactory.new()
		local notification = factory:createNotification("InGame", "Player1", "Title", "Message", "High")
		this(notification).exist()
		this(notification.type).equal("InGame")
	end,

	["NotificationFactory - should create UI notification"] = function()
		local factory = NotificationFactory.new()
		local notification = factory:createNotification("UI", "Player1", "Title", "Message")
		this(notification).exist()
		this(notification.type).equal("UI")
	end,

	["NotificationFactory - should return nil for unknown type"] = function()
		local factory = NotificationFactory.new()
		local notification = factory:createNotification("Unknown", "Player1", "Title", "Message")
		this(notification).never.exist()
	end,

	["NotificationFactory - should create batch notifications"] = function()
		local factory = NotificationFactory.new()
		local notifications = factory:createBatchNotifications("InGame", { "Player1", "Player2", "Player3" }, "Title", "Message")
		this(#notifications).equal(3)
	end,

	-- CREATIONAL: Builder - MissionBuilder
	["MissionBuilder - should build mission with fluent API"] = function()
		local builder = MissionBuilder.new()
		local mission = builder
			:setTitle("Patrol District 5")
			:setDescription("Patrol the downtown area")
			:setAssignedJob("Police")
			:setReward(100)
			:setBonusReward(50)
			:setDifficulty("Medium")
			:addObjective("Visit all checkpoints")
			:addObjective("Report findings")
			:build()
		this(mission.title).equal("Patrol District 5")
		this(#mission.objectives).equal(2)
	end,

	["MissionBuilder - should validate negative rewards"] = function()
		local builder = MissionBuilder.new()
		local mission = builder:setReward(-100):build()
		this(mission.reward).equal(0)
	end,

	["MissionBuilder - should reset builder"] = function()
		local builder = MissionBuilder.new()
		builder:setTitle("Mission 1")
		builder:reset()
		local mission = builder:build()
		this(mission.title).equal("Untitled Mission")
	end,

	-- CREATIONAL: Singleton - ServiceRegistry
	["ServiceRegistry - should return same instance"] = function()
		local registry1 = ServiceRegistry.getInstance()
		local registry2 = ServiceRegistry.getInstance()
		this(registry1).equal(registry2)
	end,

	["ServiceRegistry - should register and retrieve services"] = function()
		local registry = ServiceRegistry.getInstance()
		registry:clear()
		local mockService = { name = "TestService" }
		registry:register("TestService", mockService)
		local retrieved = registry:get("TestService")
		this(retrieved).equal(mockService)
	end,

	["ServiceRegistry - should prevent duplicate registration"] = function()
		local registry = ServiceRegistry.getInstance()
		registry:clear()
		local service1 = { name = "Service1" }
		local result1 = registry:register("Service", service1)
		local result2 = registry:register("Service", service1)
		this(result1).equal(true)
		this(result2).equal(false)
	end,

	["ServiceRegistry - should check service existence"] = function()
		local registry = ServiceRegistry.getInstance()
		registry:clear()
		registry:register("ExistingService", {})
		this(registry:hasService("ExistingService")).equal(true)
		this(registry:hasService("NonExistent")).equal(false)
	end,

	-- STRUCTURAL: Decorator - ServiceDecorator
	["ServiceDecorator - should add logging decorator"] = function()
		local decorator = ServiceDecorator.new({})
		decorator:addLoggingDecorator("testMethod")
		assert(#decorator:getDecorators() > 0, "Expected at least one decorator")
	end,

	["ServiceDecorator - should add audit decorator"] = function()
		local decorator = ServiceDecorator.new({})
		decorator:addAuditDecorator("testMethod", "TestCategory")
		assert(#decorator:getDecorators() > 0, "Expected at least one decorator")
	end,

	["ServiceDecorator - should log operations"] = function()
		local decorator = ServiceDecorator.new({})
		decorator:logOperation("TestOp", "Details")
		assert(#decorator:getLogs() > 0, "Expected at least one log entry")
	end,

	["ServiceDecorator - should track performance metrics"] = function()
		local decorator = ServiceDecorator.new({})
		decorator:addPerformanceMonitoring("testMethod")
		decorator:startMetric()
		task.wait(0.01)
		decorator:endMetric("testMethod")
		local metrics = decorator:getMetrics()
		assert(metrics.testMethod > 0, "Expected positive metric value")
	end,

	-- STRUCTURAL: Adapter - ExternalAPIAdapter
	["ExternalAPIAdapter - should create adapter for DataStore"] = function()
		local mockDataStore = {}
		local adapter = ExternalAPIAdapter.new("DataStore", mockDataStore)
		local adaptedService = adapter:adaptDataStore(mockDataStore)
		this(adaptedService).exist()
	end,

	["ExternalAPIAdapter - should list adapted methods"] = function()
		local mockDataStore = {}
		local adapter = ExternalAPIAdapter.new("DataStore", mockDataStore)
		adapter:adaptDataStore(mockDataStore)
		local methods = adapter:getAdaptedMethods()
		assert(#methods > 0, "Expected at least one adapted method")
	end,

	-- STRUCTURAL: Facade - GameFacade
	["GameFacade - should get service status"] = function()
		local mockJobService = { _playersDataService = { _profiles = {} } }
		local mockPlayersData = { _profiles = {} }
		local mockNotification = {}
		local facade = GameFacade.new(mockJobService, mockPlayersData, mockNotification)
		local status = facade:getServiceStatus()
		this(status.jobService).equal("Active")
	end,

	-- STRUCTURAL: Proxy - DataProxy
	["DataProxy - should cache data"] = function()
		local counter = { calls = 0 }
		local function fetchFunction(_)
			counter.calls = counter.calls + 1
			return "data"
		end
		local proxy = DataProxy.new(nil, 10)
		proxy:get("key1", fetchFunction)
		proxy:get("key1", fetchFunction)
		this(counter.calls).equal(1)
	end,

	["DataProxy - should track cache statistics"] = function()
		local function fetchFunction(_)
			return "data"
		end
		local proxy = DataProxy.new(nil, 10)
		proxy:get("key1", fetchFunction)
		proxy:get("key1", fetchFunction)
		local stats = proxy:getCacheStats()
		this(stats.cacheHits).equal(1)
	end,

	["DataProxy - should invalidate cache"] = function()
		local function fetchFunction(_)
			return "data"
		end
		local proxy = DataProxy.new(nil, 10)
		proxy:get("key1", fetchFunction)
		proxy:invalidate("key1")
		this(proxy:isCached("key1")).equal(false)
	end,

	-- STRUCTURAL: Bridge - JobBridge
	["JobBridge - should create server job abstraction"] = function()
		local serverJob = JobBridge.createServerJobAbstraction("Police", 250)
		this(serverJob).exist()
		this(serverJob.name).equal("Police")
	end,

	["JobBridge - should create client job abstraction"] = function()
		local clientJob = JobBridge.createClientJobAbstraction("Police")
		this(clientJob).exist()
	end,

	["JobBridge - should get job info"] = function()
		local job = JobBridge.createServerJobAbstraction("Police", 250)
		local info = job:getJobInfo()
		this(info.name).equal("Police")
		this(info.implementation).exist()
	end,

	-- BEHAVIORAL: Strategy - PaymentStrategy
	["PaymentStrategy - should calculate basic payment"] = function()
		local strategy = PaymentStrategy.BasicPaymentStrategy.new()
		local payment = strategy:calculate(240, 8, 1.0)
		this(payment).equal(240)
	end,

	["PaymentStrategy - should calculate overtime payment"] = function()
		local strategy = PaymentStrategy.OvertimePaymentStrategy.new()
		local payment = strategy:calculate(240, 12, 1.0)
		assert(payment > 240, "Expected overtime pay " .. tostring(payment) .. " to be > 240")
	end,

	["PaymentStrategy - should calculate performance payment"] = function()
		local strategy = PaymentStrategy.PerformancePaymentStrategy.new()
		local payment = strategy:calculate(240, 8, 1.5)
		this(payment).equal(360)
	end,

	["PaymentStrategy - should switch strategies with context"] = function()
		local context = PaymentStrategy.PaymentContext.new(PaymentStrategy.BasicPaymentStrategy.new())
		this(context:getStrategyName()).equal("Basic")
		context:setStrategy(PaymentStrategy.OvertimePaymentStrategy.new())
		this(context:getStrategyName()).equal("Overtime")
	end,

	-- BEHAVIORAL: State - PlayerState
	["PlayerState - should create and manage player states"] = function()
		local idleState = PlayerState.IdleState.new()
		local context = PlayerState.PlayerStateContext.new(idleState)
		this(context:getCurrentStateName()).equal("Idle")
	end,

	["PlayerState - should transition between valid states"] = function()
		local idleState = PlayerState.IdleState.new()
		local onDutyState = PlayerState.OnDutyState.new()
		local context = PlayerState.PlayerStateContext.new(idleState)
		local success = context:transitionTo(onDutyState)
		this(success).equal(true)
		this(context:getCurrentStateName()).equal("OnDuty")
	end,

	["PlayerState - should prevent invalid transitions"] = function()
		local onDutyState = PlayerState.OnDutyState.new()
		local offlineState = PlayerState.OfflineState.new()
		local context = PlayerState.PlayerStateContext.new(onDutyState)
		local success = context:transitionTo(offlineState)
		this(success).equal(false)
	end,

	["PlayerState - should maintain state history"] = function()
		local context = PlayerState.PlayerStateContext.new(PlayerState.IdleState.new())
		context:transitionTo(PlayerState.OnDutyState.new())
		context:transitionTo(PlayerState.InMissionState.new())
		local history = context:getStateHistory()
		this(#history).equal(3)
	end,

	-- BEHAVIORAL: Command - GameCommand
	["GameCommand - should start with empty history"] = function()
		local invoker = GameCommand.CommandInvoker.new()
		this(invoker:getHistorySize()).equal(0)
	end,

	["GameCommand - should maintain command history"] = function()
		local invoker = GameCommand.CommandInvoker.new(5)
		for i = 1, 3 do
			local mockCommand = {
				execute = function()
					return true
				end,
				undo = function()
					return true
				end,
				getName = function()
					return "Command" .. i
				end,
			}
			invoker:execute(mockCommand)
		end
		this(invoker:getHistorySize()).equal(3)
	end,

	-- BEHAVIORAL: Observer - PlayerDataObserver
	["PlayerDataObserver - should attach observers"] = function()
		local subject = PlayerDataObserver.PlayerDataSubject.new()
		local observer = PlayerDataObserver.LoggingObserver.new()
		local success = subject:attach(observer)
		this(success).equal(true)
		this(subject:getObserverCount()).equal(1)
	end,

	["PlayerDataObserver - should notify observers on balance change"] = function()
		local subject = PlayerDataObserver.PlayerDataSubject.new()
		local observer = PlayerDataObserver.LoggingObserver.new()
		subject:attach(observer)
		subject:notifyBalanceChange(500)
		local logs = observer:getLogs()
		assert(#logs > 0, "Expected at least one log entry after notification")
	end,

	["PlayerDataObserver - should detach observers"] = function()
		local subject = PlayerDataObserver.PlayerDataSubject.new()
		local observer = PlayerDataObserver.LoggingObserver.new()
		subject:attach(observer)
		local success = subject:detach("LoggingObserver")
		this(success).equal(true)
		this(subject:getObserverCount()).equal(0)
	end,

	-- BEHAVIORAL: Template Method - MissionTemplate
	["MissionTemplate - should create patrol mission"] = function()
		local patrol = MissionTemplate.PatrolMissionTemplate.new()
		this(patrol).exist()
	end,

	["MissionTemplate - should validate player for patrol mission"] = function()
		local patrol = MissionTemplate.PatrolMissionTemplate.new()
		local valid = patrol:validatePlayer(nil)
		this(valid).equal(false)
	end,

	-- BEHAVIORAL: Chain of Responsibility - ValidationChain
	["ValidationChain - should create validation chain"] = function()
		local builder = ValidationChain.ValidationChainBuilder.new()
		builder:addValidator(ValidationChain.PlayerValidator.new())
		local chain = builder:build()
		this(chain).exist()
	end,

	["ValidationChain - should validate job assignment"] = function()
		local validator = ValidationChain.JobValidator.new()
		local valid, _ = validator:validate({ jobName = "Police" })
		this(valid).equal(true)
	end,

	["ValidationChain - should reject invalid jobs"] = function()
		local validator = ValidationChain.JobValidator.new()
		local valid, _ = validator:validate({ jobName = "InvalidJob" })
		this(valid).equal(false)
	end,
}
