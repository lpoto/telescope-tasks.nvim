local enum = require "telescope._extensions.tasks.enum"
local run_task = require "telescope._extensions.tasks.executor.run_task"
local create = require "telescope._extensions.tasks.window.task_output.create"

local previous_get_buffer = nil

local window = {}

window.opened_win = nil

---Open the output buffer for the provided
---task in the current window.
---
---@param task Task
---@param beforeOpening function?: Before oppening the window
---This is not called if task has no output.
function window.open(task, beforeOpening)
  if task == nil then
    return
  end
  -- NOTE: make sure the provided task is running.
  local buf = run_task.get_buf_num(task.name)
  if buf == nil or vim.fn.bufexists(buf) ~= 1 then
    vim.notify("Task '" .. task.name .. "' has no output!", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return
  end
  if beforeOpening ~= nil then
    beforeOpening()
  end

  window.set_as_previous(task)

  window.__open_last_task_output()
end

---Set the provided task identified b
---task in the current window.
---
---@param task Task
function window.set_as_previous(task)
  if task == nil then
    return
  end
  -- NOTE: make sure the provided task is running.
  local buf = run_task.get_buf_num(task.name)
  if buf == nil or vim.fn.bufexists(buf) ~= 1 then
    return
  end

  previous_get_buffer = function()
    return run_task.get_buf_num(task.name)
  end
end

function window.__open_last_task_output()
  if previous_get_buffer == nil then
    return
  end

  -- Get the buffer from the provided function
  local buf = previous_get_buffer()

  -- NOTE: make sure a valid buffer was returned
  if type(buf) ~= "number" or vim.api.nvim_buf_is_valid(buf) ~= true then
    return
  end

  if vim.api.nvim_buf_get_option(0, "filetype") == "TelescopePrompt" then
    -- NOTE: close telescope popup if open
    vim.api.nvim_buf_delete(0, { force = true })
  end

  local existing_winid = vim.fn.bufwinid(buf)
  if vim.api.nvim_win_is_valid(existing_winid) then
    -- NOTE: a valid window already exists for the provided
    -- buffer so don't open another one.
    -- Rather just jump to it.
    vim.fn.win_gotoid(existing_winid)
    window.opened_win = existing_winid
    return
  end

  local ow = create.create_window(buf)
  if not vim.api.nvim_win_is_valid(ow) then
    return
  end

  -- NOTE: save the opened window so we know when to close it
  -- when toggling
  window.opened_win = ow
end

return window
