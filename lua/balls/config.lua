--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@class balls.Config
---
---@field packpath string? Custom path for storing plugins.
---@field debug boolean? Emit debug logs.

local config = {
	packpath = vim.fn.stdpath("config") .. "/pack/balls",
	debug = false,
}

---@param key string
---
---@return any value
function config:get(key)
	return self[key]
end

---@param key string
---@param value any
function config:set(key, value)
	self[key] = value
end

return config
