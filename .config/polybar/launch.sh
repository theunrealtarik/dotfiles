#!/usr/bin/env bash

DIR="$HOME/.config/polybar"
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

MONITORS=$(polybar --list-monitors | cut -d":" -f1)

PRIMARY=$(echo "$MONITORS" | head -n1)
SECONDARY=$(echo "$MONITORS" | tail -n1)

# Launch the bar


if [[ "$PRIMARY" == "$SECONDARY" ]]; then
    # Only one monitor
    MONITOR=$PRIMARY polybar primary -c "$DIR"/config.ini &
else
    MONITOR=$PRIMARY polybar primary -c "$DIR"/config.ini &
    MONITOR=$SECONDARY polybar secondary -c "$DIR"/config.ini &
fi
