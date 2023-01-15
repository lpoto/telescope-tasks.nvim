local function require_generator_module(name)
  return function()
    return require("telescope._extensions.tasks.generators.default." .. name)
  end
end

return {
  run_project = require_generator_module "run_project",
  all = function()
    return require_generator_module "run_project"().all()
  end,
}
