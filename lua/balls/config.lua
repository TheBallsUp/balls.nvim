---@class balls.Config
---
---@field packpath string? Custom path for storing plugins.
---@field debug boolean? Emit debug logs.

local config = {
	packpath = vim.fs.joinpath(vim.fn.stdpath("config"), "pack", "balls"),
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
