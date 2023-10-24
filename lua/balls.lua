--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@private
---@class BallsPlugin
---
---@field name string Name of the plugin. This will be used as the directory name as well.
---
---@field url string Git URL of the plugin's repository.
---@field rev string Git revision for pinning the plugin's version.
---
---@field lazy boolean Whether this plugin lives in `opt/`.
---@field on_sync BallsOnSync? Post-update hook.
---
---@field path fun(self: BallsPlugin): string

---@class BallsPluginConfig
---
---@field name string? Custom name for the plugin.
---
---@field url string Git URL of the plugin's repository.
---@field rev string? Git revision for pinning the plugin's version.
---
---@field lazy boolean? Whether this plugin should be loaded automatically.
---@field on_sync BallsOnSync? Post-update hook.

---@alias BallsOnSync fun(plugin: BallsPlugin)

local util = require("balls.util")
local fs = require("balls.fs")
local git = require("balls.git")
local log = require("balls.log")

if BALLS_PLUGINS == nil then
	---@type BallsPlugin[]
	BALLS_PLUGINS = {}
end

--- Configure balls.nvim
---
---@param config BallsConfig
local function setup(config)
	for key, value in pairs(config) do
		require("balls.config"):set(key, value)
	end
end

--- Registers a plugin so it can be managed by balls.nvim.
---
---@param plugin_config BallsPluginConfig
local function register(plugin_config)
	local url_parts = vim.split(plugin_config.url, "/")
	local last = url_parts[#url_parts]

	if vim.endswith(last, ".git") then
		last = last:sub(1, #last - 4)
	end

	local name = vim.F.if_nil(plugin_config.name, last)

	---@type BallsPlugin
	local plugin = vim.tbl_extend("force", {
		name = name,
		lazy = false,
		path = function(self)
			local path = require("balls.config"):get("packpath")

			if self.lazy then
				path = vim.fs.joinpath(path, "opt", self.name)
			else
				path = vim.fs.joinpath(path, "start", self.name)
			end

			return path
		end,
	}, plugin_config)

	BALLS_PLUGINS[plugin.name] = plugin

	return plugin
end

--- Lists all plugins installed by balls.nvim
local function list()
	require("balls.ui").list_plugins()
end

--- Makes sure all registered plugins are installed
local function install()
	for name, plugin in pairs(BALLS_PLUGINS) do
		if not util.ensure_installed(plugin) then
			log.info("Installed %s", name)

			if plugin.on_sync ~= nil then
				plugin.on_sync(plugin)
				log.info("Ran on_sync for %s.", plugin.name)
			end
		end
	end
end

--- Makes sure all registered plugins are installed
local function update()
	for name, plugin in pairs(BALLS_PLUGINS) do
		util.update(plugin)
		log.info("Updated %s", name)
	end
end

--- Makes sure all registered plugins are installed and up to date
local function sync()
	local remove_unused = function(path)
		for dir in vim.fs.dir(path) do
			local is_plugin = false

			for _, plugin in pairs(BALLS_PLUGINS) do
				if dir == plugin.name then
					is_plugin = true
					break
				end

				if plugin.lazy and path == "start" then
					local start = vim.fs.joinpath(path, plugin.name)
					local opt = start:gsub("start", "opt", 1)
					util.shell({ "mv", start, opt }, nil, vim.schedule_wrap(function(result)
						if result.code ~= 0 then
							return log.error("Failed to move %s from start/ to opt/: %s", plugin.name, vim.inspect(result))
						end
					end))
				elseif not plugin.lazy and path == "start" then
					local opt = vim.fs.joinpath(path, plugin.name)
					local start = opt:gsub("opt", "start", 1)
					util.shell({ "mv", opt, start }, nil, vim.schedule_wrap(function(result)
						if result.code ~= 0 then
							return log.error("Failed to move %s from opt/ to start/: %s", plugin.name, vim.inspect(result))
						end
					end))
				end
			end

			if not is_plugin then
				log.warn("Removing %s", dir)

				util.shell({ "rm", "-rf", vim.fs.joinpath(path, dir) }, nil, vim.schedule_wrap(function(result)
					if result.code ~= 0 then
						return log.error("Failed to remove %s: %s", dir, vim.inspect(result))
					end

					log.info("Removed %s", dir)
				end))
			end
		end
	end

	local packpath = require("balls.config"):get("packpath")
	local opt = vim.fs.joinpath(packpath, "opt")
	local start = vim.fs.joinpath(packpath, "start")

	remove_unused(opt)
	remove_unused(start)

	local move = function(plugin, lazy)
		if plugin.rev == nil then
			local branch = git.default_branch(plugin:path())
			git.checkout(plugin, branch)
		else
			git.checkout(plugin)
		end

		local start = vim.fs.joinpath(start, plugin.name)
		local opt = vim.fs.joinpath(opt, plugin.name)
		local command = { "mv" }

		if lazy and not plugin.lazy then
			vim.list_extend(command, { opt, start })
		elseif not lazy and plugin.lazy then
			vim.list_extend(command, { start, opt })
		end

		if vim.tbl_count(command) == 1 then
			return
		end

		util.shell(command, nil, vim.schedule_wrap(function(result)
			if result.code ~= 0 then
				return log.error("Failed to move %s from opt/ to start/: %s", plugin.name, vim.inspect(result))
			end
		end))
	end

	for dir in vim.fs.dir(start) do
		for _, plugin in pairs(BALLS_PLUGINS) do
			if dir == plugin.name then
				move(plugin, false)
			end
		end
	end

	for dir in vim.fs.dir(opt) do
		for _, plugin in pairs(BALLS_PLUGINS) do
			if dir == plugin.name then
				move(plugin, true)
			end
		end
	end

	for _, plugin in pairs(BALLS_PLUGINS) do
		local installed = util.ensure_installed(plugin)

		if installed and plugin.rev == nil then
			util.update(plugin)
		end
	end
end

--- Loads the plugin with the given `plugin_name` on the specified `events` and runs `callback`.
--- It is a simple wrapper around `vim.api.nvim_create_autocmd`.
---
---@param plugin_name string
---@param events string | string[]
---@param callback function
---
---@return integer autocmd ID
local function lazy_load(plugin_name, events, callback)
	return vim.api.nvim_create_autocmd(events, {
		group = vim.api.nvim_create_augroup("balls-lazy-" .. plugin_name, { clear = true }),
		desc = "Lazy loads " .. plugin_name,
		callback = function(...)
			vim.fn.packadd(plugin_name)
			callback(...)
		end,
	})
end

return {
	setup = setup,
	register = register,
	list = list,
	install = install,
	update = update,
	sync = sync,
	lazy_load = lazy_load,
}
