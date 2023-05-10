local ts = vim.treesitter

local M = {}

local transforms = {
  ["upper"] = function(bufnr, node)
    local node_text = ts.get_node_text(node, bufnr)
    if not node_text then return end

    return vim.fn.toupper(node_text)
  end,

  ["lower"] = function(bufnr, node)
    local node_text = ts.get_node_text(node, bufnr)
    if not node_text then return end

    return vim.fn.tolower(node_text)
  end
}

function M.apply(transform_name, buf, node)
  local transform = transforms[transform_name or "__EMPTY__"]

  if not transform then return ts.get_node_text(node, buf) end
  return transform(buf, node) or ts.get_node_text(node, buf)
end

function M.add(name, handler)
  transforms[name] = handler
end

return M
