#!/bin/bash


# PiStats: Gather and display Raspi system stats
# Such as uptime, load average, mem and disk(s) usage,...
#
# This script also provides two options (see lists below) to :
# 1) Check if given interfaces can reach the net and if dns queries work
# 2) Check the state and sub state of given services (e.g : active/running)
#
# Originally made for a raspberry pi running on raspbian jessie, but probably
# portable enough to be used on other debian derivatives


# Lists of interfaces to check (separated by a space)
# Accepts either an interface name (e.g: eth0) or an interface ip
ifaceList=(eth0)

# Fill this list with the name of the services you want to check
serviceList=(
    nginx
    mysql
    ssh
)

# Colors
# Usage : echo -e "${color}some text${nc}" or printf "${color}some text${nc}\n"
# 'nc' stands for no color
# https://stackoverflow.com/a/5947802/9598957
green="\033[0;32m"
yellow="\033[0;33m"
red="\033[0;31m"
nc="\033[0m"

uptime=$(uptime | awk '{print $3, $4}' | sed 's/,//g')
loadAvg=$(cat /proc/loadavg | awk '{print $1,$2,$3}')

# Amount of ram used by programs only (not counting buffering and disk cache)
memUsed=$(free -m |  awk '/buffers\/cache:/{print $3}')
memTotal=$(free -m | awk '/Mem:/{print $2}')
swapTotal=$(free -m | awk '/Swap:/{print $2}')
swapUsed=$(free -m | awk '/Swap:/{print $3}')

# Extract the name of each partition (e.g: sda1)
# Use option '-x' to exclude certain file systems like tmp or boot partition
diskList=$(df -h -x tmpfs -x devtmpfs -x vfat | grep -Po '^\/dev\/\K\S*')

# Check internet access for each interface present in $ifaceList
ifaceCheck() {
    if ping -q -c 1 -W 1 -I $1 google.com >> /dev/null 2>&1; then
        printf "[${green}OK${nc}]\n"
    else
        printf "[${red}KO${nc}]\n"
    fi
}

# Check status and sub status of each service in $serviceList using systemd
# We need to manually extract the value with systemd versions prior to 230
# Since version 230, the option --value gives the same result automatically
# https://unix.stackexchange.com/a/435317/284125
serviceCheck() {
    state=$(systemctl show -p ActiveState $1 | sed 's/ActiveState=//g')
    subState=$(systemctl show -p SubState $1 | sed 's/SubState=//g')
    if [[ "$state" == "active" && "$subState" == "running" ]]; then
        printf "[${green}OK${nc}]\n"
    elif [[ "$state" == "active" && "$subState" == "exited" ]]; then
        printf "[${yellow}EX${nc}]\n"
    elif [[ "$state" == "inactive" && "$subState" == "dead" ]]; then
        printf "[${red}KO${nc}]\n"
    else
        printf "[${red}ER${nc}]\n"
    fi
}

# We use a mix of echo and printf to preserve code readability over portability
echo
echo "SYSTEM"
echo "-----------------------------------"
echo "uptime: ${uptime} avg: ${loadAvg}"
echo "ram: [${memUsed}/${memTotal}MB] swap: [${swapUsed}/${swapTotal}MB]"

echo
echo "STORAGE"
echo "-----------------------------------"
(
printf "Label\tUsed\tAvail\tTotal\tUse%%\n"
for item in ${diskList[@]}; do
    diskStats=($(df -h | grep "$item" | awk '{print $3, $4, $2, $5}'))
    printf '%-9s\t%s\t%s\t%s\t%s\n' "$item" "${diskStats[@]}"
done
) | column -t -s $'\t'

echo
echo "INTERFACES"
echo "-----------------------------------"
for item in ${ifaceList[@]}; do
    printf "%-30s %s\n" "$item" $(ifaceCheck $item)
done

echo
echo 'SERVICES'
echo '-----------------------------------'
for item in ${serviceList[@]}; do
    printf "%-30s %s\n" "$item" $(serviceCheck $item)
done
echo
