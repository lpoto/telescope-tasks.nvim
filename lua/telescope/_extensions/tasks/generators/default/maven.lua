local Path = require "plenary.path"
local Default = require "telescope._extensions.tasks.model.default_generator"

---Generate tasks for running maven projects in subdirectories,
---
---maven clean package
---
local maven = Default:new {
  errorformat = "[ERROR] %f:[%l\\,%v] %m",
  opts = {
    name = "Default Maven Generator",
    experimental = true,
  },
}

local is_build_pom
local run_project_task

--- Build tasks by finding pom.xml files with <build> tags in the subdirectories.
function maven.generator()
  local tasks = {}

  if not maven:state() then
    return
  end
  local files = (maven:state():find_files() or {}).by_name
  local pom = "pom.xml"
  if type(files) ~= "table" or not next(files[pom] or {}) then
    -- NOTE: only pom.xml files are relevant
    return tasks
  end

  -- NOTE: iterate only over the pom.xml files
  for _, entry in ipairs(files[pom]) do
    if is_build_pom(entry) then
      local path = Path:new(entry)
      local cwd = path:parent():__tostring()

      --NOTE: if the FOUND file  is a maven main file and has
      --a parent maven.mod file, add a task for running the
      --project in the found file's directory.
      local full_path = path:__tostring()
      path:make_relative(vim.fn.getcwd())
      local name = "Maven project: " .. path:__tostring()
      table.insert(tasks, run_project_task(cwd, name, full_path))
    end
  end
  return tasks
end

run_project_task = function(cwd, name, full_path)
  local cmd = { "mvn", "clean", "package", "-DskipTests" }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = full_path,
    __meta = {
      "maven",
      full_path,
    },
  }
  if type(vim.g.JAVA_ENV) == "table" and next(vim.g.JAVA_ENV) then
    t.env = vim.g.JAVA_ENV
  end
  if type(vim.g.MAVEN_ENV) == "table" and next(vim.g.MAVEN_ENV) then
    t.env = vim.tbl_extend("force", t.env or {}, vim.g.MAVEN_ENV)
  end
  return t
end

--- Check whether the provided file is pom.xml and
--- contains <build> tag
is_build_pom = function(file)
  local ok, ok2 = pcall(function()
    local t = vim.fn.fnamemodify(file, ":t")
    if t ~= "pom.xml" then
      return false
    end
    local path = Path:new(file)
    if not path:is_file() then
      return false
    end

    local lines = path:readlines()
    for _, line in ipairs(lines) do
      if line:match "<build>" then
        return true
      end
    end
    return false
  end)
  return ok and ok2
end

return maven
