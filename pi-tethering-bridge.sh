#!/bin/bash

# Configure a Raspberry Pi as a transparent bridge to interface a tethered
# phone (usb) to a routeur (ethernet). We then plug the Pi to the wan port of
# the router to share the internet access provided by the phone.

# This script is a variant of 'pi-modem-router.sh' (see my 'scripts' repo)
# which gives the same result but uses ip forwarding instead of bridging.
# And from my experience, if ip forwarding offers a more generic approach, it
# can also cause latency issues due to the overhead, where bridging offers a
# more performant and straightforward method.

# Note that we use the two options 'pre-up' and 'down' to ensure that the usb
# interface will be automatically re-added to the bridge if we unplug the phone
# and plug it back in later on.


echo "Adding new rules to /etc/network/interfaces"

cat >> /etc/network/interfaces <<EOF

# Tethering setup
allow-hotplug usb0
iface usb0 inet manual
    pre-up ifup br0
    down ifdown br0

# Bridge setup
iface br0 inet dhcp
    bridge_ports eth0 usb0
EOF

echo "Done, reboot to apply changes."
