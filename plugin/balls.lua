local function command(name, callback)
	vim.api.nvim_create_user_command(name, callback, {})
end

command("BallsList", function()
	for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buffer].filetype == "balls" then
			vim.api.nvim_buf_delete(buffer, {})
		end
	end

	local buffer = vim.api.nvim_create_buf(false, true)
	local plugins = require("balls").plugins
	local lines = {
		"Total Plugins: " .. tostring(vim.tbl_count(plugins)),
	}

	table.insert(lines, string.rep("-", #lines[1]))

	for _, plugin in ipairs(plugins) do
		table.insert(lines, "* " .. plugin.name)
	end

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
	vim.bo[buffer].modifiable = false
	vim.bo[buffer].filetype = "balls"
	vim.cmd.vsplit()
	vim.api.nvim_set_current_buf(buffer)
end)

command("BallsInstall", function()
	for _, plugin in ipairs(require("balls").plugins) do
		plugin:install()
	end
end)

command("BallsUpdate", function()
	for _, plugin in ipairs(require("balls").plugins) do
		plugin:update()
	end
end)

command("BallsSync", function()
	for _, plugin in ipairs(require("balls").plugins) do
		plugin:sync()
	end

	vim.cmd.BallsClean()
end)

command("BallsClean", function()
	local U = require("balls.util")
	local packpath = require("balls").config.packpath
	local start_path = vim.fs.joinpath(packpath, "start")
	local opt_path = vim.fs.joinpath(packpath, "opt")

	local clean = function(path, dir)
		path = vim.fs.joinpath(path, dir)

		local should_remove = true

		for _, plugin in ipairs(require("balls").plugins) do
			if plugin:path() == path then
				should_remove = false
				break
			end
		end

		if should_remove then
			U.system({ "rm", "-rf", path }, {
				on_exit = function(result)
					if result.code ~= 0 then
						U.notify_error("Failed to remove `%s`: %s", dir, result.stderr)
						return
					end

					U.notify("Removed `%s`!", dir)
				end,
			})
		end
	end

	for dir in vim.fs.dir(start_path) do
		clean(start_path, dir)
	end

	for dir in vim.fs.dir(opt_path) do
		clean(opt_path, dir)
	end
end)
