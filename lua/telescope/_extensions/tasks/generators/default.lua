local default = {}

---Enable all default generators
function default.all()
  return default.go(),
    default.cargo(),
    default.python(),
    default.lua(),
    default.makefile()
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

return default
