--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@type BallsConfig
---
---@diagnostic disable-next-line missing-fields
local config = {
	debug = false,
}

config.get = function(key)
	return config[key]
end

config.set = function(key, value)
	config[key] = value
	require("balls.log").trace("Set config key `%s` to value `%s`.", vim.inspect(key), vim.inspect(value))
end

return config
