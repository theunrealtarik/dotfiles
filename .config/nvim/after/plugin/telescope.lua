local builtin = require 'telescope.builtin'

vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Search Files' })
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Search Help' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Search Keymaps' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Search Select Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Search current Word' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search by Grep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Search Diagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Search Resume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Search Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
