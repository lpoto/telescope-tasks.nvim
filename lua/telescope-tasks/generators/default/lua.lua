local Default = require("telescope-tasks.model.default_generator")
local enum = require("telescope-tasks.enum")
local setup = require("telescope-tasks.setup")

---Add a task for running the current lua file.
local lua = Default:new({
  opts = {
    name = "Default Lua Generator",
    experimental = true,
  },
  errorformat = vim.fn.exepath("lua")
    .. ": [string %.%\\+]:%\\d%\\+: %m,"
    .. vim.fn.exepath("lua")
    .. ": %f:%l: %m,"
    .. vim.fn.exepath("lua")
    .. ": %m,"
    .. "%\\s%\\+[string %.%\\+]:%\\d%\\+: %m,"
    .. "%f:%l: %m",
})

function lua.generator(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  if filetype ~= "lua" then return nil end
  local name = vim.api.nvim_buf_get_name(buf)

  local cmd = {
    setup.opts.binary.lua or "lua",
    name,
  }
  local t = {
    "Run current Lua file",
    cmd = cmd,
    filename = name,
    priority = enum.PRIORITY.MEDIUM + 1,
    keywords = {
      "lua",
      name,
    },
  }
  local env = setup.opts.env.lua
  if type(env) == "table" and next(env) then t.env = env end
  return t
end

function lua.healthcheck()
  local binary = setup.opts.binary.lua or "lua"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Lua binary '" .. binary .. "' is not executable", {
      "Install 'lua' or set a different binary in setup",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

return lua
