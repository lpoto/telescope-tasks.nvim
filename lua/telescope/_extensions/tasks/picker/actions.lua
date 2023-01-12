local enum = require "telescope._extensions.tasks.enum"
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
    executor.kill(task.name)
    return
  end

  executor.run(task.name, function()
    refresh_picker()
  end)
  refresh_picker(prompt_bufnr)
end

function actions.selected_task_output(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  output.open(selection.value, function()
    telescope_actions.close(prompt_bufnr)
  end)
end

function actions.delete_selected_task_output(picker_buf)
  local selection = action_state.get_selected_entry()
  executor.set_buffer_as_to_be_deleted(selection.value.name)
  refresh_previewer(picker_buf)
  executor.delete_task_buffer(selection.value.name)
  refresh_picker(picker_buf)
end

function actions.toggle_last_output()
  output.toggle_last()
end

refresh_picker = function(picker_buf)
  local p = action_state.get_current_picker(picker_buf or vim.fn.bufnr())
  if p == nil then
    return
  end
  local ok, e = pcall(p.refresh, p, finder.available_tasks_finder(), {
    reset_prompt = true,
  })
  if not ok and type(e) == "string" then
    vim.notify(e, vim.log.levels.ERROR, {
      title = enum.TITLE,
    })
  end
end

refresh_previewer = function(picker_buf)
  local p = action_state.get_current_picker(picker_buf or vim.fn.bufnr())
  if p ~= nil then
    p:refresh_previewer()
  end
end

return actions
