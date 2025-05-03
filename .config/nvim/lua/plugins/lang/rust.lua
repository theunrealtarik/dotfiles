return {
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
    'mrcjkb/rustaceanvim',
    version = '^4',
    lazy = false,
    ft = 'rust',
  },
}
