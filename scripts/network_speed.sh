#!/bin/bash

# File to store previous network stats
PREV_NET_STATS_FILE="/tmp/tmux_net_stats"
INTERVAL=1 # seconds

# Function to get network stats (Linux/macOS)
get_net_stats() {
    if [[ "$(uname)" == "Linux" ]]; then
        awk '
            NR > 2 {
                device = substr($1, 1, index($1, ":") - 1)
                if (device != "lo") { # Exclude loopback
                    rx_bytes += $2
                    tx_bytes += $10
                }
            }
            END { print rx_bytes, tx_bytes }
        ' /proc/net/dev
    elif [[ "$(uname)" == "Darwin" ]]; then
        rx_total=0
        tx_total=0
        # Iterate over network interfaces and sum bytes
        # This approach might be less precise than dedicated tools for specific interfaces
        # but provides a general system overview.
        while IFS= read -r line; do
            if [[ $line =~ "RX bytes:([0-9]+)" ]]; then
                rx_total=$((rx_total + BASH_REMATCH[1]))
            elif [[ $line =~ "TX bytes:([0-9]+)" ]]; then
                tx_total=$((tx_total + BASH_REMATCH[1]))
            fi
        done < <(ifconfig)
        echo "$rx_total $tx_total"
    else
        echo "0 0" # Fallback
    fi
}

current_stats=$(get_net_stats)
current_rx=$(echo "$current_stats" | awk '{print $1}')
current_tx=$(echo "$current_stats" | awk '{print $2}')

# Read previous stats or initialize to 0 for first run
if [[ -f "$PREV_NET_STATS_FILE" ]]; then
    prev_stats=$(cat "$PREV_NET_STATS_FILE")
    prev_rx=$(echo "$prev_stats" | awk '{print $1}')
    prev_tx=$(echo "$prev_stats" | awk '{print $2}')
else
    # Initialize to 0 for the very first run so we can show "0.00 B"
    prev_rx=0
    prev_tx=0
fi

# Calculate difference (rate per second)
rx_diff=$(( (current_rx - prev_rx) / INTERVAL ))
tx_diff=$(( (current_tx - prev_tx) / INTERVAL ))

# Update previous stats file for next run
echo "$current_rx $current_tx" > "$PREV_NET_STATS_FILE"

# --- MODIFIED: Format bytes to "X.YY Unit" with single digit before dot ---
format_fixed_bytes() {
    local bytes_val=$1
    local unit="B"
    local formatted_val=$bytes_val

    local KB=1024
    local MB=$((1024 * KB))
    local GB=$((1024 * MB))
    local TB=$((1024 * GB)) # Just in case for very high speeds

    # Check from largest unit down to find the appropriate one
    if (( $(echo "$bytes_val >= $TB" | bc -l) )); then
        unit="T"
        formatted_val=$(echo "scale=2; $bytes_val / $TB" | bc -l)
    elif (( $(echo "$bytes_val >= $GB" | bc -l) )); then
        unit="G"
        formatted_val=$(echo "scale=2; $bytes_val / $GB" | bc -l)
    elif (( $(echo "$bytes_val >= $MB" | bc -l) )); then
        unit="M"
        formatted_val=$(echo "scale=2; $bytes_val / $MB" | bc -l)
    elif (( $(echo "$bytes_val >= $KB" | bc -l) )); then
        unit="K"
        formatted_val=$(echo "scale=2; $bytes_val / $KB" | bc -l)
    fi

    # Now, ensure it's "X.YY" (one digit before the dot)
    # If the value in the *current* unit is >= 10.00, we need to go to the *next larger unit*
    # (unless we're already at the largest like Terabytes).

    # Simplified logic to ensure one digit before the dot:
    # We essentially divide by 1024 until the value is less than 10.
    # The smallest unit is B, but if it's > 9.99B, we convert to K.
    if (( $(echo "$formatted_val >= 10.00" | bc -l) )); then
        if [[ "$unit" == "B" ]]; then # If it was Bytes and >= 10.00, convert to K
            formatted_val=$(echo "scale=2; $bytes_val / $KB" | bc -l)
            unit="K"
        elif [[ "$unit" == "K" ]]; then # If it was K and >= 10.00, convert to M
            formatted_val=$(echo "scale=2; $bytes_val / $MB" | bc -l)
            unit="M"
        elif [[ "$unit" == "M" ]]; then # If it was M and >= 10.00, convert to G
            formatted_val=$(echo "scale=2; $bytes_val / $GB" | bc -l)
            unit="G"
        elif [[ "$unit" == "G" ]]; then # If it was G and >= 10.00, convert to T (if applicable)
            formatted_val=$(echo "scale=2; $bytes_val / $TB" | bc -l)
            unit="T" # Or keep as G if T is not desired, might show >9.99 G
        fi
    fi

    # Final formatting with printf for 2 decimal places
    printf "%.2f %s" "$formatted_val" "$unit"
}

rx_speed=$(format_fixed_bytes $rx_diff)
tx_speed=$(format_fixed_bytes $tx_diff)

# Always show the formatted speeds, no thresholding
echo "↓${rx_speed} ↑${tx_speed}"
