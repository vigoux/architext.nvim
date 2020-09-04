local ts = vim.treesitter
local M = {}

local previous_queries = {}

function M.get(parser, query)
  if query == nil or #query == 0 then return previous_queries[parser.lang] end

  local query = ts.parse_query(parser.lang, query)
  previous_queries[parser.lang] = query
  return query
end

return M
