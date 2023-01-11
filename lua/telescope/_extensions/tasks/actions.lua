local enum = require "telescope._extensions.tasks.enum"
local executor = require "telescope._extensions.tasks.executor"
local finder = require "telescope._extensions.tasks.finder"
local output_window = require "telescope._extensions.tasks.window.task_output"

local telescope_actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local actions = {}

local refresh_picker

function actions.select_task(prompt_bufnr)
  local p = action_state.get_current_picker(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local task = selection.value

  if executor.is_running(task.name) == true then
    executor.kill(task.name)
    return
  end

  executor.start(task.name, function()
    refresh_picker(p)
  end)
  refresh_picker(p)
end

function actions.selected_task_output(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  output_window.open(selection.value, function()
    telescope_actions.close(prompt_bufnr)
  end)
end

function actions.delete_selected_task_output(picker_buf)
  local p = action_state.get_current_picker(picker_buf)
  local selection = action_state.get_selected_entry()
  executor.delete_task_buffer(selection.value.name)
  refresh_picker(p)
end

function actions.toggle_last_output()
  if
    vim.api.nvim_buf_get_option(0, "filetype")
    == enum.TELESCOPE_PROMPT_FILETYPE
  then
    -- NOTE: close telescope popup if open
    vim.api.nvim_buf_delete(0, { force = true })
  end

  output_window.__toggle_last_task_output()
end

refresh_picker = function(p)
  vim.defer_fn(function()
    pcall(
      p.refresh,
      p,
      finder.available_tasks_finder(),
      { reset_prompt = true }
    )
  end, 60)
end

return actions
