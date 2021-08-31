#!bash
Home=/home/nsp/Downloads
sudo chroot  $Home/atmabundu/chroot bash <<"EOF"
apt-get update
apt-get install -y \
     openjdk-8-jdk \
     openjdk-8-jre

echo "   Remove unused applications (optional)"
apt-get purge -y \
     transmission-gtk \
     transmission-common \
     gnome-mahjongg \
     gnome-mines \
     gnome-sudoku \
     aisleriot \
     hitori
# Remove unused packages
apt-get autoremove -y

systemctl status display-manager.service
dpkg-reconfigure gdm3
EOF