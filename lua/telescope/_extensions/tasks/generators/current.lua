---@class Generator_opts
---@field filetypes table|nil
---@field patterns table|nil
---@field ignore_patterns table|nil
---@field name string|nil

local generators = {}

local verify_parameters
local call_generator_callback

local current_generators = {}

---@param generator function
---@param opts Generator_opts?
function current_generators.add_custom(generator, opts)
  verify_parameters(generator, opts)

  table.insert(generators, {
    name = (opts or {}).name or "Custom",
    generator = generator,
    opts = opts,
  })
end

---@return boolean: Whether there are no current generators
function current_generators.is_empty()
  return next(generators or {}) == nil
end

---iteratre over the currently available generators.
---Their availabily is determined based on the Generator_opts
---provided when adding the generators.
function current_generators.iterate_available(callback)
  local buf = vim.fn.bufnr()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local filename = vim.api.nvim_buf_get_name(buf)

  for _, generator in ipairs(generators or {}) do
    local opts = generator.opts or {}

    call_generator_callback(
      filetype,
      filename,
      generator.generator,
      generator.name,
      opts or {},
      callback
    )
  end
end

---@param generator function
---@param opts Generator_opts?
verify_parameters = function(generator, opts)
  assert(type(generator) == "function", "Generator must be a function")
  assert(
    opts == nil or type(opts) == "table",
    "Generator options must be a table"
  )
  for k, v in pairs(opts or {}) do
    assert(type(k) == "string", "Generator options keys must be strings")
    assert(
      (
        ({ filetypes = true, patterns = true, ignore_patterns = true })[k]
        and type(v) == "table"
      ) or k == "name" and type(v) == "string",
      "Invalid generator option: " .. k
    )
  end
end

call_generator_callback =
  function(filetype, filename, generator, name, opts, cb)
    if opts.filetypes and not vim.tbl_contains(opts.filetypes, filetype) then
      return
    end
    if opts.patterns then
      local ok = false
      for _, pattern in ipairs(opts.patterns) do
        if filename:match(pattern) then
          ok = true
          break
        end
      end
      if not ok then
        return
      end
    end
    if opts.ignore_patterns then
      local ok = true
      for _, pattern in ipairs(opts.ignore_patterns) do
        if filename:match(pattern) then
          ok = false
          break
        end
      end
      if not ok then
        return
      end
    end
    cb(generator, name)
  end

return current_generators
