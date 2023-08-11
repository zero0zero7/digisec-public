#!/bin/sh

ip -6 addr add VM6 dev eth0

# ip -6 link set eth0 up
# ip route add default via 172.16.0.65 dev eth0
# default via 172.16.0.13 dev eth0
# 172.16.0.12/30 dev eth0 scope link  src 172.16.0.14

# ip -f inet addr show eth1 | awk '/inet / {print $2}'