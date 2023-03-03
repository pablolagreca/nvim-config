local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  is_bootstrap = true
  vim.fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path }
end


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
  use { "catppuccin/nvim", as = "catppuccin" }

  -- TODO consider removing this plugins since auto-session should be enough
  -- detect and allow to select projects
  -- use({
  --   "ahmedkhalf/project.nvim",
  --   -- can't use 'opts' because module has non standard name 'project_nvim'
  --   config = function()
  --     require("project_nvim").setup({
  --       patterns = {
  --         ".git",
  --         "package.json",
  --         ".terraform",
  --         "go.mod",
  --         "requirements.yml",
  --         "pyrightconfig.json",
  --         "pyproject.toml",
  --         "pom.xml",
  --       },
  --       -- detection_methods = { "lsp", "pattern" },
  --       detection_methods = { "pattern" },
  --     })
  --   end,
  -- })

  use({
    "anuvyklack/hydra.nvim",
    requires = {
      "anuvyklack/keymap-layer.nvim",
    },
    -- commit = "ea91aa820a6cecc57bde764bb23612fff26a15de",
    config = function()
      require("core.plugins.hydra.hydra")
    end,
  })

  -- Enable `lukas-reineke/indent-blankline.nvim`
  -- Shows indentation more clearly.
  use { "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup {
        -- for example, context is off by default, use this to turn it on
        show_current_context = true,
        show_current_context_start = true,
        show_end_of_line = true,
        char = '┊',
        show_trailing_blankline_indent = false,
      }
    end
  }

  -- Allows to pick an icon with IconPicker commands
  use({
    "ziontee113/icon-picker.nvim",
    requires = {
      "stevearc/dressing.nvim"
    },
    config = function()
      require("icon-picker").setup({
        disable_legacy_commands = true
      })
    end,
  })

  -- Adds a border to the active window with a different color than the rest
  use {
    "nvim-zh/colorful-winsep.nvim",
    config = function()
      require('colorful-winsep').setup({
      })
    end
  }

  -- automatically adds closing [square] braces, curly braces, etc
  use {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup {
        enable_check_bracket_line = false, -- Don't add pairs if it already has a close pair in the same line
        ignored_next_char = "[%w%.]", -- will ignore alphanumeric and `.` symbol
        check_ts = true, -- use treesitter to check for a pair.
        ts_config = {
          lua = { "string" }, -- it will not add pair on that treesitter node
          javascript = { "template_string" },
          java = false, -- don't check treesitter on java

        }, }
    end
  }

  -- Plugin to show pretty notifications
  use { 'rcarriga/nvim-notify' }

  -- NVIM tree
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons',
    },
    tag = 'nightly'
  }

  use {
    'shatur/neovim-session-manager',
    config = function()
      local Path = require('plenary.path')
      require('session_manager').setup({
        sessions_dir = Path:new(vim.fn.stdpath('data'), 'sessions'), -- The directory where the session files will be saved.
        path_replacer = '__', -- The character to which the path separator will be replaced for session files.
        colon_replacer = '++', -- The character to which the colon symbol will be replaced for session files.
        autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
        autosave_last_session = true, -- Automatically save last session on exit and on session switch.
        autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
        autosave_ignore_dirs = {}, -- A list of directories where the session will not be autosaved.
        autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
          'gitcommit',
        },
        autosave_ignore_buftypes = {}, -- All buffers of these bufer types will be closed before the session is saved.
        autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
        max_path_length = 80, -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
      })
    end
  }

  -- Additional configuration to reset nvim-tree when changing sessions
  local config_group = vim.api.nvim_create_augroup('MySessionManager', {})
  vim.api.nvim_create_autocmd({ 'User' }, {
    pattern = "SessionLoadPost",
    group = config_group,
    callback = function()
      local nt = require('nvim-tree')
      nt.change_dir(vim.fn.getcwd())
    end
  })

  -- Plugin for organizing work and documentation.
  use {
    'phaazon/mind.nvim',
    branch = 'v2.2',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require 'mind'.setup({
        persistence = {
          state_path = '~/Google Drive/My Drive/Mind/global-mind.json',
          data_dir = "~/Google Drive/My Drive/Mind/global-data/",
        }
      })
    end
  }

  -- Plugin to jump directly to anywhere
  use {
    'phaazon/hop.nvim',
    branch = 'v2', -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require 'hop'.setup { keys = 'etovxqpdygfblzhckisuran' }
    end
  }
 
  -- Header for buffers with name and the list of open buffers
  use { 'akinsho/bufferline.nvim',
    tag = "v3.*"
    , requires = 'nvim-tree/nvim-web-devicons'
  }

  -- To navigate outside vim to tmux terminals
  use { 'christoomey/vim-tmux-navigator' }

  use { -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    requires = {
      -- Automatically install LSPs to stdpath for neovim
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      "jay-babu/mason-nvim-dap.nvim",
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


  -- govim plugin
  use 'ray-x/go.nvim'
  use 'ray-x/guihua.lua' -- recommended if need floating window support
  -- Git related plugins
  -- TODO review if we are using any of these commented git plugins
  -- use 'tpope/vim-fugitive'
  -- use 'tpope/vim-rhubarb'
  use 'lewis6991/gitsigns.nvim'

  use { 'TimUntersberger/neogit', requires = 'nvim-lua/plenary.nvim' }

  use 'navarasu/onedark.nvim' -- Theme inspired by Atom
  use 'nvim-lualine/lualine.nvim' -- Fancier statusline
  use 'numToStr/Comment.nvim' -- "gc" to comment visual regions/lines
  use 'tpope/vim-sleuth' -- Detect tabstop and shiftwidth automatically

  -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }

  use {
    "nvim-telescope/telescope.nvim", tag = '0.1.1',
    requires = {
      "jvgrootveld/telescope-zoxide",
      "crispgm/telescope-heading.nvim",
      "nvim-telescope/telescope-symbols.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "ptethng/telescope-makefile",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require('core.plugins.telescope')
    end
  }

  -- require("telescope")
  -- Ranger for file explorer
  --
  -- use 'francoiscabrol/ranger.vim'
  use 'rbgrouleff/bclose.vim'

  -- Whichkey
  use { 'folke/which-key.nvim', config = function()
    vim.opt.timeout = true
    vim.opt.timeoutlen = 300
  end,
  }
  -- FloatTerm
  use 'voldikss/vim-floaterm'


  -- Markdown
  -- install without yarn or npm
  vim.g.mkdp_auto_start = 0
  vim.g.mkdp_auto_close = 0
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })
  -- Plugin for local history of files
  -- requires to execute: pip3 install pynvim and then run :UpdateRemotePlugins in nvim
  vim.g.local_history_path = vim.fn.stdpath('data') .. '/local-history/'
  use {
    'dinhhuy258/vim-local-history'
  }
  -- Plugin for auto-save.
  use({
    "Pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup {
        -- your config goes here
        -- or just leave it empty :)
      }
    end,
  })

  -- TODO - this plugin should be install correctly with the settings above but it is not. We need to do the following manually to make it work:
  --
  --  cd ~/.local/share/nvim/site/pack/packer/start/
  -- git clone https://github.com/iamcco/markdown-preview.nvim.git
  -- cd markdown-preview.nvim
  -- yarn install
  -- yarn build --
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
    config = function()
      require("lspsaga").setup({})
    end,
    requires = {
      { "nvim-tree/nvim-web-devicons" },
      --Please make sure you install markdown and markdown_inline parser
      { "nvim-treesitter/nvim-treesitter" }
    }
  })

  -- TODO plugin to add surround to text.
  use {
    "ur4ltz/surround.nvim",
    config = function()
      require "surround".setup { mappings_style = "sandwich" }
    end
  }

  use({
    "goolord/alpha-nvim",
    requires = {
      "kyazdani42/nvim-web-devicons",
    },
    config = function()
      require("core.plugins.alpha.alpha")
    end,
  })
  -- Pick windows plugin
  use 'https://gitlab.com/yorickpeterse/nvim-window'
  -- Persist breakpoints after restart nvim
  use { 'Weissle/persistent-breakpoints.nvim' }
  -- Snippets support
  use({ "L3MON4D3/LuaSnip", tag = "v1.2.1" })

  use {
    "rest-nvim/rest.nvim",
    requires = { "nvim-lua/plenary.nvim" },
  }

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

