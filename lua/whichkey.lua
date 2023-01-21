 local M = {}

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
	  ["l"] = { "<cmd>:source .session.vim<cr>" },
	  ["w"] = { "<cmd>update!<CR>", "Save" },
	  ["q"] = { "<cmd>q!<CR>", "Quit" },
	  ["t"] = { "<cmd>NvimTreeOpen<CR>", "Explorer" },
	  ["x"] = { "<cmd>Win<CR>", "Select window" },

	  b = {
		  name = "Buffer",
		  c = { "<Cmd>bd!<Cr>", "Close current buffer" },
		  D = { "<Cmd>%bd|e#|bd#<Cr>", "Delete all buffers" },
		  b = { "<cmd>Telescope buffers<cr>", "List buffers" },
	  },

	  c = {
		  name = "Code",
		  a = { ":lua vim.lsp.buf.code_action()<cr>", "Code action" },
		  f = { ":lua vim.lsp.buf.formatting()<cr>", "Format code" },
	  },


	  e = {
		  name = "Edit",
		  o = { "o<Esc><cr>", "Add blank line" },
		  O = { "O<Esc><cr>", "Add blank line up" },
	  },

	  g = {
		  name = "Go to",
		  d = { ":lua vim.lsp.buf.definition()<cr>", "Go to definition"},
		  D = { ":lua vim.lsp.buf.declaration()<cr>", "Go to declaration"},
		  i = { ":lua vim.lsp.buf.implementation()<cr>", "Go to implementation"},
		  w = { ":lua vim.lsp.buf.document_symbol()<cr>", "Go to document symbol"},
		  W = { ":lua vim.lsp.buf.workspace_symbol()<cr>", "Go to workspace symbol"},
		  r = { ":lua vim.lsp.buf.references()<cr>", "Find references"},
		  t = { ":lua vim.lsp.buf.type_definition()<cr>", "Go to type definition"},
	  },

	  h = {
		  name = "Help",
		  k = { ":lua vim.lsp.buf.hover()<cr>"}, -- TODO add description
		  s = { ":lua vim.lsp.buf.signature_help()<cr>", "Signature" },
	  },

	  s = {
		  name = "Search",
		  f = { ":lua require('telescope.builtin').find_files()<cr>", "Files by name" },
		  F = { ":lua require('telescope.builtin').find_files({ cwd = '~', hidden = true})<cr>", "Home files by name" },
		  c = { "<cmd>Telescope live_grep<cr>", "Files by content" },
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
		  name = "Refactor",
		  r = { ":lua vim.lsp.buf.rename()<cr>", "Rename" }
	  },
	  z = {
		  name = "Packer",
		  c = { "<cmd>PackerCompile<cr>", "Compile" },
		  i = { "<cmd>PackerInstall<cr>", "Install" },
		  s = { "<cmd>PackerSync<cr>", "Sync" },
		  S = { "<cmd>PackerStatus<cr>", "Status" },
		  u = { "<cmd>PackerUpdate<cr>", "Update" },
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

  whichkey.setup(conf)
  whichkey.register(mappings, opts)
  whichkey.register(mappingsTerminal, optsTerminal)
end

return M
