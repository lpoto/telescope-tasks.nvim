local function require_generator_module(name)
  return function()
    return require("telescope._extensions.tasks.generators.default." .. name)
  end
end

return {
  run_project = require_generator_module "run_project",
  -- TODO: add generators for running tests,
  -- generators to read tasks from project's config files.. example: _Cargo.toml_ targets, _package.json_ scripts ...
}
