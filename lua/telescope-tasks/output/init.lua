local buffer = require("telescope-tasks.output.buffer")
local enum = require("telescope-tasks.enum")
local executor = require("telescope-tasks.executor")
local telescope_actions = require("telescope.actions")
local util = require("telescope-tasks.util")
local window = require("telescope-tasks.output.window")

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
  if task == nil then return end
  -- NOTE: make sure the provided task is running.
  local buf = executor.get_task_output_buf(task.name)
  if buf == nil or vim.fn.bufexists(buf) ~= 1 then
    util.warn("Task '" .. task.name .. "' has no output!")
    return
  end
  if before_opening ~= nil then before_opening() end

  output.close_output_windows()

  open_last_task_output(task.name, task.cmd, buf)
end

local last_winid = nil

---Toggle the window of the last opened output.
---Warns when there wasn't any previous outputs opened,
---or the previous output buffer is no longer available.
function output.toggle_last()
  local buf, name, cmd = executor.get_last_task_output_buf()

  if not buf then
    util.warn("There is no available output")
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

  -- Get the buffer from the provided function
  if output.close_output_windows() then
    if last_winid ~= nil and vim.api.nvim_win_is_valid(last_winid) then
      vim.fn.win_gotoid(last_winid)
    end
    return
  end

  open_last_task_output(name, cmd, buf)
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
function output.create_buffer(buf) return buffer.create(buf) end

open_last_task_output = function(name, footer, buf)
  -- NOTE: make sure a valid buffer was returned
  if type(buf) ~= "number" or vim.api.nvim_buf_is_valid(buf) ~= true then
    return
  end

  if type(footer) == "table" then
    footer = table.concat(footer, " ")
  elseif type(footer) ~= "string" then
    footer = nil
  end

  last_winid = vim.fn.win_getid()

  executor.mark_task_as_latest(name)

  local existing_winid = vim.fn.bufwinid(buf)
  if vim.api.nvim_win_is_valid(existing_winid) then
    -- NOTE: a valid window already exists for the provided
    -- buffer so don't open another one.
    -- Rather just jump to it.
    vim.fn.win_gotoid(existing_winid)
    return
  end

  local ow = window.create(buf, name, footer)
  if not vim.api.nvim_win_is_valid(ow) then return end
end

return output