-- require('nord').set()
-- Set colorscheme
vim.opt.termguicolors = true
vim.cmd.colorscheme "catppuccin"

-- Set completeopt to have a better completion experience
vim.opt.completeopt = 'menuone,noselect'

-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be usedf
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
    icons_enabled = true,
    -- theme = tokyonight,
    component_separators = '|',
    section_separators = '',
  },
  sections = { lualine_c = { "vim.fn.getcwd()" } }
}




-- Enable Comment.nvim
require('Comment').setup()

require('hop').setup({
  case_insensitive = false
})
require("bufferline").setup{}


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

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
require('nvim-treesitter.configs').setup {
  -- Add languages to be installed here that you want installed for treesitter
  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'typescript', 'help',
    'vim', 'java', 'json', 'http' },

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
-- automatically setup nvim-dap client to use installed daps
require("mason-nvim-dap").setup({
  automatic_setup = true,
})

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
    ['<C-d>'] = cmp.mapping.scroll_docs( -4),
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
      elseif luasnip.jumpable( -1) then
        luasnip.jump( -1)
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
    format = require 'lspkind'.cmp_format({
      mode = 'symbol_text',
      max_width = 50,
      ellipsis_char = '...',
      before = function(_, vim_item)
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
local HEIGHT_RATIO = 0.8 -- You can change this
local WIDTH_RATIO = 0.5 -- You can change this tooim.opt.termguicolors = true

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
    change_dir = {
      global = true, --this config is required to work well with auto-sessions https://github.com/rmagatti/auto-session/issues/178
    },
    open_file = {
      window_picker = {
        enable = false,
      },
    },
  },
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
    float = {
      enable = true,
      quit_on_focus_loss = true,
      open_win_config = function()
        local screen_w = vim.opt.columns:get()
        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
        local window_w = screen_w * WIDTH_RATIO
        local window_h = screen_h * HEIGHT_RATIO
        local window_w_int = math.floor(window_w)
        local window_h_int = math.floor(window_h)
        local center_x = (screen_w - window_w) / 2
        local center_y = ((vim.opt.lines:get() - window_h) / 2)
            - vim.opt.cmdheight:get()
        return {
          border = "rounded",
          relative = "editor",
          row = center_y,
          col = center_x,
          width = window_w_int,
          height = window_h_int,
        }
      end,
    }
  }
})

