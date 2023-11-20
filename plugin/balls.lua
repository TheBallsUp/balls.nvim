--- @class balls.Plugin
---
--- @field url string A Git URL.
--- @field rev? string A Git revision.
--- @field name string A custom name.
---
--- @field lazy boolean Do not load this plugin automatically.
---
--- @field on_sync? fun(self: balls.Plugin) Callback function to run anytime the plugin installs / updates.
---
--- @field path fun(self: balls.Plugin, lazy?: boolean): string Returns the local installation path of this plugin.
--- @field installed fun(self: balls.Plugin): boolean Returns whether the plugin is installed.
--- @field install fun(self: balls.Plugin) Installs this plugin locally.
--- @field update fun(self: balls.Plugin) Updates this plugin.
--- @field sync fun(self: balls.Plugin) Makes sure the plugin is installed as specified by the spec.
--- @field checkout fun(self: balls.Plugin, rev?: string) Checks out a specific git revision for this plugin.
--- @field helptags fun(self: balls.Plugin) Generates helptags for this plugin.
--- @field lazy_load fun(self: balls.Plugin, events: string | string[], opts: balls.EventOpts) Sets up an autocmd to load this plugin on specific events.

--- @class balls.PluginSpec
---
--- @field url string A Git URL.
--- @field rev? string A Git revision.
--- @field name? string A custom name.
---
--- @field lazy? boolean Do not load this plugin automatically.
---
--- @field on_sync? fun(plugin: balls.Plugin) Callback function to run anytime the plugin installs / updates.

require("balls.plugins")

local command = function(name, callback, opts)
	vim.api.nvim_create_user_command(name, callback, vim.F.if_nil(opts, {}))
end

command("BallsList", function()
	require("balls").list()
end, {
	desc = "Opens a floating window listing all registered plugins.",
})

command("BallsInstall", function()
	require("balls").install()
end, {
	desc = "Installs any registered plugins that aren't installed yet.",
})

command("BallsUpdate", function()
	require("balls").update()
end, {
	desc = "Updates any registered and installed plugins.",
})

command("BallsSync", function()
	require("balls").sync()
end, {
	desc = "Syncs registered plugins with what's actually installed locally.",
})

command("BallsClean", function()
	require("balls").clean()
end, {
	desc = "Cleans up any still installed but not registered plugins.",
})
