return {
  misc = {
    dots = '󰇘',
  },
  ft = {
    octo = '',
  },
  modes = {
    Normal = {
      nerd  = "",
      utf8  = "⎈",
      emoji = "🧭",
    },

    Insert = {
      nerd  = "",
      utf8  = "✎",
      emoji = "✍️",
    },

    Visual = {
      nerd  = "",
      utf8  = "▢",
      emoji = "👁️",
    },

    VisualLine = {
      nerd  = "",
      utf8  = "▤",
      emoji = "📏",
    },

    VisualBlock = {
      nerd  = "",
      utf8  = "▥",
      emoji = "🧱",
    },

    Command = {
      nerd  = "ﲵ",
      utf8  = "⌘",
      emoji = "💻",
    },

    Replace = {
      nerd  = "",
      utf8  = "↺",
      emoji = "🔁",
    },

    Terminal = {
      nerd  = "",
      utf8  = "⎆",
      emoji = "🖥️",
    },

    current_mode_icon = function(style)
      local mode_name_map = {
        n     = "Normal",
        i     = "Insert",
        v     = "Visual",
        V     = "VisualLine",
        [""] = "VisualBlock",
        c     = "Command",
        r     = "Replace",
        R     = "Replace",
        t     = "Terminal",
      }

      local mode_icons = require('lib.icons').modes
      local mode = vim.api.nvim_get_mode().mode
      local name = mode_name_map[mode] or "Normal"
      return mode_icons[name][style or 'nerd']
    end
  },
  dap = {
    Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
    Breakpoint = ' ',
    BreakpointCondition = ' ',
    BreakpointRejected = { ' ', 'DiagnosticError' },
    LogPoint = '.>',
  },
  diagnostics = {
    Error = ' ',
    Warn = ' ',
    Hint = ' ',
    Info = ' ',
  },
  git = {
    added = ' ',
    modified = ' ',
    removed = ' ',
  },
  kinds = {
    Array = ' ',
    Boolean = '󰨙 ',
    Class = ' ',
    Codeium = '󰘦 ',
    Color = ' ',
    Control = ' ',
    Collapsed = ' ',
    Constant = '󰏿 ',
    Constructor = ' ',
    Copilot = ' ',
    Enum = ' ',
    EnumMember = ' ',
    Event = ' ',
    Field = ' ',
    File = ' ',
    Folder = ' ',
    Function = '󰊕 ',
    Interface = ' ',
    Key = ' ',
    Keyword = ' ',
    Method = '󰊕 ',
    Module = ' ',
    Namespace = '󰦮 ',
    Null = ' ',
    Number = '󰎠 ',
    Object = ' ',
    Operator = ' ',
    Package = ' ',
    Property = ' ',
    Reference = ' ',
    Snippet = '󱄽 ',
    String = ' ',
    Struct = '󰆼 ',
    Supermaven = ' ',
    TabNine = '󰏚 ',
    Text = ' ',
    TypeParameter = ' ',
    Unit = ' ',
    Value = ' ',
    Variable = '󰀫 ',
  },
}
