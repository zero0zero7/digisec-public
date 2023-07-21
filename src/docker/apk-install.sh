#!/bin/bash
set -e


apk update && apk upgrade

apk add --quiet --no-progress openrc 
apk add --quiet --no-progress util-linux 
apk add --quiet --no-progress net-tools 
apk add --quiet --no-progress nftables 
apk add --quiet --no-progress kmod
apk add --quiet --no-progress slirp4netns
apk add --quiet --no-progress fuse-overlayfs
apk add --quiet --no-progress linux-lts
apk add --quiet --no-progress fuse
apk add --quiet --no-progress curl
apk add --quiet --no-progress libcap
apk add --quiet --no-progress file
apk add --quiet --no-progress shadow
apk add --quiet --no-progress tree 
apk add --quiet --no-progress acl
apk add --quiet --no-progress  attr

sed -i 's/^#rc_cgroup_mode="hybrid".*/rc_cgroup_mode="unified"/' /etc/rc.conf
apk add --quiet --no-progress podman
