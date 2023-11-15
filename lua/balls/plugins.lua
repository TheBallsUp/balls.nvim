local M = {}

--- @type fun(path: string): boolean
--- @diagnostic disable-next-line
local exists = vim.uv.fs_stat

--- Returns the path of a plugin.
---
--- @private
---
--- @param plugin balls.Plugin
---
--- @return string path
function M._path(plugin)
	local packpath = require("balls.config").packpath

	if plugin.lazy then
		packpath = vim.fs.joinpath(packpath, "opt")
	else
		packpath = vim.fs.joinpath(packpath, "start")
	end

	return vim.fs.joinpath(packpath, plugin.name)
end

--- Returns whether a plugin is installed as specified by its spec.
---
--- @private
---
--- @param plugin balls.Plugin
---
--- @return boolean installed
function M._installed(plugin)
	--- @diagnostic disable-next-line
	return vim.uv.fs_stat(plugin:path()) ~= nil
end

--- Installs a plugin.
---
--- @private
---
--- @param plugin balls.Plugin
function M._install(plugin)
	require("balls.util").system({ "git", "clone", plugin.url, plugin:path() }, {
		on_exit = function(result)
			if result.code ~= 0 then
				require("balls.log").error("Failed to clone `%s`: %s", plugin.name, vim.inspect(result))
				return
			end

			require("balls.log").info("Installed `%s`!", plugin.name)

			if plugin.rev ~= nil then
				plugin:checkout()
				return
			end

			plugin:helptags()

			if plugin.on_sync ~= nil then
				plugin:on_sync()
				require("balls.log").info("Ran on_sync callback for `%s`!", plugin.name)
			end
		end,
	})
end

--- Installs a plugin.
---
--- @private
---
--- @param plugin balls.Plugin
function M._update(plugin)
	if not plugin:installed() then
		return
	end

	if plugin.rev ~= nil then
		plugin:checkout()
		return
	end

	require("balls.util").system({ "git", "pull" }, {
		cwd = plugin:path(),
		on_exit = function(result)
			if result.code ~= 0 then
				require("balls.log").error("Failed to update `%s`: %s", plugin.name, vim.inspect(result))
				return
			end

			if vim.trim(result.stdout) == "Already up to date." then
				return
			end

			require("balls.log").info("Updated `%s`!", plugin.name)

			plugin:helptags()

			if plugin.on_sync ~= nil then
				plugin:on_sync()
				require("balls.log").info("Ran on_sync callback for `%s`!", plugin.name)
			end
		end,
	})
end

--- Checks out a specific git revision for a plugin.
---
--- @private
---
--- @param plugin balls.Plugin
--- @param rev? string
function M._checkout(plugin, rev)
	rev = vim.F.if_nil(rev, plugin.rev)

	if rev == nil then
		return
	end

	require("balls.util").system({ "git", "checkout", rev }, {
		cwd = plugin:path(),
		on_exit = function(result)
			if result.code ~= 0 then
				require("balls.log").error(
					"Failed to checkout revision `%s` for `%s`: %s",
					rev,
					plugin.name,
					vim.inspect(result)
				)

				return
			end

			require("balls.log").debug("Checked out revision `%s` for `%s`.", rev, plugin.name)

			plugin:helptags()

			if plugin.on_sync ~= nil then
				plugin:on_sync()
				require("balls.log").info("Ran on_sync callback for `%s`!", plugin.name)
			end
		end,
	})
end

--- Makes sure the plugin is installed as specified by the spec.
---
--- @private
---
--- @param plugin balls.Plugin
function M._sync(plugin)
	local path = plugin:path()
	local start = path:gsub("opt", "start", 1)
	local opt = path:gsub("start", "opt", 1)
	local command = { "rm", "-rf" }

	if plugin.lazy and exists(start) then
		table.insert(command, start)
	elseif not plugin.lazy and exists(opt) then
		table.insert(command, opt)
	end

	if #command == 3 then
		require("balls.util").system(command, {
			on_exit = function(result)
				if result.code ~= 0 then
					require("balls.log").error(
						"Failed to remove old version of `%s`: %s",
						plugin.name,
						vim.inspect(result)
					)

					return
				end

				require("balls.log").debug("Removed old version of `%s`.", plugin.name)
			end,
		})
	end

	if plugin:installed() then
		plugin:update()
	else
		plugin:install()
	end
end

--- Generates helptags for a plugin.
---
--- @private
---
--- @param plugin balls.Plugin
function M._helptags(plugin)
	local doc_path = vim.fs.joinpath(plugin:path(), "doc")

	--- @diagnostic disable-next-line
	if vim.uv.fs_stat(doc_path) then
		vim.cmd.helptags(doc_path)
		require("balls.log").debug("Generated helptags for `%s`.", plugin.name)
	end
end

--- @class balls.Event
---
--- @field id integer The ID of the autocmd
--- @field event string The name of the triggered event
--- @field group integer? The ID of the augroup ID, if any
--- @field match string The value of <amatch>
--- @field buf integer The value of <abuf>
--- @field file string The value of <afile>
--- @field data any Arbitrary data passed via `nvim_exec_autocmds()`

--- @class balls.EventOpts : vim.api.keyset.create_autocmd
---
--- @field callback? fun(event: balls.Event, plugin: balls.Plugin)

--- Sets up an autocmd to load an optional plugin.
---
--- @private
---
--- @param plugin balls.Plugin
--- @param events string | string []
--- @param opts balls.EventOpts
function M._lazy_load(plugin, events, opts)
	vim.validate({
		plugin = { plugin, "table" },
		events = { events, { "string", "table" } },
		lazy_load_opts = { opts, "table" },
	})

	local default_opts = {
		group = vim.api.nvim_create_augroup("balls_lazy_" .. plugin.name, { clear = true }),
		desc = string.format("Lazy Loads `%s`.", plugin.name),
	}

	local callback = opts.callback

	default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	default_opts.callback = vim.schedule_wrap(function(event)
		vim.cmd.packadd(plugin.name)

		if callback ~= nil then
			callback(event, plugin)
		end
	end)

	vim.api.nvim_create_autocmd(events, default_opts)
end

--- List of plugins registered by balls.nvim
---
--- @generic Name : string
---
--- @type table<Name, balls.Plugin>
_G.BALLS_PLUGINS = {}

return M
