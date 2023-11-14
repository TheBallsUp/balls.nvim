local M = {}

--- @class balls.SystemOpts : SystemOpts
---
--- @field on_exit? fun(result: vim.SystemCompleted)

--- @param command string[]
--- @param opts? balls.SystemOpts
---
--- @return vim.SystemCompleted | vim.SystemObj
function M.system(command, opts)
	opts = vim.F.if_nil(opts, {})
	opts.text = vim.F.if_nil(opts.text, true)

	if opts.on_exit == nil then
		return vim.system(command, opts):wait()
	end

	return vim.system(command, opts, vim.schedule_wrap(opts.on_exit))
end

return M
