--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

local fs = require("balls.fs")

--- Runs a shell command.
--- Thin wrapper around |vim.system()|.
---
---@param command string[] shell command arguments
---@param options SystemOpts?
---@param on_exit fun(result: vim.SystemCompleted)?
---
---@return vim.SystemObj
local function shell(command, options, on_exit)
	options = vim.tbl_extend("force", { text = true }, vim.F.if_nil(options, {}))

	return vim.system(command, options, on_exit)
end

--- Makes sure the given `plugin` is installed.
---
---@private
---
---@return boolean already_installed
local function ensure_installed(plugin)
	if fs.exists(plugin:path()) then
		return true
	end

	require("balls.git").clone(plugin)
	return false
end

--- Makes sure the given `plugin` is up to date.
---
---@private
local function update(plugin)
	if plugin.rev ~= nil then
		require("balls.git").checkout(plugin)
	else
		require("balls.git").pull(plugin)
	end
end

return {
	shell = shell,
	ensure_installed = ensure_installed,
	update = update,
}
