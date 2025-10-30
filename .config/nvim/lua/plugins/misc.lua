return {
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
  { 'numToStr/Comment.nvim', opts = {}, lazy = false },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup()
    end,
  },
  {
    'KronsyC/nvim-license',
    opts = function()
      return {
        name = 'theunrealtarik',
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
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'vyfor/cord.nvim',
    build = ':Cord update',
    -- opts = {}
  }
}
