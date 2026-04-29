--[[
	@class JobFactory
	@desc Factory Method pattern for creating Job configuration objects
	@pattern Factory Method
	
	This factory encapsulates the creation of job objects, allowing easy
	instantiation of different job types without exposing their internal structure.
	Implements the Factory Method design pattern to handle job creation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JobConfig = require(ReplicatedStorage:WaitForChild("Classes"):WaitForChild("JobConfig"))

local JobFactory = {}
JobFactory.__index = JobFactory

export type JobData = {
	name: string,
	teamName: string,
	basePay: number,
	jobDescription: string,
}

--[[
	@method new
	@desc Creates a new JobFactory instance
	@return JobFactory
]]
function JobFactory.new()
	local self = setmetatable({}, JobFactory)
	self._jobs = JobConfig
	self._jobInstances = {}
	return self
end

--[[
	@method createJob
	@desc Factory method to create a job object by name
	@param jobName: string - Name of the job to create
	@return JobData | nil - Created job object or nil if not found
]]
function JobFactory:createJob(jobName: string): JobData?
	if self._jobInstances[jobName] then
		return self._jobInstances[jobName]
	end

	local jobConfig = self._jobs[jobName]
	if not jobConfig then
		warn("JobFactory: Job '" .. jobName .. "' does not exist in config")
		return nil
	end

	local jobData: JobData = {
		name = jobName,
		teamName = jobConfig.teamName,
		basePay = jobConfig.basePay,
		jobDescription = jobConfig.jobDescription,
	}

	self._jobInstances[jobName] = jobData
	return jobData
end

--[[
	@method getAllJobs
	@desc Returns all available jobs
	@return table - Table of all job configurations
]]
function JobFactory:getAllJobs(): { [string]: JobData }
	local allJobs = {}
	for jobName, _ in pairs(self._jobs) do
		allJobs[jobName] = self:createJob(jobName)
	end
	return allJobs
end

--[[
	@method validateJob
	@desc Validates if a job exists and has required properties
	@param jobName: string - Name of the job
	@return boolean - true if valid, false otherwise
]]
function JobFactory:validateJob(jobName: string): boolean
	local job = self:createJob(jobName)
	return job ~= nil and job.teamName ~= nil and job.basePay ~= nil
end

return JobFactory
