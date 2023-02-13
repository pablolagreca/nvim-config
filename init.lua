local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  is_bootstrap = true
  vim.fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path }

end


-- TODO add telescope dap
-- https://github.com/nvim-telescope/telescope-dap.nvim

-- Autocommand that reloads neovim whenever you save this file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost init.lua source <afile> | PackerSync
  augroup end
]])

local status, packer = pcall(require, 'packer')
if not status then
  return
end


require('packer').startup(function(use)
  -- Package manager
  use 'wbthomason/packer.nvim'

  -- use 'bluz71/vim-nightfly-guicolors'
  use 'shaunsingh/nord.nvim'

  use { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    requires = {
      -- Automatically install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      'j-hui/fidget.nvim',

      -- Additional lua configuration, makes nvim stuff amazing
      'folke/neodev.nvim',
    },
  }

  use { -- Autocompletion
    'hrsh7th/nvim-cmp',
    requires = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path', 'rcarriga/cmp-dap', 'hrsh7th/cmp-vsnip', 'hrsh7th/vim-vsnip' },
  }

  -- icons in Autocompletion
  use 'onsails/lspkind.nvim'

  use { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    run = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
  }

  use { -- Additional text objects via treesitter
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
  }
  -- Git related plugins
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'
  use 'lewis6991/gitsigns.nvim'

  use 'navarasu/onedark.nvim' -- Theme inspired by Atom
  use 'nvim-lualine/lualine.nvim' -- Fancier statusline
  use 'lukas-reineke/indent-blankline.nvim' -- Add indentatio
  use 'numToStr/Comment.nvim' -- "gc" to comment visual regions/lines
  use 'tpope/vim-sleuth' -- Detect tabstop and shiftwidth automatically

  -- Fuzzy Finder (files, lsp, etc)
  use { 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { 'nvim-lua/plenary.nvim' } }

  -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }

  -- Ranger for file explorer
  use 'francoiscabrol/ranger.vim'
  use 'rbgrouleff/bclose.vim'

  -- Whichkey
  use { 'folke/which-key.nvim', config = function()
    vim.opt.timeout = true
    vim.opt.timeoutlen = 300
  end,
  }
  -- FloatTerm
  use 'voldikss/vim-floaterm'

  -- NVIM tree
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons',
    },
    tag = 'nightly'
  }

  -- Markdown
  -- install without yarn or npm
  use 'iamcco/markdown-preview.nvim'
  -- ndap client
  use 'mfussenegger/nvim-dap'
  use 'theHamsta/nvim-dap-virtual-text'
  use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } }
  -- Java jdtls plugin
  use 'mfussenegger/nvim-jdtls'
  -- TODO configure well Saga once nvim 0.9 it's out
  -- Lsp Saga for popups in LSP calls
  use({
    "glepnir/lspsaga.nvim",
    branch = "main",
  })

  use 'tpope/vim-surround'
  use 'windwp/nvim-autopairs'
  use {
    'phaazon/hop.nvim',
    branch = 'v2',
  }

  -- Golang configuration
  use 'fatih/vim-go'
  -- Pick windows plugin
  use 'https://gitlab.com/yorickpeterse/nvim-window'
  -- Persist breakpoints after restart nvim
  use { 'Weissle/persistent-breakpoints.nvim' }
  -- Snippets support 
  use({"L3MON4D3/LuaSnip", tag = "v1.2.1"})

  -- Add custom plugins to packer from ~/.config/nvim/lua/custom/plugins.lua
  local has_plugins, plugins = pcall(require, 'custom.plugins')
  if has_plugins then
    plugins(use)
  end

  if is_bootstrap then
    require('packer').sync()
  end
end)

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
--
-- You'll need to restart nvim, and then it will work.
if is_bootstrap then
  print '=================================='
  print '    Plugins are being installed'
  print '    Wait until Packer completes,'
  print '       then restart nvim'
  print '=================================='
  return
end

-- Automatically source and re-compile packer whenever you save this init.lua
local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  command = 'source <afile> | silent! LspStop | silent! LspStart | PackerCompile',
  group = packer_group,
  pattern = vim.fn.expand '$MYVIMRC',
})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Make line numbers default
vim.wo.number = true
vim.opt.relativenumber = true

-- Indenting
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- cursor line
vim.opt.cursorline = true
vim.opt.background = 'dark'
vim.opt.signcolumn = 'yes'

-- clipboard
vim.opt.clipboard:append("unnamedplus")

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.iskeyword:append('-')

