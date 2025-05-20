#!/bin/bash

# Define the export PATH here to ensure commands like 'free' and 'awk' are found
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# This script is specifically for Linux. The previous macOS part is removed for clarity
# as your environment is confirmed Linux.

# Get the main memory line from 'free -m'
mem_info=$(free -m | grep -E "^Mem:")

# Extract total and available memory (in MB)
# For your 'free -m' output:
# total is column 2
# available is column 7
total_mem=$(echo "$mem_info" | awk '{print $2}')
available_mem=$(echo "$mem_info" | awk '{print $7}')

# Basic validation for total_mem
if [[ -z "$total_mem" || "$total_mem" -eq 0 ]]; then
    echo "?%"
    exit 0
fi

# Calculate used memory (Total - Available)
# This gives memory truly used by applications, excluding buffers/cache
used_mem_calc=$((total_mem - available_mem))

# Calculate percentage (scale=0 for integer percentage)
mem_usage_perc=$(echo "scale=2; $used_mem_calc / $total_mem * 100" | bc -l)

echo "${mem_usage_perc}%"
