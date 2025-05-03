local keymaps = {
  -- General
  { 'n', '<C-s>', '<cmd>write!<CR>', { desc = 'Save File' } },
  { 'n', '<C-z>', '<cmd>:u<CR>', { desc = 'Undo' } },
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Highlighted Search' } },
  { 'n', '<C-Q>', '<cmd>q!<CR>', { desc = '[Q]uit' } },

  -- File Tree
  { 'n', '<leader>ft', '<cmd>NvimTreeFocus<CR>', { desc = '[F]ocus On [T]ree' } },
  { 'n', '<leader>tt', '<cmd>NvimTreeToggle<CR>', { desc = '[T]ree [T]oggle' } },

  -- Window Navigation
  { 'n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' } },
  { 'n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' } },
  { 'n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' } },
  { 'n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' } },

  -- Line Navigation
  { 'n', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'n', '<C-e>', '<End>', { desc = 'End of line' } },
  { 'i', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'i', '<C-e>', '<End>', { desc = 'End of line' } },
  { 'v', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'v', '<C-e>', '<End>', { desc = 'End of line' } },

  -- Terminal
  { 't', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' } },

  -- Diagnostics
  {
    'n',
    '<leader>]',
    function()
      vim.diagnostic.jump { count = 1, float = true }
    end,
    { desc = 'Go to next Diagnostic message' },
  },
  { 'n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic Error messages' } },
  {
    'n',
    '<leader>lV',
    function()
      local v = vim.diagnostic.config().virtual_text
      vim.diagnostic.config { virtual_text = not v }
    end,
    { desc = '[D]iagnostics Toggle [V]irtual [T]ext' },
  },
  {
    'n',
    '<leader>lT',
    function()
      if vim.diagnostic.is_enabled() then
        vim.diagnostic.enable(false)
      else
        vim.diagnostic.enable()
      end
    end,
    { desc = '[D]iagnostics [T]oggle' },
  },

  -- LSP
  {
    'n',
    'K',
    function()
      vim.lsp.buf.hover()
    end,
    { desc = 'LSP Hover' },
  },
  {
    'n',
    '<leader>lfm',
    function()
      vim.lsp.buf.format { async = false }
    end,
    { desc = '[L]sp [F]or[m]atting' },
  },
  {
    'n',
    '<leader>ih',
    function()
      local is_enabled = vim.lsp.inlay_hint.is_enabled {}
      vim.lsp.inlay_hint.enable(not is_enabled)
    end,
    { desc = 'Toggle LSP Inlay Hints' },
  },

  -- Comment
  {
    'n',
    '<leader>/',
    function()
      require('Comment.api').toggle.linewise.current()
    end,
    { desc = 'Toggle Comment' },
  },
}

for _, map in ipairs(keymaps) do
  vim.keymap.set(map[1], map[2], map[3], map[4])
end
