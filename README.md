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
-- Replace `alphakeks` with your own name here!
--
-- Alternatively replace it will `balls` and make sure to register balls.nvim itself as a plugin
-- somewhere in your config. If you don't, it will uninstall itself!
local balls_path = vim.fn.stdpath("config") .. "/pack/alphakeks/start/balls.nvim"

if not vim.uv.fs_stat(balls_path) then
  local command = { "git", "clone", "https://github.com/AlphaKeks/balls.nvim", balls_path }
  local opts = { text = true }

  local result = vim.system(command, opts):wait()

  if result.code ~= 0 then
    print("failed to install balls.nvim!")
    return
  end

  print("installed balls.nvim!")
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
  url = "<git url>",

  -- You can specify a specific git branch.
  branch = nil,

  -- You can specify a specific git tag.
  tag = nil,

  -- You can specify a specific git commit hash.
  commit = nil,

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

## Lazy Loading

You can lazy load a plugin by setting `lazy = true` when registering it. This will cause it to be
installed into `pack/balls/opt/`, which means you will have to use the `:packadd` command to load
it. For example, to load a plugin on a specific event, you could write code like this:

```lua
require("balls").register({
  url = "https://github.com/hrsh7th/nvim-cmp.git",
  lazy = true,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  desc = "Loads nvim-cmp when entering insert mode",
  callback = function()
    vim.cmd.packadd("nvim-cmp")

    require("cmp").setup({
      -- your cmp setup here
    })
  end,
})
```

## API

See `:help balls-api`.
