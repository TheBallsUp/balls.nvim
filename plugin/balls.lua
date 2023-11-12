--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

if BALLS_PLUGINS == nil then
	---@type balls.Plugin[]
	BALLS_PLUGINS = {}
end

vim.api.nvim_create_user_command("BallsList", function()
	require("balls").list()
end, { desc = "Lists all plugins installed by balls.nvim" })

vim.api.nvim_create_user_command("BallsInstall", function()
	require("balls").install()
end, { desc = "Makes sure all registered plugins are installed" })

vim.api.nvim_create_user_command("BallsUpdate", function()
	require("balls").update()
end, { desc = "Makes sure all registered plugins are installed" })

vim.api.nvim_create_user_command("BallsSync", function()
	require("balls").sync()
end, { desc = "Makes sure all registered plugins are installed and up to date" })

require("balls").register({
	url = "https://github.com/AlphaKeks/balls.nvim",
})

vim.cmd.helptags("ALL")
