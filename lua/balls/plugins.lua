--- List of plugins registered by balls.nvim
---
--- @type table<string, balls.Plugin>
_G.BALLS_PLUGINS = {}

local M = {}

--- Creates a new Plugin.
---
--- @param override table
---
--- @return balls.Plugin plugin
function M.new(override)
	local U = require("balls.util")
	local L = require("balls.log")

	local plugin = {}

	--- @private
	---
	--- @param lazy boolean
	---
	--- @return string path
	function plugin:_path(lazy)
		local packpath = require("balls.config").packpath

		if lazy then
			packpath = vim.fs.joinpath(packpath, "opt")
		else
			packpath = vim.fs.joinpath(packpath, "start")
		end

		return vim.fs.joinpath(packpath, self.name)
	end

	--- @return string path
	function plugin:path()
		return self:_path(self.lazy)
	end

	--- @param path string
	---
	--- @return boolean exists
	local exists = function(path)
		--- @diagnostic disable-next-line
		return vim.uv.fs_stat(path) ~= nil
	end

	--- @return boolean installed
	function plugin:installed()
		return exists(self:path())
	end

	--- @private
	function plugin:_on_sync()
		if self.on_sync ~= nil then
			self:on_sync()
		end

		local doc_path = vim.fs.joinpath(self:path(), "doc")

		if exists(doc_path) then
			vim.cmd.helptags(doc_path)
			L.debug("Generated helptags for `%s`.", self.name)
		end

		L.debug("Ran on_sync callback for `%s`.", self.name)
	end

	--- @param rev? string
	function plugin:checkout(rev)
		rev = vim.F.if_nil(rev, self.rev)

		if rev == nil then
			return
		end

		U.system({ "git", "checkout", rev }, {
			cwd = self:path(),
			on_exit = function(result)
				if result.code ~= 0 then
					L.error("Failed to checkout `%s` for `%s`.", rev, self.name)
					return
				end

				L.debug("Checked out `%s` for `%s`.", rev, self.name)

				self:_on_sync()
			end,
		})
	end

	function plugin:install()
		U.system({ "git", "clone", self.url, self:path() }, {
			on_exit = function(result)
				if result.code ~= 0 then
					L.error("Failed to install `%s`: %s", self.name, vim.inspect(result))
					return
				end

				L.info("Installed `%s`!", self.name)

				if self.rev ~= nil then
					self:checkout()
					return
				end

				self:_on_sync()
			end,
		})
	end

	function plugin:update()
		if not self:installed() then
			return
		end

		if self.rev ~= nil then
			self:checkout()
			return
		end

		U.system({ "git", "pull" }, {
			cwd = self:path(),
			on_exit = function(result)
				if result.code ~= 0 then
					L.error("Failed to update `%s`: %s", self.name, vim.inspect(result))
					return
				end

				if vim.trim(result.stdout) == "Already up to date." then
					L.debug("Already up to date: `%s`.", self.name)
					return
				end

				L.info("Updated `%s`!", self.name)

				self:_on_sync()
			end,
		})
	end

	function plugin:sync()
		local start_dir = self:_path(false)
		local opt_dir = self:_path(true)
		local command = nil
		local destination = nil

		if self.lazy and exists(start_dir) then
			command = { "mv", start_dir, opt_dir }
			destination = "opt/"
		elseif not self.lazy and exists(opt_dir) then
			command = { "mv", opt_dir, start_dir }
			destination = "start/"
		end

		if command == nil then
			if self:installed() then
				self:update()
			else
				self:install()
			end

			return
		end

		start_dir = assert(vim.fs.dirname(start_dir))
		opt_dir = assert(vim.fs.dirname(opt_dir))

		if destination == "start/" and not exists(start_dir) then
			vim.fn.mkdir(start_dir, "p")
		elseif destination == "opt/" and not exists(opt_dir) then
			vim.fn.mkdir(opt_dir, "p")
		end

		U.system(command, {
			on_exit = function(result)
				if result.code ~= 0 then
					L.error("Failed to move `%s`: %s", self.name, vim.inspect(result))
					return
				end

				L.debug("Moved `%s` to `%s`.", self.name, destination)

				self:update()
			end,
		})
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

	--- @param events string | string[]
	--- @param opts? balls.EventOpts
	---
	--- @return integer autocmd_id
	function plugin:load_on(events, opts)
		vim.validate({
			events = { events, { "string", "table" } },
			lazy_load_opts = { opts, { "nil", "table" } },
		})

		opts = vim.F.if_nil(opts, {})

		local default_opts = {
			group = vim.api.nvim_create_augroup("balls_lazy_" .. self.name, { clear = true }),
			desc = string.format("Lazy Loads `%s`.", self.name),
		}

		local callback = opts.callback

		default_opts = vim.tbl_deep_extend("force", default_opts, opts)
		default_opts.callback = vim.schedule_wrap(function(event)
			vim.cmd.packadd(self.name)

			if callback ~= nil then
				callback(event, self)
			end
		end)

		return vim.api.nvim_create_autocmd(events, default_opts)
	end

	return vim.tbl_deep_extend("force", plugin, override)
end

return M
