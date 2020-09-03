" Last Change: 2020 Sep 03

if exists("g:loaded_architext")
	finish
endif

command! -nargs=0 ArchitextREPL lua require"architext.repl".setup_repl()
