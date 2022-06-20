local cmd = require 'architext.cmd'
local a = vim.api

local function create_command(name)
  a.nvim_create_user_command(name, function(args)
    cmd.run(args.args, args.line1, args.line2, a.nvim_get_current_buf())
  end, {
    nargs = 1,
    range = "%",
    complete = cmd.complete,
    desc = "Runs ratatoskr in the current buffer",
    force = true,
    preview = function(args, ns, buf)
      cmd.run(args.args, args.line1, args.line2, buf)
    end
  })
end

create_command "A"
create_command "Architext"
