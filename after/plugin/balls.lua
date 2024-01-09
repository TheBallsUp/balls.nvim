local config = require("balls.config")

local plugin = require("balls"):register(config.url, config.spec)
local doc_path = vim.fs.joinpath(plugin:path(), "doc")
vim.cmd.helptags(doc_path)
