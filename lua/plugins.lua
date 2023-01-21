return require('packer').startup(function()
	use 'wbthomason/packer.nvim'
	use {
		'folke/which-key.nvim',
		config = function()
			require("whichkey").setup()
		end,
	}
	use {
		'kyazdani42/nvim-tree.lua',
    		requires = {
      			'kyazdani42/nvim-web-devicons', -- optional, for file icon
    		},
    		tag = 'nightly'
	}
	-- use 'http://github.com/tpope/vim-surround' -- Surrounding ysw)
	use 'https://github.com/tpope/vim-commentary' -- For Commenting gcc & gc
	-- use 'https://github.com/lifepillar/pgsql.vim' -- PSQL Pluging needs :SQLSetType pgsql.vim
	use 'https://github.com/ap/vim-css-color' -- CSS Color Preview
	use 'https://github.com/rafi/awesome-vim-colorschemes' -- Retro Scheme
	-- use 'https://github.com/ryanoasis/vim-devicons' -- Developer Icons
	-- use 'https://github.com/preservim/tagbar' -- Tagbar for code navigation
	-- use 'https://github.com/terryma/vim-multiple-cursors' -- CTRL + N for multiple cursors
	-- -- use {
	-- 	'junegunn/fzf.vim',
	use {
		'nvim-telescope/telescope.nvim',
		requires = { {'nvim-lua/plenary.nvim'} }
	}
	-- use 'udalov/kotlin-vim'
	use 'voldikss/vim-floaterm'
	use 'chrisbra/changesPlugin'
    use 'itchyny/lightline.vim'
	use 'mengelbrecht/lightline-bufferline'
	use { 'nvim-treesitter/nvim-treesitter' }
	use 'neovim/nvim-lspconfig'
	use 'williamboman/nvim-lsp-installer'
	use 'hrsh7th/cmp-nvim-lsp'
	use 'hrsh7th/cmp-buffer'
	use 'hrsh7th/cmp-path'
	use 'hrsh7th/cmp-cmdline'
	use 'hrsh7th/nvim-cmp'
	use 'hrsh7th/cmp-vsnip'
	use 'hrsh7th/vim-vsnip'
	use {
		'fatih/vim-go',
		run = ':GoUpdateBinaries' }
	use 'dstein64/vim-win'
end)
