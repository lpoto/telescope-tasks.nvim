local util = require "telescope-tasks.util"

---@class Generator_opts
---@field filetypes table|nil
---@field patterns table|nil
---@field ignore_patterns table|nil
---@field parent_dir_includes table|nil
---@field parent_dir_not_includes table|nil
---@field name string|nil
---@field experimental boolean|nil
local Generator_opts = {}
Generator_opts.__index = Generator_opts

---@param o table: A table to generate the options from
---@return Generator_opts
function Generator_opts:new(o)
  assert(o == nil or type(o) == "table", "Generator options must be a table")
  local opts = setmetatable(o or {}, Generator_opts)
  for k, v in pairs(opts) do
    assert(type(k) == "string", "Generator options keys must be strings")
    assert(
      (
        ({
          filetypes = true,
          patterns = true,
          ignore_patterns = true,
          parent_dir_includes = true,
          parent_dir_not_includes = true,
        })[k] and type(v) == "table"
      )
        or (k == "name" and type(v) == "string")
        or (k == "experimental" and type(v) == "boolean"),
      "Invalid generator option: " .. k
    )
  end
  return opts
end

---@return boolean: Whether the options are OK in the current context
function Generator_opts:check_in_current_context()
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local filename = vim.api.nvim_buf_get_name(buf)

  if
    next(self.filetypes or {})
    and not vim.tbl_contains(self.filetypes, filetype)
  then
    return false
  end
  if next(self.ignore_patterns or {}) then
    for _, pattern in ipairs(self.ignore_patterns) do
      if filename:match(pattern) then
        return false
      end
    end
  end
  if next(self.patterns or {}) then
    local ok = false
    for _, pattern in ipairs(self.patterns) do
      if filename:match(pattern) then
        ok = true
        break
      end
    end
    if not ok then
      return false
    end
  end
  if next(self.parent_dir_includes or {}) then
    if not util.parent_dir_includes(self.parent_dir_includes) then
      return false
    end
  end
  if next(self.parent_dir_not_includes or {}) then
    if util.parent_dir_includes(self.parent_dir_not_includes) then
      return false
    end
  end
  return true
end

return Generator_opts
