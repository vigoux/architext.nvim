" Last Change: 2020 Sep 04

function! architext#complete(lead, cmdline, pos)
	return luaeval("require'architext.cmd'.complete(_A[1], _A[2])", [a:cmdline, a:pos])
endfunction
