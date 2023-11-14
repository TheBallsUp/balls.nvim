# balls.nvim

> This is very much WIP and probably has bugs :D

An idiomatic plugin manager leveraging neovim's builtin package system.

This plugin manager focuses on simplicity and embracing neovim's builtin features as much as
possible. Plugins are git repositories stored as part of your configuration. If you keep your neovim
configuration in a git repository or as part of your dotfiles I recommend either `.gitignore`ing
your `pack/balls/` directory or treating your plugins as submodules and only using balls.nvim for
updating them.

## Quickstart

> ⚠️ neovim 0.10 is required ⚠️

To install balls.nvim put the following code into your `init.lua`:

```lua
-- You can replace `balls` here with whatever you want, but if you want balls.nvim to keep itself up
-- to date it must either be `balls` or match the `packpath` parameter you pass to `balls.setup()`.
--
-- See `:help balls-api`.
local balls_path = vim.fs.joinpath(vim.fn.stdpath("config"), "/pack/balls/start/balls.nvim")

if not vim.uv.fs_stat(balls_path) then
  local command = { "git", "clone", "https://github.com/TheBallsUp/balls.nvim", balls_path }
  local opts = { text = true }
  local result = vim.system(command, opts):wait()

  if result.code ~= 0 then
    error("Failed to install balls.nvim! " .. vim.inspect(result))
  end

  vim.cmd.packloadall()
  vim.notify("Installed balls.nvim! Run `:BallsIntall` to install registered plugins.")
end
```

## Installing plugins

You can install plugins by adding code snippets like this anywhere in your config:

```lua
require("balls").register({
  -- Some URL pointing to a git repository.
  --
  -- This could be HTTPS or ssh and will shell out to git
  url = "<Git URL>",

  -- You can specify a specific git revision (commit).
  rev = nil,

  -- You can specify a custom name.
  --
  -- This is useful for plugins like catppuccin which have "nvim" as their repo name
  name = nil,

  -- Do not immediately load the plugin.
  --
  -- If this is set to `true` you will have to load the plugin yourself using the |packadd| command.
  lazy = nil,

  -- A custom callback.
  --
  -- This will be called everytime after plugin gets synced (installed or updated).
  on_sync = nil,
})
```

## Making type definitions available with [`lua_ls`](https://github.com/LuaLS/lua-language-server)

If you use LSP, you can make `lua_ls` recognize type definitions from balls.nvim by setting it up
like so:

```lua
local packpath = require("balls.config").packpath

vim.lsp.start({
 -- ... other options
  settings = {
    Lua = {
      workspace = {
        library = {
          vim.fs.joinpath(packpath, "start", "balls.nvim"),
        },
      },
    },
  },
})
```

This will make sure that it scans the directory, which means you'll get LSP type hints and
completion when using balls' Lua API (e.g. `balls.register()`).

## API

See `:help balls-api`.

## Lazy Loading

See `:help balls-lazy-loading`.
