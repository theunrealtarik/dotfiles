return {
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    keys = {
      { '<leader>c', group = 'Code', desc = 'code' },
      { '<leader>d', group = 'Document', desc = 'document', hidden = true },
      { '<leader>h', group = 'Harpoon', desc = 'harpoon', hidden = true },
      { '<leader>l', group = 'Lsp', desc = 'lsp', hidden = true },
      { '<leader>r', group = 'Rename', desc = 'rename', hidden = true },
      { '<leader>s', group = 'Search', desc = 'search', hidden = true },
      { '<leader>t', group = 'Tree', desc = 'tree', hidden = true },
      { '<leader>w', group = 'Workspace', desc = 'workspace', hidden = true },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
  { 'numToStr/Comment.nvim', opts = {}, lazy = false },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    -- use opts = {} for passing setup options
    -- this is equalent to setup({}) function
  },
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    tag = 'stable',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('crates').setup {}
    end,
  },
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup()
    end,
  },
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'Trouble',
    opts = {},
    keys = {
      {
        '<leader>qd',
        '<cmd>Trouble diagnostics toggle<CR>',
        desc = 'Open diagnostic document quickfix list',
      },
      {
        '<leader>qf',
        '<cmd>Trouble qflist toggle<CR>',
        desc = 'Open quickfix list',
      },
      { '<leader>qs', '<cmd>Trouble symbols toggle pinned=true win.relative=win win.position=right<CR>', desc = 'Open diagnostic workspace quickfix list' },
    },
  },
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()
    end,
  },
  {
    'KronsyC/nvim-license',
    opts = function()
      return {
        name = 'YOUR_USERNAME',
        -- Optional
        -- year = "2023"
      }
    end,

    cmd = {
      'License',
      'LicenseHeader',
      'AutoLicense',
    },
    dependencies = {
      { 'numToStr/Comment.nvim' },
    },
  },
  {
    'vyfor/cord.nvim',
    build = '.\\build',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
}
