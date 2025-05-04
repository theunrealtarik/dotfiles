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
