--[[ Copyright (C) AlphaKeks <alphakeks@dawn.sh>                                                  ]]
--[[                                                                                              ]]
--[[ This is free software: you may redistribute it and / or modify it under the terms of the GNU ]]
--[[ General Public License version 3.                                                            ]]
--[[ For a copy of the full license see the LICENSE file at the root of this repository or visit  ]]
--[[ <https://www.gnu.org/licenses/>.                                                             ]]

local log = require("balls.log")

--- Runs a git command with the given `args` and executes the given `callback` when the command
--- is done.
---
---@param args string[]
---@param callback? fun(result: vim.SystemCompleted)
---@param opts? { cwd?: string }
local function git(args, callback, opts)
	args = vim.list_extend({ "git" }, args)
	opts = vim.F.if_nil(opts, {})

	local result = vim.system(args, { text = true, cwd = opts.cwd }):wait()

	if result.code ~= 0 then
		log.error("Failed to run git command: %s", vim.inspect(result))
		return
	end

	log.debug("Executed `%s`", table.concat(args, " "))

	if callback ~= nil then
		callback(result)
		log.debug("Ran post clone callback")
	end
end

--- Clones a git repository from the given `url`.
---
---@param url string Git URL
---@param path string Destination path
---@param options? { branch?: string, tag?: string, commit?: string }
local function clone(url, path, options)
	options = vim.F.if_nil(options, {})

	local post_clone = {}

	if options.branch ~= nil then
		table.insert(post_clone, { "checkout", options.branch })
	end

	if options.tag ~= nil then
		table.insert(post_clone, { "checkout", options.tag })
	end

	if options.commit ~= nil then
		table.insert(post_clone, { "checkout", options.commit })
	end

	git({ "clone", url, path }, function()
		log.debug("Cloned %s", url)

		for _, command in ipairs(post_clone) do
			git(command, nil, { cwd = path })
		end
	end)
end

--- Pulls the latest commit in the Git repository located at `path`.
---
---@param path string
local function pull(path)
	git({ "pull" }, nil, { cwd = path })
end

return {
	clone = clone,
	pull = pull,
}
