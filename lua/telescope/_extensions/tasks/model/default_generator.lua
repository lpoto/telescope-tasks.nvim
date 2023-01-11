---@class Default_generator
---@field name string
---@field filetypes table|nil
---@field patterns table|nil
---@field ignore_patterns table|nil
---@field parent_dir_includes table|nil
---@field generator_fn function
local Default_generator = {
  name = "Default generator",
  generator_fn = function()
    return nil
  end,
}
Default_generator.__index = Default_generator

---@return table: Generator function on index 1 and
---options on index 2.
function Default_generator:get_generator()
  return {
    generator = self.generator_fn,
    opts = {
      name = self.name,
      filetypes = self.filetypes,
      patterns = self.patterns,
      ignore_patterns = self.ignore_patterns,
      parent_dir_includes = self.parent_dir_includes,
    },
  }
end

return Default_generator
