local setup = require "telescope-tasks.setup"

local health = {}

local checks = {}

function health.check()
  vim.health.start "Telescope Tasks"
  local setup_errs = setup.get_errors()
  if package.loaded["telescope"] then
    vim.health.ok "Telescope is loaded"
  else
    vim.health.warn "Telescope is not loaded"
  end
  if setup_errs ~= nil then
    if next(setup_errs) then
      vim.health.warn("An error occured during setup", setup_errs)
    else
      vim.health.ok "Setup successful"
    end
  end
  for _, v in ipairs(checks) do
    if type(v) == "function" then
      v()
    end
  end
end

function health.__add_check(f)
  table.insert(checks, f)
end

return health
