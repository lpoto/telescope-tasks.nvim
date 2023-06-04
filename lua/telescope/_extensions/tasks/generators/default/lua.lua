local Default = require "telescope._extensions.tasks.model.default_generator"
local util = require "telescope._extensions.tasks.util"

---Add a task for running the current lua file.
local lua = Default:new {
  opts = {
    name = "Default Lua Generator",
    experimental = true,
  },
  errorformat = vim.fn.exepath "lua"
    .. ": [string %.%\\+]:%\\d%\\+: %m,"
    .. vim.fn.exepath "lua"
    .. ": %f:%l: %m,"
    .. vim.fn.exepath "lua"
    .. ": %m,"
    .. "%\\s%\\+[string %.%\\+]:%\\d%\\+: %m,"
    .. "%f:%l: %m",
}

function lua.generator(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "lua" then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)

  local cmd = {
    "lua",
    name,
  }
  local t = {
    "Run current Lua file",
    cmd = cmd,
    filename = name,
    keywords = {
      "lua",
      name,
    },
  }
  local env = util.get_env "lua"
  if type(env) == "table" and next(env) then
    t.env = env
  end
  return t
end

return lua
