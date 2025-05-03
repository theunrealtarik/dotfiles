return {
  filename = function(buffer)
    buffer = buffer or vim.api.nvim_get_current_buf()
    return vim.fs.basename(vim.api.nvim_buf_get_name(buffer))
  end,
}
