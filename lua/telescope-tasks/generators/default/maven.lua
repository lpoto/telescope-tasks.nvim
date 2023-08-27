local Default = require("telescope-tasks.model.default_generator")
local Path = require("plenary.path")
local State = require("telescope-tasks.model.state")
local enum = require("telescope-tasks.enum")
local setup = require("telescope-tasks.setup")

---Generate tasks for running maven projects in subdirectories,
---
---maven clean package
---
local maven = Default:new({
  errorformat = "[ERROR] %f:[%l\\,%v] %m",
  opts = {
    name = "Default Maven Generator",
    experimental = true,
  },
})

local is_build_pom
local run_project_task

--- Build tasks by finding pom.xml files with <build> tags in the subdirectories.
function maven.generator()
  local tasks = {}

  if not maven:state() then return end
  local files = (maven:state():find_files(5) or {}).by_name
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
      path:normalize(vim.fn.getcwd())
      local name = "Maven project: " .. path:__tostring()
      table.insert(tasks, run_project_task(cwd, name, full_path))
    end
  end
  return tasks
end

run_project_task = function(cwd, name, full_path)
  local binary = setup.opts.binary.maven or "mvn"
  local cmd = { binary, "clean", "package", "-DskipTests" }

  local t = {
    name,
    cmd = cmd,
    cwd = cwd,
    filename = full_path,
    priority = enum.PRIORITY.LOW + 4,
    keywords = {
      "maven",
      full_path,
    },
  }
  local env = setup.opts.env.java
  if type(env) == "table" and next(env) then t.env = env end
  env = setup.opts.env.maven
  if type(env) == "table" and next(env) then
    t.env = vim.tbl_extend("force", t.env or {}, env)
  end
  return t
end

--- Check whether the provided file is pom.xml and
--- contains <build> tag
is_build_pom = function(file)
  local ok, ok2 = pcall(function()
    local t = vim.fn.fnamemodify(file, ":t")
    if t ~= "pom.xml" then return false end
    local path = Path:new(file)
    if not path:is_file() then return false end

    local lines = path:readlines()
    for _, line in ipairs(lines) do
      if line:match("<build>") then return true end
    end
    return false
  end)
  return ok and ok2
end

function maven.healthcheck()
  local binary = setup.opts.binary.maven or "mvn"
  if vim.fn.executable(binary) == 0 then
    vim.health.warn("Maven binary '" .. binary .. "' is not executable", {
      "Install 'maven' or set a different binary in setup",
    })
  else
    vim.health.ok("'" .. binary .. "' is executable")
  end
end

function maven.on_load() State.register_file_names({ "pom.xml" }) end

return maven
