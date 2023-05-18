local util = require "telescope._extensions.tasks.util"

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
function default.go()
  require("telescope._extensions.tasks.generators.default.go"):load()
end

---Enable Cargo default generator
function default.cargo()
  require("telescope._extensions.tasks.generators.default.cargo"):load()
end

---Enable Python generator
function default.python()
  require("telescope._extensions.tasks.generators.default.python"):load()
end

---Enable Lua default generator
function default.lua()
  require("telescope._extensions.tasks.generators.default.lua"):load()
end

---Enable Makefile default generator
function default.makefile()
  require("telescope._extensions.tasks.generators.default.makefile"):load()
end

---Enable package json default generator
function default.package_json()
  require("telescope._extensions.tasks.generators.default.package_json"):load()
end

---Enable maven default generator
function default.maven()
  require("telescope._extensions.tasks.generators.default.maven"):load()
end

return default
