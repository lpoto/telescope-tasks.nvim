local Default = require "telescope._extensions.tasks.model.default_generator"

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
    __meta = {
      name = "lua_run_file_" .. name:gsub("/", "_"):gsub("\\", "-"),
    },
  }
  if type(vim.g.LUA_ENV) == "table" and next(vim.g.LUA_ENV) then
    t.env = vim.g.LUA_ENV
  end
  return t
end

return lua
