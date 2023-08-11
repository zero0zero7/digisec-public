#!/bin/sh
set -x

mount /dev/vdb /setup
sh /setup/rw-setup.sh 
umount /setup
# mount /dev/vdb ie. rw-disk onto user1's home dir
mount -o size=2G -t tmpfs none /home/user1 
# reset permissions of /home/user1 to user1
chown -R user1 /home/user1 
chgrp -R user1 /home/user1 

#restart cgroups to set to v2
rc-service cgroups restart

chgrp user1 /dev/net/tun                                        
chgrp user1 /dev/fuse                                                
chmod 660 /dev/fuse                                                   
chmod 660 /dev/net/tun 

mkdir -p /home/user1/rundir/libpod
chown user1 /home/user1/rundir/libpod

mkdir -p /home/user1/run
chown user1 /home/user1/run

chown user1 /home/user1/rundir