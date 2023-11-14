return {
	--- Logs a message at `TRACE` level.
	---
	---@param message string
	---@param ... any formatting arguments
	trace = function(message, ...)
		if require("balls.config"):get("debug") then
			vim.notify("[balls] [TRACE] " .. message:format(...), vim.log.levels.TRACE)
		end
	end,

	--- Logs a message at `DEBUG` level.
	---
	---@param message string
	---@param ... any formatting arguments
	debug = function(message, ...)
		if require("balls.config"):get("debug") then
			vim.notify("[balls] [DEBUG] " .. message:format(...), vim.log.levels.DEBUG)
		end
	end,

	--- Logs a message at `INFO` level.
	---
	---@param message string
	---@param ... any formatting arguments
	info = function(message, ...)
		vim.notify("[balls] " .. message:format(...), vim.log.levels.INFO)
	end,

	--- Logs a message at `WARN` level.
	---
	---@param message string
	---@param ... any formatting arguments
	warn = function(message, ...)
		vim.notify("[balls] " .. message:format(...), vim.log.levels.WARN)
	end,

	--- Logs a message at `ERROR` level.
	---
	---@param message string
	---@param ... any formatting arguments
	error = function(message, ...)
		vim.notify("[balls] " .. message:format(...), vim.log.levels.ERROR)
	end,
}
