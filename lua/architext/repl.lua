local ts = vim.treesitter
local a = vim.api
local edit = require'architext.edit'

local M = {}

local QUERY_STATE = 1
local CAPTURE_STATE = 2

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
        edit.edit(buf, parser, current_query, capture_change_table)
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
