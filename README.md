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
local balls_path = vim.fn.stdpath("config") .. "/pack/balls/start/balls.nvim"

if not vim.uv.fs_stat(balls_path) then
  local command = { "git", "clone", "https://github.com/AlphaKeks/balls.nvim", balls_path }
  local opts = { text = true }
  local result = vim.system(command, opts):wait()

  if result.code ~= 0 then
    vim.print("Failed to install balls.nvim! " .. vim.inspect(result))
    return
  end

  vim.print("Installed balls.nvim! Run `:BallsInstall` to install your plugins.")
  vim.cmd.packadd("balls.nvim")
  vim.cmd.helptags("ALL")
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

## API

See `:help balls-api`.

## Lazy Loading

See `:help balls-lazy-loading`.
