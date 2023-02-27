--ocal Hydra = require("hydra")
-- local cmd = require('hydra.keymap-util').cmd
--
-- local hint = [[
--  _f_: files          _p_: projects
--  _t_: live grep      _s_: grep string
--  _H_: header         _S_: symbols
--  _R_: register       _P_: plugins
--  _h_: vim help       _c_: execute command
--  _k_: keymaps        _;_: commands history
--  _O_: options        _?_: search history
--  _/_: search in file _m_: make
--  _r_: recently opened files
--
--  ^
--  _<Enter>_: Telescope   _q_: Exit
-- ]]
--
-- Hydra({
--   name = "Telescope",
--   hint = hint,
--   config = {
--     invoke_on_body = true,
--     hint = {
--       position = "middle",
--       border = "rounded",
--     },
--   },
--   mode = "n",
--   body = "<Leader>s",
--   heads = {
--     { "c", cmd("Telescope commands"), { desc = "execute command" } },
--     { "f", cmd("Telescope find_files({ initial_mode = 'insert' })") },
--     { "t", cmd("Telescope live_grep") },
--     { "h", cmd("Telescope help_tags"), { desc = "vim help" } },
--     { "H", cmd("Telescope heading") },
--     { "k", cmd("Telescope keymaps") },
--     { "O", cmd("Telescope vim_options") },
--     { "m", cmd("Telescope make") },
--     { "p", cmd("Telescope projects"), { desc = "projects" } },
--     { "P", cmd("Telescope packer") },
--     { "r", cmd("Telescope oldfiles"), { desc = "recently opened files" } },
--     { "R", cmd("Telescope registers") },
--     { "s", cmd("Telescope grep_string"), { desc = "Text under cursor" } },
--     { "S", cmd("Telescope symbols") },
--     { "/", cmd("Telescope current_buffer_fuzzy_find"), { desc = "search in file" } },
--     { "?", cmd("Telescope search_history"), { desc = "search history" } },
--     { ";", cmd("Telescope command_history"), { desc = "command-line history" } },
--     { "<Enter>", cmd("Telescope"), { exit = true, desc = "list all pickers" } },
--     { "q", nil, { exit = true, nowait = true } },
--   },
-- })
local Hydra = require('hydra')
local cmd = require('hydra.keymap-util').cmd

local hint = [[
 _f_: files          _m_: marks
 _o_: old files      _g_: live grep
 _/_: search in file
 _F_: files in home  _s_: sessions

 _r_: resume         _u_: undotree
 _h_: vim help       _c_: execute command
 _k_: keymaps        _;_: commands history 
 _O_: options        _?_: search history

 _<Enter>_: Telescope           _<Esc>_
]]

Hydra({
   name = 'Telescope',
   hint = hint,
   config = {
      color = 'teal',
      invoke_on_body = true,
      hint = {
         position = 'middle',
         border = 'rounded',
      },
   },
   mode = 'n',
   body = '<Leader>s',
   heads = {
      { 'f', cmd 'Telescope find_files' },
      { 'F', ':lua require("telescope.builtin").find_files({ cwd = "~", hidden = true})<cr>' },
      { 'g', cmd 'Telescope live_grep' },
      { 'o', cmd 'Telescope oldfiles', { desc = 'recently opened files' } },
      { 'h', cmd 'Telescope help_tags', { desc = 'vim help' } },
      { 'm', cmd 'MarksListBuf', { desc = 'marks' } },
      { 'k', cmd 'Telescope keymaps' },
      { 'O', cmd 'Telescope vim_options' },
      { 'r', cmd 'Telescope resume' },
      { 's', cmd 'SessionManager load_session' },
      { 'p', cmd 'Telescope projects', { desc = 'projects' } },
      { '/', cmd 'Telescope current_buffer_fuzzy_find', { desc = 'search in file' } },
      { '?', cmd 'Telescope search_history',  { desc = 'search history' } },
      { ';', cmd 'Telescope command_history', { desc = 'command-line history' } },
      { 'c', cmd 'Telescope commands', { desc = 'execute command' } },
      { 'u', cmd 'silent! %foldopen! | UndotreeToggle', { desc = 'undotree' }},
      { '<Enter>', cmd 'Telescope', { exit = true, desc = 'list all pickers' } },
      { '<Esc>', nil, { exit = true, nowait = true } },
   }
})
