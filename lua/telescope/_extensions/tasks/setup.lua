local enum = require "telescope._extensions.tasks.enum"
local env = require "telescope._extensions.tasks.generators.env"

local setup = {}

setup.opts = {}

---Creates the default picker options from the provided
---options. If the `theme` field with a string value is added,
---the telescope theme identified by that value is added to the options.
---@param opts table
function setup.setup(opts)
  if type(opts) ~= "table" then
    vim.notify("Tasks config should be a table!", vim.log.levels.WARN, {
      title = enum.TITLE,
    })
    return
  end

  local opts_env = opts.env

  if type(opts.theme) == "string" then
    local theme = require("telescope.themes")["get_" .. opts.theme]
    if theme == nil then
      vim.notify(
        "No such telescope theme: '" .. opts.theme .. "'",
        vim.log.levels.WARN,
        {
          title = enum.TITLE,
        }
      )
    else
      opts = theme(opts)
    end
  end
  if opts_env then
    local ok, e = pcall(env.add, opts_env)
    if not ok and type(e) == "string" then
      vim.notify(e, vim.log.levels.WARN, {
        title = enum.TITLE,
      })
    end
  end
  setup.opts = vim.tbl_extend("force", setup.opts, opts)
end

return setup
