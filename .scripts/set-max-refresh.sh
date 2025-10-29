#!/usr/bin/env bash
#
# Automatically set each connected monitor to its highest available refresh rate.
# Requires: xrandr, awk, grep, sort, head

source ./lib/logging.sh

log "Detecting connected monitors..."
MONITORS=$(xrandr | awk '/ connected/{print $1}')

if [ -z "$MONITORS" ]; then
    error "No connected monitors found."
    exit 1
fi

for MON in $MONITORS; do
    log "Configuring monitor: ${YELLOW}${MON}${NC}"

    # Get preferred resolution (marked with '+')
    RES=$(xrandr | awk -v mon="$MON" '
        $0 ~ mon" connected" {show=1; next}
        show && /^[A-Z]/ {show=0}
        show && /\+/ {print $1; exit}
    ')

    if [ -z "$RES" ]; then
        warn "Could not detect preferred resolution for $MON, skipping."
        continue
    fi

    # Get highest refresh rate for that resolution
    RATE=$(xrandr | awk -v mon="$MON" -v res="$RES" '
        $0 ~ mon" connected" {show=1; next}
        show && /^[A-Z]/ {show=0}
        show && $1 == res {
            for (i=2; i<=NF; i++) {
                sub("\\+","",$i)
                sub("\\*","",$i)
                print $i
            }
        }
    ' | sort -nr | head -n1)

    if [ -z "$RATE" ]; then
        warn "No refresh rates found for ${RES} on ${MON}, skipping."
        continue
    fi

    log "Setting ${MON} to ${RES} @ ${RATE}Hz..."
    if xrandr --output "$MON" --mode "$RES" --rate "$RATE"; then
        log "${MON} successfully set to ${RES} @ ${RATE}Hz."
    else
        error "Failed to set ${MON} to ${RES} @ ${RATE}Hz."
    fi
done

log "All set!"

