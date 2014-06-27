#!/bin/bash 
################################################################################
# 
# Setup networking and iptables forwarding rules for kippo.
#
# Auto selects if there is only one interface, otherwise asks you to specify.
#
# REAL_SSH_PORT:  port you want the real OpenSSH service to listen on.
# KIPPO_PORT:     port the twistd daemon listens on (default 2222)
# KIPPO_SSH_PORT: port to forward SSH attacks from (default 22)
# INTERFACE:      networking interface all this is happening on. Set to avoid prompts
#
# Author: alienelephant
# Part of: https://github.com/alienelephant/kippo-frankenstein
# Version 1.0
#
################################################################################

if [[ $EUID -ne 0 ]]; then
  echo "Must be run as root"
  exit 1
fi

IPT=`which iptables`
REAL_SSH_PORT=5223
KIPPO_PORT=2222
KIPPO_SSH_PORT=22

# info gathering
INTERFACES=($(ifconfig |grep HWaddr|awk '{print $1}'))
INTERFACE=${INTERFACES}
if [ ! ${#INTERFACES[@]} -eq 1 ]; then
        read -p "Select interface (${INTERFACES[*]}): " -e INTERFACE
        FOUND="grep $INTERFACE: /proc/net/dev"

        if [ -z "$FOUND" ]; then
                echo "Interface '$INTERFACE' not founnd. Exiting"
                exit 1
        fi
fi

echo "Using $INTERFACE"

# Drop EVERYTHING from ipv6
if [ -f /sbin/ip6tables ]; then
        /sbin/ip6tables -P INPUT DROP
        /sbin/ip6tables -P FORWARD DROP
        /sbin/ip6tables -P OUTPUT DROP
fi

# Flush everything
$IPT -F LOGDROP
$IPT -F INPUT
$IPT -F OUTPUT
$IPT -F FORWARD
$IPT -t nat -F
$IPT -X

# Default policies
$IPT -P INPUT DROP
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT

## Setup logging chains
$IPT -N LOGDROP
$IPT -A LOGDROP -j LOG --log-prefix "iptables: " --log-level 4
$IPT -A LOGDROP -j DROP

## Input chain
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -i ${INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT

# Drop brute force attacks if >5 attemtps in 60 seconds
$IPT -A INPUT -p tcp --dport ${REAL_SSH_PORT} -m state --state NEW -m recent --set
$IPT -A INPUT -p tcp -i ${INTERFACE} -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j LOGDROP

# Allow SSH
$IPT -A INPUT -p tcp --dport ${REAL_SSH_PORT} -j ACCEPT
$IPT -A INPUT -p tcp --dport ${KIPPO_SSH_PORT} -j ACCEPT
$IPT -A INPUT -p tcp --dport ${KIPPO_PORT} -j ACCEPT

# KIPPO rules
$IPT -t nat -A PREROUTING -i ${INTERFACE} -p tcp --dport ${KIPPO_SSH_PORT} -j REDIRECT --to-port ${KIPPO_PORT}

# Default log and drop
$IPT -A INPUT -j LOGDROP
