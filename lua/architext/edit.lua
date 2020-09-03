local ts = vim.treesitter
local ts_q = require'vim.treesitter.query'
local a = vim.api

local M = {}

local function node_to_lsp_range(node)
  local start_line, start_col, end_line, end_col = node:range()
  local rtn = {}
  rtn.start = { line = start_line, character = start_col }
  rtn['end'] = { line = end_line, character = end_col }
  return rtn
end

-- @thing is a reference to the capture @thing
-- @@ is a literal @
local function parse_replacement(text, query)
  local text_left = text
  local to_evaluate = {}

  repeat
    local start, stop, rest, capture = string.find(text_left, "(.-)(@[a-zA-Z.]+)")

    -- We have a capture here
    if start and stop and rest and capture then
      table.insert(to_evaluate, rest)
      -- Strip @
      capture = capture:sub(2)

      local index = vim.fn.index(query.captures, capture)
      if index < 0 then return {} end

      table.insert(to_evaluate, index + 1)

      text_left = text_left:sub(stop + 1)
    else
      table.insert(to_evaluate, text_left)
      text_left = ""
    end
  until not text_left or #text_left == 0

  return to_evaluate
end

local function compile_changes(changes, query)
  local compiled = {}

  for i, change in pairs(changes) do
    compiled[i] = parse_replacement(change, query)
  end

  return compiled
end

local function evaluate_change(buf, change, match)
  local final_text = ""

  for _, thing in ipairs(change) do
    if type(thing) == "number" then
      final_text = final_text .. ts_q.get_node_text(match[thing], buf)
    else
      final_text = final_text .. thing
    end
  end

  return final_text
end

function M.edit(buf, parser, query, capture_changes)
  -- We need to compute and apply the changes now
  local edits = {}

  local buf_line_count = a.nvim_buf_line_count(buf)

  local compiled_changes = compile_changes(capture_changes, query)

  for pattern, match in query:iter_matches(parser:parse():root(), buf,
    0, buf_line_count + 1) do

    for id, replacement in pairs(compiled_changes) do
      local newText = evaluate_change(buf, replacement, match)

      if newText and #newText > 0 then

        table.insert(edits, {
          range = node_to_lsp_range(match[id]),
          newText = newText
        })
      end
    end
  end

  vim.lsp.util.apply_text_edits(edits, buf)
end
return M
