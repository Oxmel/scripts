#!/bin/bash


# IP Info 0.1 - Simple wrapper for ipinfo.io api
#
# I deliberaltely limited the current options at the ones that
# don't require an api key but more will be added in the future
# With the ability to use a token which will give an access
# to a set of more advanced features proposed by ipinfo.io
#
# Especially the possibility to use a more fine-grained filtering,
# or to use their 'batch' system which allows to send up to 100
# ip address in only one POST request. Instead of having to send
# them one by one like in the current implementation.


BASEURL="ipinfo.io"


helper() {
cat <<"EOF"
IP Info 0.1 - Simple wrapper for ipinfo.io api
Displays details for a single address or a list
Uses the calling ip if no options are provided

Usage: ipinfo [option] <arg>

Options:
  -i    <ip>      Lookup for a specific address
  -f    <file>    Read a raw list of ip from a file
  -h              Display this message

Examples:
  ipinfo -i 8.8.8.8
  ipinfo -f /tmp/iplist.txt
EOF
}


# option with params = :o: - option without params = :o
while getopts ":i:f:h" option; do
    case $option in
        i)
            curl -s $BASEURL/$OPTARG ; echo
            ;;
        f)
            # Read each IP in the file and pass them in the loop
            # We use the option '/geo' to output results faster
            # Note that ipinfo can accept a batch of ips with only
            # one call to the API. But it requires a token
            xargs -a $OPTARG -I% curl -s $BASEURL/%/geo ; echo
            ;;
        h)
            helper
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            echo "Use -h for a list of available options"
            exit
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit
            ;;
    esac
done


# Get details for the calling address if no options are provided
# Double brackets so we don't have to use quotes for the comparison
if [[ $# -eq 0 ]]; then
    curl -s $BASEURL ; echo
fi
