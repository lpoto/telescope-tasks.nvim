local executor = require "telescope._extensions.tasks.executor"
local finder = require "telescope._extensions.tasks.finder"
local output_window = require "telescope._extensions.tasks.window.task_output"

local telescope_actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local actions = {}
actions.__prev_buf = nil

local refresh_picker

function actions.select_task(prompt_bufnr, prev_buf)
  local p = action_state.get_current_picker(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local task = selection.value

  if executor.is_running(task.name) == true then
    executor.kill(task.name, prev_buf)
    return
  end

  executor.start(task.name, prev_buf, function()
    refresh_picker(p, prev_buf)
  end)
  refresh_picker(p, prev_buf)
end

function actions.selected_task_output(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  output_window.open(selection.value, function()
    telescope_actions.close(prompt_bufnr)
  end)
end

function actions.delete_selected_task_output(picker_buf, prev_buf)
  local p = action_state.get_current_picker(picker_buf)
  local selection = action_state.get_selected_entry()
  executor.delete_task_buffer(selection.value.name)
  refresh_picker(p, prev_buf)
end

function actions.toggle_last_output()
  if
    output_window.opened_win ~= nil
    and vim.api.nvim_win_is_valid(output_window.opened_win)
  then
    vim.api.nvim_win_close(output_window.opened_win, false)
    return
  end
  output_window.__open_last_task_output()
end

refresh_picker = function(p, prev_buf)
  vim.defer_fn(function()
    pcall(
      p.refresh,
      p,
      finder.available_tasks_finder(prev_buf),
      { reset_prompt = true }
    )
  end, 60)
end

return actions
