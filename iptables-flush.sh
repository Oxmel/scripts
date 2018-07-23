#!/bin/bash

# This script deletes every iptables routing entry
# Useful when testing stuff to flush all rules at once
#
# Note that it only takes care of ipv4 rules
# To flush ipv6 routing rules, use the command 'ip6tables' instead

# Check if user has root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Run it as root"
    exit
fi

# Flush all iptables rules
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables -t raw -F
iptables -t raw -X

echo "Done"
