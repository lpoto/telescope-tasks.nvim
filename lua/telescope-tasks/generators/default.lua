local util = require("telescope-tasks.util")

local default = {}

---Enable all default generators
function default.all()
  for k, v in pairs(default) do
    if type(v) == "function" and k ~= "all" then
      local ok, e = pcall(v)
      if not ok then
        util.warn("Error loading default generator - ", k, ":", e)
      end
    end
  end
end

---Enable Go default generator
function default.go() require("telescope-tasks.generators.default.go"):load() end

---Enable Cargo default generator
function default.cargo()
  require("telescope-tasks.generators.default.cargo"):load()
end

---Enable Python generator
function default.python()
  require("telescope-tasks.generators.default.python"):load()
end

---Enable Lua default generator
function default.lua()
  require("telescope-tasks.generators.default.lua"):load()
end

---Enable Makefile default generator
function default.makefile()
  require("telescope-tasks.generators.default.makefile"):load()
end

---Enable package json default generator
function default.package_json()
  require("telescope-tasks.generators.default.package_json"):load()
end

---Enable maven default generator
function default.maven()
  require("telescope-tasks.generators.default.maven"):load()
end

---Enable docker-compose default generator
function default.docker_compose()
  require("telescope-tasks.generators.default.docker_compose"):load()
end

return default
