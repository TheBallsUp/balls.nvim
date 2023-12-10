# balls.nvim

`balls.nvim` is a plugin manager focused on simplicity. This means that it's mostly just a git
wrapper with some quality of life features around neovim's builtin `:help packages`. You should be
familiar with them to understand how plugins are installed and how they integrate with the rest of
your config.

> [!IMPORTANT]
> `balls.nvim` requires neovim 0.10!

# Quickstart

To install `balls.nvim`, put the following code somewhere into your config (e.g. `init.lua`):

```lua
local config_path = vim.fn.stdpath("config")
local balls_path = vim.fs.joinpath(config_path, "pack", "balls", "start", "balls.nvim")

if vim.uv.fs_stat(balls_path) == nil then
  local command = {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/TheBallsUp/balls.nvim",
    balls_path,
  }

  vim.system(command, {}, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      error("Failed to install balls.nvim: " .. result.stderr)
    end

    vim.notify("Installed balls.nvim!")
    vim.cmd.packloadall()
    vim.cmd.helptags(vim.fs.joinpath(balls_path, "doc"))
  end))
end
```

# Example plugin installation: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Put the following code somewhere in your config (e.g. `after/plugin/telescope.lua`):

```lua
local Balls = require("balls")

Balls:register("https://github.com/nvim-telescope/telescope.nvim")

local telescope_installed, telescope = pcall(require, "telescope")

if not telescope_installed then
  return
end

telescope.setup({})
```

Then run `:BallsInstall` and restart neovim.

# Documentation

For examples and technical documentation about commands and the Lua API see `:help balls`.

# Making [lua_ls](https://github.com/LuaLS/lua-language-server) aware of `balls.nvim` types

If you use the `lua_ls` LSP server you might notice that you don't get type hints or completion for
`balls.nvim` functions. In that case you need to make the language server aware of the plugin's
files, like so:

```lua
local packpath = require("balls").config.packpath
local balls_path = vim.fs.joinpath(packpath, "start", "balls.nvim", "lua")

-- If you use nvim-lspconfig
require("lspconfig").lua_ls.setup({
  -- ...
  settings = {
    Lua = {
      workspace = {
        library = { balls_path },
      },
    },
  },
})

-- If you use `vim.lsp.start()`
vim.lsp.start({
  -- ...
  settings = {
    Lua = {
      workspace = {
        library = { balls_path },
      },
    },
  },
})
```
