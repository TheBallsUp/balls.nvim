vim.api.nvim_create_user_command("BallsList", function()
	local buffer = vim.api.nvim_create_buf(false, true)
	local list = {}

	for plugin in require("balls"):plugins() do
		table.insert(list, "* " .. plugin.name)

		if not plugin:installed() then
			list[#list] = list[#list] .. " (not installed)"
		end

		if plugin.lazy ~= require("balls.config").lazy_by_default then
			table.insert(list, "  • lazy-loaded")
		end

		if plugin.rev then
			table.insert(list, "  • revision: " .. plugin.rev)
		end
	end

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, list)
	vim.bo[buffer].modifiable = false

	vim.keymap.set("n", "q", function()
		vim.api.nvim_buf_delete(buffer, { force = true })
	end, { buffer = buffer })

	vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.5),
		height = math.floor(vim.o.lines * 0.8),
		row = math.floor(vim.o.lines * 0.1),
		col = math.floor(vim.o.columns * 0.25),
		focusable = true,
		zindex = 300,
		style = "minimal",
		border = "single",
		title = string.format("[ %d Plugins ]", #list),
		title_pos = "center",
	})
end, { desc = "Displays all currently installed plugins." })

vim.api.nvim_create_user_command("BallsInstall", function()
	require("balls"):install()
end, { desc = "Installs any missing plugins." })

vim.api.nvim_create_user_command("BallsUpdate", function(cmd)
	if cmd.args == "" then
		require("balls"):update()
		return
	end

	local plugin = vim.iter(require("balls").plugin_list):find(function(plugin)
		return plugin.name == cmd.args
	end)

	if not plugin then
		error("Invalid plugin `" .. cmd.args .. "`.")
	end

	plugin:update()
end, {
	desc = "Updates any installed plugins.",
	nargs = "?",
	complete = function(input)
		return vim.tbl_map(function(plugin)
			return plugin.name
		end, vim.tbl_filter(function(plugin)
			if input == "" then
				return true
			else
				return vim.startswith(plugin.name, input)
			end
		end, require("balls").plugin_list))
	end,
})

vim.api.nvim_create_user_command("BallsClean", function()
	require("balls"):clean()
end, { desc = "Removes any unused plugins." })
