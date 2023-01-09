local Task = require "telescope._extensions.tasks.model.task"
local enum = require "telescope._extensions.tasks.enum"
local finder = require "telescope._extensions.tasks.finder"
local previewer = require "telescope._extensions.tasks.previewer"
local mappings = require "telescope._extensions.tasks.mappings"

local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
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
        results_title = "Available Tasks",
        finder = finder.available_tasks_finder(prev_buf),
        sorter = conf.generic_sorter(opts),
        previewer = previewer.task_previewer(),
        dynamic_preview_title = true,
        selection_strategy = "row",
        scroll_strategy = "cycle",
        attach_mappings = mappings.get_attach_mappings(prev_buf),
      })
      :find()
  end

  tasks_picker(options)
end

return picker.available_tasks_picker
