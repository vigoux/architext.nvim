local ts = vim.treesitter
local a = vim.api
local f = vim.fn
local edit = require'architext.edit'

local M = {}

local function split_argument(text)
  local separator = text:sub(1, 1)
  local text = text:sub(2)

  local parts = vim.split(text, separator, true)
  local query_text = table.remove(parts, 1)

  return query_text, parts
end

function M.complete(cmdline, cursorpos)

  -- Strip the end of the cmdline
  local cmdline = cmdline:sub(1, cursorpos)

  local buf = a.nvim_get_current_buf()

  -- Remove command name
  local text = cmdline:gsub("^%w+", "")

  local parser = ts.get_parser(buf)
  local query_text, parts = split_argument(text)

  local completions = {}

  if #parts > 0 then
    -- Complete capture names if start of string or after @
    local part = parts[#parts]
    local query = ts.parse_query(parser.lang, query_text)

    -- TODO(vigoux): actually complete here
  else
    -- Complete node names
    -- Extract last node and determine type first
    local language = ts.inspect_language(parser.lang)

    local start_suffix, _, suffix = text:find("(%w*)$")

    -- This needs massage to be used
    local preffix = text:sub(1, start_suffix - 1)
    local pref_words = vim.split(preffix, " ", true)
    preffix = pref_words[#pref_words]


    local last_char = preffix:sub(#preffix)

    -- Symbol desc is a table {name, is_terminal}
    for _, symbol_desc in pairs(language.symbols) do
      local name, is_non_terminal = unpack(symbol_desc)
      if vim.startswith(name, suffix) then
        if last_char == [["]] and not is_non_terminal then
          table.insert(completions, preffix .. name .. [["]])
        elseif last_char == "(" and is_non_terminal then
          print(name, suffix)
          table.insert(completions, preffix .. name)
        end
      end
    end
  end

  return completions
end

-- Parses things like
-- /query/capture:replacement/etc/etc
local function parse_argument(parser, text)
  local query_text, parts = split_argument(text)

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
