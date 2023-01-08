local enum = require "telescope._extensions.tasks.enum"
local run_task = require "telescope._extensions.tasks.executor.run_task"
local output_window = require "telescope._extensions.tasks.window.output"

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
  local create_buffer, handle_window = window.get_init_functions(task)
  output_window.open(create_buffer, handle_window)
  output_window.set_previous(create_buffer, handle_window)
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
  output_window.set_previous(window.get_init_functions(task))
end

---@param task Task: the task for which the output will be shown.
---@return function: Function to get the output buffer number
---@return function: Function to handle the opened window
function window.get_init_functions(task)
  ---@return number?: An task output buffer number
  local create_buffer = function()
    return run_task.get_buf_num(task.name)
  end
  local handle_window = function(winid)
    -- NOTE: set wrap for the opened window
    vim.api.nvim_win_set_option(winid, "wrap", true)

    -- NOTE: match some higlights in the output window
    -- to distinguish the echoed step and task info from
    -- the actual output
    window.highlight_added_text(winid)
  end
  return create_buffer, handle_window
end

function window.highlight_added_text(winid)
  pcall(vim.api.nvim_win_call, winid, function()
    vim.fn.matchadd("Function", "^==> TASK: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Constant", "^==> STEP: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Comment", "^==> CWD: \\[\\_.\\{-}\\n\\n")
    vim.fn.matchadd("Statement", "^\\[Process exited .*\\]$")
    vim.fn.matchadd("Function", "^\\[Process exited 0\\]$")

    if vim.fn.winwidth(winid) < 50 and vim.o.columns >= 70 then
      -- NOTE: make sure the output window is at least 50 columns wide
      vim.fn.execute("vertical resize " .. 50, true)
    end
  end)
end

return window
