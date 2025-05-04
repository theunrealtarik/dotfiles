return {
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    tag = 'stable',
    ft = { 'toml' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('crates').setup {
        completion = {
          cmp = {
            enabled = true,
          },
        },
      }
      require('cmp').setup.buffer {
        sources = { { name = 'crates' } },
      }
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^4',
    lazy = false,
    ft = 'rust',
    config = function() end,
  },
}
