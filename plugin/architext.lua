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
      cmd.run(args.args, args.line1, args.line2, buf, ns)
      return 2
    end
  })
end

for _, gname in ipairs(cmd.HL_MAPPING) do
  a.nvim_set_hl(0, gname, { link = "Search", default = true })
end

create_command "A"
create_command "Architext"
