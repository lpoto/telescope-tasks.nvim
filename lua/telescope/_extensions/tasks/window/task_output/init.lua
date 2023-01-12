local enum = require "telescope._extensions.tasks.enum"
local executor = require "telescope._extensions.tasks.executor"
local create = require "telescope._extensions.tasks.window.task_output.create"

local prev_task_name = nil

local window = {}

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
  local buf = executor.get_task_output_buf(task.name)
  if buf == nil or vim.fn.bufexists(buf) ~= 1 then
    vim.notify("Task '" .. task.name .. "' has no output!", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return
  end
  if beforeOpening ~= nil then
    beforeOpening()
  end

  prev_task_name = task.name

  window.__open_last_task_output()
end

function window.__open_last_task_output()
  -- Get the buffer from the provided function
  if prev_task_name == nil then
    return
  end
  local buf = executor.get_task_output_buf(prev_task_name)

  -- NOTE: make sure a valid buffer was returned
  if type(buf) ~= "number" or vim.api.nvim_buf_is_valid(buf) ~= true then
    prev_task_name = nil
    return
  end

  local existing_winid = vim.fn.bufwinid(buf)
  if vim.api.nvim_win_is_valid(existing_winid) then
    -- NOTE: a valid window already exists for the provided
    -- buffer so don't open another one.
    -- Rather just jump to it.
    vim.fn.win_gotoid(existing_winid)
    return
  end

  local ow = create.create_window(buf, prev_task_name)
  if not vim.api.nvim_win_is_valid(ow) then
    return
  end
end

function window.__toggle_last_task_output()
  -- Get the buffer from the provided function
  if prev_task_name == nil then
    return
  end
  local buf = executor.get_task_output_buf(prev_task_name)

  -- NOTE: make sure a valid buffer was returned
  if type(buf) ~= "number" or vim.api.nvim_buf_is_valid(buf) ~= true then
    vim.notify(
      prev_task_name .. ": output no longer available",
      vim.log.levels.WARN,
      {
        title = enum.TITLE,
      }
    )
    return
  end

  if
    vim.api.nvim_buf_get_option(0, "filetype")
    == enum.TELESCOPE_PROMPT_FILETYPE
  then
    -- NOTE: close telescope popup if open
    vim.api.nvim_buf_delete(0, { force = true })
  end

  local existing_winid = vim.fn.bufwinid(buf)
  if vim.api.nvim_win_is_valid(existing_winid) then
    vim.api.nvim_win_close(existing_winid, false)
    return
  end

  window.__open_last_task_output()
end

return window
