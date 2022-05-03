local a_trans = require'architext.transform'
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
    local start, stop, pref, capture = string.find(text_left, "(.-)(@[a-zA-Z.:]+)")

    -- We have a capture here
    if start and stop and pref and capture then
      local pref_corr = pref:gsub("@@", "@")
      table.insert(to_evaluate, pref_corr)
      -- Strip @
      capture = capture:sub(2)

      -- Maybe there is the transform
      local cname, transform = unpack(vim.split(capture, ":", true))

      local index = vim.fn.index(query.captures, cname)
      if index < 0 then return {} end

      table.insert(to_evaluate, {capt = index + 1, trans = transform})

      text_left = text_left:sub(stop + 1)
    else
      local text_corr = text_left:gsub("@@", "@")
      table.insert(to_evaluate, text_corr)
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
    if type(thing) == "table" and thing.capt and match[thing.capt] then
      local additional_text = a_trans.apply(thing.trans, buf, match[thing.capt])
      final_text = final_text .. additional_text
    else
      final_text = final_text .. thing
    end
  end

  return final_text
end

function M.edit(buf, parser, query, capture_changes, start_row, end_row)
  start_row = start_row or 0
  end_row = end_row or a.nvim_buf_line_count(buf) + 1

  -- We need to compute and apply the changes now
  local edits = {}

  local compiled_changes = compile_changes(capture_changes, query)

  for _, match in query:iter_matches(parser:parse()[1]:root(), buf,
    start_row, end_row) do

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

  vim.lsp.util.apply_text_edits(edits, buf, 'utf-8')
end
return M
