local util = {}

---The file system path separator for the current platform.
util.separator = "/"
util.is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win32unix" == 1
if util.is_windows == true then
    util.separator = "\\"
end

---@param patterns table?: A table of root patterns
---@param max_depth number?: Max depth to search for the root
---@return string: Root, vim.fn.getcwd() when not found.
function util.find_root(patterns, max_depth)
    max_depth = max_depth or 10
    patterns = patterns or { ".git" }

    local default_path_maker = "%:p:h"
    local path_maker = default_path_maker

    for _ = 1, max_depth, 1 do
        local path = vim.fn.expand()
        if path:len() == 1 or util.join_path(path, "") == os.getenv "HOME" then
            break
        end
        for _, pattern in ipairs(patterns) do
            if vim.fn.filereadable(util.join_path(path, pattern)) == 1
                or vim.fn.isdirectory(util.join_path(path, pattern)) == 1
            then
                return path
            end
        end
        path_maker = path_maker .. ":h"
    end
    return vim.fn.getcwd()
end

---Joins arbitrary number of paths together.
---@param ... string The paths to join.
---@return string
function util.join_path(...)
    local args = { ... }
    if #args == 0 then
        return ""
    end

    local all_parts = {}
    if type(args[1]) == "string" and args[1]:sub(1, 1) == M.separator then
        all_parts[1] = ""
    end

    for _, arg in ipairs(args) do
        local arg_parts = util.split_path(arg, util.separator)
        vim.list_extend(all_parts, arg_parts)
    end
    if args[#args] == "" then
        table.insert(all_parts, "")
    end
    return table.concat(all_parts, util.separator)
end

---Split the provided path into a table of strings using a separator.
---@param path string The string to split.
---@param sep string The separator to use.
---@return table table A table of strings.
function util.split_path(path, sep)
    local fields = {}

    local pattern = string.format("([^%s]+)", sep)
    local _ = string.gsub(path, pattern, function(c)
        fields[#fields + 1] = c
    end)

    return fields
end

return util
