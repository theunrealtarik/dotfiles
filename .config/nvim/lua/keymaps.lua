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
local keymaps = {}

---@type Keymap[]
local general = {
  { 'n', '<C-s>', '<cmd>write!<CR>', { desc = 'Save File' } },
  { 'n', '<C-z>', '<cmd>:u<CR>', { desc = 'Undo' } },
  { 'n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Highlighted Search' } },
  { 'n', '<C-Q>', '<cmd>q!<CR>', { desc = 'Quit' } },
}
vim.list_extend(keymaps, general)

---@type Keymap[]
local filetree = {
  { 'n', '<leader>ft', '<cmd>NvimTreeFocus<CR>', { desc = '[F]ocus On [T]ree' } },
  { 'n', '<leader>tt', '<cmd>NvimTreeToggle<CR>', { desc = '[T]ree [T]oggle' } },
}
vim.list_extend(keymaps, filetree)

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
vim.list_extend(keymaps, navigation)

---@type Keymap[]
local terminal = {
  { 't', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' } },
}
vim.list_extend(keymaps, terminal)

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
vim.list_extend(keymaps, diagnostics)

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
vim.list_extend(keymaps, lsp)

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
vim.list_extend(keymaps, comment)

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
vim.list_extend(keymaps, rust)

---@type Keymap[]
local telescope = {
  -- { 'n', '<C-p>', builtin.git_files, { desc = 'Search git files' } },
  { 'n', '<C-p>', builtin.find_files, { desc = 'Search files' } },
  { 'n', '<leader>sh', builtin.help_tags, { desc = 'Search help' } },
  { 'n', '<leader>sk', builtin.keymaps, { desc = 'Search keymaps' } },
  { 'n', '<leader>ss', builtin.builtin, { desc = 'Search select telescope' } },
  { 'n', '<leader>sw', builtin.grep_string, { desc = 'Search current word' } },
  { 'n', '<leader>sg', builtin.live_grep, { desc = 'Search by grep' } },
  { 'n', '<leader>sd', builtin.diagnostics, { desc = 'Search diagnostics' } },
  { 'n', '<leader>sr', builtin.resume, { desc = 'Search resume' } },
  { 'n', '<leader>s.', builtin.oldfiles, { desc = 'Search recent files ("." for repeat)' } },
  { 'n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' } },
}
vim.list_extend(keymaps, telescope)

---@type Keymap[]
local debugging = {
  { 'n', '<leader>db', '<cmd>DapToggleBreakpoint<cr>', { desc = 'Debugger toggle breakpoint' } },
  { 'n', '<leader>dl', '<cmd>DapStepInto<CR>', { desc = 'Debugger step into' } },
  { 'n', '<leader>dj', '<cmd>DapStepOver<CR>', { desc = 'Debugger step over' } },
  { 'n', '<leader>dk', '<cmd>DapStepOut<CR>', { desc = 'Debugger step out' } },
  { 'n', '<leader>dc', '<cmd>DapContinue<CR>', { desc = 'Debugger continue' } },
  {
    'n',
    '<leader>di',
    function()
      local widgets = require 'dap.ui.widgets'
      local sidebar = widgets.sidebar(widgets.scopes)
      sidebar.open()
    end,
    { desc = 'Open debugging inspector sidebar' },
  },
}
vim.list_extend(keymaps, debugging)

---
for _, map in ipairs(keymaps) do
  vim.keymap.set(map[1], map[2], map[3], map[4])
end
