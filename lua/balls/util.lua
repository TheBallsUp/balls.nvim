local M = {}

--- @param message string
--- @param ... any
function M.notify(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.INFO)
end

--- @param message string
--- @param ... any
function M.notify_debug(message, ...)
	if require("balls").config.debug then
		vim.notify("[balls DEBUG] " .. message:format(...), vim.log.levels.DEBUG)
	end
end

--- @param message string
--- @param ... any
function M.notify_error(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.ERROR)
end

--- @param cmd string[]
--- @param opts table
function M.system(cmd, opts)
	local on_exit = nil

	if opts.on_exit ~= nil then
		on_exit = vim.schedule_wrap(opts.on_exit)
		opts.on_exit = nil
	end

	if on_exit == nil then
		return vim.system(cmd, opts):wait()
	end

	return vim.system(cmd, opts, on_exit)
end

--- @param path string
---
--- @return boolean exists
function M.exists(path)
	--- @diagnostic disable-next-line
	return vim.uv.fs_stat(path) ~= nil
end

--- @param ... string extra path segments
---
--- @return string config_path
function M.config_path(...)
	--- @diagnostic disable-next-line
	return vim.fs.joinpath(vim.fn.stdpath("config"), ...)
end

--- @param repo_dir string
---
--- @return string branch
function M.default_branch(repo_dir)
	local result = M.system({
		"git",
		"symbolic-ref",
		"refs/remotes/origin/HEAD",
		"--short"
	}, {
		cwd = repo_dir,
	})

	if result.code ~= 0 then
		M.notify_error("Failed to get default branch for `%s`: %s", repo_dir, result.stderr)
		return "master"
	end

	return vim.trim(result.stdout):sub(8)
end

return M
