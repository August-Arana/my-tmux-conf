#!/bin/bash

if [[ "$(uname)" == "Linux" ]]; then
    # Read /proc/stat directly — reliable across all distros
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    used=$((total - idle - iowait))

    prev_file="/tmp/tmux_cpu_prev"
    if [[ -f "$prev_file" ]]; then
        read -r prev_total prev_used < "$prev_file"
        dt=$((total - prev_total))
        du=$((used - prev_used))
        if (( dt > 0 )); then
            cpu_usage=$(( du * 100 / dt ))
        else
            cpu_usage=0
        fi
    else
        cpu_usage=0
    fi
    echo "$total $used" > "$prev_file"
elif [[ "$(uname)" == "Darwin" ]]; then
    cpu_idle=$(top -l 1 | awk '/CPU usage/ {gsub(/%/,"",$7); print $7}')
    cpu_usage=$(echo "100 - $cpu_idle" | bc)
else
    cpu_usage="?"
fi

if (( cpu_usage > 70 )); then
    echo "#[fg=#e06c75] ${cpu_usage}%"
elif (( cpu_usage > 40 )); then
    echo "#[fg=#e5c07b] ${cpu_usage}%"
else
    echo "#[fg=#282c34] ${cpu_usage}%"
fi
