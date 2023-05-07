local enum = require "telescope._extensions.tasks.enum"
local util = require "telescope._extensions.tasks.util"
local executor = require "telescope._extensions.tasks.executor"
local buffer = require "telescope._extensions.tasks.output.buffer"
local window = require "telescope._extensions.tasks.output.window"
local telescope_actions = require "telescope.actions"

local output = {}

local open_last_task_output

---Open the output for the provided task.
---Warn when the provided task has no output.
---If a window with the task's output buffer is already
---opened, navigate to it,  else open a new window, based
---on the setup's output_window parameter.
---@param task Task: The task to open the output for
---@param before_opening function?: Function to be called before
---opening the output. Is not called if the task has no output.
function output.open(task, before_opening)
  if task == nil then
    return
  end
  -- NOTE: make sure the provided task is running.
  local buf = executor.get_task_output_buf(task.name)
  if buf == nil or vim.fn.bufexists(buf) ~= 1 then
    util.warn("Task '" .. task.name .. "' has no output!")
    return
  end
  if before_opening ~= nil then
    before_opening()
  end

  output.close_output_windows()

  open_last_task_output(task.name, buf)
end

---Toggle the window of the last opened output.
---Warns when there wasn't any previous outputs opened,
---or the previous output buffer is no longer available.
function output.toggle_last()
  -- Get the buffer from the provided function
  if output.close_output_windows() then
    return
  end

  local buf, name = executor.get_last_task_output_buf()

  if not buf then
    util.warn "There is no available output"
    return
  end

  if
      vim.api.nvim_buf_get_option(0, "filetype")
      == enum.TELESCOPE_PROMPT_FILETYPE
  then
    -- NOTE: close telescope popup if open
    local prompt_bufnr = vim.api.nvim_get_current_buf()
    pcall(telescope_actions.close, prompt_bufnr)
  end

  open_last_task_output(name, buf)
end

function output.close_output_windows()
  local win_handles = vim.tbl_filter(function(win_handle)
    local buf = vim.api.nvim_win_get_buf(win_handle)
    return vim.api.nvim_buf_get_option(buf, "filetype")
        == enum.OUTPUT_BUFFER_FILETYPE
  end, vim.api.nvim_list_wins())
  local ok = false
  for _, winid in ipairs(win_handles) do
    vim.api.nvim_win_close(winid, false)
    ok = true
  end
  return ok
end

---Create an output buffer and set up the proper options. If a valid
---buf number is provided, that buffer will be used instead.
---@param buf number?: An existing buffer.
---@return number: The buffer number, -1 when invalid.
function output.create_buffer(buf)
  return buffer.create(buf)
end

open_last_task_output = function(name, buf)
  -- NOTE: make sure a valid buffer was returned
  if type(buf) ~= "number" or vim.api.nvim_buf_is_valid(buf) ~= true then
    return
  end

  executor.mark_task_as_latest(name)

  local existing_winid = vim.fn.bufwinid(buf)
  if vim.api.nvim_win_is_valid(existing_winid) then
    -- NOTE: a valid window already exists for the provided
    -- buffer so don't open another one.
    -- Rather just jump to it.
    vim.fn.win_gotoid(existing_winid)
    return
  end

  local ow = window.create(buf, name)
  if not vim.api.nvim_win_is_valid(ow) then
    return
  end
end

return output
