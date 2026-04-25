return {
  filename = function(buffer)
    buffer = buffer or vim.api.nvim_get_current_buf()
    return vim.fs.basename(vim.api.nvim_buf_get_name(buffer))
  end,
  capitalize = function(str)
    return str:sub(1, 1):upper() .. str:sub(2):lower()
  end,
  conditional = function(element, cond)
    if cond then
      return element
    end
  end,
}
