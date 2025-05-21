#!/bin/bash

# Get CPU idle percentage
# macOS: use 'sysctl -n vm.loadavg' or 'top -l 1'
# Linux: use 'top -bn1'

if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    cpu_idle=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
    cpu_usage=$(echo "100 - $cpu_idle" | bc)
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux
    cpu_idle=$(LC_ALL=C top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/,//')
    cpu_usage=$(echo "100 - $cpu_idle" | bc)
else
    cpu_usage="?" # Fallback for other OS
fi

# Basic coloring based on usage (optional, remove if you prefer fixed colors)
if (( $(echo "$cpu_usage > 70" | bc -l) )); then
    echo "#[fg=red]${cpu_usage}%"
elif (( $(echo "$cpu_usage > 40" | bc -l) )); then
    echo "#[fg=yellow]${cpu_usage}%"
else
    echo "#[fg=green]${cpu_usage}%"
fi
