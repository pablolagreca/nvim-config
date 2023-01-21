require('plugins')
require('lightline')
require('config')
require('lightline')
vim.opt.relativenumber=true
vim.opt.autoindent=true
vim.opt.tabstop=4
vim.opt.shiftwidth=4
vim.opt.smarttab=true
vim.opt.softtabstop=4
-- vim.opt.mouse=a
vim.opt.undofile=true
vim.opt.timeoutlen=500
vim.opt.encoding='UTF-8'
vim.opt.termguicolors=true

-- vim.opt.completeopt-=preview  --For No Previews


vim.cmd(':colorscheme jellybeans')

-- air-line
vim.g.airline_powerline_fonts = 1

if vim.g.airline_symbols == nil then
    vim.g.airline_symbols = {}
end

-- airline symbols
vim.g.airline_left_sep = ''
vim.g.airline_left_alt_sep = ''
vim.g.airline_right_sep = ''
vim.g.airline_right_alt_sep = ''
vim.g.airline_symbols.branch = ''
vim.g.airline_symbols.readonly = ''
vim.g.airline_symbols.linenr = ''
