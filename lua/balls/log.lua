--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

--- Logs a message with format specifiers on `TRACE` level.
---
---@param message string
---@param ... any format arguments
local function trace(message, ...)
	if not require("balls.config").get("debug") then
		return
	end

	vim.notify("[balls TRACE] " .. message:format(...), vim.log.levels.TRACE)
end

--- Logs a message with format specifiers on `DEBUG` level.
---
---@param message string
---@param ... any format arguments
local function debug(message, ...)
	if not require("balls.config").get("debug") then
		return
	end

	vim.notify("[balls DEBUG] " .. message:format(...), vim.log.levels.DEBUG)
end

--- Logs a message with format specifiers on `INFO` level.
---
---@param message string
---@param ... any format arguments
local function info(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.INFO)
end

--- Logs a message with format specifiers on `WARN` level.
---
---@param message string
---@param ... any format arguments
local function warn(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.WARN)
end

--- Logs a message with format specifiers on `ERROR` level.
---
---@param message string
---@param ... any format arguments
local function error(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.ERROR)
end

return {
	trace = trace,
	debug = debug,
	info = info,
	warn = warn,
	error = error,
}
