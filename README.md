[![asciicast](https://asciinema.org/a/357784.svg)](https://asciinema.org/a/357784)

# architext.nvim

A structural editing plugin for neovim, powered by treesitter.

# Installation

Use the only package manager :

```lua
use {
  "vigoux/architext.nvim"
  requires = {
    -- Not required, only used to refine the language resolution
    "nvim-treesitter/nvim-treesitter"
  }
}
```

# Usage

## Using the REPL

1. Open a buffer, and be sure to have the correct parsers installed for the buffers filetype.
2. `:ArchitextREPL`
3. Type your query, with captures for the things we want to replace / refer to
4. Type the replacements for them (empty to not replace), and refer to a capture using `@{capture
   name}`
5. Hit `<CR>` your edits happen !

## Using `:Architext`

First, open a buffer, be sure to have a parser for it installed.

Then, you can use the `:Architext` (or `:A` in short) command.
This is a `substitue` like command, with this signature :
```
:{range}Architext/{query}(/{capture name}:{replacement})*
```

Which instanciates into this, to replace every occurence of the `identifier` `foo` by `bar` :

```
:Architext/((identifier) @i (#eq? @i "foo"))/i:bar/
```

You can refer to captured nodes like this, lets say you want to wrap an identifier into a function:

```
:A/((identifier) @wrapit (#eq? @wrapit "foo"))/wrapit:func(@wrapit)/
```

Additional notes :

- The delimiter can be anything, and is specified by the first character after the command
- You can insert a literal `@` like so `@@`

### Query templates

You can recall query templates by starting the query argument with a `$`.
Query templates are called like so :

```
$TEMPLATE:arg1:arg2:...
```

The `:` can be replaced by any non uppercase character (though, `:` is recommended).

If you want to omit an argument :

```
$TEMPLATE::arg2:...
```

While this might seem useful, and robust, it is actually not, and no check is done on the number of
arguments you pass to a query, and wether they are expected.

### Writing templates

Writing templates is easy, and follows an over-simplified snippet-like syntax, for example the
builtin `IDENT` template looks like this :

```
((identifier) @id (#eq? @id "$1"))
```

Arguments of the template are called with `${number}`, 1-based (why not ?).

## Using the API

The main function une `architext` is `architext.edit.edit`, which
contains all the machinery for handling replacements on (non-template)
queries.

The signature is as follows:
```lua
edit(buf, parser, query, changes, start_row, end_row)
```

The arguments are thus:

1. The buffer number where the edits take place
2. The parser to use for that given buffer
3. The query used as reference for matching the tree (think the first
   part of the `:Architext` command)
4. The actual changes to perform, in the form of a map between capture
   names and their replacements (think, the rest of the `:Architext`
   command): note the there _must not be the leading `@` in the
   capture names_.
5. The start row (inclusive)
6. The end row (inclusive)

As an example, here is the API to swap the first two arguments of
function calls in lua:

```lua
local curbuf = vim.api.nvim_get_current_buf()
local parser = vim.treesitter.get_parser(curbuf)

local query = vim.treesitter.query.parse("lua", [[
  (arguments 
    . (_) @first
    . (_) @second)
]])

require'architext.edit'.edit(curbuf, parser, query, { first =
"@second", second = "@first" }, 0, 10)
```

# Credits

Thanks @tjdevries for the name.
