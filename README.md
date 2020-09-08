[![asciicast](https://asciinema.org/a/357784.svg)](https://asciinema.org/a/357784)

# architext.nvim

A structural editing plugin for neovim, powered by treesitter.

# Installation

Use the only package manager :

```lua
use "vigoux/architext.nvim"
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

## Query templates

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

# Credits

Thanks @tjdevries for the name.
