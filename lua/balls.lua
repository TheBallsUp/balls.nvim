--- @class balls.PluginSpec
---
--- @field name string? Custom name for the plugin.
--- @field rev string? Custom Git revision to checkout.
--- @field lazy boolean? Whether to put the plugin into `opt/`.
--- @field on_sync fun(self: balls.Plugin)? Custom function that runs when the plugin gets installed or updated.

--- @class balls.ConfigOverride
---
--- @field debug boolean? Print debug logs.
--- @field packpath string? Custom path for plugins. See `:help 'packpath'`
--- @field lazy_by_default boolean? Install all plugins as lazy by default.
--- @field balls_spec balls.PluginSpec? Custom plugin spec for balls.nvim itself.

--- @class balls.EventOpts : vim.api.keyset.create_autocmd
---
--- @field callback fun(event: table, plugin: balls.Plugin) Function that runs when the event(s) get triggered.

local U = require("balls.util")

local if_nil = vim.F.if_nil

local Balls = {}

--- @type balls.Plugin[]
---
--- Global list of registered plugins.
Balls.plugins = {}

--- @class balls.Config
---
--- @field debug boolean
--- @field packpath string
--- @field lazy_by_default boolean
--- @field balls_spec balls.PluginSpec
---
--- Configuration for balls.nvim
Balls.config = {
	debug = false,
	packpath = U.config_path("pack", "balls"),
	lazy_by_default = false,
	balls_spec = {
		lazy = false,
	},
}

--- Changes configuration options. See `:help balls-config`.
--- You do not have to call this function unless you want to change anything!
---
--- @param config_override balls.ConfigOverride
function Balls:setup(config_override)
	self.config = vim.tbl_deep_extend("force", self.config, if_nil(config_override, {}))
end

