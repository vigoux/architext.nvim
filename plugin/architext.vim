" Last Change: 2020 Sep 04

if exists("g:loaded_architext")
	finish
endif

command! -nargs=0 ArchitextREPL lua require"architext.repl".setup_repl()

command! -nargs=1 -range=% Architext lua require'architext.cmd'.run(<f-args>, <line1>, <line2>)
command! -nargs=1 -range=% A lua require'architext.cmd'.run(<f-args>, <line1>, <line2>)
