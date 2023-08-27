local custom = require("telescope-tasks.generators.custom")
local default = require("telescope-tasks.generators.default")

return {

  ---Access the default generators api
  default = default,

  ---Access the custom generators api
  custom = custom,
}
