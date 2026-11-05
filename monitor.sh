#Monitor AWS metrics

#!/bin/bash

# Linux Infrastructure Monitoring
# Project: AWS Infrastructure Monitoring
# Version: 1.0

set -u

# Monitoring thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

# Display server information
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "========================================"
echo "     LINUX SERVER MONITORING"
echo "========================================"
echo "Hostname : $HOSTNAME"
echo "Date     : $TIMESTAMP"
echo "========================================"

# Function to check CPU utilization
check_cpu() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

    CPU_IDLE1=$((idle + iowait))
    CPU_TOTAL1=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1

    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

    CPU_IDLE2=$((idle + iowait))
    CPU_TOTAL2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    TOTAL_DIFF=$((CPU_TOTAL2 - CPU_TOTAL1))
    IDLE_DIFF=$((CPU_IDLE2 - CPU_IDLE1))

    if [ "$TOTAL_DIFF" -gt 0 ]; then
        CPU_USAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
    else
        CPU_USAGE=0
    fi

    echo ""
    echo "CPU Usage: ${CPU_USAGE}%"

    if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
        echo "WARNING: High CPU utilization"
    else
        echo "STATUS: CPU utilization normal"
    fi
}

# Function to check memory utilization
check_memory() {
    MEMORY_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    MEMORY_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if [ -z "$MEMORY_TOTAL" ] || [ -z "$MEMORY_AVAILABLE" ] || [ "$MEMORY_TOTAL" -eq 0 ]; then
        echo "ERROR: Unable to read memory information"
        return 1
    fi

    MEMORY_USED=$((MEMORY_TOTAL - MEMORY_AVAILABLE))
    MEMORY_USAGE=$((100 * MEMORY_USED / MEMORY_TOTAL))

    echo ""
    echo "Memory Usage: ${MEMORY_USAGE}%"

    if [ "$MEMORY_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
        echo "WARNING: High memory utilization"
    else
        echo "STATUS: Memory utilization normal"
    fi
}

# Function to check disk utilization
check_disk() {
    echo ""
    echo "Disk Usage:"
    df -hP -x tmpfs -x devtmpfs | awk 'NR==1 || $5+0 >= 0 {
        print
    }'

    echo ""
    echo "Disk Usage Warnings:"

    df -P -x tmpfs -x devtmpfs | awk -v threshold="$DISK_THRESHOLD" '
    NR > 1 {
        usage=$5
        gsub("%", "", usage)

        if (usage >= threshold) {
            printf "WARNING: %s is %s%% full\n", $6, usage
        }
    }'
}

# Execute monitoring checks
check_cpu
check_memory
check_disk

echo ""
echo "========================================"
echo "Monitoring completed"
echo "========================================"
