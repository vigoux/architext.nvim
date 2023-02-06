local ts = vim.treesitter
local a = vim.api
local f = vim.fn
local edit = require'architext.edit'
local q = require'architext.query'
local utils = require'architext.utils'

local M = {}

local function split_argument(text)
  local separator = text:sub(1, 1)
  text = text:sub(2)

  local parts = vim.split(text, separator, true)
  local query_text = table.remove(parts, 1)

  return query_text, parts
end

function M.complete(_, cmdline, cursorpos)
  local function preffix_massage(preffix)
    local pref_words = vim.split(preffix, " ", true)
    return pref_words[#pref_words]
  end

  -- Strip the end of the cmdline
  cmdline = cmdline:sub(1, cursorpos)

  local buf = a.nvim_get_current_buf()

  -- Remove command name
  local text = cmdline:gsub("^.-%w", "")

  local parser = utils.get_parser(buf)
  if not parser then return end

  local query_text, parts = split_argument(text)

  if #parts > 0 then
    local function make_items(cname, query, preffix, suffix)
      preffix = preffix_massage(preffix)
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
    local query = q.get(parser, query_text)

    -- Two case, either we are at the start of the string, or after an @
    local start_cname, end_cname, cname = part:find("^(%w*)")

    if end_cname == #part then
      -- Start of the string
      return make_items(cname, query, preffix_massage(text:sub(1, #text - #part)), ":")
    else
      start_cname, end_cname, cname = part:find("@(%w*)")
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
    local language = ts.inspect_language(parser:lang())

    local start_suffix, _, suffix = text:find("(%w*)$")

    -- This needs massage to be used
    local preffix = preffix_massage(text:sub(1, start_suffix - 1))

    local last_char = preffix:sub(#preffix)

    if last_char == [["]] or last_char == "(" then
      -- Complete nodes because we start by " or (
      -- Symbol desc is a table {name, is_terminal}
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
    elseif last_char == "$" then
      -- Complete query template $
      for _, template in ipairs(q.list_templates()) do
        if vim.startswith(template, suffix) then
          table.insert(completions, preffix .. template .. ":")
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

  local query = q.get(parser, query_text)
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

M.HL_MAPPING = setmetatable({
  "ArchitextSearch1",
  "ArchitextSearch2",
  "ArchitextSearch3",
  "ArchitextSearch4",
  "ArchitextSearch5",
  "ArchitextSearch6",
}, {
  __index = function(table, key)
    return rawget(table, (key % #table) + 1)
  end
})

function M.run(text, start_row, end_row, buf, preview_ns)
  buf = buf or a.nvim_get_current_buf()

  local parser = utils.get_parser(buf)
  if not parser then return end

  local query, changes = parse_argument(parser, text)

  if preview_ns then
    -- TODO: make the preview more interesting by displaying unset captures differently
    local root = parser:parse()[1]:root()
    local display = {}

    for cid, _ in pairs(query.captures) do
      if not changes[cid] or #changes[cid] == 0 then
        display[cid] = true
      end
    end

    for cid, node in query:iter_captures(root, buf, start_row - 1, end_row) do
      if display[cid] then
        local start, start_col, _end, end_col = node:range()
        vim.api.nvim_buf_set_extmark(buf, preview_ns, start, start_col, {
        end_row = _end,
        end_col = end_col,
        hl_group = M.HL_MAPPING[cid],
        hl_mode = "replace",
        priority = 1000,
        })
      end
    end
  end

  edit.edit(buf, parser, query, changes, start_row - 1, end_row) -- Because end_row is exclusive
end

return M
