return {
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
}
