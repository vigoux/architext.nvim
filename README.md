[![asciicast](https://asciinema.org/a/357694.svg)](https://asciinema.org/a/357694)

# architext.nvim

A structural editing plugin for neovim, powered by treesitter.

# Installation

Use the only package manager :

```lua
use "vigoux/architext.nvim"
```

# Usage

1. Open a buffer, and be sure to have the correct parsers installed for the buffers filetype.
2. `:ArchitextREPL`
3. Type your query, with captures for the things we want to replace / refer to
4. Type the replacements for them (empty to not replace), and refer to a capture using `@{capture
   name}`
5. Hit `<CR>` your edits happen !

# Credits

Thanks @tjdevries for the name.
