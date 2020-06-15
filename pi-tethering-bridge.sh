#!/bin/bash

# Configure a Raspberry Pi as a transparent bridge to interface a tethered
# phone (usb) with a routeur (ethernet). We then plug the Pi to the wan port of
# the router to share the internet access provided by the phone.
#
# This method offers couple advantages compared to ip forwarding. We don't
# need to create iptables rules, we don't need two differents subnets, and
# we also don't need to install and manage a dhcp server. All we have to do is
# to create the bridge and ask the dhcp server of the phone for an address.
#
# Also, we can use the phone as a trigger to control the bridge dynamically with
# the two options 'pre-up' and 'down'. So when the phone is plugged in, the
# bridge is automatically set up and vice versa.
#
# On the other hand, the main problem with this setup is the fact that if the
# phone is not connected, the Pi becomes unreachable from the local network. And
# even if the phone is connected, the IP of the bridge may change from time to time.
# In these conditions, trying to manage the Pi via ssh can quickly become a pain.
#
# One solution consists of using another network interface like a usb to ethernet
# adapter. That way, if something goes wrong we only have to plug the adapter to
# access the Pi again. And we can either give it a static IP or a permanent DHCP
# lease via the router's configuration.


if [[ $EUID -ne 0 ]]; then
    echo "Run it as root"
    exit
fi

# We could use 'iproute2' instead but 'brctl' offers a simpler syntax.
# https://unix.stackexchange.com/a/255489/284125
if ! command -v brctl &> /dev/null; then
    echo "This script requires 'brctl'"
    echo "Run 'apt install bridge-utils' to install it"
    exit
fi

echo "Adding new rules to /etc/network/interfaces"

cat >> /etc/network/interfaces <<EOF

# Ethernet (built-in)
iface eth0 inet manual

# Ethernet (usb adapter)
allow-hotplug eth1
iface eth1 inet dhcp

# Tethering
allow-hotplug usb0
iface usb0 inet manual
    pre-up ifup br0
    down ifdown br0

# Bridge
iface br0 inet dhcp
    bridge_ports eth0 usb0
EOF

echo "Done, reboot to apply changes."
