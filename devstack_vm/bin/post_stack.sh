#!/bin/bash
set -x

nova quota-class-update --instances 50 --cores 100 --ram $((51200*4)) --floating-ips 50 --security-groups 50 --security-group-rules 100 default
cinder quota-class-update --snapshots 50 --volumes 50 --gigabytes 2000 default

# NAT
sudo /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo /sbin/iptables -A FORWARD -i eth0 -o br-eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo /sbin/iptables -A FORWARD -i br-eth1 -o eth0 -j ACCEPT
