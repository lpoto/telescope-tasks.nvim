local util = require "telescope._extensions.tasks.util"
local Path = require "plenary.path"

local setup = {}

setup.opts = {
  output = {
    style = "float", -- "split" | "vsplit" | "tab" | "float"
    layout = "center", -- "bottom" | "left" | "right"
    scale = 0.4,
  },
  data_dir = Path:new(vim.fn.stdpath "data", "telescope_tasks"):__tostring(),
}

---Creates the default picker options from the provided
---options. If the `theme` field with a string value is added,
---the telescope theme identified by that value is added to the options.
---@param opts table
function setup.setup(opts)
  if type(opts) ~= "table" then
    util.warn "Tasks config should be a table!"
    return
  end

  local output_opts = setup.opts.output
  if opts.output then
    output_opts = vim.tbl_extend("force", output_opts, opts.output)
  end
  if opts.data_dir then
    if type(opts.data_dir) ~= "string" then
      util.warn "'data_dir' should be a string"
      opts.data_dir = nil
    end
  end

  if type(opts.theme) == "string" then
    local theme = require("telescope.themes")["get_" .. opts.theme]
    if theme == nil then
      util.warn("No such telescope theme: '" .. opts.theme .. "'")
    else
      opts = theme(opts)
    end
  end
  opts.output = output_opts
  setup.opts = vim.tbl_extend("force", setup.opts, opts)
end

return setup
