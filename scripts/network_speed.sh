#!/bin/bash

PREV_NET_STATS_FILE="/tmp/tmux_net_stats"

if [[ "$(uname)" == "Linux" ]]; then
    stats=$(awk 'NR>2 { split($1,a,":"); if(a[1]!="lo"){ rx+=$2; tx+=$10 } } END{print rx,tx}' /proc/net/dev)
else
    echo "↓- ↑-"
    exit 0
fi

current_rx=$(echo "$stats" | awk '{print $1}')
current_tx=$(echo "$stats" | awk '{print $2}')

if [[ -f "$PREV_NET_STATS_FILE" ]]; then
    read -r prev_rx prev_tx < "$PREV_NET_STATS_FILE"
else
    prev_rx=$current_rx
    prev_tx=$current_tx
fi

echo "$current_rx $current_tx" > "$PREV_NET_STATS_FILE"

rx_diff=$(( current_rx - prev_rx ))
tx_diff=$(( current_tx - prev_tx ))

fmt() {
    local b=$1
    if   (( b >= 1073741824 )); then printf "%.1fG" "$(echo "scale=1; $b/1073741824" | bc)"
    elif (( b >= 1048576 ));    then printf "%.1fM" "$(echo "scale=1; $b/1048576"    | bc)"
    elif (( b >= 1024 ));       then printf "%.1fK" "$(echo "scale=1; $b/1024"       | bc)"
    else                             printf "%dB"   "$b"
    fi
}

echo "↓$(fmt $rx_diff) ↑$(fmt $tx_diff)"
