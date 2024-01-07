# balls.nvim

A minimalistic plugin manager.

> [!IMPORTANT]
> neovim version 0.10 or higher is required!

> [!IMPORTANT]
> read `:help balls`

# Quickstart

To install balls.nvim, put the following code into your `init.lua`:

```lua
local config_path = vim.fn.stdpath("config")
local balls_path = vim.fs.joinpath(config_path, "pack", "balls", "start", "balls.nvim")

if not vim.uv.fs_stat(balls_path) then
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
      error("Failed to install balls.nvim: " .. vim.trim(result.stderr))
    end

    vim.notify("Installed balls.nvim!")
  end))
end

local ok, Balls = pcall(require, "balls")

if not ok then
  return
end

Balls:setup({
  -- If you want plugins to be installed automatically
  auto_install = true,
})
```

# Example - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Navigate into your config directory and create `after/plugin/telescope.lua`,
then put the following code into it:

```lua
local Balls = require("balls")

local plenary = Balls:register("https://github.com/nvim-lua/plenary.nvim")

Balls:register("https://github.com/nvim-telescope/telescope.nvim")

local ok, telescope = pcall(require, "telescope")

if not (ok and plenary:installed()) then
  return
end

telescope.setup({})

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<Leader>ff", builtin.find_files)
vim.keymap.set("n", "<Leader>fl", builtin.live_grep)
vim.keymap.set("n", "<Leader>fb", builtin.buffers)
```

Now, either `:source` the file or restart neovim. Then run `:BallsInstall`. Then
restart neovim, and telescope should now work. You can double check by running
`:BallsList`.

# Integrating [lua_ls](https://github.com/LuaLS/lua-language-server)

If you're using lua_ls, you might have noticed that you don't get completion for
any functions coming from plugins, such as balls.nvim. This is because it
doesn't scan those directories automatically, but you can use the following
snippet to force it:

```lua
local balls = vim.iter(require("balls").plugin_list):find(function(plugin)
  return plugin.name == "balls.nvim"
end)

require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      workspace = {
        library = {
          -- neovim's standard library
          vim.env.VIMRUNTIME,

          -- balls.nvim
          vim.fs.joinpath(balls:path(), "lua"),
        },
      },
    },
  },
})
```

You can do the same for all of your plugins, but keep in mind that the more
plugins you have, the slower lua_ls will get.

```lua
local library = vim.tbl_map(function(plugin)
  return vim.fs.joinpath(plugin:path(), "lua")
end, require("balls").plugin_list)

-- make sure to include neovim's standard library as well
table.insert(library, vim.env.VIMRUNTIME)

require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      workspace = {
        library = library,
      },
    },
  },
})
```
