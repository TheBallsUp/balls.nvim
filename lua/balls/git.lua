--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

local util = require("balls.util")
local log = require("balls.log")

--- Checks out a specific git revision for the given `plugin`.
---
---@private
---
---@param plugin balls.Plugin
---@param rev string?
local function checkout(plugin, rev)
	local command = { "git", "checkout", vim.F.if_nil(rev, plugin.rev) }
	local opts = { cwd = plugin:path() }
	local result = util.shell(command, opts):wait()

	if result.code ~= 0 then
		return log.error(
			"Failed to checkout commit `%s` for `%s`: %s",
			vim.F.if_nil(rev, plugin.rev),
			plugin.name,
			vim.inspect(result)
		)
	end

	log.debug("Checked out commit `%s` for `%s`.", plugin.rev, plugin.name)
end

--- Clones a plugin from its remote repository.
---
---@private
---
---@param plugin balls.Plugin
local function clone(plugin)
	local result = util.shell({ "git", "clone", plugin.url, plugin:path() }):wait()

	if result.code ~= 0 then
		return log.error("Failed to clone plugin `%s`: %s", plugin.name, vim.inspect(result))
	end

	log.debug("Cloned plugin `%s`.", plugin.name)

	if plugin.rev ~= nil then
		checkout(plugin)
	end

	if plugin.on_sync ~= nil then
		plugin.on_sync(plugin)
		log.info("Ran on_sync for %s.", plugin.name)
	end
end

--- Pulls the latest version of the given `plugin` if it's not pinned to a specifc revision.
---
---@private
---
---@param plugin balls.Plugin
local function pull(plugin)
	if plugin.rev ~= nil then
		return
	end

	local result = util.shell({ "git", "pull" }, { cwd = plugin:path() }):wait()

	if result.code ~= 0 then
		return log.error("Failed to pull updates for plugin `%s`: %s", plugin.name, vim.inspect(result))
	end

	log.debug("Updated plugin `%s`.", plugin.name)

	if plugin.on_sync ~= nil then
		plugin.on_sync(plugin)
		log.info("Ran on_sync for %s.", plugin.name)
	end
end

--- Finds the default branch name for the repo at the given `path`.
---
---@param path string
---
---@return string branch
local function default_branch(path)
	local command = { "git", "symbolic-ref", "refs/remotes/origin/HEAD", "--short" }
	local result = util.shell(command, { cwd = path }):wait()

	if result.code ~= 0 then
		log.error("Failed to find branch name for %s: %s", path, vim.inspect(result))
		return "master"
	end

	return vim.trim(result.stdout):match(".-/(.*)")
end

return {
	checkout = checkout,
	clone = clone,
	pull = pull,
	default_branch = default_branch,
}
