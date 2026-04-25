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
    init_option = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              inlayHints = {
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 25 },
                parameterHints = { enable = true },
                typeHints = { enable = true },
              },
            },
          },
        },
      }
    end,
  },
}
