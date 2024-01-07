local M = {}

---@param ... string
function M.config_path(...)
	local config_dir = vim.fn.stdpath("config") --[[@as string]]

	return vim.fs.joinpath(config_dir, ...)
end

---@param message string
---@param ... any
function M.debug(message, ...)
	if not require("balls.config").debug then
		return
	end

	vim.notify("[balls DEBUG] " .. message:format(...), vim.log.levels.DEBUG)
end

---@param message string
---@param ... any
function M.info(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.INFO)
end

---@param message string
---@param ... any
function M.warn(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.WARN)
end

---@param message string
---@param ... any
function M.error(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.ERROR)
end

---@class balls.ShellOptions : SystemOpts
---
---@field on_exit? fun(result: vim.SystemCompleted)

---@param command string[]
---@param options? balls.ShellOptions
---
---@return vim.SystemObj
function M.shell(command, options)
	options = vim.F.if_nil(options, {}) --[[@as balls.ShellOptions]]

	local on_exit = nil

	if options.on_exit then
		on_exit = vim.schedule_wrap(options.on_exit)
		options.on_exit = nil
	end

	return vim.system(command, options, on_exit)
end

---@param path string
---
---@return boolean exists
function M.exists(path)
	---@diagnostic disable-next-line
	return vim.uv.fs_stat(path) ~= nil
end

---@param dir string
local function remove_parent_if_empty(dir)
	local parent = vim.fs.dirname(dir)

	if parent and vim.fs.dir(parent)() == nil then
		vim.fn.delete(parent, "d")
	end
end

---@param path string
function M.rm(path)
	vim.fn.delete(path, "rf")
	remove_parent_if_empty(path)
end

---@param from string
---@param to string
function M.mv(from, to)
	local to_parent = vim.fs.dirname(to)

	if to_parent and not M.exists(to_parent) then
		vim.fn.mkdir(to_parent, "p")
	end

	if vim.fn.rename(from, to) ~= 0 then
		M.error("Failed to move file from `%s` to `%s`.", from, to)
		return
	end

	remove_parent_if_empty(from)
end

---@param git_dir string
---@param plugin_name string
---
---@return boolean
function M.is_detached(git_dir, plugin_name)
	local result = M.shell({ "git", "branch" }, { cwd = git_dir }):wait()

	if result.code ~= 0 then
		M.error("Failed to list branches for `%s`.", plugin_name)
		return true
	end

	local current_branch = vim.split(vim.trim(result.stdout), "\n")[1]

	return current_branch:match("detached at") ~= nil
end

---@param git_dir string
---@param plugin_name string
---
---@return string? branch
function M.current_revision(git_dir, plugin_name)
	local result = M.shell({ "git", "rev-parse", "HEAD" }, { cwd = git_dir }):wait()

	if result.code ~= 0 then
		M.error("Failed to get current revision for `%s`: %s", plugin_name, vim.trim(result.stderr))
		return nil
	end

	return vim.trim(result.stdout)
end

---@param git_dir string
---@param plugin_name string
---
---@return string branch
function M.default_branch(git_dir, plugin_name)
	local result = M.shell({
		"git",
		"symbolic-ref",
		"refs/remotes/origin/HEAD",
		"--short"
	}, { cwd = git_dir }):wait()

	if result.code ~= 0 then
		M.error(
			"Failed to get default branch for `%s`, assuming 'master': %s",
			plugin_name,
			vim.trim(result.stderr)
		)

		return "master"
	end

	return vim.trim(result.stdout):sub(8)
end

return M
