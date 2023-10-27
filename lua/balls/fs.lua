--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

--- Checks if the given `path` exists on the filesytem.
---
---@private
---
---@param path string
---
---@return boolean exists
local function exists(path)
	if vim.version().minor == 10 then
		return vim.uv.fs_stat(path)
	else
		require("balls.log").error("Invalid neovim version! You need at least version 0.9 for this plugin to work.")
		return false
	end
end

return {
	exists = exists,
}
