local run_project =
  require "telescope._extensions.tasks.generators.default.run_project"

return {
  ---Access the run_projet default generators api
  run_project = run_project,

  ---Enable all default generators
  all = function()
    run_project.all()
  end,
}
