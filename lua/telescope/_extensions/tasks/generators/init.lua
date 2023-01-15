local default = require "telescope._extensions.tasks.generators.default"
local custom = require "telescope._extensions.tasks.generators.custom"

return {

  ---Access the default generators api
  default = default,

  ---Access the custom generators api
  custom = custom,
}