-- Autopairs configuration
-- import nvim-autopairs safely
local autopairs_setup, autopairs = pcall(require, "nvim-autopairs")
if not autopairs_setup then
  return
end


-- rest plugin
require("rest-nvim").setup({
  -- Open request results in a horizontal split
  result_split_horizontal = false,
  -- Keep the http file buffer above|left when split horizontal|vertical
  result_split_in_place = false,
  -- Skip SSL verification, useful for unknown certificates
  skip_ssl_verification = false,
  -- Encode URL before making request
  encode_url = true,
  -- Highlight request on run
  highlight = {
    enabled = true,
    timeout = 150,
  },
  result = {
    -- toggle showing URL, HTTP info, headers at top the of result window
    show_url = true,
    show_http_info = true,
    show_headers = true,
    -- executables or functions for formatting response body [optional]
    -- set them to false if you want to disable them
    formatters = {
      json = "jq",
      html = function(body)
        return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
      end
    },
  },
  -- Jump to request line on run
  jump_to_request = false,
  env_file = '.env',
  custom_dynamic_variables = {},
  yank_dry_run = true,
})


-- require('dap-go').setup()

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

require('persistent-breakpoints').setup {
  load_breakpoints_event = { "BufReadPost" }
}

-- GO plugin configuration
require('go').setup({

  disable_defaults = false, -- true|false when true set false to all boolean settings and replace all table
  -- settings with {}
  go='go', -- go command, can be go[default] or go1.18beta1
  goimport='gopls', -- goimport command, can be gopls[default] or goimport
  fillstruct = 'gopls', -- can be nil (use fillstruct, slower) and gopls
  gofmt = 'gofumpt', --gofmt cmd,
  max_line_len = 128, -- max line length in golines format, Target maximum line length for golines
  tag_transform = false, -- can be transform option("snakecase", "camelcase", etc) check gomodifytags for details and more options
  tag_options = 'json=omitempty', -- sets options sent to gomodifytags, i.e., json=omitempty
  gotests_template = "", -- sets gotests -template parameter (check gotests for details)
  gotests_template_dir = "", -- sets gotests -template_dir parameter (check gotests for details)
  comment_placeholder = '' ,  -- comment_placeholder your cool placeholder e.g. ﳑ       
  icons = {breakpoint = '🧘', currentpos = '🏃'},  -- setup to `false` to disable icons setup
  verbose = false,  -- output loginf in messages
  lsp_cfg = false, -- true: use non-default gopls setup specified in go/lsp.lua
                   -- false: do nothing
                   -- if lsp_cfg is a table, merge table with with non-default gopls setup in go/lsp.lua, e.g.
                   --   lsp_cfg = {settings={gopls={matcher='CaseInsensitive', ['local'] = 'your_local_module_path', gofumpt = true }}}
  lsp_gofumpt = false, -- true: set default gofmt in gopls format to gofumpt
  lsp_on_attach = nil, -- nil: use on_attach function defined in go/lsp.lua,
                       --      when lsp_cfg is true
                       -- if lsp_on_attach is a function: use this function as on_attach function for gopls
  lsp_keymaps = true, -- set to false to disable gopls/lsp keymap
  lsp_codelens = true, -- set to false to disable codelens, true by default, you can use a function
  -- function(bufnr)
  --    vim.api.nvim_buf_set_keymap(bufnr, "n", "<space>F", "<cmd>lua vim.lsp.buf.formatting()<CR>", {noremap=true, silent=true})
  -- end
  -- to setup a table of codelens
  lsp_diag_hdlr = true, -- hook lsp diag handler
  lsp_diag_underline = true,
  -- virtual text setup
  lsp_diag_virtual_text = { space = 0, prefix = "" },
  lsp_diag_signs = true,
  lsp_diag_update_in_insert = false,
  lsp_document_formatting = true,
  -- set to true: use gopls to format
  -- false if you want to use other formatter tool(e.g. efm, nulls)
 lsp_inlay_hints = {
    enable = true,
    -- Only show inlay hints for the current line
    only_current_line = false,
    -- Event which triggers a refersh of the inlay hints.
    -- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
    -- not that this may cause higher CPU usage.
    -- This option is only respected when only_current_line and
    -- autoSetHints both are true.
    only_current_line_autocmd = "CursorHold",
    -- whether to show variable name before type hints with the inlay hints or not
    -- default: false
    show_variable_name = true,
    -- prefix for parameter hints
    parameter_hints_prefix = " ",
    show_parameter_hints = true,
    -- prefix for all the other hints (type, chaining)
    other_hints_prefix = "=> ",
    -- whether to align to the lenght of the longest line in the file
    max_len_align = false,
    -- padding from the left if max_len_align is true
    max_len_align_padding = 1,
    -- whether to align to the extreme right or not
    right_align = false,
    -- padding from the right if right_align is true
    right_align_padding = 6,
    -- The color of the hints
    highlight = "Comment",
  },
  gopls_cmd = nil, -- if you need to specify gopls path and cmd, e.g {"/home/user/lsp/gopls", "-logfile","/var/log/gopls.log" }
  gopls_remote_auto = true, -- add -remote=auto to gopls
  gocoverage_sign = "█",
  sign_priority = 5, -- change to a higher number to override other signs
  dap_debug = true, -- set to false to disable dap
  dap_debug_keymap = true, -- true: use keymap for debugger defined in go/dap.lua
                           -- false: do not use keymap in go/dap.lua.  you must define your own.
                           -- windows: use visual studio keymap
  dap_debug_gui = {}, -- bool|table put your dap-ui setup here set to false to disable
  dap_debug_vt = { enabled_commands = true, all_frames = true }, -- bool|table put your dap-virtual-text setup here set to false to disable

  dap_port = 38697, -- can be set to a number, if set to -1 go.nvim will pickup a random port
  dap_timeout = 15, --  see dap option initialize_timeout_sec = 15,
  dap_retries = 20, -- see dap option max_retries
  build_tags = "tag1,tag2", -- set default build tags
  textobjects = true, -- enable default text jobects through treesittter-text-objects
  test_runner = 'go', -- one of {`go`, `richgo`, `dlv`, `ginkgo`, `gotestsum`}
  verbose_tests = true, -- set to add verbose flag to tests deprecated, see '-v' option
  run_in_floaterm = false, -- set to true to run in float window. :GoTermClose closes the floatterm
                           -- float term recommend if you use richgo/ginkgo with terminal color

  floaterm = {   -- position
    posititon = 'auto', -- one of {`top`, `bottom`, `left`, `right`, `center`, `auto`}
    width = 0.45, -- width of float window if not auto
    height = 0.98, -- height of float window if not auto
  },
  trouble = false, -- true: use trouble to open quickfix
  test_efm = false, -- errorfomat for quickfix, default mix mode, set to true will be efm only
  luasnip = false, -- enable included luasnip snippets. you can also disable while add lua/snips folder to luasnip load
  --  Do not enable this if you already added the path, that will duplicate the entries
  on_jobstart = function(cmd) _=cmd end, -- callback for stdout
  on_stdout = function(err, data) _, _ = err, data end, -- callback when job started
  on_stderr = function(err, data)  _, _ = err, data  end, -- callback for stderr
  on_exit = function(code, signal, output)  _, _, _ = code, signal, output  end, -- callback for jobexit, output : string
})
-- Foramt code on save
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    require('go.format').goimport()
    require('go.format').gofmt()
  end,
  group = format_sync_grp,
})

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
dap.configurations.go = {
  {
    type = 'go',
    name = 'Debug',
    request = 'launch',
    showLog = true,
    program = "${file}",
    dlvToolPath = vim.fn.exepath('dlv') -- Adjust to where delve is installed
  },
}

