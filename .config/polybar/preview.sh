path="$HOME/.dotfiles/.config/polybar/config.ini"

killall -q polybar
polybar -r secondary -c $path
