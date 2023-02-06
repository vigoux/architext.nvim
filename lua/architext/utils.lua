local nts_present, nts_parsers = pcall(require, 'nvim-treesitter.parsers')

local M = {}

if nts_present then
  M.get_parser = nts_parsers.get_parser
else
  M.get_parser = vim.treesitter.get_parser
end

return M
