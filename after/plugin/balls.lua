require("balls").register(vim.tbl_extend("force", {
	url = "https://github.com/TheBallsUp/balls.nvim",
	lazy = false,
	on_sync = function(plugin)
		plugin:helptags()
	end,
}, vim.F.if_nil(require("balls.config").balls_spec, {})))
