#!/bin/bash
#
#          Tested on Raspbian Jessie, Stretch and Buster (lite)
#
# The main purpose of this script is to forward the connection
# between the two interfaces wlan0 and eth0 to turn the Pi into a
# a modem-router. Where wlan0 acts as the 'wan' port.
# It also installs dnsmasq as a dhcp server for the ethernet port.
#
# For more infos and use cases, see the project 'hotspot-connect'
# https://github.com/Oxmel/hotspot-connect


# For some reason, network interfaces on raspbian buster still use the
# old naming standards (e.g: wlan0, eth0,...). Which doesn't follow
# the new interface naming system implemented recently on debian.
wlan_name="wlan0"
eth_name="eth0"


# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Run it as root"
    exit
fi


# Check if internet is reachable
echo "Connectivity check..."
wget -q --tries=5 --timeout=10 --spider https://google.com > /dev/null
if [[ $? -eq 0 ]]; then
    echo "Passed"
else
    echo "Failed!"
    exit
fi

# Only hide standard output, errors will still be displayed (if any)
echo "Installing dnsmasq..."
apt-get install dnsmasq -y > /dev/null && echo "Done" || { echo "Failed!"; exit; }


# Set up dhcp range for ethernet interface
# Current config allows 5 machines max to be addressed via dhcp
echo "Creating config for dnsmasq"
cat > /etc/dnsmasq.conf <<EOF
interface=$eth_name
dhcp-range=10.0.0.2,10.0.0.7,255.255.255.0,12h
EOF


echo "Configuring interfaces"


# Prevent dhcpcd from addressing eth0
echo "denyinterfaces $eth_name" >> /etc/dhcpcd.conf


# If dhcpcd detects that the main 'interfaces' file has been altered, it will
# stop managing network interfaces. But we still need it to handle dhcp
# requests on wlan0 so we write the custom config for eth0 in the folder
# '/etc/network/interfaces.d' instead.
cat >> /etc/network/interfaces.d/eth0-router <<EOF

# Provide a static ip for ethernet iface
allow-hotplug $eth_name
iface $eth_name inet static
    address 10.0.0.1
    netmask 255.255.255.0
    network 10.0.0.0
    broadcast 10.0.0.255

# Apply iptables rules once interfaces are up
post-up /etc/network/if-up.d/net-forward.sh
EOF


echo "Creating routing rules"
cat > /etc/network/if-up.d/net-forward.sh <<EOF
# Route wlan connection to ethernet subnet
iptables -t nat -A POSTROUTING -o $wlan_name -s 10.0.0.0/24 -j MASQUERADE
# Forward connection between those two interfaces
iptables -A FORWARD -i $wlan_name -o $eth_name -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $eth_name -o $wlan_name -j ACCEPT
EOF
chmod +x /etc/network/if-up.d/net-forward.sh


echo "Activating ipv4 forwarding"
sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
sed -i 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf


echo "Done (reboot to apply changes)"
