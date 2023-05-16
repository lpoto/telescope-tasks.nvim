local default = {}

---Enable all default generators
function default.all()
  return default.go(),
    default.cargo(),
    default.python(),
    default.lua(),
    default.makefile(),
    default.package_json()
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

return default
