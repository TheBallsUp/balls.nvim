--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

---@class BallsPluginSpec
---
---@field url string Git URL to clone the plugin
---@field branch? string Git branch
---@field tag? string Git tag
---@field commit? string Git commit hash
---
---@field name? string Custom name
---@field lazy? boolean Do not load the plugin by default
---@field on_sync? fun(plugin: BallsPlugin) Custom hook to run after the plugin is synced

---@class BallsPlugin : BallsPluginSpec
---
---@field name string
---@field lazy boolean
---@field path string

---@class BallsConfig
---
---@field debug boolean enable debug logs
---
---@field set fun(key: string, value: any)
---@field get fun(key: string): any