--- Registers a plugin. This means it will be considered by `:BallsInstall` and friends.
---
--- @param url string
--- @param plugin_spec balls.PluginSpec?
function Balls:register(url, plugin_spec)
	vim.validate({
		plugin_url = { url, "string" },
		plugin_spec = { plugin_spec, { "nil", "table" } },
	})

	--- @type balls.PluginSpec
	plugin_spec = if_nil(plugin_spec, {})

	--- This is only for overriding balls.nvim's own spec in `.setup()`
	--- @diagnostic disable-next-line
	if plugin_spec.url ~= nil then
		--- @diagnostic disable-next-line
		url = plugin_spec.url
	end

	local url_parts = vim.split(url, "/")
	local plugin_name = if_nil(plugin_spec.name, url_parts[#url_parts])

	if plugin_spec.name == nil and vim.endswith(plugin_name, ".git") then
		plugin_name = plugin_name:sub(1, #plugin_name - 4)
	end

	--- @class balls.Plugin
	---
	--- @field name string Custom name for the plugin.
	--- @field url string Git URL for cloning the plugin repository.
	--- @field rev string? Custom Git revision to checkout.
	--- @field lazy boolean Whether to put the plugin into `opt/`.
	---
	--- A registered plugin.
	local Plugin = {
		name = plugin_name,
		url = url,
		rev = plugin_spec.rev,
		lazy = if_nil(plugin_spec.lazy, Balls.config.lazy_by_default),
	}

	--- @param lazy_override boolean?
	---
	--- @return string path the installation path for this plugin
	function Plugin:path(lazy_override)
		local path = Balls.config.packpath
		local lazy = if_nil(lazy_override, self.lazy)

		if lazy then
			path = vim.fs.joinpath(path, "opt")
		else
			path = vim.fs.joinpath(path, "start")
		end

		return vim.fs.joinpath(path, self.name)
	end

	--- Autocommand wrapper to load a plugin on specific event(s).
	---
	--- @param events string | string[]
	--- @param opts balls.EventOpts?
	---
	--- @return integer autocmd_id
	function Plugin:load_on(events, opts)
		--- @type balls.EventOpts
		opts = if_nil(opts, {})
		opts.group = vim.api.nvim_create_augroup("balls_lazy_" .. self.name, { clear = true })

		local callback = opts.callback

		opts.callback = vim.schedule_wrap(function(event)
			vim.cmd.packadd(self.name)
			U.notify_debug("Loaded `%s`.", self.name)

			if callback ~= nil then
				callback(event, self)
			end
		end)

		return vim.api.nvim_create_autocmd(events, opts)
	end

	--- @return boolean installed whether this plugin is currently installed
	function Plugin:installed()
		return U.exists(self:path())
	end

	--- Installs this plugin.
	function Plugin:install()
		if self:installed() then
			return
		end

		U.system({ "git", "clone", self.url, self:path() }, {
			on_exit = function(result)
				if result.code ~= 0 then
					U.notify_error("Failed to install `%s`: %s", self.name, result.stderr)
					return
				end

				U.notify("Installed `%s`!", self.name)
				self:on_sync()
			end,
		})
	end

	--- Updates this plugin.
	function Plugin:update()
		if not self:installed() then
			return
		end

		local should_pull = self.rev == nil
		local rev = if_nil(self.rev, U.default_branch(self:path()))

		U.system({ "git", "checkout", rev }, {
			cwd = self:path(),
			on_exit = function(result)
				if result.code ~= 0 then
					U.notify_error("Failed to checkout rev `%s` for `%s`: %s", rev, self.name, result.stderr)
					return
				end

				if not should_pull then
					U.notify_debug("Checked out rev `%s` for `%s`.", rev, self.name)
					self:on_sync()
					return
				end

				U.system({ "git", "pull" }, {
					cwd = self:path(),
					on_exit = function(result)
						if result.code ~= 0 then
							U.notify_error("Failed to update `%s`: %s", self.name, result.stderr)
							return
						end

						if vim.trim(result.stdout) == "Already up to date." then
							return
						end

						U.notify("Updated `%s`!", self.name)
						self:on_sync()
					end,
				})
			end,
		})
	end

	--- Makes sure this plugin is installed in the correct location and up to date with its remote.
	function Plugin:sync()
		local start_path = self:path(false)
		local opt_path = self:path(true)

		if not (U.exists(start_path) or U.exists(opt_path)) then
			self:install()
			return
		end

		local cmd = nil

		local ensure_exists = function(dir)
			local start_dir = vim.fs.joinpath(Balls.config.packpath, dir)

			if not U.exists(start_dir) then
				vim.fn.mkdir(start_dir, "p")
			end
		end

		if self.lazy and U.exists(start_path) then
			cmd = { "mv", start_path, opt_path }

			ensure_exists("opt")
		elseif not self.lazy and U.exists(opt_path) then
			cmd = { "mv", opt_path, start_path }

			ensure_exists("start")
		end

		if cmd == nil then
			self:update()
			return
		end

		U.system(cmd, {
			on_exit = function(result)
				if result.code ~= 0 then
					U.notify_error("Failed to move `%s`: %s", self.name, result.stderr)
					return
				end

				U.notify_debug("Moved `%s`.", self.name)
				self:update()
			end,
		})
	end

	--- @private
	---
	--- Runs anytime the plugin is installed or updated.
	function Plugin:on_sync()
		self:generate_helptags()

		if plugin_spec.on_sync ~= nil then
			plugin_spec.on_sync(self)
			U.notify_debug("Ran on_sync routine for `%s`.", self.name)
		end
	end

	--- @private
	---
	--- Generates helptags for this plugin.
	function Plugin:generate_helptags()
		local doc_path = vim.fs.joinpath(self:path(), "doc")

		if not U.exists(doc_path) then
			return
		end

		vim.cmd.helptags(doc_path)
		U.notify_debug("Generated helptags for `%s`.", self.name)
	end

	table.insert(self.plugins, Plugin)
	U.notify_debug("Registered `%s`.", Plugin.name)

	return Plugin
end

return Balls
