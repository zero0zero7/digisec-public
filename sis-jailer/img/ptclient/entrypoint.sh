#!/bin/sh
ssh-keygen -A -f /tmp/ussh
/usr/sbin/sshd -d -f /tmp/ussh/etc/ssh/sshd_config
