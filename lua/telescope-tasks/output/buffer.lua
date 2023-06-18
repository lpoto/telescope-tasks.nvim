local util = require("telescope-tasks.util")
local enum = require("telescope-tasks.enum")

local buffer = {}

local handle_buffer

---@param buf? number: An existing buffer, if it is valid
---it will be used instead.
---@return number: buffer number, -1 when invalid
function buffer.create(buf)
  if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    local ok
    ok, buf = pcall(vim.api.nvim_create_buf, false, true)
    if ok == false then
      util.warn(buf)
      return -1
    end
  end
  local ok, err = pcall(handle_buffer, buf)
  if ok == false and type(err) == "string" then
    util.warn(err)
  end
  return buf
end

handle_buffer = function(buf)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "modified", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "filetype", enum.OUTPUT_BUFFER_FILETYPE)

  vim.api.nvim_clear_autocmds({
    event = { "TermClose", "TermEnter" },
    buffer = buf,
    group = enum.TASKS_AUGROUP,
  })

  --NOTE: set the autocmd for the terminal buffer, so that
  --when it finishes, we cannot enter the insert mode.
  --(when we enter insert mode in the closed terminal, it is deleted)
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    group = enum.TASKS_AUGROUP,
    callback = function()
      vim.cmd("stopinsert")
      vim.api.nvim_create_autocmd("TermEnter", {
        group = enum.TASKS_AUGROUP,
        callback = function()
          vim.cmd("stopinsert")
        end,
        buffer = buf,
      })
    end,
    nested = true,
    once = true,
  })
end

return buffer
