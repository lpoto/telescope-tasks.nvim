local Default = require "telescope._extensions.tasks.model.default_generator"
local Path = require "plenary.path"
local util = require "telescope._extensions.tasks.util"

local package_json = Default:new {
  opts = {
    name = "Default package.json scripts Generator",
    experimental = true,
  },
}

local get_tasks

function package_json.generator()
  local files = (package_json:state():find_files() or {}).by_name
  if not next(files or {}) then
    return {}
  end
  local tasks = {}

  for _, m in ipairs(files["package.json"] or {}) do
    m = Path.new(m)
    local ok, json = pcall(m.read, m)
    if ok then
      local f = vim.json.decode and vim.json.decode or vim.fn.json_decode
      local ok2, pkg = pcall(f, json)
      if ok2 then
        for _, task in ipairs(get_tasks(m, pkg) or {}) do
          table.insert(tasks, task)
        end
      end
    end
  end
  return tasks
end

function get_tasks(path, pkg)
  if
    type(pkg) ~= "table"
    or type(pkg.scripts) ~= "table"
    or not next(pkg.scripts)
  then
    return {}
  end
  local relative_path = path:make_relative(vim.fn.getcwd())
  local cwd = path:parent():__tostring()
  local filename = path:__tostring()

  local tasks = {}

  for k, v in pairs(pkg.scripts) do
    if type(v) == "string" then
      local t = {
        relative_path .. ": " .. k,
        filename = filename,
        cmd = v,
        cwd = cwd,
        keywords = {
          "package.json",
          filename,
          k,
        },
      }
      local env = util.get_env "package.json"
      if type(env) == "table" and next(env) then
        t.env = env
      end
      env = util.get_env "package.json"
      if type(env) == "table" and next(env) then
        t.env = vim.tbl_extend("force", t.env or {}, env)
      end
      table.insert(tasks, t)
    end
  end
  return tasks
end

return package_json
