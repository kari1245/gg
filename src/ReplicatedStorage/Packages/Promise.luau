-- sleitnick/Promise v4.0.0 (rút gọn, bản chuẩn cho Roblox)
-- https://github.com/Sleitnick/RbxUtil/blob/main/modules/Promise/init.lua
-- Đã được rút gọn cho dự án, chỉ giữ lại API cơ bản nhất

local Promise = {}
Promise.ClassName = "Promise"
Promise.Status = {
	Started = "Started",
	Resolved = "Resolved",
	Rejected = "Rejected"
}
Promise.__index = Promise

function Promise.new(executor)
	local self = setmetatable({}, Promise)
	self._status = Promise.Status.Started
	self._value = nil
	self._error = nil
	self._queuedResolve = {}
	self._queuedReject = {}
	local function resolve(value)
		if self._status == Promise.Status.Started then
			self._status = Promise.Status.Resolved
			self._value = value
			for _, cb in ipairs(self._queuedResolve) do cb(value) end
		end
	end
	local function reject(err)
		if self._status == Promise.Status.Started then
			self._status = Promise.Status.Rejected
			self._error = err
			for _, cb in ipairs(self._queuedReject) do cb(err) end
		end
	end

task.spawn(function()
		local ok, err = pcall(function() executor(resolve, reject) end)
		if not ok then reject(err) end
	end)
	return self
end

function Promise:andThen(onResolve, onReject)
	return Promise.new(function(resolve, reject)
		if self._status == Promise.Status.Resolved then
			if onResolve then
				local ok, result = pcall(onResolve, self._value)
				if ok then resolve(result) else reject(result) end
			else
				resolve(self._value)
			end
		elseif self._status == Promise.Status.Rejected then
			if onReject then
				local ok, result = pcall(onReject, self._error)
				if ok then resolve(result) else reject(result) end
			else
				reject(self._error)
			end
		else
			table.insert(self._queuedResolve, function(v)
				if onResolve then
					local ok, result = pcall(onResolve, v)
					if ok then resolve(result) else reject(result) end
				else
					resolve(v)
				end
			end)
			table.insert(self._queuedReject, function(e)
				if onReject then
					local ok, result = pcall(onReject, e)
					if ok then resolve(result) else reject(result) end
				else
					reject(e)
				end
			end)
		end
	end)
end

function Promise:catch(onReject)
	return self:andThen(nil, onReject)
end

return Promise
