--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

--- Returns the path to balls.nvim's |packpath|.
---
---@param opts { opt: boolean }
---
---@return string path
local function packpath(opts)
	local path = vim.fn.stdpath("config") .. "/pack/balls/"

	if opts.opt then
		return path .. "opt/"
	else
		return path .. "start/"
	end
end

--- Checks if the given path exists on the filesystem.
---
---@param path string
---
---@return boolean
local function exists(path)
	return vim.uv.fs_stat(path)
end

return {
	packpath = packpath,
	exists = exists,
}
