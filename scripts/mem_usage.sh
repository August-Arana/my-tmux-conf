#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

mem_info=$(free -m | awk '/^Mem:/ {print $2, $7}')
total_mem=$(echo "$mem_info" | awk '{print $1}')
available_mem=$(echo "$mem_info" | awk '{print $2}')

if [[ -z "$total_mem" || "$total_mem" -eq 0 ]]; then
    echo "?%"
    exit 0
fi

used_mem=$(( total_mem - available_mem ))
mem_perc=$(( used_mem * 100 / total_mem ))

echo "${mem_perc}%"
