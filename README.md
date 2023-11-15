# balls.nvim

This is a minimal plugin manager for neovim that focuses on simplicity and leveraging builtin
features. It uses neovim's `packages` feature for storing and loading plugins and acts as a thin
wrapper around some git commands.

> [!IMPORTANT]
> `balls.nvim` requires neovim 0.10 to function properly.

# Quickstart

To install `balls.nvim`, put the following code somewhere into your config (e.g. `init.lua`):

```lua
local balls_path = vim.fs.joinpath(vim.fn.stdpath("config"), "pack", "balls", "start", "balls.nvim")

if not vim.uv.fs_stat(balls_path) then
  local command = {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/TheBallsUp/balls.nvim",
    balls_path
  }

  vim.system(command, { text = true }, function(result)
    if result.code ~= 0 then
      vim.notify("Failed to install balls.nvim: " .. result.stderr, vim.log.levels.ERROR)
      return
    end

    vim.notify("Installed balls.nvim!", vim.log.levels.INFO)
    vim.cmd.helptags(vim.fs.joinpath(balls_path, "doc"))
  end)
end
```

# Documentation

For all documentation about commands, Lua functions, type definitions, etc. see `:help balls`.

# Making [lua_ls](https://github.com/LuaLS/lua-language-server) aware of `balls.nvim` types

If you use the `lua_ls` LSP server you might notice that you don't get type hints or completion for
`balls.nvim` functions. In that case you need to make the language server aware of the plugin's
files, like so:

```lua
local balls_dir = vim.fs.joinpath(_G.BALLS_PLUGINS["balls.nvim"]:path(), "lua")

-- If you use nvim-lspconfig
require("lspconfig").lua_ls.setup({
  -- ...
  settings = {
    Lua = {
      workspace = {
        library = { balls_dir },
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
        library = { balls_dir },
      },
    },
  },
})
```
