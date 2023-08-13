--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@type BallsPlugin[]
BALLS_PLUGINS = {}

vim.api.nvim_create_user_command("BallsInstall", function()
	for _, plugin in pairs(BALLS_PLUGINS) do
		require("balls").install(plugin)
	end
end, {
	desc = "Installs all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsUpdate", function()
	for _, plugin in pairs(BALLS_PLUGINS) do
		require("balls").update(plugin)
	end
end, {
	desc = "Updates all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsSync", function()
	local foreach = function(path)
		local should_exist = false

		for _, plugin in pairs(BALLS_PLUGINS) do
			if plugin.path == path then
				should_exist = true
				break
			end
		end

		if not should_exist then
			require("balls.log").warn("Removing %s", path)
			vim.system({ "rm", "-rf", path }, { text = true }, vim.schedule_wrap(function(result)
				if result.code ~= 0 then
					require("balls.log").error("Failed to remove `%s`: %s", path, result)
				else
					require("balls.log").info("Removed %s", path)
				end
			end))
		end
	end

	local packpath = require("balls.fs").packpath({ opt = true })

	for path in vim.fs.dir(packpath) do
		foreach(packpath .. path)
	end

	packpath = require("balls.fs").packpath({ opt = false })

	for path in vim.fs.dir(require("balls.fs").packpath({ opt = false })) do
		foreach(packpath .. path)
	end

	for _, plugin in pairs(BALLS_PLUGINS) do
		require("balls").sync(plugin)
	end
end, {
	desc = "Installs and updates all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsList", function()
	local buffer = vim.api.nvim_create_buf(false, true)
	local width = 80
	local plugin_count = vim.tbl_count(BALLS_PLUGINS)
	local window = vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = width,
		height = plugin_count,
		row = math.floor((vim.o.lines - plugin_count) / 3),
		col = math.floor((vim.o.columns - width) / 2),
		zindex = 300,
		style = "minimal",
		border = "single",
		title = string.format("[ Total Plugins: %d ]", plugin_count),
		title_pos = "center",
	})

	local text = {}

	for _, plugin in pairs(BALLS_PLUGINS) do
		local lazy = ""

		if plugin.lazy then
			lazy = "(optional)"
		end

		table.insert(text, string.format("* %s %s", plugin.name, lazy))
	end

	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buffer })
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, text)

	local close = function()
		pcall(vim.api.nvim_win_close, window, true)
	end

	vim.keymap.set("n", "q", close)
	vim.keymap.set("n", "<Esc>", close)
end, {
	desc = "Installs and updates all plugins registered by balls.nvim",
})
