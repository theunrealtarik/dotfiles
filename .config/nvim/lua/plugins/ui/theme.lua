return {
  {
    'Mofiqul/vscode.nvim',
    config = function()
      local c = require('vscode.colors').get_colors()
      local vscode = require 'vscode'

      vscode.setup {
        transparent = true,
        italic_comments = true,
        underline_links = true,
        disable_nvimtree_bg = true,
        color_overrides = {
          vscLineNumber = '#636363',
        },

        group_overrides = {
          Cursor = { fg = c.vscDarkBlue, bg = c.vscLightGreen, bold = true },
          Comment = { fg = c.vscGray },
        },
      }
      vscode.load()
    end,
  },
  { 'echasnovski/mini.nvim', version = '*' },
  {
    'DaikyXendo/nvim-material-icon',
    config = function()
      require('nvim-web-devicons').setup {
        color_icons = true,
        default = true,
      }
    end,
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {},
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require('noice').setup {
        cmdline = {
          view = 'cmdline',
        },
        routes = {
          {
            view = "notify",
            filter = { event = "msg_showmode" },
          },
        },
        lsp = {
          progress = {
            enabled = false,
          },
        },
      }
    end,
  },
}
