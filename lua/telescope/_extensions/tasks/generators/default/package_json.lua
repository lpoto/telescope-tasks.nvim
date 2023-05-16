local Default = require "telescope._extensions.tasks.model.default_generator"
local Path = require "plenary.path"

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
        __meta = {
          name = "package_json_" .. k .. "_" .. filename
            :gsub("/", "_")
            :gsub("\\", "-"),
        },
      }
      if type(vim.g.MAKEFILE_ENV) == "table" and next(vim.g.MAKEFILE_ENV) then
        t.env = vim.g.MAKEFILE_ENV
      end
      table.insert(tasks, t)
    end
  end
  return tasks
end

return package_json
