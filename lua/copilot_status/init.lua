local Status = require "copilot_status.status"
local config = require "copilot_status.config"

local M = {
	__has_setup_run = false,
}

---@type table<number, copilot_status.status>
local buf_status_map = {}

local function on_buf_enter(event)
	local cp_util = require "copilot.util"
	local bufnr = event.buf
	if buf_status_map[bufnr] then return end
	local client = cp_util.get_copilot_client()
	local status = Status:new(client)
	buf_status_map[bufnr] = status
end

local function on_buf_leave(event)
	local bufnr = event.buf
	buf_status_map[bufnr] = nil
end

---@parm cfg copilot_status.config|nil
function M.setup(cfg)
	local cp_ok = pcall(require, "copilot")
	if not cp_ok then
		vim.notify("copilot.lua not found while running setup", vim.log.levels.ERROR)
		return
	end

	config.setup(cfg)

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = on_buf_enter,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		callback = on_buf_leave,
	})

	M.__has_setup_run = true
end

function M.status()
	if not M.__has_setup_run then M.setup() end
	local bufnr = vim.api.nvim_get_current_buf()
	local status = buf_status_map[bufnr]
	if not status then return { status = "offline", message = nil } end
	return { status = status.status, message = status.message }
end

return M
