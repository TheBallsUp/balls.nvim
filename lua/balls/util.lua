--- Makes sure the given `plugin` is installed.
---
---@private
---
---@return boolean already_installed
local function ensure_installed(plugin)
	if vim.uv.fs_stat(plugin:path()) then
		return true
	end

	require("balls.git").clone(plugin)

	vim.cmd.packloadall()
	vim.cmd.helptags("ALL")

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

	vim.cmd.packloadall()
	vim.cmd.helptags("ALL")
end

return {
	ensure_installed = ensure_installed,
	update = update,
}
