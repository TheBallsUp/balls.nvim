local M = {}

--- @param message string
--- @param ... any
function M.debug(message, ...)
	if not require("balls.config").debug then
		return
	end

	vim.notify("[balls DEBUG] " .. message:format(...), vim.log.levels.DEBUG)
end

--- @param message string
--- @param ... any
function M.info(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.INFO)
end

--- @param message string
--- @param ... any
function M.error(message, ...)
	vim.notify("[balls] " .. message:format(...), vim.log.levels.ERROR)
end

return M
