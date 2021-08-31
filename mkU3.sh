export Home="/home"
echo "Part 2"
cp PrepareDrive $Home/atmabundu/chroot/usr/bin/PrepareDrive
rm -r  $Home/atmabundu/image*
mv  $Home/atmabundu/atma*.iso  $Home/atmabundu/Old_atmabuntu.iso
cp -r etc $Home/atmabundu/chroot/
cp -r boot $Home/atmabundu/chroot/
echo  "alias mc='. /etc/mc/exitcwd' ">> $Home/atmabundu/chroot/etc/bash.bashrc
cat mycaty >$Home/atmabundu/chroot/etc/init.d/atma
chmod +x $Home/atmabundu/chroot/etc/init.d/atma
ln -sf ../init.d/atma $Home/atmabundu/chroot/etc/rc2.d/S01atma
ln -sf ../init.d/atma $Home/atmabundu/chroot/etc/rc3.d/S01atma
ln -sf ../init.d/atma $Home/atmabundu/chroot/etc/rc4.d/S01atma
ln -sf ../init.d/atma $Home/atmabundu/chroot/etc/rc5.d/S01atma
ln -sf ../init.d/atma $Home/atmabundu/chroot/etc/rcS.d/S01atma
cat mycatx >$Home/atmabundu/chroot/etc/init.d/atma0
chmod +x $Home/atmabundu/chroot/etc/init.d/atma0
ln -sf ../init.d/atma0 $Home/atmabundu/chroot/etc/rc6.d/K01atma
ln -sf ../init.d/atma0 $Home/atmabundu/chroot/etc/rc1.d/K01atma
ln -sf ../init.d/atma0 $Home/atmabundu/chroot/etc/rc0.d/K01atma
cp atmanidra $Home/atmabundu/chroot/usr/bin/
cp -r usr $Home/atmabundu/chroot/
echo "export GRUB_MENU_PICTURE=\"/usr/share/images/splash.png\"">>$Home/atmabundu/chroot/etc/default/grub
cd $Home/atmabundu
echo <<EOF > /etc/systemd/system/wol.service 
[Unit]
Description=Configure Wake-up on LAN

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s enp2s0 wol g

[Install]
WantedBy=basic.target 
EOF
chmod +x /etc/systemd/system/wol.service
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

menuentry "Try atmabuntu FS without installing" {
   linux /casper/vmlinuz boot=casper quiet splash ---
   initrd /casper/initrd
}

menuentry "Install atmabuntu FS" {
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
cp grub $Home/atmabundu/chroot/etc/default/
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
#define DISKNAME ATMA-BUNTU
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
   -volid "ATMABUNTU" \
   -output "../atmabuntu.iso" \
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
echo "======================Please insert Ventoy Pendrive and press Enter ============================="
sleep 100
#sudo dd if=atmabuntu.iso of=<device> status=progress oflag=sync
rm  /media/nsp/Ventoy/atmabuntu.iso
rsync $Home/atmabundu/atmabuntu.iso /media/nsp/Ventoy/atmabuntu.iso
umount /media/nsp/Ventoy/