return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'arkav/lualine-lsp-progress',
    },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = ' '
      else
        vim.o.laststatus = 0
      end
    end,
    config = function()
      local lualine = require('lualine')

      local conditions = {
        buffer_not_empty = function()
          return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
        end,
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
        check_git_workspace = function()
          local filepath = vim.fn.expand('%:p:h')
          local gitdir = vim.fn.finddir('.git', filepath .. ';')
          return gitdir and #gitdir > 0 and #gitdir < #filepath
        end,
      }

      local icons = require 'lib.icons'
      local utils = require 'lib.utils'

      local lualine_require = require 'lualine_require'
      lualine_require.require = require

      vim.o.laststatus = vim.g.lualine_laststatus

      local config = {
        theme = 'auto',
        options = {
          component_separators = '',
          section_separators = '',
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'ministarter', 'snacks_dashboard' } },
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return icons.modes.current_mode_icon('utf8') .. " " .. utils.capitalize(str)
              end,
            },
          },
          lualine_b = { 'branch', 'diff' },
          lualine_c = {
            'filename',
            utils.conditional('filesize', conditions.buffer_not_empty),
            {
              'diagnostics',
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
          },
          lualine_x = {
            { 'encoding', fmt = string.upper },
            'fileformat',
            {
              'filetype',
              fmt = utils.capitalize,
              color = { gui = 'bold' }
            },
          },
          lualine_y = {
            {
              'lsp_progress',
              color = { fg = '#ffffff', },
            }
          },
        },
      }

      lualine.setup(config)
    end
  },
}
