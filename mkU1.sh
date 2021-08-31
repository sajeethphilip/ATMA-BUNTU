export Home="/home"
#/home/nsp/Downloads
echo "Please specify which version to install (tiny, executive, GIS):"
read vrname
export "$vrname"
sudo apt update
sudo apt upgrade
sudo apt-get -y install \
    grub2 \
    binutils \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    plymouth-themes
mkdir -p $Home/atmabundu

sudo debootstrap \
   --arch=amd64 \
   --variant=minbase \
   focal \
   $Home/atmabundu/chroot \
   http://us.archive.ubuntu.com/ubuntu/

sudo mount --bind /dev $Home/atmabundu/chroot/dev
sudo mount --bind /run $Home/atmabundu/chroot/run

if [ "$vrname" != "tiny" ]; then
cp -r Update_enterprice $Home/atmabundu/chroot/Update
if [  "$vrname" == "GIS" ]; then
cp Gis_packages_list.txt $Home/atmabundu/chroot/Update/packages_list.txt
fi
cp mkU2.sh  $Home/atmabundu/chroot/
else
cp -r Update $Home/atmabundu/chroot/
cp mkU20.sh  $Home/atmabundu/chroot/mkU2.sh
fi

mkdir -p $Home/atmabundu/chroot/usr/share/plymouth/themes/ubuntu-logo/
cp atmabuntu.png $Home/atmabundu/chroot/usr/share/plymouth/themes/ubuntu-logo/
cp atmabuntu.png $Home/atmabundu/chroot/usr/share/plymouth/themes/ubuntu-logo/atmabuntu16.png
cp Plymouth/default.plymouth $Home/atmabundu/chroot/usr/share/plymouth/
mkdir -p $Home/atmabundu/chroot/boot/grub2/images
cp Plymouth/atmabuntu.jpg $Home/atmabundu/chroot/boot/grub2/images/ # <-- provide the location of your image
mkdir -p $Home/atmabundu/chroot/etc/default
cp grub $Home/atmabundu/chroot/etc/default/grub.1


sudo chroot  $Home/atmabundu/chroot  


