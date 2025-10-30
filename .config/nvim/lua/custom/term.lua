local state = {
  term = { buf = -1, win = -1 },
}

local function create_floating_window(opts)
  opts = opts or {}

  local ui = vim.api.nvim_list_uis()[1]

  local width = opts.width or math.floor(ui.width * 0.7)
  local height = opts.height or math.floor(ui.height * 0.7)

  local col = math.floor((ui.width - width) / 2)
  local row = math.floor((ui.height - height) / 2)

  local buf = nil

  if not vim.api.nvim_buf_is_valid(opts.buf) then
    buf = vim.api.nvim_create_buf(false, true)
  else
    buf = opts.buf
  end

  local win = vim.api.nvim_open_win(buf, true, {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
  })

  return { buf = buf, win = win }
end

local function toggle_terminal()
  if not vim.api.nvim_win_is_valid(state.term.win) then
    if vim.api.nvim_get_mode() ~= 'insert' then
      vim.cmd 'startinsert'
    end

    state.term = create_floating_window { buf = state.term.buf }
    if vim.bo[state.term.buf].buftype ~= 'terminal' then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.term.win)
  end
end

-- vim.keymap.set({ 'n', 'i' }, '<C-t>', toggle_terminal, { desc = 'Toggle a floating terminal' })