-- Enable mouse mode
vim.opt.mouse = 'a'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.updatetime = 250
vim.wo.signcolumn = 'yes'

require('nord').set()
-- Set colorscheme
vim.opt.termguicolors = true
-- vim.cmd [[colorscheme nord]]

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Move to normal mode more easy
vim.keymap.set('i', 'jk', '<ESC>')


-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Set lualine as statusline
-- See `:help lualine.txt`
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = nord,
    component_separators = '|',
    section_separators = '',
  },
}




-- Enable Comment.nvim
require('Comment').setup()

require('hop').setup({
  case_insensitive = false
})

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help indent_blankline.txt`
require('indent_blankline').setup {
  char = '┊',
  show_trailing_blankline_indent = false,
}

-- Gitsigns
-- See `:help gitsigns.txt`
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require('nvim-treesitter.configs').setup {
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'markdown', 'python', 'rust', 'typescript', 'help', 'vim', 'java' },

  highlight = { enable = true },
  indent = { enable = true, disable = { 'python' } },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<c-space>',
      node_incremental = '<c-space>',
      scope_incremental = '<c-s>',
      node_decremental = '<c-backspace>',
    },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
    swap = {
      enable = true,
      swap_next = {
        ['<leader>a'] = '@parameter.inner',
      },
      swap_previous = {
        ['<leader>A'] = '@parameter.inner',
      },
    },
  },
}

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- tsserver = {},
}

-- Setup neovim lua configuration
require('neodev').setup()
--
-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Setup mason so it can manage external tooling
require('mason').setup()

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
    }
  end,
}

-- Turn on lsp status information
require('fidget').setup()

-- nvim-cmp setup
local cmp = require 'cmp'
local luasnip = require 'luasnip'

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'path' },
    { name = 'buffer' },
    { name = 'vsnip' },
  },
  formatting = {
    format = require'lspkind'.cmp_format({
      mode = 'symbol_text',
      max_width = 50,
      ellipsis_char = '...',
      before = function (_, vim_item) 
        return vim_item
      end
    })
  },
  enabled = function() -- for cmp-dap
    return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
        or require("cmp_dap").is_dap_buffer()
  end
}

--for cmp-dap
require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
  sources = {
    { name = "dap" },
  },
})

-- Nvim-tree configuration
-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- change color for arrows in tree to light blue
vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

require("nvim-tree").setup({
  renderer = {
    icons = {
      glyphs = {
        folder = {
          arrow_closed = "",
          arrow_open = "",
        }
      }
    }
  },
  -- disable window_picker for
  -- explorer to work well with
  -- window splits
  actions = {
    open_file = {
      window_picker = {
        enable = false,
      },
    },
  },
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
  }
})

-- Autopairs configuration
-- import nvim-autopairs safely
local autopairs_setup, autopairs = pcall(require, "nvim-autopairs")
if not autopairs_setup then
  return
end


-- LSP Saga configuration
require('lspsaga').setup({
  -- keybinds for navigation in lspsaga window
  scroll_preview = { scroll_down = "<C-f>", scroll_up = "<C-b>" },
  -- use enter to open file with definition preview
  definition = {
    edit = "<CR>",
  },
  ui = {
    colors = {
      normal_bg = "#022746",
    },
  },
})


-- configure autopairs
autopairs.setup({
  check_ts = true, -- enable treesitter
  ts_config = {
    lua = { "string" }, -- don't add pairs in lua string treesitter nodes
    javascript = { "template_string" }, -- don't add pairs in javscript template_string treesitter nodes
    java = false, -- don't check treesitter on java
  },
})

-- import nvim-autopairs completion functionality safely
local cmp_autopairs_setup, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
if not cmp_autopairs_setup then
  return
end

-- import nvim-cmp plugin safely (completions plugin)
local cmp_setup, cmp = pcall(require, "cmp")
if not cmp_setup then
  return
end

-- make autopairs and completion work together
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())


vim.fn.sign_define('DapBreakpoint', { text = '🟥', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '▶️', texthl = '', linehl = '', numhl = '' })

require('persistent-breakpoints').setup{
	load_breakpoints_event = { "BufReadPost" }
}

local dap, dapui = require("dap"), require("dapui")
dapui.setup({
  icons = { expanded = "", collapsed = "", current_frame = "" },
  mappings = {
    -- Use a table to apply multiple mappings
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
  },
  -- Use this to override mappings for specific elements
  element_mappings = {
    -- Example:
    -- stacks = {
    --   open = "<CR>",
    --   expand = "o",
    -- }
  },
  -- Expand lines larger than the window
  -- Requires >= 0.7
  expand_lines = vim.fn.has("nvim-0.7") == 1,
  -- Layouts define sections of the screen to place windows.
  -- The position can be "left", "right", "top" or "bottom".
  -- The size specifies the height/width depending on position. It can be an Int
  -- or a Float. Integer specifies height/width directly (i.e. 20 lines/columns) while
  -- Float value specifies percentage (i.e. 0.3 - 30% of available lines/columns)
  -- Elements are the elements shown in the layout (in order).
  -- Layouts are opened in order so that earlier layouts take priority in window sizing.
  layouts = {
    {
      elements = {
        -- Elements can be strings or table with id and size keys.
        { id = "scopes", size = 0.25 },
        "breakpoints",
        "stacks",
        "watches",
      },
      size = 40, -- 40 columns
      position = "left",
    },
    {
      elements = {
        "repl",
        "console",
      },
      size = 0.25, -- 25% of total lines
      position = "bottom",
    },
  },
  controls = {
    -- Requires Neovim nightly (or 0.8 when released)
    enabled = true,
    -- Display controls in this element
    element = "repl",
    icons = {
      pause = "",
      play = "",
      step_into = "",
      step_over = "",
      step_out = "",
      step_back = "",
      run_last = "",
      terminate = "",
    },
  },
  floating = {
    max_height = nil, -- These can be integers or a float between 0 and 1.
    max_width = nil, -- Floats will be treated as percentage of your screen.
    border = "single", -- Border style. Can be "single", "double" or "rounded"
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
  render = {
    max_type_length = nil, -- Can be integer or nil.
    max_value_lines = 100, -- Can be integer or nil.
  }
})
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
dap.configurations.java = {
  {
    type = 'java',
    request = 'attach',
    name = "Debug (attach) - Remote",
    hostName = "127.0.0.1",
    port = 5005
  }
}

function show_dap_centered_scopes()
  local widgets = require 'dap.ui.widgets'
  widgets.centered_float(widgets.scopes)
end

function attach_to_debug()
  dap.continue()
end

require('nvim-dap-virtual-text').setup()

-- run debug
function get_test_runner(test_name, debug)
  if debug then
    return 'mvn test -o -Dmaven.surefire.debug -Dtest="' .. test_name .. '"'
  end
  return 'mvn test -o -Dtest="' .. test_name .. '"'
end

function run_java_test_method(debug)
  local utils = require 'utils'
  local method_name = utils.get_current_full_method_name("\\#")
  vim.cmd('tab new "test " .. method_name')
  vim.cmd('term ' .. get_test_runner(method_name, debug))
end

function run_java_test_class(debug)
  local utils = require 'utils'
  local class_name = utils.get_current_full_class_name()
  vim.cmd('tab new "test " .. class_name')
  vim.cmd('term ' .. get_test_runner(class_name, debug))
end

function get_spring_boot_runner(profile, debug)
  local debug_param = ""
  if debug then
    debug_param = ' -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005" '
  end

  local profile_param = ""
  if profile then
    profile_param = " -Dspring-boot.run.profiles=" .. profile .. " "
  end

  return 'mvn spring-boot:run -o ' .. profile_param .. debug_param
end

function run_spring_boot(debug)
  vim.cmd('tab new "running app"')
  vim.cmd('term ' .. get_spring_boot_runner(method_name, debug))
end

--TODO CMP setup for debugger REPL: https://www.youtube.com/watch?v=kbRIosrvof0



-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
--

local M = {}
local hop = require('hop')

function M.setup()
  local whichkey = require "which-key"

  local conf = {
    window = {
      border = "single", -- none, single, double, shadow
      position = "bottom", -- bottom, top
    },
  }

  local opts = {
    mode = "n", -- Normal mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = false, -- use `nowait` when creating keymaps
  }

  local optsTerminal = {
    mode = "t", -- Normal mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = false, -- use `nowait` when creating keymaps
  }

  local mappings = {
    --["l"] = { "<cmd>:source .session.vim<cr>" },
    ["W"] = { "<cmd>update!<CR>", "Save" },
    -- ["q"] = { "<cmd>q!<CR>", "Quit" },
    ["?"] = { "Find recently open files" },
    ["<space>"] = { "Find existing buffers" },
    ["/"] = { "Fuzzily search in current file" },
    --["x"] = { "<cmd>Win<CR>", "Select window" },

    b = {
      name = "Buffer",
      c = { "<Cmd>bd!<Cr>", "Close current buffer" },
      D = { "<Cmd>%bd|e#|bd#<Cr>", "Delete all buffers" },
    },

    c = {
      name = "Code",
      a = { "<cmd>Lspsaga code_action<CR>", "Code action" },
      f = { ":lua vim.lsp.buf.formatting()<cr>", "Format code" },
      r = {
        name = "Rename",
        r = { "<cmd>Lspsaga rename<CR>", "Rename symbol" },
        w = { "<cmd>Lspsaga rename ++project<CR>", "Rename word" },
      }
    },

    d = {
      name = "Debug",
      a = { ":lua attach_to_debug()<cr>", "Attach to debug" },
      t = {
        name = "Test",
        m = { ":lua run_java_test_method(true)<cr>", "Test method" },
        c = { ":lua run_java_test_class(true)<cr>", "Test class" }
      },
      y = { ":lua require'jdtls'.test_nearest_method()<cr>", "Test nearest method" },
      o = { ":lua require('dapui').open()<cr>", "Open debugger UI" },
      c = { ":lua require('dapui').close()<cr>", "Close debugger UI" },
      C = { ":lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>", "Clear all breakpoints"},
      b = { ":lua require'dap'.toggle_breakpoint()<cr>", "Toogle breakpoint" },
      B = { ":lua require('persistent-breakpoints.api').set_conditional_breakpoint()<cr>", "Toogle conditional endpoint" },
      l = { ":lua require'dap'.toggle_breakpoint(nil, nil, vim.fn.input('Log: '))<cr>", "Toogle log breakpoint" },
      r = { ":lua request'dap'.repl.open()<cr>", "Open REPL" },
      s = { ":lua show_dap_centered_scopes()<cr>", "Show debug scopes" }
    },
    
    e = {
      name = "Edit",
      o = { "o<Esc><cr>", "Add blank line" },
      O = { "O<Esc><cr>", "Add blank line up" },
    },

    g = {
      name = "Git",
      d = { "<cmd>Gitsigns diffthis<cr>", "Diff file" },
      n = { "<cmd>Gitsigns next_hunk<cr>", "Next change" },
      p = { "<cmd>Gitsigns prev_hunk<cr>", "Previous change"},
      r = { "<cmd>Gitsigns reset_hunk<cr>", "Reset change"},
    },

    j = {
      name = "Jump",
      c = { "<cmd>HopChar1<cr>", "Jump to char" },
      j = { "<cmd>HopChar2<cr>", "Jump to char2" },
      l = { "<cmd>HopLine<cr>", "Jump to line" },
    },

    s = {
      name = "Search",
      d = { "Diagnostics" },
      f = { "Files by name" },
      F = { ":lua require('telescope.builtin').find_files({ cwd = '~', hidden = true})<cr>", "Files in home by name" },
      g = { "<cmd>Telescope live_grep<cr>", "Files by grep" },
      h = { "Help" },
    },

    u = {
      name = "Utilities",
      d = { "<cmd>CD<cr>", "Show diff" },
      D = { "<cmd>TCV<cr>", "Enable/disable diff" },
      t = { "<cmd>FloatermNew<cr>", "New terminal" },
      u = { "<cmd>FloatermToggle<cr>", "Terminal toggle" },
      y = { "<cmd>FloatermNext<cr>", "Next terminal" },
    },

    r = {
      name = "Run",
      t = {
        name = "Test",
        m = { ":lua run_java_test_method()<cr>", "Test method" },
        c = { ":lua run_java_test_class()<cr>", "Test class" }
      },
    },
    t = {
      name = "Explorer / Tabs",
      o = { "<cmd>tabnew<cr>", "Open new tab" },
      x = { "<cmd>tabclose<cr>", "Close tab" },
      n = { "<cmd>tabn<cr>", "Next tab" },
      p = { "<cmd>tabp<cr>", "Previous tab" },
      t = { "<cmd>NvimTreeFocus<cr>", "Open explorer" },
      f = { "<cmd>NvimTreeFindFile<cr>", "Open explorer in current file" }
    },
    w = { ":lua require('nvim-window').pick()<cr>", "Window pick" },
  }



  local mappingsTerminal = {

    u = {
      name = "Utilities",
      t = { "<cmd>FloatermNew<cr>", "New terminal" },
      u = { "<cmd>FloatermToggle<cr>", "Terminal toggle" },
      y = { "<cmd>FloatermNext<cr>", "Next terminal" },
    },

  }

  local topLevelMappings = {}
  topLevelMappings["["] = { d = "Previous diagnostic" }
  topLevelMappings["]"] = { d = "Next diagnostic" }
  topLevelMappings["g"] = {
    name = "Go to",
    c = {
      name = "Call hierarchy / Comment",
      c = { "Comment line" },
      b = { "Comment block" },
      i = { "<cmd>Lspsaga incoming_calls<CR>", "Incoming calls" },
      o = { "<cmd>Lspsaga outgoing_calls<CR>", "Outgoing calls" },
    },
    d = { "<cmd>Lspsaga peek_definition<CR>", "Peek definition" },
    D = { "<cmd>Lspsaga goto_definition<CR>", "Go to declaration" },
    e = { "<cmd>Lspsaga show_line_diagnostics<CR>", "Show line diagnostics" },
    f = { "<cmd>Lspsaga lsp_finder<CR>", "Find symbol" },
    h = { "<cmd>Lspsaga hover_doc<CR>", "Hover docs" },
    i = { ":lua vim.lsp.buf.implementation()<cr>", "Go to implementation" },
    k = { "<cmd>Lspsaga hover_doc ++keep<CR>", "Hover docs - keep window" },
    o = { "<cmd>Lspsaga outline<CR>", "Toggle outline" },
    r = { ":lua require('telescope.builtin').lsp_references()<cr>", "Find references" },
    s = { ":lua vim.lsp.buf.signature_help()<cr>", "Signature help" },
    S = { ":lua require('telescope.builtin').lsp_document_symbols()<cr>", "Go to document symbol" },
    t = { ":lua vim.lsp.buf.type_definition()<cr>", "Go to type definition" },
    w = { ":lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>", "Go to workspace symbol" },
    ["["] = { "<cmd>Lspsaga diagnostic_jump_prev<cr>", "Show previous diagnostics" },
    ["]"] = { "<cmd>Lspsaga diagnostic_jump_next<cr>", "Show next diagnostics" },
  }
  topLevelMappings["<F5>"] = { ":lua require'dap'.continue()<cr>", "Debug - Continue " }
  topLevelMappings["<F6>"] = { ":lua require'dap'.step_over()<cr>", "Debug - Step over" }
  topLevelMappings["<F7>"] = { ":lua require'dap'.step_into()<cr>", "Debug - Step into" }
  topLevelMappings["<F8>"] = { ":lua require'dap'.step_out()<cr>", "Debug - Step out" }
  vim.keymap.set("n", "<F10>", function() run_spring_boot() end)
  vim.keymap.set("n", "<F11>", function() run_spring_boot(true) end)
  topLevelMappings["<F10>"] = { "Run application" }
  topLevelMappings["<F11>"] = { "Debug application" }

  vim.g.maplocalleader = ','
  local wkl = require('which-key')

  -- Logic to change mappings based on the file type.
  -- vim.cmd('autocmd FileType * lua setKeybinds()')
  -- function setKeybinds()
  --   local fileTy = vim.api.nvim_buf_get_option(0, "filetype")
  --   local opts = { prefix = '<localleader>', buffer = 0 }
  --
  --   if (fileTy == 'java') then
  --
  --   elseif fileTy == 'python' then
  --     wkl.register({
  --       ['w'] = { ':w<CR>', 'test write' },
  --       ['q'] = { ':q<CR>', 'test quit' },
  --     }, opts)
  --   elseif fileTy == 'sh' then
  --     wkl.register({
  --       ['W'] = { ':w<CR>', 'test write' },
  --       ['Q'] = { ':q<CR>', 'test quit' },
  --     }, opts)
  --   end
  -- end

  whichkey.setup(conf)
  whichkey.register(mappings, opts)
  whichkey.register(mappingsTerminal, optsTerminal)
  whichkey.register(topLevelMappings)
  -- vim.cmd('autocmd FileType java lua JavaMappings()')
  function JavaMappings()
    mappings.c.c = { ":lua require('jdtls').extract_constant()<CR>", "Extract constant" }
    mappings.c.m = { ":lua require('jdtls').extract_method(true)<cr>", "Extract method" }
    mappings.c.o = { ":lua require'jdtls'.organize_imports()<CR>", "Organize imports" }
    mappings.c.v = { ":lua require('jdtls').extract_variable()<CR>", "Extract variable" }
    whichkey.register(mappings, opts)
  end
end

M.setup()
