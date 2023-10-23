--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

--- Register a new plugin to make sure it gets installed the next time `:BallsInstall` is ran.
---
---@param spec BallsPluginSpec
---
---@return BallsPlugin plugin
local function register(spec)
	local name_parts = vim.split(spec.url, "/")

	---@type BallsPlugin
	local plugin = vim.tbl_deep_extend("force", {
		name = name_parts[#name_parts],
		lazy = false,
	}, spec)

	plugin.path = require("balls.fs").packpath({ opt = plugin.lazy })
			.. plugin.name

	BALLS_PLUGINS[plugin.name] = plugin
	require("balls.log").trace("Registered plugin `%s`.", plugin.name)

	return plugin
end

--- Clones the given `plugin` if it's not already installed.
---
---@param plugin BallsPlugin
local function install(plugin)
	if require("balls.fs").exists(plugin.path) then
		require("balls.log").debug("%s already exists. Skipping install.", plugin.path)
		return
	end

	require("balls.git").clone(plugin.url, plugin.path, {
		branch = plugin.branch,
		tag = plugin.tag,
		commit = plugin.commit,
	})

	require("balls.log").info("Installed %s.", plugin.name)

	if plugin.on_sync ~= nil then
		plugin.on_sync(plugin)
		require("balls.log").info("Executed on_sync routine for %s", plugin.path)
	end
end

--- Will install all registered plugins.
local function install_all()
	for _, plugin in pairs(BALLS_PLUGINS) do
		install(plugin)
	end
end

--- Updates the given `plugin` by pulling from its remote repository.
---
---@param plugin BallsPlugin
local function update(plugin)
	require("balls.git").pull(plugin.path)
	require("balls.log").info("Updated %s.", plugin.name)

	if plugin.on_sync ~= nil then
		plugin.on_sync(plugin)
		require("balls.log").info("Executed on_sync routine for %s", plugin.path)
	end
end

--- Will updated all registered plugins.
local function update_all()
	for _, plugin in pairs(BALLS_PLUGINS) do
		update(plugin)
	end
end

--- Syncs the given `plugin` by either cloning it or pulling from its remote repository.
---
---@param plugin BallsPlugin
local function sync(plugin)
	if require("balls.fs").exists(plugin.path) then
		update(plugin)
		return
	end

	install(plugin)
end

--- Will install and updated all registered plugins, as well as remove any unregistered ones.
local function sync_all()
	local foreach = function(path)
		local should_exist = false

		for _, plugin in pairs(BALLS_PLUGINS) do
			if plugin.path == path then
				should_exist = true
				break
			end
		end

		if not should_exist then
			require("balls.log").warn("Removing %s", path)
			vim.system({ "rm", "-rf", path }, { text = true }, vim.schedule_wrap(function(result)
				if result.code ~= 0 then
					require("balls.log").error("Failed to remove `%s`: %s", path, result)
				else
					require("balls.log").info("Removed %s", path)
				end
			end))
		end
	end

	local packpath = require("balls.fs").packpath({ opt = true })

	for path in vim.fs.dir(packpath) do
		foreach(packpath .. path)
	end

	packpath = require("balls.fs").packpath({ opt = false })

	for path in vim.fs.dir(require("balls.fs").packpath({ opt = false })) do
		foreach(packpath .. path)
	end

	for _, plugin in pairs(BALLS_PLUGINS) do
		require("balls").sync(plugin)
	end
end

--- Configure balls.nvim
---
---@param config BallsConfig
local function setup(config)
	for key, value in pairs(config) do
		require("balls.config").set(key, value)
	end
end

return {
	register = register,
	install = install,
	install_all = install_all,
	update = update,
	update_all = update_all,
	sync = sync,
	sync_all = sync_all,
	setup = setup,
}
