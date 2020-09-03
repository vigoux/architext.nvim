local ts = vim.treesitter
local a = vim.api

local M = {}

local QUERY_STATE = 1
local CAPTURE_STATE = 2

local function node_to_lsp_range(node)
  local start_line, start_col, end_line, end_col = node:range()
  local rtn = {}
  rtn.start = { line = start_line, character = start_col }
  rtn['end'] = { line = end_line, character = end_col }
  return rtn
end

local function get_prompt_funcs(repl_buf, buf, win)

  local parser = ts.get_parser(buf)
  local current_query
  local state = QUERY_STATE
  local capture_index = 1
  local capture_change_table

  local prompts = {
    [QUERY_STATE] = function() return "Query" end,
    [CAPTURE_STATE] = function()
      return string.format("Capture %s", current_query.captures[capture_index])
    end
  }

  local transition = {
    [QUERY_STATE] = function()
      if not current_query.captures[capture_index] then
        return QUERY_STATE
      end
      capture_change_table = {}
      capture_index = 1
      return CAPTURE_STATE
    end,

    [CAPTURE_STATE] = function()
      if not current_query.captures[capture_index] then
        -- We need to compute and apply the changes now
        local edits = {}

        local buf_line_count = a.nvim_buf_line_count(buf)

        for pattern, match in current_query:iter_matches(parser:parse():root(), buf,
                                                         0, buf_line_count + 1) do
          for id,node in pairs(match) do
            local newText = capture_change_table[id]

            if newText and #newText > 0 then
              table.insert(edits, {
                range = node_to_lsp_range(node),
                newText = newText
              })
            end
          end
        end

        vim.lsp.util.apply_text_edits(edits, buf)

        current_query = nil
        return QUERY_STATE
      else
        return CAPTURE_STATE
      end
    end
  }

  local function make_transition()
    state = transition[state]()
    vim.fn.prompt_setprompt(repl_buf, prompts[state]() .. "> ")
  end

  local function prompt_cb(text)
    -- TODO(vigoux): there can be other types of queries
    -- This is a query
    if state == QUERY_STATE then
      current_query = ts.parse_query(parser.lang, text)
    elseif state == CAPTURE_STATE then
      capture_change_table[capture_index] = text
      capture_index = capture_index + 1
    end

    make_transition()
  end

  local function interrupt_cb()
    a.nvim_win_close(win, true)
    a.nvim_buf_set_option(repl_buf, 'buftype', 'nofile')
    vim.cmd(string.format("bwipe! %d", repl_buf))
  end

  return prompt_cb, interrupt_cb
end

function M.setup_repl(bufnr)
  local buf = bufnr or a.nvim_get_current_buf()
  vim.cmd[[split]]
  local win = a.nvim_get_current_win()

  local repl_buf = a.nvim_create_buf(false, true)

  local p_cb, i_cb = get_prompt_funcs(repl_buf, buf, win)

  vim.fn.prompt_setcallback(repl_buf, p_cb)
  vim.fn.prompt_setinterrupt(repl_buf, i_cb)

  vim.fn.prompt_setprompt(repl_buf, "Query> ")

  a.nvim_buf_set_option(repl_buf, 'buftype', 'prompt')
  a.nvim_buf_set_name(repl_buf, [[Architext REPL]])
  a.nvim_win_set_buf(win, repl_buf)

  vim.cmd[[normal! i]]
end

return M
