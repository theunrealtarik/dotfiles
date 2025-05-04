local bufnr = vim.api.nvim_get_current_buf()
local builtin = require 'telescope.builtin'
local harpoon = require 'harpoon'

for i = 1, 3 do
  vim.keymap.set('n', '<leader>h' .. i, function()
    harpoon:list():select(i)
  end, { desc = 'Select item ' .. i })
end

---@class Keymap
---@field [1] string        # Mode (e.g., 'n', 'i')
---@field [2] string        # LHS (keybind)
---@field [3] string|fun()  # RHS (command string or function)
---@field [4]? table        # Options (desc, silent, buffer, etc.)

---@type Keymap[]
local general = {
  { 'n', '<C-s>', '<cmd>write!<CR>', { desc = 'Save File' } },
  { 'n', '<C-z>', '<cmd>:u<CR>', { desc = 'Undo' } },
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Highlighted Search' } },
  { 'n', '<C-Q>', '<cmd>q!<CR>', { desc = 'Quit' } },
}

---@type Keymap[]
local filetree = {
  { 'n', '<leader>ft', '<cmd>NvimTreeFocus<CR>', { desc = '[F]ocus On [T]ree' } },
  { 'n', '<leader>tt', '<cmd>NvimTreeToggle<CR>', { desc = '[T]ree [T]oggle' } },
}

---@type Keymap[]
local navigation = {
  { 'n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' } },
  { 'n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' } },
  { 'n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' } },
  { 'n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' } },
  { 'n', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'n', '<C-e>', '<End>', { desc = 'End of line' } },
  { 'i', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'i', '<C-e>', '<End>', { desc = 'End of line' } },
  { 'v', '<C-b>', '<ESC>^i', { desc = 'Beginning of line' } },
  { 'v', '<C-e>', '<End>', { desc = 'End of line' } },
  {
    'n',
    '<leader>ha',
    function()
      harpoon:list():add()
    end,
    { desc = 'Harpoon Add' },
  },
  {
    'n',
    '<leader>hm',
    function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end,
    { desc = 'Harpoon Menu' },
  },
  {
    'n',
    '<leader>hp',
    function()
      harpoon:list():prev()
    end,
    { desc = 'Harpoon Previous' },
  },
  {
    'n',
    '<leader>hn',
    function()
      harpoon:list():next()
    end,
    { desc = 'Harpoon Nnext' },
  },
}

---@type Keymap[]
local terminal = {
  { 't', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' } },
}

---@type Keymap[]
local diagnostics = {
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
    { desc = 'Diagnostics toggle virtual text' },
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
    { desc = 'Diagnostics Toggle' },
  },
}

---@type Keymap[]
local lsp = {
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
    { desc = 'Lsp Formatting' },
  },
  {
    'n',
    '<leader>ih',
    function()
      local is_enabled = vim.lsp.inlay_hint.is_enabled {}
      vim.lsp.inlay_hint.enable(not is_enabled)
    end,
    { desc = 'Toggle LSP inlay hints' },
  },
}

---@type Keymap[]
local comment = {
  {
    'n',
    '<leader>/',
    function()
      require('Comment.api').toggle.linewise.current()
    end,
    { desc = 'Toggle comment' },
  },
}

---@type Keymap[]
local rust = {
  {
    'n',
    '<leader>ca',
    function()
      vim.cmd.RustLsp 'codeAction'
    end,
    { silent = true, buffer = bufnr },
  },
  {
    'n',
    '<leader>ot',
    function()
      vim.cmd.RustLsp 'openCargo'
    end,
    { desc = "Open project' Cargo.toml file" },
  },
  {
    'n',
    '<leader>od',
    function()
      vim.cmd.RustLsp 'openDocs'
    end,
    { desc = 'Open docs.rs' },
  },
  {
    'n',
    '<leader>jl',
    function()
      vim.cmd.RustLsp 'joinLines'
    end,
    {},
  },
}

---@type Keymap[]
local telescope = {
  { 'n', '<C-p>', builtin.find_files, { desc = 'Search Files' } },
  { 'n', '<leader>sh', builtin.help_tags, { desc = 'Search Help' } },
  { 'n', '<leader>sk', builtin.keymaps, { desc = 'Search Keymaps' } },
  { 'n', '<leader>ss', builtin.builtin, { desc = 'Search Select Telescope' } },
  { 'n', '<leader>sw', builtin.grep_string, { desc = 'Search current Word' } },
  { 'n', '<leader>sg', builtin.live_grep, { desc = 'Search by Grep' } },
  { 'n', '<leader>sd', builtin.diagnostics, { desc = 'Search Diagnostics' } },
  { 'n', '<leader>sr', builtin.resume, { desc = 'Search Resume' } },
  { 'n', '<leader>s.', builtin.oldfiles, { desc = 'Search Recent Files ("." for repeat)' } },
  { 'n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' } },
}

---@type Keymap[]
local keymaps = {}

vim.list_extend(keymaps, general)
vim.list_extend(keymaps, filetree)
vim.list_extend(keymaps, navigation)
vim.list_extend(keymaps, terminal)
vim.list_extend(keymaps, diagnostics)
vim.list_extend(keymaps, lsp)
vim.list_extend(keymaps, comment)
vim.list_extend(keymaps, rust)
vim.list_extend(keymaps, telescope)
vim.list_extend(keymaps, harpoon)

for _, map in ipairs(keymaps) do
  vim.keymap.set(map[1], map[2], map[3], map[4])
end
