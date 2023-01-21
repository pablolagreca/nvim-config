vim.cmd "set noshowmode"
-- lightline-buffer configuration
vim.g['lightline'] = {
  colorscheme = 'one',
  active = {
    left = {{'mode', 'paste'}, {'readonly', 'filename', 'modified'}}
  },
  tabline = {
    left = {{'buffers'}},
    right = {{'close'}}
  },
  component_expand = {
    buffers = 'lightline#bufferline#buffers'
  },
  component_type = {
    buffers = 'tabsel'
  },
  bufferline = {
	  enable_devicons=1
  }
}

vim.cmd "set showtabline=2"
