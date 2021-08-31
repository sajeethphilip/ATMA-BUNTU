#!/bin/bash

echo "Changing root - Please verify"
ls -l
sleep 2

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C


echo "=================================Stage -2============================================"
sleep 5

cat <<EOF > /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse    
EOF

echo "=================================Stage -1============================================"
sleep 5
apt-get update
sudo apt autoremove
apt install -y dbus
apt-get install -y libterm-readline-gnu-perl systemd-sysv
apt-get install -y dialog
dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id

echo "=================================Stage 0============================================"
sleep 5
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
apt upgrade
apt-get install -y \
    sudo \
    ubuntu-standard \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober \
    network-manager \
    resolvconf \
    net-tools \
    wireless-tools \
    wpagui \
    locales \
    grub2-common\
    lilo\
    grml-rescueboot\
    screen
#    grub-gfxpayload-lists \
#    grub-pc \
#    grub-pc-bin 
apt-get install -y --no-install-recommends linux-generic
apt-get install --yes grub2 plymouth-x11
echo "=================================Stage 1============================================"
sleep 5
apt-get install -y \
    ubiquity \
    ubiquity-casper \
    ubiquity-frontend-gtk \
    ubiquity-frontend-kde \
    ubiquity-slideshow-ubuntu \
    ubiquity-ubuntu-artwork
echo "=================================Stage 2============================================"
sleep 5
apt-get install -y \
    plymouth-theme-ubuntu-logo \
    ubuntu-gnome-desktop \
    lxdm \
    sddm \
    lightdm \
    lxd   \
    lxde-core \
    lxde \
    lxctl \
    lxqt \
    lxd-tools \
    ubuntu-gnome-wallpapers
echo "=================================Stage 3============================================"
sleep 5
apt-get install -y \
    grub-customizer \
    terminator \
    apt-transport-https \
    curl \
    vim \
    nano \
    less

echo "=================================Stage 4============================================"
sudo add-apt-repository -y ppa:yannubuntu/boot-repair
sudo apt-get update
sudo apt-get install -y boot-repair 
sleep 5
echo" Example code installation--------------------------"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
rm microsoft.gpg

apt-get update
apt-get install -y code
echo "======================= Installing Browsers ======================================"
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

apt-get update
apt-get install google-chrome-stable
sudo apt -y install overlayroot
echo "overlayroot=tmpfs:swap=1,recurse=0">>/etc/overlayroot.conf
sudo apt install apt-transport-https curl

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

sudo apt -y install brave-browser

#--------------Install JDK 8----------------
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
apt-get autoremove -y

echo "Reconfigure packages"
# Generate locales
dpkg-reconfigure locales
echo "Reconfigure resolvconf"
dpkg-reconfigure resolvconf

echo "Configure Network manager"
cat <<EOF > /etc/NetworkManager/NetworkManager.conf
[main]
rc-manager=resolvconf
plugins=ifupdown,keyfile
dns=dnsmasq
[ifupdown]
managed=false
EOF
dpkg-reconfigure network-manager
echo "Setting up Grub"
mkdir -p /boot/efi/EFI/ubuntu
#echo GRUB_BACKGROUND="/usr/share/images/atmabuntu.png" >>/etc/default/grub
mv /etc/default/grub.1 /etc/default/grub
grub-mkconfig -o /boot/grub2/grub.cfg
grub-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg
cd /Update
/bin/bash ./Easy_install.sh
echo $$
rm -r /Update
rm /mkU*.sh
sudo dpkg-reconfigure lightdm
echo "------------------------------------------------------------------------------------------------------"
echo " Please click exit to Exit from the  prompt. You may check for commands or add new/remove with apt here"
echo "------------------------------------------------------------------------------------------------------"
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

sudo umount /sys
sudo umount /proc
sudo umount /dev/pts
echo "--------------------------------------------------------"
echo " Please click exit to Exit from the installation folder"
echo "--------------------------------------------------------"

