--- Will open a floting window listing all registered plugins.
---
---@private
local function list_plugins()
	local lines = {}

	for name, plugin in pairs(BALLS_PLUGINS) do
		local version = ""

		if plugin.rev ~= nil then
			version = string.format(" (%s)", plugin.rev)
		end

		local lazy = ""

		if plugin.lazy then
			lazy = " (lazy)"
		end

		table.insert(lines, string.format("* %s%s%s", name, version, lazy))
	end

	local buffer = vim.api.nvim_create_buf(false, true)

	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buffer })
	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

	local width = math.floor(vim.o.columns / 3)
	local height = vim.tbl_count(lines)

	local window = vim.api.nvim_open_win(buffer, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 3),
		col = math.floor((vim.o.columns - width) / 2),
		focusable = true,
		zindex = 300,
		style = "minimal",
		border = "single",
		title = string.format("[ Total Plugins: %d ]", vim.tbl_count(BALLS_PLUGINS)),
		title_pos = "center",
	})

	local close = function()
		pcall(vim.api.nvim_win_close, window, true)
	end

	vim.keymap.set("n", "q", close, { buffer = buffer })
	vim.keymap.set("n", "<Esc>", close, { buffer = buffer })
end

return {
	list_plugins = list_plugins,
}
