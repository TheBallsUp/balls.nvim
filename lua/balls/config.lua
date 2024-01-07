---@class balls.ConfigOverride
---
---@field debug? boolean
---@field packpath? string
---@field lazy_by_default? boolean
---@field auto_install? boolean
---@field auto_update? boolean
---@field url? string
---@field spec? balls.PluginSpec

---@class balls.Config
---
---@field debug boolean
---@field packpath string
---@field lazy_by_default boolean
---@field auto_install boolean
---@field auto_update boolean
---@field url string
---@field spec? balls.PluginSpec
local Config = {
	debug = false,
	packpath = require("balls.util").config_path("pack", "balls"),
	lazy_by_default = false,
	auto_install = false,
	auto_update = false,
	url = "https://github.com/TheBallsUp/balls.nvim",
}

return Config
