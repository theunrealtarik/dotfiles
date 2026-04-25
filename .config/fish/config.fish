source /usr/share/cachyos-fish-config/cachyos-config.fish

alias pallete="wal --out-dir ~/.dotfiles/.pallete"

set_color "#fce5d5"
# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
  fastfetch -c minimal
end

function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  set -l show_untracked (git config --bool bash.showUntrackedFiles)
  set -l untracked
  if [ "$theme_display_git_untracked" = 'no' -o "$show_untracked" = 'false' ]
    set untracked '--untracked-files=no'
  end
  echo (command git status -s --ignore-submodules=dirty $untracked 2> /dev/null)
end

function fish_prompt
  set -l last_status $status
  set -l cyan (set_color -o cyan)
  set -l yellow (set_color -o yellow)
  set -l red (set_color -o red)
  set -l blue (set_color -o blue)
  set -l green (set_color -o green)
  set -l normal (set_color normal)

  set -l arrow_color (set_color "#fce5d5")
  set -l path_color (set_color "#807573")

  if test $last_status = 0
      set arrow "$arrow_color➜ "
  else
      set arrow "$red➜ "
  end
  set -l cwd $path_color(basename (prompt_pwd))

  if [ (_git_branch_name) ]
    set -l git_branch $red(_git_branch_name)
    set git_info "$blue git:($git_branch$blue)"

    if [ (_is_git_dirty) ]
      set -l dirty "$yellow ✗"
      set git_info "$git_info$dirty"
    end
  end

  echo -n -s $arrow ' ' $cwd $git_info $normal ' '
end

fish_add_path /home/tarik/.spicetify

# cargo
source "$HOME/.cargo/env.fish"

# brew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# node
# bass source $HOME/.nvm/nvm.sh --no-use
if type -q nvm
    nvm use latest --silent
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
