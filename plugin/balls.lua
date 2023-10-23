--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@type BallsPlugin[]
BALLS_PLUGINS = {}

vim.api.nvim_create_user_command("BallsInstall", function()
	require("balls").install_all()
end, {
	desc = "Installs all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsUpdate", function()
	require("balls").update_all()
end, {
	desc = "Updates all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsSync", function()
	require("balls").sync_all()
end, {
	desc = "Installs and updates all plugins registered by balls.nvim",
})

vim.api.nvim_create_user_command("BallsList", function()
	require("balls.ui").display_list()
end, {
	desc = "Installs and updates all plugins registered by balls.nvim",
})
