local util = require "telescope._extensions.tasks.util"
local executor = require "telescope._extensions.tasks.executor"
local finder = require "telescope._extensions.tasks.picker.finder"
local output = require "telescope._extensions.tasks.output"

local telescope_actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local actions = {}

local refresh_picker
local refresh_previewer

function actions.select_task(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local task = selection.value

  if executor.is_running(task.name) then
    executor.kill(task)
    return
  end

  executor.run(task, function()
    refresh_picker()
  end, function()
    refresh_picker(prompt_bufnr)
  end, true, false)
end

function actions.run_task_with_modyfiable_command(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local task = selection.value

  if executor.is_running(task.name) then
    util.error "Task is already running"
    return
  end

  executor.run(task, function()
    refresh_picker()
  end, function()
    refresh_picker(prompt_bufnr)
  end, false, false)
end

function actions.run_task_and_save_modified_command(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  local task = selection.value

  if executor.is_running(task.name) then
    util.error "Task is already running"
    return
  end

  executor.run(task, function()
    refresh_picker()
  end, function()
    refresh_picker(prompt_bufnr)
  end, false, true)
end

function actions.selected_task_output(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  output.open(selection.value, function()
    telescope_actions.close(prompt_bufnr)
  end)
end

function actions.delete_selected_task_output(picker_buf)
  local selection = action_state.get_selected_entry()
  local task = selection.value
  executor.set_buffer_as_to_be_deleted(task.name)
  local running = executor.is_running(task.name)
  refresh_previewer(picker_buf)
  executor.delete_task_buffer(task)
  if not running then
    refresh_picker(picker_buf, true)
  end
end

function actions.selection_to_qf()
  local selection = action_state.get_selected_entry()
  local task = selection.value
  executor.to_qf(task)
end

function actions.toggle_last_output()
  output.toggle_last()
end

refresh_picker = function(picker_buf, close_on_no_results)
  local buf = vim.api.nvim_get_current_buf()
  local p = action_state.get_current_picker(picker_buf or buf)
  if p == nil then
    return
  end
  local tasks_finder =
      finder.available_tasks_finder(p.starting_buffer, close_on_no_results)
  if not tasks_finder then
    pcall(telescope_actions.close, picker_buf)
    return
  end
  local ok, e = pcall(p.refresh, p, tasks_finder)
  if not ok and type(e) == "string" then
    util.error(e)
  end
end

refresh_previewer = function(picker_buf)
  local buf = vim.api.nvim_get_current_buf()
  local p = action_state.get_current_picker(picker_buf or buf)
  if p ~= nil then
    p:refresh_previewer()
  end
end

return actions
