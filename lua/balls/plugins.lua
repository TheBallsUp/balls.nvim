---@class balls.Plugin
---
---@field name string
---@field lazy boolean
---
---@field url string
---@field rev? string
---
---@private
---@field _spec balls.PluginSpec
local Plugin = {}
Plugin.__index = Plugin

---@class balls.Event
---
---@field id integer
---@field event string
---@field group? integer
---@field match string
---@field buf integer
---@field file string
---@field data any

---@class balls.LoadOptions : vim.api.keyset.create_autocmd
---
---@field callback? fun(event: balls.Event, plugin: balls.Plugin)

---@class balls.PluginSpec
---
---@field name? string
---@field lazy? boolean
---@field rev? string
---@field on_sync? fun(self: balls.Plugin)

--- Creates a new plugin object.
---
---@param url string
---@param spec balls.PluginSpec
---
---@return balls.Plugin plugin
function Plugin.new(url, spec)
	local config = require("balls.config")
	local plugin = setmetatable({
		lazy = vim.F.if_nil(spec.lazy, config.lazy_by_default),
		url = url,
		rev = spec.rev,
		_spec = spec,
	}, Plugin)

	if spec.name then
		plugin.name = spec.name
	else
		local url_parts = vim.split(url, "/")
		local name = url_parts[#url_parts]

		if vim.endswith(name, ".git") then
			name = name:sub(1, #name - 4)
		end

		plugin.name = name
	end

	return plugin
end

--- Returns the path of where the plugin is / will be installed.
---
---@return string install_path
function Plugin:path()
	return self:_path(self.lazy)
end

---@param lazy boolean
---
---@return string install_path
---
---@private
function Plugin:_path(lazy)
	local path = require("balls.config").packpath

	if lazy then
		path = vim.fs.joinpath(path, "opt")
	else
		path = vim.fs.joinpath(path, "start")
	end

	return vim.fs.joinpath(path, self.name)
end

--- Checks whether this plugin is currently installed.
---
---@return boolean is_installed
function Plugin:installed()
	return require("balls.util").exists(self:path())
end

---@private
function Plugin:on_sync()
	local U = require("balls.util")
	local doc_path = vim.fs.joinpath(self:path(), "doc")

	if U.exists(doc_path) then
		vim.cmd.helptags(doc_path)
		U.debug("Generated helptags for `%s`.", self.name)
	end

	if self._spec.on_sync then
		self._spec.on_sync(self)
		U.debug("Ran on_sync callback for `%s`.", self.name)
	end
end

--- Loads the plugin.
function Plugin:load()
	vim.cmd.packadd(self.name)
end

--- Loads the plugin when one of the given `events` fires.
---
---@param events string | string[]
---@param options? balls.LoadOptions
---
---@return integer autocmd_id
function Plugin:load_on(events, options)
	options = vim.F.if_nil(options, {}) --[[@as balls.LoadOptions]]
	options.once = vim.F.if_nil(options.once, true)

	if options.callback then
		local callback = assert(options.callback)

		options.callback = function(event)
			if not self:installed() then
				return
			end

			vim.cmd.packadd(self.name)
			return callback(event, self)
		end
	end

	return vim.api.nvim_create_autocmd(events, options)
end

--- Ensures this plugin is installed.
function Plugin:install()
	if self:installed() then
		return
	end

	local U = require("balls.util")

	U.shell({ "git", "clone", self.url, self:path() }, {
		on_exit = function(result)
			if result.code ~= 0 then
				U.error("Failed to install `%s`: %s", self.name, vim.trim(result.stderr))
				return
			end

			U.info("Installed `%s`.", self.name)
			self:on_sync()
		end,
	})
end

--- Ensures this plugin is up to date.
---
---@param pull boolean? pull updates - defaults to `true`
function Plugin:update(pull)
	pull = vim.F.if_nil(pull, true)

	local U = require("balls.util")
	local opt = self:_path(true)
	local start = self:_path(false)

	if U.exists(opt) and not self.lazy then
		if U.exists(start) then
			U.rm(opt)
			U.debug("Removed `%s`.", opt)
		else
			U.mv(opt, start)
			U.info("Disabled lazy-loading for `%s`.", self.name)
		end
	end

	if U.exists(start) and self.lazy then
		if U.exists(opt) then
			U.rm(start)
			U.debug("Removed `%s`.", start)
		else
			U.mv(start, opt)
			U.info("Enabled lazy-loading for `%s`.", self.name)
		end
	end

	if not self:installed() then
		self:install()
		return
	end

	local is_detached = U.is_detached(self:path(), self.name)
	local rev = nil
	local has_changed = nil

	if is_detached then
		if self.rev then
			rev = self.rev

			local current_rev = U.current_revision(self:path(), self.name)

			if current_rev then
				has_changed = self.rev ~= current_rev
			else
				has_changed = true
			end
		else
			rev = U.default_branch(self:path(), self.name)
			has_changed = true
		end
	else
		if self.rev then
			rev = self.rev
			has_changed = true
		else
			rev = U.default_branch(self:path(), self.name)
			has_changed = false
		end
	end

	assert(rev ~= nil)
	assert(has_changed ~= nil)

	U.shell({ "git", "fetch" }, {
		cwd = self:path(),
		on_exit = function(result)
			if result.code ~= 0 then
				U.error("Failed to fetch updates for `%s`: %s", self.name, vim.trim(result.stderr))
				return
			end

			if has_changed then
				self:_checkout(rev, pull)
			elseif pull then
				self:_pull(false)
			end
		end,
	})
end

---@param rev string
---@param pull boolean
---
---@private
function Plugin:_checkout(rev, pull)
	local U = require("balls.util")

	U.shell({ "git", "checkout", rev }, {
		cwd = self:path(),
		on_exit = function(result)
			if result.code ~= 0 then
				U.error(
					"Failed to checkout `%s` for `%s`: %s",
					vim.inspect(rev),
					self.name,
					result.stderr
				)
				return
			end

			U.info("Checked out `%s` for `%s`.", rev, self.name)

			if pull then
				self:_pull(true)
			end
		end,
	})
end

---@param run_on_sync boolean
---
---@private
function Plugin:_pull(run_on_sync)
	local U = require("balls.util")

	U.shell({ "git", "pull" }, {
		cwd = self:path(),
		on_exit = function(result)
			local stderr_lines = vim.split(vim.trim(result.stderr), "\n")

			if result.code == 1 and vim.startswith(stderr_lines[1], "You are not currently on a branch.") then
				if run_on_sync then
					self:on_sync()
				end

				return
			end

			if result.code ~= 0 then
				U.error("Failed to pull updates for `%s`: %s", self.name, vim.trim(result.stderr))
				return
			end

			if vim.trim(result.stdout) == "Already up to date." then
				if run_on_sync then
					self:on_sync()
				end

				return
			end

			U.info("Updated `%s`.", self.name)
			self:on_sync()
		end,
	})
end

return Plugin
