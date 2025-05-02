local harpoon = require 'harpoon'

vim.keymap.set('n', '<leader>ha', function()
  harpoon:list():add()
end, { desc = 'Harpoon Add' })

vim.keymap.set('n', '<leader>hm', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = 'Harpoon Menu' })

for i = 1, 3 do
  vim.keymap.set('n', '<leader>h' .. i, function()
    harpoon:list():select(i)
  end, { desc = 'Select item ' .. i })
end

vim.keymap.set('n', '<leader>hp', function()
  harpoon:list():prev()
end, { desc = 'Harpoon Previous' })
vim.keymap.set('n', '<leader>hn', function()
  harpoon:list():next()
end, { desc = 'Harpoon Nnext' })
