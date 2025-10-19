-- TreeRecord.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classes = ReplicatedStorage:WaitForChild("Classes")
local Node = require(Classes:WaitForChild("TrieNode"))

local TreeRecord = {}
TreeRecord.__index = TreeRecord

export type NodeType = typeof(Node.new())
export type TreeRecord = {
	root: NodeType,
	folder: Instance,
	index: { [string]: { Instance } },
	conns: { RBXScriptConnection },
}

local function normalizeName(s: string): string
	return string.lower(s)
end

function TreeRecord.new(folder: Instance): TreeRecord
	local self: TreeRecord = setmetatable({}, TreeRecord)
	self.root = Node.new()
	self.folder = folder
	self.index = {}
	self.conns = {}
	return self
end

function TreeRecord:AddInstance(inst: Instance)
	local word = normalizeName(inst.Name)
	local bucket = self.index[word]
	if not bucket then
		bucket = {}
		self.index[word] = bucket
		self.root:Insert(word)
	end
	for i = 1, #bucket do
		if bucket[i] == inst then
			return
		end
	end
	table.insert(bucket, inst)
end

function TreeRecord:RemoveInstance(inst: Instance)
	local word = normalizeName(inst.Name)
	local bucket = self.index[word]
	if not bucket then
		return
	end
	for i = #bucket, 1, -1 do
		if bucket[i] == inst then
			table.remove(bucket, i)
		end
	end
	if #bucket == 0 then
		self.index[word] = nil
		local path = {} :: { [number]: { node: NodeType, ch: string } }
		local node: NodeType = self.root
		for i = 1, #word do
			local ch = string.sub(word, i, i)
			local nextNode = node.children[ch]
			if not nextNode then
				return
			end
			path[i] = { node = node, ch = ch }
			node = nextNode
		end
		node.isEnd = false
		for i = #path, 1, -1 do
			local parent = path[i].node
			local ch = path[i].ch
			local child = parent.children[ch]
			local hasChildren = false
			for _ in pairs(child.children) do
				hasChildren = true
				break
			end
			if (not child.isEnd) and not hasChildren then
				parent.children[ch] = nil
			else
				break
			end
		end
	end
end

function TreeRecord:Search(prefix: string, limit: number?): { Instance }
	local p = normalizeName(prefix or "")
	if p == "" then
		return {}
	end
	local startNode = self.root:Find(p)
	if not startNode then
		return {}
	end

	local words = {}
	startNode:Collect(p, words, limit)

	local results = {}
	for i = 1, #words do
		local bucket = self.index[words[i]]
		if bucket then
			for j = 1, #bucket do
				results[#results + 1] = bucket[j]
				if limit and #results >= limit then
					return results
				end
			end
		end
	end
	return results
end

return TreeRecord
