local ts = vim.treesitter
local M = {}

local previous_queries = {}

local templates = {
  ["IDENT"] = [[((identifier) @id (#eq? @id "$1"))]]
}

local function evaluate_template(name, args)
  local template = templates[name]
  if not template then return end

  for i, arg in ipairs(args) do
    template = template:gsub(string.format("$%d", i), arg)
  end

  return template
end

function M.get(parser, query)
  if query == nil or #query == 0 then return previous_queries[parser:lang()] end

  if query:sub(1, 1) == "$" then
    -- Parse this template query
    local template_name, sep, args = query:sub(2):match("^(%u+)(%U)(.*)")
    if template_name and sep and args then
      query = evaluate_template(template_name, vim.split(args, sep, true))
    end
  end

  query = ts.parse_query(parser:lang(), query)
  previous_queries[parser:lang()] = query
  return query
end

function M.template_query(name, template)
  if name:match("^%u+$") then
    templates[name] = template
  else
    vim.api.nvim_err_writeln(string.format("%s is not a valid template name (they must be all uppercase)"))
  end
end

function M.list_templates()
  return vim.tbl_keys(templates)
end

return M
