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

  local function preffix_massage(preffix)
    local pref_words = vim.split(preffix, " ", true)
    return pref_words[#pref_words]
  end

  -- Strip the end of the cmdline
  local cmdline = cmdline:sub(1, cursorpos)

  local buf = a.nvim_get_current_buf()

  -- Remove command name
  local text = cmdline:gsub("^.-%w", "")

  print(text)

  local parser = ts.get_parser(buf)
  local query_text, parts = split_argument(text)

  if #parts > 0 then
    local function make_items(cname, query, preffix, suffix)
      local preffix = preffix_massage(preffix)
      local completions = {}
      for _, cap in ipairs(query.captures) do
        if vim.startswith(cap, cname) then
          table.insert(completions, preffix .. cap .. (suffix or ""))
        end
      end

      return completions
    end

    -- Complete capture names if start of string or after @
    local part = parts[#parts]
    local query = ts.parse_query(parser.lang, query_text)

    -- Two case, either we are at the start of the string, or after an @
    local start_cname, end_cname, cname = part:find("^(%w*)")

    if end_cname == #part then
      -- Start of the string
      return make_items(cname, query, preffix_massage(text:sub(1, #text - #part)), ":")
    else
      local start_cname, end_cname, cname = part:find("@(%w*)")
      if start_cname and end_cname and cname then
        return make_items(cname, query, preffix_massage(text:sub(1, #text - #cname)))
      else
        return {}
      end
    end
  else
    -- Complete node names
    -- Extract last node and determine type first
    local completions = {}
    local language = ts.inspect_language(parser.lang)

    local start_suffix, _, suffix = text:find("(%w*)$")

    -- This needs massage to be used
    local preffix = preffix_massage(text:sub(1, start_suffix - 1))

    local last_char = preffix:sub(#preffix)

    -- Symbol desc is a table {name, is_terminal}
    if last_char == [["]] or last_char == "(" then
      for _, symbol_desc in pairs(language.symbols) do
        local name, is_non_terminal = unpack(symbol_desc)
        if vim.startswith(name, suffix) then
          if last_char == [["]] and not is_non_terminal then
            table.insert(completions, preffix .. name .. [["]])
          elseif last_char == "(" and is_non_terminal then
            table.insert(completions, preffix .. name)
          end
        end
      end
    else
      for _, field in ipairs(language.fields) do
        if vim.startswith(field, suffix) then
          table.insert(completions, preffix .. field .. ":")
        end
      end
    end

    return completions
  end
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
  edit.edit(buf, parser, query, changes, start_row - 1, end_row) -- Because end_row is exclusive
end

return M
