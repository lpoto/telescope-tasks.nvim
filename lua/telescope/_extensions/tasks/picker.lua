local executor = require "telescope._extensions.tasks.executor"
local Task = require "telescope._extensions.tasks.model.task"
local enum = require "telescope._extensions.tasks.enum"
local finder = require "telescope._extensions.tasks.finder"
local previewer = require "telescope._extensions.tasks.previewer"
local output_window = require "telescope._extensions.tasks.window.task_output"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local picker = {}
local prev_buf = nil

local available_tasks_telescope_picker

---Displays available tasks in a telescope prompt.
---In the opened window.
---
---@param opts table?: options to pass to the picker
---@return table: a telescope picker
function picker.available_tasks_picker(opts)
  available_tasks_telescope_picker(opts)
end

local function refresh_picker(p)
  vim.defer_fn(function()
    pcall(
      p.refresh,
      p,
      finder.available_tasks_finder(prev_buf),
      { reset_prompt = true }
    )
  end, 60)
end

local function select_task(p, task)
  if executor.is_running(task.name) == true then
    executor.kill(task.name, prev_buf)
    return
  end

  executor.start(task.name, prev_buf, function()
    refresh_picker(p)
  end)
  refresh_picker(p)
end

local function output_of_task_under_cursor(picker_buf)
  local selection = action_state.get_selected_entry()
  output_window.open(selection.value, function()
    actions.close(picker_buf)
  end)
end

local function delete_output_of_task_under_cursor(picker_buf)
  local p = action_state.get_current_picker(picker_buf)
  local selection = action_state.get_selected_entry()
  executor.delete_task_buffer(selection.value.name)
  refresh_picker(p)
end

local function attach_picker_mappings()
  return function(prompt_bufnr, map)
    actions.select_default:replace(function()
      local selection = action_state.get_selected_entry()
      local p = action_state.get_current_picker(prompt_bufnr)
      select_task(p, selection.value)
    end)
    for _, mode in ipairs { "i", "n" } do
      map(mode, "<C-o>", function()
        output_of_task_under_cursor(prompt_bufnr)
      end)
      map(mode, "<C-d>", function()
        delete_output_of_task_under_cursor(prompt_bufnr)
      end)
    end
    return true
  end
end

available_tasks_telescope_picker = function(options)
  local cur_buf = vim.fn.bufnr()
  if
    vim.api.nvim_buf_get_option(cur_buf, "buftype") ~= "terminal"
    or vim.api.nvim_buf_get_option(cur_buf, "filetype")
      ~= enum.OUTPUT_BUFFER_FILETYPE
  then
    prev_buf = vim.fn.bufnr()
  end

  local tasks, err = Task.__available_tasks(prev_buf)
  if err ~= nil then
    vim.notify(err, vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return -1
  end

  if tasks == nil or next(tasks) == nil then
    vim.notify("There are no available tasks", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return -1
  end

  local function tasks_picker(opts)
    opts = opts or {}
    print(vim.inspect(opts))
    pickers
      .new(opts, {
        prompt_title = "Tasks",
        results_title = "<CR> - Run/kill , <C-o> - Show output, <C-d> - Delete output",
        finder = finder.available_tasks_finder(prev_buf),
        sorter = conf.generic_sorter(opts),
        previewer = previewer.task_previewer(),
        dynamic_preview_title = true,
        selection_strategy = "row",
        attach_mappings = attach_picker_mappings(),
      })
      :find()
  end

  tasks_picker(options)
end

return picker
