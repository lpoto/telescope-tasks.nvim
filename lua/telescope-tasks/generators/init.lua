local default = require "telescope-tasks.generators.default"
local custom = require "telescope-tasks.generators.custom"

return {

  ---Access the default generators api
  default = default,

  ---Access the custom generators api
  custom = custom,
}
