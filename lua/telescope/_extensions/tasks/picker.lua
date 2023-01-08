local Task = require "telescope._extensions.tasks.model.task"
local enum = require "telescope._extensions.tasks.enum"
local finder = require "telescope._extensions.tasks.finder"
local previewer = require "telescope._extensions.tasks.previewer"
local actions = require "telescope._extensions.tasks.actions"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local telescope_actions = require "telescope.actions"

local picker = {}
local prev_buf = nil

local available_tasks_telescope_picker

---Displays available tasks in a telescope prompt.
---In the opened window.
---
---@param opts table?: options to pass to the picker
function picker.available_tasks_picker(opts)
  available_tasks_telescope_picker(opts)
end

local function attach_picker_mappings()
  return function(prompt_bufnr, map)
    telescope_actions.select_default:replace(function()
      actions.select_task(prompt_bufnr, prev_buf)
    end)
    for _, mode in ipairs { "i", "n" } do
      map(mode, "<C-o>", function()
        actions.selected_task_output(prompt_bufnr)
      end)
      map(mode, "<C-d>", function()
        actions.delete_selected_task_output(prompt_bufnr, prev_buf)
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

return picker.available_tasks_picker
