local Balls = {
	---@type balls.Plugin[]
	plugin_list = {},
}

---@param config_override? balls.ConfigOverride
---
---@return balls.Config
function Balls:setup(config_override)
	vim.validate({
		config = { config_override, { "nil", "table" } },
	})

	if not config_override then
		return require("balls.config")
	end

	for k, v in pairs(config_override) do
		if require("balls.config")[k] ~= nil then
			require("balls.config")[k] = v
		end
	end

	return require("balls.config")
end

--- Registers a new plugin.
---
---@param url string
---@param spec? balls.PluginSpec
---
---@return balls.Plugin plugin
function Balls:register(url, spec)
	vim.validate({
		plugin_url = { url, "string" },
		plugin_spec = { spec, { "nil", "table" } },
	})

	local plugin = require("balls.plugins").new(url, vim.F.if_nil(spec, {}))
	local idx = nil

	for i, p in ipairs(self.plugin_list) do
		if p.url == plugin.url then
			idx = i
			break
		end
	end

	if idx then
		self.plugin_list[idx] = plugin
	else
		table.insert(self.plugin_list, plugin)
	end

	require("balls.util").debug("Registered plugin `%s`.", plugin.name)

	if require("balls.config").auto_update then
		plugin:update(true)
	elseif require("balls.config").auto_install then
		plugin:update(false)
	end

	return plugin
end

--- Returns an iterator over all currently registered plugins.
---
---@return fun(): balls.Plugin?
function Balls:plugins()
	local i = 0

	return function()
		i = i + 1
		return Balls.plugin_list[i]
	end
end

--- Installs any missing plugins.
function Balls:install()
	for plugin in self:plugins() do
		plugin:install()
	end
end

--- Updates any installed plugins.
function Balls:update()
	for plugin in self:plugins() do
		plugin:update()
	end
end

--- Removes any unused plugins.
function Balls:clean()
	local cache = {}

	for plugin in self:plugins() do
		cache[plugin:path()] = true
	end

	local packpath = require("balls.config").packpath

	self:_clean_dir(vim.fs.joinpath(packpath, "opt"), cache)
	self:_clean_dir(vim.fs.joinpath(packpath, "start"), cache)
end

---@param dir string
---@param cache table<string, boolean>
---
---@private
function Balls:_clean_dir(dir, cache)
	local U = require("balls.util")

	for entry in vim.fs.dir(dir) do
		local path = vim.fs.joinpath(dir, entry)

		if not cache[path] then
			U.rm(path)

			local segments = vim.split(path, "/")
			local name = segments[#segments]

			U.info("Removed `%s`.", name)
		end
	end

	U.debug("Cleaned `%s`.", dir)
end

return Balls
