-- Promise implementation tailored for Planet Project
-- Includes: Cancel, Retry, Static Methods

local Promise = {}
Promise.ClassName = "Promise"
Promise.Status = {
	Started = "Started",
	Resolved = "Resolved",
	Rejected = "Rejected",
	Cancelled = "Cancelled"
}
Promise.__index = Promise

-- Helper
local function isPromise(obj)
	return type(obj) == "table" and obj.ClassName == "Promise"
end

-- Constructor
function Promise.new(executor)
	local self = setmetatable({}, Promise)
	self._status = Promise.Status.Started
	self._value = nil
	self._error = nil
	self._queuedResolve = {}
	self._queuedReject = {}
	self._parent = nil -- Keep track to chain cancel upstream

	local function resolve(value)
		if self._status ~= Promise.Status.Started then return end
		self._status = Promise.Status.Resolved
		self._value = value
		for _, cb in ipairs(self._queuedResolve) do task.spawn(cb, value) end
		self._queuedResolve = nil
		self._queuedReject = nil
	end

	local function reject(err)
		if self._status ~= Promise.Status.Started then return end
		self._status = Promise.Status.Rejected
		self._error = err
		for _, cb in ipairs(self._queuedReject) do task.spawn(cb, err) end
		self._queuedResolve = nil
		self._queuedReject = nil
	end
	
	-- On Cancel Hook (Optional)
	self._onCancel = nil
	local function onCancel(callback)
		self._onCancel = callback
	end

	task.spawn(function()
		local ok, err = pcall(function() executor(resolve, reject, onCancel) end)
		if not ok then reject(err) end
	end)

	return self
end

-- Static Methods
function Promise.resolve(value)
	return Promise.new(function(resolve) resolve(value) end)
end

function Promise.reject(err)
	return Promise.new(function(_, reject) reject(err) end)
end

-- [QUAN TRỌNG] Hàm Retry cho logic Spawn
function Promise.retryWithDelay(callback, times, delay)
	return Promise.new(function(resolve, reject, onCancel)
		local cancelled = false
		onCancel(function() cancelled = true end)

		local attempts = 0
		
		local function attempt()
			if cancelled then return end
			attempts += 1
			
			local result
			local ok, err = pcall(function() 
				result = callback() 
			end)

			if ok and isPromise(result) then
				result:andThen(resolve):catch(function(e)
					if attempts >= times then
						reject(e)
					else
						task.wait(delay)
						attempt()
					end
				end)
			elseif ok then
				resolve(result)
			else
				if attempts >= times then
					reject(err)
				else
					task.wait(delay)
					attempt()
				end
			end
		end
		
		attempt()
	end)
end

-- Instance Methods
function Promise:andThen(onResolve, onReject)
	local child = Promise.new(function(resolve, reject, onCancel)
		local function success(val)
			if onResolve then
				local ok, res = pcall(onResolve, val)
				if ok then
					if isPromise(res) then
						res:andThen(resolve, reject)
						-- Propagate cancel to inner promise
						onCancel(function() if res.cancel then res:cancel() end end)
					else
						resolve(res)
					end
				else
					reject(res)
				end
			else
				resolve(val)
			end
		end

		local function failure(err)
			if onReject then
				local ok, res = pcall(onReject, err)
				if ok then
					if isPromise(res) then
						res:andThen(resolve, reject)
						onCancel(function() if res.cancel then res:cancel() end end)
					else
						resolve(res)
					end
				else
					reject(res)
				end
			else
				reject(err)
			end
		end

		if self._status == Promise.Status.Resolved then
			success(self._value)
		elseif self._status == Promise.Status.Rejected then
			failure(self._error)
		elseif self._status == Promise.Status.Started then
			table.insert(self._queuedResolve, success)
			table.insert(self._queuedReject, failure)
		end
	end)
	
	child._parent = self -- Link for cancellation
	return child
end

function Promise:catch(onReject)
	return self:andThen(nil, onReject)
end

function Promise:finally(onFinally)
	return self:andThen(
		function(val)
			onFinally(Promise.Status.Resolved)
			return val
		end,
		function(err)
			onFinally(Promise.Status.Rejected)
			return Promise.reject(err)
		end
	)
end

-- [QUAN TRỌNG] Hàm Cancel để hủy request cũ
function Promise:cancel()
	if self._status ~= Promise.Status.Started then return end
	self._status = Promise.Status.Cancelled
	
	if self._onCancel then
		task.spawn(self._onCancel)
	end
	
	-- Cancel parent recursively (upstream cancellation)
	if self._parent then
		self._parent:cancel()
	end
	
	self._queuedResolve = nil
	self._queuedReject = nil
end

function Promise:getStatus()
	return self._status
end

return Promise