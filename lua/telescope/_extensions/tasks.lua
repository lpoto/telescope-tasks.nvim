local util = require("telescope-tasks.util")
local enum = require("telescope-tasks.enum")
local picker = require("telescope-tasks.picker")
local setup = require("telescope-tasks.setup")
local actions = require("telescope-tasks.picker.actions")
local generators = require("telescope-tasks.generators")

-- NOTE: ensure the telescope is loaded
-- before registering the extension
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  util.error(
    "This extension requires telescope.nvim "
      .. "(https://github.com/nvim-telescope/telescope.nvim)"
  )
end

---Opens the tasks picker and merges the provided opts
---with the default options provided during the setup.
---@param opts table|nil
local function tasks(opts)
  opts = opts or {}
  picker(vim.tbl_extend("force", setup.opts, opts))
end

-- NOTE: create the augroup used by the plugin
vim.api.nvim_create_augroup(enum.TASKS_AUGROUP, { clear = true })

-- NOTE: register the extension
return telescope.register_extension({
  setup = setup.setup,
  exports = {
    tasks = tasks,
    actions = actions,
    generators = generators,
    util = util,
    _picker = picker,
  },
})
