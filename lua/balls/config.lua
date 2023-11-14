--- @class balls.Config
---
--- @field packpath string Custom path for packages. Defaults to `nvim/pack/balls`.
--- @field always_lazy boolean Lazy load plugins by default.
--- @field debug boolean Enable debug logs.
--- @field balls_spec? balls.PluginSpec Custom spec for balls.nvim itself.

--- @class balls.ConfigOverride
---
--- @field packpath? string Custom path for packages. Defaults to `nvim/pack/balls`.
--- @field always_lazy? boolean Lazy load plugins by default.
--- @field debug? boolean Enable debug logs.
--- @field balls_spec? balls.PluginSpec Custom spec for balls.nvim itself.

--- @type balls.Config
local config = {
	packpath = vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "pack", "balls"),
	always_lazy = false,
	debug = false,
}

return config
