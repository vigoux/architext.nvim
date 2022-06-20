" Last Change: 2022 Jun 20

if exists("g:loaded_architext")
	finish
endif

lua require'architext'

command! -nargs=0 ArchitextREPL lua require"architext.repl".setup_repl()