function show_dap_centered_scopes()
  local widgets = require 'dap.ui.widgets'
  widgets.centered_float(widgets.scopes)
end

function attach_to_debug()
  dap.continue()
end

-- To show values for variables during debug within the buffer file.
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
    debug_param =
    ' -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005" '
  end

  local profile_param = ""
  if profile then
    profile_param = " -Dspring-boot.run.profiles=" .. profile .. " "
  end

  return 'mvn spring-boot:run -o ' .. profile_param .. debug_param
end

local function run_spring_boot(debug)
  vim.cmd('tab new "running app"')
  vim.cmd('term ' .. get_spring_boot_runner(method_name, debug))
end

local function run(debug)
  local cwd = vim.fn.getcwd()
  print('CWD is: ' .. cwd)
  print('test pom: ' .. vim.fn.filereadable(cwd .. '/pom.xml'))
  if vim.fn.filereadable(cwd .. '/pom.xml') ~= 0 then
    run_spring_boot(debug)
  elseif vim.fn.filereadable(cwd .. '/go.mod') ~= 0 then
    if debug then
      vim.cmd('GoDebug')
    else
      vim.cmd('GoRun')
    end
  end
end

--TODO CMP setup for debugger REPL: https://www.youtube.com/watch?v=kbRIosrvof0



