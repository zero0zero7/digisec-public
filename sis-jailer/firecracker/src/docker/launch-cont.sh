#!/bin/sh

set -e 

podman run -i --rm --tmpdir /home/user1/var/tmp sisclient
reboot