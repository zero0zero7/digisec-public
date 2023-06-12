#!/bin/bash
set -e


# Set up a login terminal on the serial console (ttyS0):
echo "Setting up tty"
ln -s agetty /etc/init.d/agetty.ttyS0
echo ttyS0 > /etc/securetty
rc-update add agetty.ttyS0 default

# Make sure special file systems are mounted on boot:
echo "Mounting on boot"
rc-update add devfs boot
rc-update add procfs boot
rc-update add sysfs boot

# Then, copy the newly configured system to the rootfs image:
for d in bin etc lib root sbin usr; do tar c "/$d" | tar x -C /my-rootfs; done

# The above command may trigger the following message:
# tar: Removing leading "/" from member names
# However, this is just a warning, so you should be able to
# proceed with the setup process.

for dir in dev proc run sys var; do mkdir -p /my-rootfs/${dir}; done

echo "DONE applying"