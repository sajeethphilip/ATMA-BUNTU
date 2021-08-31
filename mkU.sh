export Home=$HOME/Downloads
sudo apt-get install \
    binutils \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools
sudo rm -r $Home/atmabundu
mkdir $Home/atmabundu

sudo debootstrap \
   --arch=amd64 \
   --variant=minbase \
   focal \
   $Home/atmabundu/chroot \
   http://us.archive.ubuntu.com/ubuntu/

sudo mount --bind /dev $Home/atmabundu/chroot/dev
sudo mount --bind /run $Home/atmabundu/chroot/run
cp -r Update $Home/atmabundu/chroot/
sudo chroot $Home/atmabundu/chroot gnome-terminal -e /bin/bash <<"EOT"

echo "Changing root - Please verify"
ls -l
sleep 2

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C

echo "atmabundu" > /etc/hostname

cat <<EOF > /etc/apt/sources.list
deb http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse
deb http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse 
deb-src http://us.archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse    
EOF


apt-get update

apt-get install -y libterm-readline-gnu-perl systemd-sysv

dbus-uuidgen > /etc/machine-id
ln -fs /etc/machine-id /var/lib/dbus/machine-id

echo "=================================Stage 0============================================"
sleep 5
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl
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
    grub-common \
    grub-gfxpayload-lists \
    grub-pc \
    grub-pc-bin \
    grub2-common
apt-get install -y --no-install-recommends linux-generic
echo "=================================Stage 1============================================"
sleep 5
apt-get install -y \
    ubiquity \
    ubiquity-casper \
    ubiquity-frontend-gtk \
    ubiquity-slideshow-ubuntu \
    ubiquity-ubuntu-artwork
echo "=================================Stage 2============================================"
sleep 5
apt-get install -y \
    plymouth-theme-ubuntu-logo \
    ubuntu-gnome-desktop \
    ubuntu-gnome-wallpapers
echo "=================================Stage 3============================================"
sleep 5
apt-get install -y \
    clamav-daemon \
    terminator \
    apt-transport-https \
    curl \
    vim \
    nano \
    less
echo "=================================Stage 4============================================"
sleep 5
echo" Example code installation--------------------------"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
rm microsoft.gpg

apt-get update
apt-get install -y code
#----------------------------chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

apt-get update
apt-get install google-chrome-stable

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
# Remove unused packages
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

echo "Cleanup the chroot environment"
#If you installed software, be sure to run
truncate -s 0 /etc/machine-id
#Remove the diversion
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
apt-get clean
rm -rf /tmp/* ~/.bash_history
umount /proc
umount /sys
umount /dev/pts
export HISTSIZE=0
cd /Update
/bin/bash ./Easy_install.sh
echo $$

EOT

exit

echo "Part 2"



sudo umount $Home/atmabundu/chroot/dev
sudo umount $Home/atmabundu/chroot/run

cd $Home/atmabundu
mkdir -p image/{casper,isolinux,install}
sudo cp chroot/boot/vmlinuz-**-**-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-**-**-generic image/casper/initrd
sudo cp chroot/boot/memtest86+.bin image/install/memtest86+

wget --progress=dot https://www.memtest86.com/downloads/memtest86-usb.zip -O image/install/memtest86-usb.zip
unzip -p image/install/memtest86-usb.zip memtest86-usb.img > image/install/memtest86
rm image/install/memtest86-usb.zip

cd $Home/atmabundu
touch image/ubuntu
echo"Create image/isolinux/grub.cfg"

cat <<EOF > image/isolinux/grub.cfg

search --set=root --file /ubuntu

insmod all_video

set default="0"
set timeout=30

menuentry "Try Ubuntu FS without installing" {
   linux /casper/vmlinuz boot=casper quiet splash ---
   initrd /casper/initrd
}

menuentry "Install Ubuntu FS" {
   linux /casper/vmlinuz boot=casper only-ubiquity quiet splash ---
   initrd /casper/initrd
}

menuentry "Check disc for defects" {
   linux /casper/vmlinuz boot=casper integrity-check quiet splash ---
   initrd /casper/initrd
}

menuentry "Test memory Memtest86+ (BIOS)" {
   linux16 /install/memtest86+
}

menuentry "Test memory Memtest86 (UEFI, long load time)" {
   insmod part_gpt
   insmod search_fs_uuid
   insmod chain
   loopback loop /install/memtest86
   chainloader (loop,gpt1)/efi/boot/BOOTX64.efi
}
EOF

cd $Home/atmabundu
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest

sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop

sudo sed -i '/ubiquity/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/casper/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/discover/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/laptop-detect/d' image/casper/filesystem.manifest-desktop

sudo sed -i '/os-prober/d' image/casper/filesystem.manifest-desktop

cd $Home/atmabundu

sudo mksquashfs chroot image/casper/filesystem.squashfs

printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

cd $Home/atmabundu

#Create file image/README.diskdefines
cat <<EOF > image/README.diskdefines
#define DISKNAME  Ubuntu from scratch
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  amd64
#define ARCHamd64  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1
EOF
cd $Home/atmabundu/image

#Create a grub UEFI image
grub-mkstandalone \
   --format=x86_64-efi \
   --output=isolinux/bootx64.efi \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

#Create a FAT16 UEFI boot disk image containing the EFI bootloader
(
   cd isolinux && \
   dd if=/dev/zero of=efiboot.img bs=1M count=10 && \
   sudo mkfs.vfat efiboot.img && \
   LC_CTYPE=C mmd -i efiboot.img efi efi/boot && \
   LC_CTYPE=C mcopy -i efiboot.img ./bootx64.efi ::efi/boot/
)

#►Create a grub BIOS image
grub-mkstandalone \
   --format=i386-pc \
   --output=isolinux/core.img \
   --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
   --modules="linux16 linux normal iso9660 biosdisk search" \
   --locales="" \
   --fonts="" \
   "boot/grub/grub.cfg=isolinux/grub.cfg"

#►Combine a bootable grub cdboot.img
cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img
#►Generate md5sum.txt
sudo /bin/bash -c "(find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt)"

#Create iso from the image directory using the command-line
sudo xorriso \
   -as mkisofs \
   -iso-level 3 \
   -full-iso9660-filenames \
   -volid "Ubuntu from scratch" \
   -output "../ubuntu-from-scratch.iso" \
   -eltorito-boot boot/grub/bios.img \
      -no-emul-boot \
      -boot-load-size 4 \
      -boot-info-table \
      --eltorito-catalog boot/grub/boot.cat \
      --grub2-boot-info \
      --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
   -eltorito-alt-boot \
      -e EFI/efiboot.img \
      -no-emul-boot \
   -append_partition 2 0xef isolinux/efiboot.img \
   -m "isolinux/efiboot.img" \
   -m "isolinux/bios.img" \
   -graft-points \
      "/EFI/efiboot.img=isolinux/efiboot.img" \
      "/boot/grub/bios.img=isolinux/bios.img" \
      "."

sudo dd if=ubuntu-from-scratch.iso of=<device> status=progress oflag=sync
