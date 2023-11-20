if _G.BALLS_PLUGINS == nil then
	require("balls.plugins")
end

local M = {}

--- Configure balls.nvim with some custom options.
---
--- @param override balls.ConfigOverride
function M.setup(override)
	vim.validate({
		balls_config = { override, "table" },
	})

	if override.packpath ~= nil then
		vim.validate({
			balls_packpath = { override.packpath, "string" },
		})

		require("balls.config").packpath = override.packpath
	end

	if override.always_lazy ~= nil then
		vim.validate({
			balls_lazy = { override.always_lazy, "boolean" },
		})

		require("balls.config").always_lazy = override.always_lazy
	end

	if override.debug ~= nil then
		vim.validate({
			balls_debug = { override.debug, "boolean" },
		})

		require("balls.config").debug = override.debug
	end
end

--- Registers a plugin.
---
--- This means it will appear in `:BallsList` and be affected by other `:Balls*` commands such as
--- `:BallsSync`.
---
--- @param plugin_spec balls.PluginSpec
---
--- @return balls.Plugin plugin
function M.register(plugin_spec)
	vim.validate({
		plugin_spec = { plugin_spec, "table" },
		plugin_url = { plugin_spec.url, "string" },
	})

	local url_parts = vim.split(plugin_spec.url, "/")
	local plugin_name = vim.split(url_parts[#url_parts], ".git", { plain = true })[1]

	if plugin_spec.name ~= nil then
		vim.validate({
			plugin_name = { plugin_spec.name, "string" },
		})

		plugin_name = plugin_spec.name --[[@as string]]
	end

	local config = require("balls.config")
	local lazy = vim.F.if_nil(plugin_spec.lazy, config.always_lazy)

	vim.validate({
		plugin_is_lazy = { lazy, "boolean" },
	})

	local P = require("balls.plugins")

	--- @type balls.Plugin
	local plugin = {
		url = plugin_spec.url,
		rev = plugin_spec.rev,
		name = plugin_name,
		lazy = lazy,
		on_sync = plugin_spec.on_sync,
		path = P._path,
		installed = P._installed,
		install = P._install,
		update = P._update,
		checkout = P._checkout,
		sync = P._sync,
		helptags = P._helptags,
		lazy_load = P._lazy_load,
	}

	_G.BALLS_PLUGINS[plugin.name] = plugin
	require("balls.log").debug("Registered plugin `%s`.", plugin.name)

	return vim.deepcopy(plugin)
end

--- Opens a floating window listing all registered plugins.
function M.list()
	local lines = {}
	local longest_line = 0

	--- @param plugin balls.Plugin
	local format = function(plugin)
		local new_lines = {
			plugin.name .. " [" .. plugin.url .. "]",
			"  * Lazy: " .. tostring(plugin.lazy),
			"  * Installed: " .. tostring(plugin:installed()),
		}

		if plugin.rev ~= nil then
			table.insert(new_lines, "  * Revision: " .. plugin.rev)
		end

		for _, line in ipairs(new_lines) do
			if #line > longest_line and #line <= vim.o.columns then
				longest_line = #line
			end
		end

		table.insert(new_lines, "")
		vim.list_extend(lines, new_lines)
	end

	format(_G.BALLS_PLUGINS["balls.nvim"])

	local plugins = vim.tbl_values(_G.BALLS_PLUGINS)

	table.sort(plugins, function(a, b)
		return a.name < b.name
	end)

	for _, plugin in ipairs(plugins) do
		if plugin.name ~= "balls.nvim" then
			format(plugin)
		end
	end

	assert(longest_line > 0)

	local buffer = vim.api.nvim_create_buf(false, true)

	local close = function()
		vim.api.nvim_buf_delete(buffer, { force = true })
	end

	vim.keymap.set("n", "q", close, { buffer = buffer })
	vim.keymap.set("n", "<Esc>", close, { buffer = buffer })

	local width = math.max(longest_line, math.floor(vim.o.columns / 2))

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })
	vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = width,
		height = math.min(#lines, vim.o.lines),
		row = math.floor((vim.o.lines - #lines) / 3),
		col = math.floor((vim.o.columns - width) / 2),
		zindex = 300,
		style = "minimal",
		border = "rounded",
		title = string.format("[ Total Plugins: %d ]", vim.tbl_count(_G.BALLS_PLUGINS)),
		title_pos = "center",
	})
end

--- Installs any missing plugins.
function M.install()
	for _, plugin in pairs(_G.BALLS_PLUGINS) do
		if not plugin:installed() then
			plugin:install()
		end
	end
end

--- Updates any installed plugins.
function M.update()
	for _, plugin in pairs(_G.BALLS_PLUGINS) do
		if plugin:installed() then
			plugin:update()
		else
			plugin:install()
		end
	end
end

--- Syncs the list of registered plugins with the actually installed plugins on the system.
function M.sync()
	for _, plugin in pairs(_G.BALLS_PLUGINS) do
		plugin:sync()
	end

	M.clean()
end

--- Removes any unregistered plugins that are still installed.
function M.clean()
	local registered_plugins = vim.tbl_keys(_G.BALLS_PLUGINS)
	local packpath = require("balls.config").packpath
	local start = vim.fs.joinpath(packpath, "start")
	local opt = vim.fs.joinpath(packpath, "opt")
	local to_remove = {}

	--- @param parent string
	--- @param dir string
	local remove = function(parent, dir)
		if not vim.tbl_contains(registered_plugins, dir) then
			table.insert(to_remove, vim.fs.joinpath(parent, dir))
		end
	end

	for dir in vim.fs.dir(start) do
		remove(start, dir)
	end

	for dir in vim.fs.dir(opt) do
		remove(opt, dir)
	end

	for _, path in ipairs(to_remove) do
		require("balls.util").system({ "rm", "-rf", path }, {
			on_exit = function(result)
				if result.code ~= 0 then
					require("balls.log").error("Failed to remove `%s`: %s", path, vim.inspect(result))
					return
				end

				require("balls.log").info("Removed `%s`.", path)
			end,
		})
	end
end

return M
