#!/bin/bash

echo "Changing root - Please verify"
ls -l
sleep 2

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
echo "------------------------------------------"
echo "Ready to set up. Press exit when done"
echo "------------------------------------------"
/bin/bash
echo "Cleanup the chroot environment"
#If you installed software, be sure to run
truncate -s 0 /etc/machine-id
#Remove the diversion
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/* ~/.bash_history
export HISTSIZE=0
rm mkU*.sh
rm -r Update
sudo umount /sys
sudo umount /proc
sudo umount /dev/pts
exit