-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
--
local map = vim.keymap.set
-- paste over currently selected text without yanking it
map("v", "p", '"_dp')
map("v", "P", '"_dP')

-- switch buffer
map("n", "<tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-- save like your are used to
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- move over a closing element in insert mode
map("i", "<C-l>", function()
  return require("core.utils.functions").escapePair()
end)

-- debuggin
map("v", "<M-k>", ":lua require('dapui').eval()<CR>", { desc = "Evaluate" })

local M = {}
local hop = require('hop')

-- Function for MindToogle keybinding
vim.api.nvim_create_user_command(
  'UMindToogle',
  function()
    if (vim.g.mind_main_tree_open == false) then
      vim.g.mind_main_tree_open = true
      vim.api.nvim_command("MindOpenMain")
      return "mindopenmain"
    else
      vim.g.mind_main_tree_open = false
      vim.api.nvim_command("MindClose")
    end
  end,
  {}
)

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
      name = "Buffers",
      b = {
        "<cmd>Telescope buffers<cr>",
        "Find buffer",
      },
      D = {
        "<cmd>%bd|e#|bd#<cr>",
        "Close all but the current buffer",
      },
      d = { "<cmd>Bclose<cr>", "Close buffer" },
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
      d = { ":lua require'dap'.run_last()<cr>", "Run last debug session" },
      t = {
        name = "Test",
        m = { ":lua run_java_test_method(true)<cr>", "Test method" },
        c = { ":lua run_java_test_class(true)<cr>", "Test class" }
      },
      y = { ":lua require'jdtls'.test_nearest_method()<cr>", "Test nearest method" },
      o = { ":lua require('dapui').open()<cr>", "Open debugger UI" },
      c = { ":lua require('dapui').close()<cr>", "Close debugger UI" },
      C = { ":lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>", "Clear all breakpoints" },
      b = { ":lua require('persistent-breakpoints.api').set_breakpoint()<cr>", "Toogle breakpoint" },
      B = { ":lua require('persistent-breakpoints.api').set_conditional_breakpoint()<cr>", "Toogle conditional endpoint" },
      l = { ":lua require'dap'.toggle_breakpoint(nil, nil, vim.fn.input('Log: '))<cr>", "Toogle log breakpoint" },
      r = { ":lua request'dapui'.float_element('repl')<cr>", "Open REPL" },
      s = { ":lua show_dap_centered_scopes()<cr>", "Show debug scopes" }
    },
    e = {
      name = "Edit",
      o = { "o<Esc><cr>", "Add blank line" },
      O = { "O<Esc><cr>", "Add blank line up" },
    },
    u = {
      name = "Utilities",
      d = { "<cmd>CD<cr>", "Show diff" },
      D = { "<cmd>TCV<cr>", "Enable/disable diff" },
      m = { "<cmd>UMindToogle<cr>", "Mind Main Tree" },
      M = { "<cmd>MarkdownPreview<cr>", "Markdown Preview" },
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
    -- s = { ":lua require('telescope.builtin').find_files()<cr>", "Go to document symbol" },
    t = {
      name = "Explorer / Tabs",
      f = { "<cmd>NvimTreeFindFile<cr>", "Open explorer in current file" },
      x = { "<cmd>tabclose<cr>", "Close tab" },
      n = { "<cmd>tabn<cr>", "Next tab" },
      o = { "<cmd>tabnew<cr>", "Open new tab" },
      p = { "<cmd>tabp<cr>", "Previous tab" },
      t = { "<cmd>NvimTreeToggle<cr>", "Open explorer" },
    },
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
  topLevelMappings["<tab>"] = { "<cmd>e#<cr>", "Prev buffer" }
  topLevelMappings["["] = { d = "Previous diagnostic" }
  topLevelMappings["]"] = { d = "Next diagnostic" }
  topLevelMappings["g"] = {
    name = "Go to",
    c = {
      name = "Call hierarchy / Comment",
      c = { "Comment line" },
      b = { "Comment block" },
      i = { "<cmd>Lspsaga incoming_calls()<CR>", "Incoming calls" },
      o = { "<cmd>Lspsaga outgoing_calls()<CR>", "Outgoing calls" },
    },
    d = { "<cmd>Lspsaga peek_definition<CR>", "Peek definition" },
    D = { "<cmd>Lspsaga goto_definition<CR>", "Go to declaration" },
    e = { "<cmd>Lspsaga show_line_diagnostics<CR>", "Show line diagnostics" },
    f = { "<cmd>Lspsaga lsp_finder<CR>", "Find symbol" },
    h = { "<cmd>Lspsaga hover_doc<CR>", "Hover docs" },
    -- d = { ":lua vim.lsp.buf.peek_definition()<cr>", "Peek definition" },
    -- D = { ":lua vim.lsp.buf.peek_definition()<cr>", "Go to declaration" },
    -- e = { ":lua vim.lsp.buf.show_line_diagnostics()<cr>", "Show line diagnostics" },
    -- h = { "<cmd>Lspsaga hover_doc<CR>", "Hover docs" },
    i = { ":lua require('telescope.builtin').lsp_implementations()<cr>", "Go to implementation" },
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
  vim.keymap.set("n", "<F10>", function() run() end)
  vim.keymap.set("n", "<F11>", function() run(true) end)
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
  -- TODO assign the functions to this mappings
  whichkey.register({
    sa = "Add surrounding",
    sd = "Delete surrounding",
    sh = "Highlight surrounding",
    sn = "Surround update n lines",
    sr = "Replace surrounding",
    sF = "Find left surrounding",
    sf = "Replace right surrounding",
    ss = { "<cmd>HopChar1<cr>", "Jump to character" },
    st = { "<cmd>lua require('tsht').nodes()<cr>", "TS hint textobject" },
  })
  vim.cmd('autocmd FileType java lua JavaMappings()')
  function JavaMappings()
    mappings.c.c = { ":lua require('jdtls').extract_constant()<CR>", "Extract constant" }
    mappings.c.m = { ":lua require('jdtls').extract_method(true)<cr>", "Extract method" }
    mappings.c.o = { ":lua require'jdtls'.organize_imports()<CR>", "Organize imports" }
    mappings.c.v = { ":lua require('jdtls').extract_variable()<CR>", "Extract variable" }
    whichkey.register(mappings, opts)
  end

  vim.cmd('autocmd FileType go lua GoMappings()')
  function GoMappings()
    mappings.c.o = { ":lua vim.lsp.buf.organize_imports()<cr>", "Organize imports" }
    mappings.d.b = { "<cmd>GoBreakToggle<cr>", "Toogle breakpoint" }
    whichkey.register(mappings, opts)
  end

  vim.cmd('autocmd FileType http lua HttpMappings()')
  function HttpMappings()
    mappings.r.h = { "<Plug>RestNvim", "HTTP request" }
    mappings.r.l = { "<Plug>RestNvimLast", "Last HTTP request" }
    mappings.r.p = { "<Plug>RestNvimPreview", "HTTP request preview" }
    whichkey.register(mappings, opts)
  end
end

M.setup()
