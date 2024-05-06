#!/bin/bash

# Define the IP address and use curl to retrieve the CIDR ranges
ip_address="3.91.221.106"

# Retrieve the JSON and filter the entries
cidr_data=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes[] | select(.region=="us-east-1") | "\(.ip_prefix) \(.region) \(.service)"')

# Function to check if IP address belongs to a CIDR range
ip_in_cidr() {
    local ip=$1
    local cidr=$2

    local network_address=$(echo $cidr | cut -d'/' -f1)
    local subnet_mask=$(echo $cidr | cut -d'/' -f2)
    local subnet_bits=$(( 32 - subnet_mask ))

    local ip_binary=$(echo $ip | awk -F'.' '{printf "%08d%08d%08d%08d\n", $1, $2, $3, $4}')
    local network_binary=$(echo $network_address | awk -F'.' '{printf "%08d%08d%08d%08d\n", $1, $2, $3, $4}')

    local ip_network=$(echo $ip_binary | cut -c1-$subnet_mask)
    local network_network=$(echo $network_binary | cut -c1-$subnet_mask)

    if [ "$ip_network" = "$network_network" ]; then
        return 0
    else
        return 1
    fi
}

# Store matching CIDR ranges
matching_cidr_ranges=()

# Check if IP address belongs to any of the CIDR ranges
while read line; do
    cidr=$(echo $line | cut -d' ' -f1)
    if ip_in_cidr $ip_address $cidr; then
        matching_cidr_ranges+=("$line")
    fi
done <<< "$cidr_data"

# Check if any matching CIDR ranges were found
if [ ${#matching_cidr_ranges[@]} -eq 0 ]; then
    echo "IP address $ip_address does not belong to any of the provided CIDR ranges"
    exit 1
else
    echo "IP address $ip_address belongs to the following CIDR ranges:"
    for range_info in "${matching_cidr_ranges[@]}"; do
        echo "$range_info"
    done
    exit 0
fi

