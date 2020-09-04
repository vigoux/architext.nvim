local ts = vim.treesitter
local a = vim.api
local f = vim.fn
local edit = require'architext.edit'

local M = {}

-- Parses things like
-- /query/capture:replacement/etc/etc
local function parse_argument(parser, text)
  local separator = text:sub(1, 1)
  local text = text:sub(2)

  local parts = vim.split(text, separator, true)
  local query_text = table.remove(parts, 1)

  local query = ts.parse_query(parser.lang, query_text)
  local changes = {}

  for _, replacement in ipairs(parts) do
    -- Extract capture to replacement, and just ignore everything else
    local start, stop, capture_name = replacement:find("^([a-zA-Z.]+).")

    if start and stop and capture_name then
      local index = f.index(query.captures, capture_name)

      if index >= 0 then
        changes[index + 1] = replacement:sub(stop + 1)
      end
    end
  end

  return query, changes
end

function M.run(text, start_row, end_row)

  local buf = a.nvim_get_current_buf()
  local parser = ts.get_parser(buf)

  if not parser then return end

  local query, changes = parse_argument(parser, text)
  edit.edit(buf, parser, query, changes, start_row - 1, end_row - 1)
end

return M
